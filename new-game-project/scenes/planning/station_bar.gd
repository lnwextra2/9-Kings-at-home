extends Control
## แถบสถานีด้านบน — โชว์เวฟย้อนหลัง past_count + ปัจจุบัน + อนาคต future_count
## วาดจาก Game.state.wave_track (สีเวฟต่อ floor ที่วางแผนไว้): ปัจจุบัน=ไฮไลต์, ผ่านแล้ว=จาง
## จูนได้จาก @export ด้านล่าง

@export var past_count: int = 2
@export var future_count: int = 4
@export var node_radius: float = 14.0
@export var pad_x: float = 46.0
@export_group("Colors")
@export var line_color: Color = Color(0.5, 0.5, 0.55, 0.5)
@export var ring_current: Color = Color(1.0, 0.9, 0.4)
@export var ring_boss: Color = Color(0.95, 0.55, 0.2)
@export var ring_normal: Color = Color(0.22, 0.22, 0.26)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # ตกแต่งอย่างเดียว คลิกทะลุ
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var st: GameState = Game.state
	if st == null or st.wave_track.is_empty():
		return
	var cur: int = st.floor_num
	var lo: int = maxi(1, cur - past_count)
	var hi: int = cur + future_count
	var n: int = hi - lo + 1
	if n < 1:
		return
	var cy: float = size.y * 0.5 - 6.0
	var step: float = 0.0 if n <= 1 else (size.x - 2.0 * pad_x) / float(n - 1)
	var font: Font = ThemeDB.fallback_font

	# เส้นเชื่อมสถานี (วาดก่อน ให้วงกลมทับ)
	if n >= 2:
		draw_line(Vector2(pad_x, cy), Vector2(pad_x + step * (n - 1), cy), line_color, 2.0)

	for k in n:
		var f: int = lo + k
		var cx: float = pad_x + step * k
		var center := Vector2(cx, cy)
		var is_cur: bool = f == cur
		var is_past: bool = f < cur
		var typ: StringName = _station_type(st, f)
		var boss: bool = typ == &"boss"

		var fill: Color = _type_fill(st, f, typ)
		if is_past:
			fill = fill.darkened(0.55)
			fill.a = 0.75
		var r: float = node_radius + (3.0 if is_cur else 0.0) + (2.0 if boss else 0.0)
		draw_circle(center, r, fill)
		_draw_marker(center, typ)   # ไอคอนบอกชนิดสถานี (รูปทรง ไม่ใช่ glyph)

		var ring: Color = ring_normal
		var rw: float = 2.0
		if is_cur:
			ring = ring_current; rw = 3.0
		elif boss:
			ring = ring_boss; rw = 2.5
		draw_arc(center, r, 0.0, TAU, 28, ring, rw)

		# หมายเลข floor ใต้สถานี
		var num_col: Color = Color(0.92, 0.92, 0.96) if not is_past else Color(0.6, 0.6, 0.66)
		draw_string(font, Vector2(cx - 14.0, cy + r + 15.0), str(f),
			HORIZONTAL_ALIGNMENT_CENTER, 28.0, 12, num_col)


## ไอคอนกลางสถานี: ร้าน=สี่เหลี่ยม, พร=ข้าวหลามตัด, บอส=จุด, สู้=ว่าง
func _draw_marker(c: Vector2, typ: StringName) -> void:
	var ink := Color(1, 1, 1, 0.9)
	match typ:
		&"shop":
			draw_rect(Rect2(c - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), ink)
		&"blessing":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -6), c + Vector2(5, 0), c + Vector2(0, 6), c + Vector2(-5, 0)]), ink)
		&"boss":
			draw_circle(c, 3.5, Color(1, 0.85, 0.3))


func _station_type(st: GameState, f: int) -> StringName:
	var i: int = f - 1
	if i >= 0 and i < st.wave_track.size():
		return st.wave_track[i].type
	return WaveGen.station_type(f)


## สีวงกลม: combat/boss = สีเวฟ, shop = ทอง, blessing = ม่วง
func _type_fill(st: GameState, f: int, typ: StringName) -> Color:
	match typ:
		&"shop": return Color(0.72, 0.58, 0.22)
		&"blessing": return Color(0.50, 0.36, 0.70)
	var i: int = f - 1
	var col: StringName = st.wave_track[i].color if (i >= 0 and i < st.wave_track.size()) else &"?"
	return _wave_color_of(col)


## palette เดียวกับที่อื่น (ถ้าจะรวมเป็น config ที่เดียวค่อยทำภายหลัง)
func _wave_color_of(c: StringName) -> Color:
	match c:
		&"blue": return Color(0.30, 0.50, 0.90)
		&"red": return Color(0.85, 0.32, 0.28)
		&"mint": return Color(0.32, 0.80, 0.70)
		&"green": return Color(0.34, 0.72, 0.40)
		&"gold": return Color(0.88, 0.72, 0.24)
		&"gray": return Color(0.58, 0.60, 0.66)
		&"purple": return Color(0.62, 0.44, 0.82)
		&"orange": return Color(0.90, 0.56, 0.24)
		&"indigo": return Color(0.42, 0.44, 0.82)
		_: return Color(0.45, 0.45, 0.50)
