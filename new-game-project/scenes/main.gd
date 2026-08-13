extends Control
## ตัวสลับ phase — planning (วาง+ร้าน) ↔ combat (สนามรบ) ↔ reward ↔ gameover
## UI ทั้งหมดเป็น node ใน main.tscn (จัดใน editor ได้) — สคริปต์แค่ wire signal + refresh

@onready var _top: Label = $TopBar
@onready var _planning: Control = $Planning
@onready var _board = $Planning/BoardView
@onready var _hand = $Planning/HandView
@onready var _fight: Button = $Planning/FightButton
@onready var _color_btn: Button = $Planning/ColorButton
@onready var _panel = $Planning/CardPanel
@onready var _shop = $ShopView
@onready var _shop_continue: Button = $ShopContinue
@onready var _blessing = $BlessingView
@onready var _expand_prompt: Label = $ExpandPrompt
@onready var _event_toggle: Button = $EventToggle
@onready var _reward = $RewardView
@onready var _sell_zone = $Planning/SellZone
@onready var _station = $StationBar
@onready var _battle = $Battlefield
@onready var _devbtn: Button = $DevButton
@onready var _debug = $DebugView
@onready var _overlay: Control = $ResultOverlay
@onready var _result_label: Label = $ResultOverlay/Panel/VBox/ResultLabel
@onready var _continue: Button = $ResultOverlay/Panel/VBox/ContinueButton

@export_group("End-turn buff sequence")   # จังหวะเลขบัฟเด้งตอนจบเทิร์นก่อนเข้ารบ — จูนได้
@export var buff_burst_delay: float = 0.20   # เว้นระหว่างแต่ละ burst (สิ่งก่อสร้าง/ครั้ง)
@export var buff_tail: float = 0.6           # หน่วงท้ายให้เห็น burst สุดท้าย ก่อนเข้าสนามรบ

var _color_sb: StyleBoxFlat
var _sel_hand: int = -1
var _sel_slot: int = -1
var _resolving: bool = false   # กำลังเล่นอนิเมชั่นจบเทิร์น (บล็อก input)
var _peek: bool = false        # ปิด window อีเวนต์ชั่วคราวเพื่อดูกระดาน (ยังอยู่ใน event)


func _ready() -> void:
	_hand.connect("card_selected", _on_card_selected)
	_board.connect("slot_clicked", _on_slot_clicked)
	_board.connect("card_dropped", _on_card_dropped)
	_sell_zone.connect("sell_dropped", _on_sell_dropped)
	_fight.pressed.connect(_on_fight)
	_battle.connect("combat_ended", _on_combat_ended)
	_continue.pressed.connect(_on_gameover_continue)
	_panel.connect("sell_pressed", _on_sell)
	_panel.clear()
	_shop.connect("buy", _on_buy)
	_shop.connect("reroll_pressed", _on_shop_reroll)
	_shop_continue.pressed.connect(_on_shop_continue)
	_blessing.connect("picked", _on_blessing_pick)
	_blessing.connect("reroll_pressed", _on_blessing_reroll)
	_event_toggle.pressed.connect(func(): _peek = not _peek; _refresh_event())
	_reward.connect("picked", _on_reward_pick)
	_reward.connect("reroll_pressed", _on_reward_reroll)
	_debug.connect("give_card", _on_dbg_give)
	_debug.connect("give_gold", _on_dbg_gold)
	_debug.connect("skip_floor", _on_dbg_skip)
	_debug.connect("spawn_enemies", _on_dbg_spawn)
	_debug.connect("clear_enemies", _on_dbg_clear)
	_debug.visible = false
	_devbtn.pressed.connect(func(): _debug.visible = not _debug.visible)
	_color_btn.pressed.connect(_on_reroll_color)
	_color_sb = StyleBoxFlat.new()   # พื้นปุ่มสีเวฟ (เปลี่ยนสีตามเวฟใน _update_top)
	_color_sb.set_corner_radius_all(6)
	for _cs in ["normal", "hover", "pressed", "disabled"]:
		_color_btn.add_theme_stylebox_override(_cs, _color_sb)
	_refresh_planning()
	_update_phase()


func _on_reroll_color() -> void:
	if GameSim.step(Game.state, {"type": &"reroll_color"}):
		_refresh_planning()


## สีพื้นปุ่มสีเวฟ (โทนกลาง อ่านตัวหนังสือขาวออก) — เพิ่มสีใหม่ที่นี่
func _wave_btn_color(c: StringName) -> Color:
	match c:
		&"blue": return Color(0.24, 0.40, 0.66)
		&"red": return Color(0.62, 0.24, 0.22)
		&"green": return Color(0.24, 0.50, 0.30)
		&"gold": return Color(0.58, 0.48, 0.16)
		&"mint": return Color(0.22, 0.52, 0.46)
		_: return Color(0.30, 0.32, 0.36)


func _color_name(c: StringName) -> String:
	match c:
		&"blue": return "ฟ้า"
		&"red": return "แดง"
		&"green": return "เขียว"
		&"gold": return "ทอง"
		&"mint": return "มินต์"
		_: return str(c)


func _on_dbg_give(id: StringName) -> void:
	GameSim.step(Game.state, {"type": &"dbg_give", "data_id": id})
	_refresh_planning()


func _on_dbg_gold() -> void:
	GameSim.step(Game.state, {"type": &"dbg_gold", "amount": 100})
	_refresh_planning()


func _on_dbg_skip() -> void:
	GameSim.step(Game.state, {"type": &"dbg_skip_floor", "amount": 1})
	_refresh_planning()
	_update_phase()


func _on_dbg_spawn() -> void:
	GameSim.step(Game.state, {"type": &"dbg_spawn_enemies", "count": 20})


func _on_dbg_clear() -> void:
	GameSim.step(Game.state, {"type": &"dbg_clear_enemies"})


# --- planning: place / inspect ---
func _on_card_selected(i: int) -> void:
	_sel_hand = i
	_sel_slot = -1
	_panel.show_base(Game.state.hand[i])


func _on_slot_clicked(idx: int) -> void:
	if _resolving:
		return
	var ev: StringName = Game.state.event
	if ev == &"expand":   # อีเวนต์ขยาย: คลิกช่องล็อกที่ติดพื้นที่ = ปลดล็อก
		if GameSim.step(Game.state, {"type": &"expand_tile", "slot": idx}):
			_reset_selection()
			_refresh_planning()
			_update_phase()
		return
	if ev != &"":   # อีเวนต์อื่น: ดู stat การ์ดได้ แต่เล่นไม่ได้
		var t = Game.state.board[idx]
		if t is Dictionary:
			_panel.show_current(t)
		else:
			_panel.clear()
		return
	if _sel_hand >= 0:
		var d: CardData = Content.card(Game.state.hand[_sel_hand])
		var act: StringName = &"use_card" if (d.kind == CardData.Kind.BUFF or d.kind == CardData.Kind.TOME) else &"place_card"
		if GameSim.step(Game.state, {"type": act, "hand_index": _sel_hand, "slot": idx}):
			_sel_hand = -1
			_hand.set_selected(-1)
			_refresh_planning()
			_flush_buff_pops()
			var occ = Game.state.board[idx]
			if occ is Dictionary:
				_panel.show_current(occ)
			else:
				_panel.clear()
		return
	_hand.set_selected(-1)
	var target = Game.state.board[idx]
	if target is Dictionary:
		_sel_slot = idx
		_panel.show_current(target)
	else:
		_sel_slot = -1
		_panel.clear()


## ระบายเลขบัฟที่ core ปล่อยไว้ → เด้งที่ช่องเป้าหมายบนกระดาน (เรียกหลัง refresh)
func _flush_buff_pops() -> void:
	for e in Game.state.buff_events:
		_board.pop_buff(e.slot, _buff_text(e), _buff_color(e))
	Game.state.buff_events.clear()


func _buff_text(e: Dictionary) -> String:
	match e.kind:
		&"stat":
			var s: String = _stat_label(e.stat)
			if e.is_percent:
				return "+%d%% %s" % [int(round(float(e.amount) * 100.0)), s]
			return "+%d %s" % [int(round(float(e.amount))), s]
		&"gold":
			return "+%dg" % int(e.amount)
		&"level":
			return "Lv +1"
		&"clone":
			return "แยกร่าง!"   # สไลม์ก็อปตัวเองลงช่องว่าง
		&"grow":
			return "+%d%% ALL" % int(round(float(e.amount) * 100.0))   # orc โตทุก stat
	return "+%d %s" % [int(e.stacks), str(e.ability)]   # ability buff


func _buff_color(e: Dictionary) -> Color:
	match e.kind:
		&"stat": return Color(0.45, 0.95, 0.55)   # เขียว
		&"gold": return Color(0.98, 0.82, 0.30)   # ทอง
		&"level": return Color(0.80, 0.60, 1.0)   # ม่วง = อัพเลเวล
		&"clone": return Color(0.55, 0.95, 0.85)  # เขียวมิ้นต์ = สไลม์แยกร่าง
		&"grow": return Color(1.0, 0.55, 0.35)    # ส้มแดง = orc โต
	return Color(0.55, 0.75, 1.0)                  # ฟ้า = ability


## ชื่อย่อ stat สำหรับโชว์ (เพิ่ม stat ใหม่ที่นี่)
func _stat_label(s: StringName) -> String:
	match s:
		&"attack": return "dmg"
		&"max_hp": return "hp"
		&"attack_cd": return "aspd"
		&"count": return "count"
		&"move_speed": return "spd"
		_: return str(s)


## ลากการ์ดจากมือมาวางบนช่องกระดาน (drag-drop)
func _on_card_dropped(slot: int, hand_index: int) -> void:
	if _resolving or hand_index < 0 or hand_index >= Game.state.hand.size():
		return
	var d: CardData = Content.card(Game.state.hand[hand_index])
	var act: StringName = &"use_card" if (d.kind == CardData.Kind.BUFF or d.kind == CardData.Kind.TOME) else &"place_card"
	if GameSim.step(Game.state, {"type": act, "hand_index": hand_index, "slot": slot}):
		_reset_selection()
		_refresh_planning()
		_flush_buff_pops()
		var occ = Game.state.board[slot]
		if occ is Dictionary:
			_panel.show_current(occ)
		else:
			_panel.clear()


## ลากการ์ดจากมือมาปล่อยที่บ่อขาย
func _on_sell_dropped(hand_index: int) -> void:
	if _resolving or hand_index < 0 or hand_index >= Game.state.hand.size():
		return
	if GameSim.step(Game.state, {"type": &"sell_card", "hand_index": hand_index}):
		_reset_selection()
		_refresh_planning()


func _on_sell() -> void:
	if _sel_hand < 0:
		return
	if GameSim.step(Game.state, {"type": &"sell_card", "hand_index": _sel_hand}):
		_sel_hand = -1
		_hand.set_selected(-1)
		_panel.clear()
		_refresh_planning()


# --- shop station ---
func _on_buy(index: int) -> void:
	if GameSim.step(Game.state, {"type": &"buy", "shop_index": index}):
		_shop.refresh()
		_hand.refresh()
		_update_top()


func _on_shop_reroll() -> void:
	if GameSim.step(Game.state, {"type": &"reroll_shop"}):
		_shop.refresh()
		_update_top()


func _on_shop_continue() -> void:
	if GameSim.step(Game.state, {"type": &"shop_continue"}):
		_reset_selection()
		_refresh_planning()
		_update_phase()


# --- combat ---
## กดเริ่มรบ: ยิงบัฟจบเทิร์น → board ค้างเล่นเลขบัฟเรียงลำดับ → แล้วค่อยเข้าสนามรบ
func _on_fight() -> void:
	if _resolving:
		return
	GameSim.step(Game.state, {"type": &"resolve_turn"})   # บัฟถูก apply แล้ว, ได้ buff_events
	_board.refresh()                                       # โชว์ stat/count ใหม่บนกระดานก่อนเด้งเลข
	var events: Array = Game.state.buff_events.duplicate()
	Game.state.buff_events.clear()
	if events.is_empty():
		_begin_combat()
		return
	_resolving = true
	_fight.disabled = true
	_play_buff_sequence(events)


## แบ่ง events ตาม burst แล้วตั้งเวลาเด้งเป็นสเต็ป (burst เดียวกัน = พร้อมกัน)
func _play_buff_sequence(events: Array) -> void:
	var by_burst: Dictionary = {}
	var max_b: int = 0
	for e in events:
		var b: int = int(e.get("burst", 0))
		max_b = maxi(max_b, b)
		if not by_burst.has(b):
			by_burst[b] = []
		by_burst[b].append(e)
	for b in by_burst:
		var delay: float = float(b) * buff_burst_delay
		get_tree().create_timer(delay).timeout.connect(_pop_group.bind(by_burst[b]))
	var total: float = float(max_b) * buff_burst_delay + buff_tail
	get_tree().create_timer(total).timeout.connect(_begin_combat)


func _pop_group(group: Array) -> void:
	for e in group:
		_board.pop_buff(e.slot, _buff_text(e), _buff_color(e))


func _begin_combat() -> void:
	_resolving = false
	GameSim.step(Game.state, {"type": &"begin_combat"})
	_battle.start()
	_update_phase()


func _on_combat_ended() -> void:
	GameSim.end_combat(Game.state)   # ตั้ง phase ถัดไป (สถานีถัดไป / gameover / won)
	_battle.visible = false
	_reset_selection()
	_refresh_planning()
	_update_phase()


# --- reward (หลังจบเวฟ) ---
func _on_reward_pick(index: int) -> void:
	if GameSim.step(Game.state, {"type": &"pick_reward", "index": index}):
		_reset_selection()
		_refresh_planning()
		_update_phase()


func _on_reward_reroll() -> void:
	if GameSim.step(Game.state, {"type": &"reroll_reward"}):
		_reward.refresh()
		_update_top()


# --- blessing station ---
func _on_blessing_pick() -> void:
	if GameSim.step(Game.state, {"type": &"pick_blessing"}):
		_reset_selection()
		_refresh_planning()
		_update_phase()


func _on_blessing_reroll() -> void:
	if GameSim.step(Game.state, {"type": &"reroll_blessing"}):
		_blessing.refresh()
		_update_top()


# --- gameover / won ---
func _on_gameover_continue() -> void:
	Game.restart()
	_overlay.visible = false
	_reset_selection()
	_refresh_planning()
	_update_phase()


# --- shared ---
func _update_phase() -> void:
	_peek = false                       # สถานีใหม่ = โชว์ window อีเวนต์เสมอ
	var ph: StringName = Game.state.phase
	_planning.visible = ph == &"planning"
	_battle.visible = ph == &"combat"
	_overlay.visible = ph == &"gameover" or ph == &"won"
	if ph == &"gameover":
		var st: GameState = Game.state
		_result_label.text = "GAME OVER\nไปถึงชั้น %d    ฆ่าศัตรู %d    ทองสะสม %d\n\n(กด 'ต่อไป' เพื่อเริ่มใหม่)" % [st.floor_num, st.kills, st.gold_earned]
	elif ph == &"won":
		var st2: GameState = Game.state
		_result_label.text = "🏆 ชนะแล้ว!\nพิชิตบอสเวฟ 30    ฆ่าศัตรู %d    ทองสะสม %d\n\n(กด 'ต่อไป' เพื่อเริ่มใหม่)" % [st2.kills, st2.gold_earned]
	_refresh_event()
	_update_top()


## โชว์ window อีเวนต์ (shop/blessing) ทับ planning หรือ prompt (expand); peek = ปิดชั่วคราว
func _refresh_event() -> void:
	var ev: StringName = Game.state.event
	var in_plan: bool = Game.state.phase == &"planning"
	var active: bool = in_plan and ev != &""
	var windowed: bool = ev == &"shop" or ev == &"blessing" or ev == &"reward"
	var show_win: bool = active and windowed and not _peek
	_shop.visible = ev == &"shop" and show_win
	_shop_continue.visible = ev == &"shop" and show_win
	_blessing.visible = ev == &"blessing" and show_win
	_reward.visible = ev == &"reward" and show_win
	_expand_prompt.visible = active and ev == &"expand"
	_event_toggle.visible = active and windowed
	_event_toggle.text = "👁 ดูอีเวนต์" if _peek else "👁 ดูกระดาน"
	_fight.visible = in_plan and ev == &""   # สู้ได้เฉพาะสถานี combat (ไม่มี event)
	if _shop.visible:
		_shop.refresh()
	if _blessing.visible:
		_blessing.refresh()
	if _reward.visible:
		_reward.refresh()


func _refresh_planning() -> void:
	_board.refresh()
	_hand.refresh()
	_fight.disabled = Board.find_base(Game.state) == -1   # บังคับวางฐานก่อนรบ
	_update_top()


func _reset_selection() -> void:
	_sel_hand = -1
	_sel_slot = -1
	_hand.set_selected(-1)
	_panel.clear()


func _update_top() -> void:
	var st: GameState = Game.state
	var ph: String = "วางแผน"
	if st.phase == &"combat":
		ph = "สู้!"
	elif st.phase == &"gameover":
		ph = "จบเกม"
	elif st.phase == &"won":
		ph = "ชนะ!"
	elif st.event == &"shop":
		ph = "ร้านค้า"
	elif st.event == &"blessing":
		ph = "พร"
	elif st.event == &"expand":
		ph = "ขยายพื้นที่"
	elif st.event == &"reward":
		ph = "รางวัล"
	_top.text = "ชั้น %d  ·  gold %d  ·  HP %d  ·  [%s]" % [st.floor_num, st.gold, st.base_hp, ph]
	# ปุ่มรีโรลสีศัตรู เฉพาะสถานี combat (planning ไม่มี event)
	_color_btn.visible = st.phase == &"planning" and st.event == &""
	_color_btn.text = "ศัตรูเวฟนี้: สี%s   ·   รีโรล %dg" % [_color_name(st.wave_color), st.enemy_reroll_cost]
	_color_btn.disabled = st.gold < st.enemy_reroll_cost
	_color_sb.bg_color = _wave_btn_color(st.wave_color)
	_station.refresh()
