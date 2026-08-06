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
        cell.text = "%s\nLv%d" % [d.display_name, occ.level]
    cell.disabled = locked
    if not locked:
        cell.pressed.connect(_emit_slot.bind(idx))
    return cell


func _emit_slot(idx: int) -> void:
    slot_clicked.emit(idx)
