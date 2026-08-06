class_name GameState
extends RefCounted
## สถานะทั้งหมดของเกม (serialize ได้) — core/ ล้วน ห้ามรู้จัก Node

var phase: StringName = &"planning"   # planning / combat / reward / gameover
var floor_num: int = 1
var gold: int = 30
var base_hp: int = 3                   # ชีวิตบ้าน

var cols: int = 5
var rows: int = 5
var board: Array = []                  # cols*rows ช่อง: null (ว่าง) / &"locked" / card instance Dictionary
var hand: Array = []                   # การ์ดในมือ (Array ของ data_id StringName)


## สร้าง state เริ่มต้นจาก config — วางเลย์เอาต์ช่องปลดล็อก (บล็อกกลาง)
static func new_run(cfg: RunConfig) -> GameState:
	var s := GameState.new()
	s.cols = cfg.board_cols
	s.rows = cfg.board_rows
	s.gold = cfg.start_gold
	s.base_hp = cfg.base_hp
	s.board.resize(s.cols * s.rows)

	var mx: int = int((s.cols - cfg.unlocked_cols) / 2.0)   # margin ซ้าย/บนของบล็อกกลาง
	var my: int = int((s.rows - cfg.unlocked_rows) / 2.0)
	for r in s.rows:
		for c in s.cols:
			var unlocked: bool = c >= mx and c < mx + cfg.unlocked_cols \
				and r >= my and r < my + cfg.unlocked_rows
			s.board[r * s.cols + c] = null if unlocked else &"locked"
	return s


func is_locked(idx: int) -> bool:
	# board[idx] เป็นได้ 3 แบบ: null / &"locked" (StringName) / card Dictionary
	# เลี่ยงเทียบ == ข้ามชนิด (Godot 4 error เมื่อ Dictionary == StringName)
	return board[idx] is StringName and board[idx] == &"locked"


func is_empty(idx: int) -> bool:
	return typeof(board[idx]) == TYPE_NIL
