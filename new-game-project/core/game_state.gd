class_name GameState
extends RefCounted
## สถานะทั้งหมดของเกม (serialize ได้) — core/ ล้วน ห้ามรู้จัก Node

var phase: StringName = &"planning"   # planning / combat / reward / gameover
var floor_num: int = 1
var wave_color: StringName = &"blue"   # สีศัตรูเวฟนี้ (ศัตรูใช้การ์ดผู้เล่นสีนี้)
var wave_track: Array = []             # สถานีวางแผนล่วงหน้า: {type, color} ต่อ floor (index = floor-1)
var enemy_reroll_cost: int = 10        # รีโรลสีศัตรู (แพงขึ้นถาวร)
var gold: int = 30
var gold_earned: int = 0               # ทองสะสมทั้ง run (สำหรับหน้าสรุป)
var base_hp: int = 3                   # ชีวิตบ้าน
var kills: int = 0                     # ศัตรูที่ฆ่าทั้ง run (สำหรับหน้าสรุป)
var sell_value: int = 9                # ขายการ์ดในมือได้กี่ gold

var cols: int = 5
var rows: int = 5
var board: Array = []                  # cols*rows ช่อง: null (ว่าง) / &"locked" / card instance Dictionary
var hand: Array = []                   # การ์ดในมือ (Array ของ data_id StringName)
var shop: Array = []                   # ร้าน: data_id / &"" (ช่องซื้อไปแล้ว)

# reward (legacy — ยังไม่ลบ เผื่อใช้; flow ใหม่ใช้สถานี shop/blessing แทน)
var reward_cards: Array = []           # ตัวเลือกรางวัล (data_id)
var reward_reroll_cost: int = 10       # reset ทุกหน้า reward

# event overlay บน planning (&"" = ไม่มี, ต้องจบ event ก่อนเล่นการ์ดได้)
var event: StringName = &""            # "" / "shop" / "blessing" / "expand"

# blessing (เลือก 1 พร หรือรีโรล, stack ได้)
var blessings: Dictionary = {}         # {blessing_id: stacks} — global run modifier
var blessing_choice: StringName = &""  # พรที่เสนอ (1 อัน)
var blessing_reroll_cost: int = 10     # รีโรลพร (+10 ถาวร)

var rng: Rng                           # สุ่มทั้งหมดผ่านตัวนี้

# combat (ใช้เฉพาะ phase = combat, transient — ไม่ต้อง serialize กลางสนาม)
var units: Array = []                  # unit dict (M2); SoA เป็นงาน M3
var projectiles: Array = []
var damage_events: Array = []          # feed เลขดาเมจเด้ง (transient): {x,y,amount} — view drain ทิ้งทุกเฟรม
var buff_events: Array = []            # feed เลขบัฟบนกระดาน (transient): {slot,kind,...} — view drain
var combat_time: float = 0.0
var result: StringName = &""           # "" / "win" / "lose"
var base_unit: int = -1                # index ใน units ของฐาน (จุดที่ศัตรูมุ่งเข้าเมื่อทหารเราหมด)
var battle_cfg: BattleConfig           # config สนามรบ (set โดย Game; Resource ใช้ใน core ได้)


## สร้าง state เริ่มต้นจาก config — วางเลย์เอาต์ช่องปลดล็อก (บล็อกกลาง)
static func new_run(cfg: RunConfig) -> GameState:
	var s := GameState.new()
	s.rng = Rng.new()
	WaveGen.ensure_track(s, s.floor_num)            # วางแผนสถานีล่วงหน้า (แถบสถานี)
	s.wave_color = s.wave_track[s.floor_num - 1].color
	s.cols = cfg.board_cols
	s.rows = cfg.board_rows
	s.gold = cfg.start_gold
	s.gold_earned = cfg.start_gold
	s.base_hp = cfg.base_hp
	s.sell_value = cfg.sell_value
	s.board.resize(s.cols * s.rows)

	var mx: int = int((s.cols - cfg.unlocked_cols) / 2.0)   # margin ซ้าย/บนของบล็อกกลาง
	var my: int = int((s.rows - cfg.unlocked_rows) / 2.0)
	for r in s.rows:
		for c in s.cols:
			var unlocked: bool = c >= mx and c < mx + cfg.unlocked_cols \
				and r >= my and r < my + cfg.unlocked_rows
			s.board[r * s.cols + c] = null if unlocked else &"locked"

	# มือเริ่มต้น: ฐาน (บังคับวาง wave 0) + สุ่มทหาร start_cards ใบ
	s.hand = [&"mint_base"]
	var pool: Array = []
	for d in Content.all():
		if d.kind == CardData.Kind.SOLDIER and d.id != WaveGen.ENEMY_ID:   # เว้นการ์ดศัตรู debug
			pool.append(d.id)
	if not pool.is_empty():
		for i in cfg.start_cards:
			s.hand.append(pool[s.rng.randi_range(0, pool.size() - 1)])
	return s


func is_locked(idx: int) -> bool:
	# board[idx] เป็นได้ 3 แบบ: null / &"locked" (StringName) / card Dictionary
	# เลี่ยงเทียบ == ข้ามชนิด (Godot 4 error เมื่อ Dictionary == StringName)
	return board[idx] is StringName and board[idx] == &"locked"


func is_empty(idx: int) -> bool:
	return typeof(board[idx]) == TYPE_NIL
