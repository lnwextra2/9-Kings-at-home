extends Control
## กระดานวางการ์ด — วาดจาก Game.state, คลิกช่อง → emit slot_clicked (view ไม่แก้ state เอง)
signal slot_clicked(idx: int)

@export var cell_size: int = 72
@export var cell_gap: int = 8
@export_group("Colors")
@export var color_empty: Color = Color(0.20, 0.27, 0.36)   # ช่องปลดล็อก (ว่าง)
@export var color_locked: Color = Color(0.11, 0.12, 0.15)  # ช่องล็อก
@export var color_card: Color = Color(0.24, 0.34, 0.50)    # ช่องมีการ์ด

@onready var _grid: GridContainer = $Center/Grid


func _ready() -> void:
    refresh()


func refresh() -> void:
    for ch in _grid.get_children():
        ch.queue_free()
    var st: GameState = Game.state
    _grid.columns = st.cols
    _grid.add_theme_constant_override("h_separation", cell_gap)
    _grid.add_theme_constant_override("v_separation", cell_gap)
    for idx in st.board.size():
        _grid.add_child(_make_cell(st, idx))


func _make_cell(st: GameState, idx: int) -> Button:
    var cell := Button.new()
    cell.custom_minimum_size = Vector2(cell_size, cell_size)
    cell.focus_mode = Control.FOCUS_NONE
    cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var locked := st.is_locked(idx)
    var occ = st.board[idx]
    var col: Color = color_locked if locked else (color_card if occ is Dictionary else color_empty)
    var sb := StyleBoxFlat.new()
    sb.bg_color = col
    sb.set_corner_radius_all(8)
    for s in ["normal", "hover", "pressed", "disabled"]:
        cell.add_theme_stylebox_override(s, sb)
    if occ is Dictionary:
        var d: CardData = Content.card(occ.data_id)
        if d.sprite != null:
            cell.add_child(_sprite_rect(d.sprite))   # รูปกลางช่อง
        else:
            cell.text = d.display_name
        # ดาวบอก level (กลางด้านล่าง)
        cell.add_child(_overlay(_stars(int(occ.level)), Vector2(0, cell_size - 18), cell_size, HORIZONTAL_ALIGNMENT_CENTER, 12))
        # จำนวน current count (มุมขวาบน) — เฉพาะทหาร
        if d.kind == CardData.Kind.SOLDIER:
            cell.add_child(_overlay("×%d" % int(occ.cur_count), Vector2(cell_size - 32, 1), 30, HORIZONTAL_ALIGNMENT_RIGHT, 12))
    cell.disabled = locked
    if not locked:
        cell.pressed.connect(_emit_slot.bind(idx))
    return cell


func _sprite_rect(tex: Texture2D) -> TextureRect:
    var tr := TextureRect.new()
    tr.texture = tex
    tr.position = Vector2(6, 2)
    tr.size = Vector2(cell_size - 12, cell_size - 20)   # เว้นล่างไว้ให้ดาว
    tr.custom_minimum_size = tr.size
    tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE   # คลิกทะลุไปที่ปุ่มช่อง
    return tr


func _overlay(text: String, pos: Vector2, w: int, halign: int, fsize: int) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.custom_minimum_size = Vector2(w, 16)
    l.size = Vector2(w, 16)
    l.horizontal_alignment = halign
    l.add_theme_font_size_override("font_size", fsize)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE   # คลิกทะลุไปที่ปุ่มช่อง
    return l


## ดาวบอก level: filled = level, ที่เหลือเป็นดาวโปร่ง (cap แสดง 3)
func _stars(level: int) -> String:
    var filled: int = clampi(level, 0, 3)
    return "★".repeat(filled) + "☆".repeat(3 - filled)


func _emit_slot(idx: int) -> void:
    slot_clicked.emit(idx)
