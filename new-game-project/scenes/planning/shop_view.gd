extends Control
## ร้านค้า — โชว์การ์ดขาย 4 ช่อง + ปุ่ม reroll (view อ่าน state, ส่ง signal)
signal buy(index: int)
signal reroll_pressed

@onready var _row: HBoxContainer = $Panel/VBox/Row
@onready var _reroll: Button = $Panel/VBox/Reroll


func _ready() -> void:
    _reroll.pressed.connect(func(): reroll_pressed.emit())


func refresh() -> void:
    for ch in _row.get_children():
        ch.queue_free()
    var st: GameState = Game.state
    for i in st.shop.size():
        _row.add_child(_slot(i, st.shop[i]))
    _reroll.text = "รีโรล (%dg)" % Shop.REROLL_COST
    _reroll.disabled = st.gold < Shop.REROLL_COST


func _slot(i: int, data_id) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(100, 88)
    b.focus_mode = Control.FOCUS_NONE
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if not (data_id is StringName) or data_id == &"":
        b.text = "(ซื้อแล้ว)"
        b.disabled = true
        return b
    var d: CardData = Content.card(data_id)
    b.text = "%s\n%dg" % [d.display_name, d.cost]
    b.disabled = Game.state.gold < d.cost
    b.pressed.connect(func(): buy.emit(i))
    return b
