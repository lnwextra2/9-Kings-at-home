extends Control
## กระดานวางการ์ด — M0: โชว์กริด 5×5 (3×3 กลางปลดล็อก) คลิกได้ ยังไม่มี logic

@export var cell_size: int = 72
@export var cell_gap: int = 8
@export_group("Colors")
@export var color_empty: Color = Color(0.20, 0.27, 0.36)   # ช่องปลดล็อก (ว่าง)
@export var color_locked: Color = Color(0.11, 0.12, 0.15)  # ช่องล็อก

@onready var _grid: GridContainer = $Center/Grid


func _ready() -> void:
    _build()


func _build() -> void:
    var st: GameState = Game.state
    _grid.columns = st.cols
    _grid.add_theme_constant_override("h_separation", cell_gap)
    _grid.add_theme_constant_override("v_separation", cell_gap)
    for idx in st.board.size():
        _grid.add_child(_make_cell(idx, st.is_locked(idx)))


func _make_cell(idx: int, locked: bool) -> Button:
    var cell := Button.new()
    cell.custom_minimum_size = Vector2(cell_size, cell_size)
    cell.focus_mode = Control.FOCUS_NONE
    var sb := StyleBoxFlat.new()
    sb.bg_color = color_locked if locked else color_empty
    sb.set_corner_radius_all(8)
    for state_name in ["normal", "hover", "pressed"]:
        cell.add_theme_stylebox_override(state_name, sb)
    cell.pressed.connect(_on_cell_pressed.bind(idx))
    return cell


func _on_cell_pressed(idx: int) -> void:
    print("clicked slot %d (locked=%s)" % [idx, Game.state.is_locked(idx)])
