extends Control
## หน้ารางวัล — จบเวฟ (แพ้/ชนะก็ได้) เลือกการ์ด 1 จาก 3 + reroll
signal picked(index: int)
signal reroll_pressed

@onready var _title: Label = $Panel/VBox/Title
@onready var _row: HBoxContainer = $Panel/VBox/Row
@onready var _reroll: Button = $Panel/VBox/Reroll


func _ready() -> void:
    _reroll.pressed.connect(func(): reroll_pressed.emit())


func refresh() -> void:
    var st: GameState = Game.state
    var res: String = "ชนะเวฟ!" if st.result == &"win" else "แพ้เวฟ (บ้าน −1 HP)"
    _title.text = "%s   —   เลือกการ์ดรางวัล 1 ใบ   (HP บ้าน %d)" % [res, st.base_hp]
    for ch in _row.get_children():
        ch.queue_free()
    for i in st.reward_cards.size():
        _row.add_child(_card(i, st.reward_cards[i]))
    _reroll.text = "รีโรลรางวัล (%dg)" % st.reward_reroll_cost
    _reroll.disabled = st.gold < st.reward_reroll_cost


func _card(i: int, data_id: StringName) -> Button:
    var d: CardData = Content.card(data_id)
    var b := Button.new()
    b.custom_minimum_size = Vector2(130, 120)
    b.focus_mode = Control.FOCUS_NONE
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.text = d.display_name
    b.pressed.connect(func(): picked.emit(i))
    return b
