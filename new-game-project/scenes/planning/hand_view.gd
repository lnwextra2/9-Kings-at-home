extends Control
## การ์ดในมือ — เลือกได้ 1 ใบ (toggle) แล้ว emit ให้ controller เอาไปวาง
signal card_selected(index: int)

@export var card_w: int = 92
@export var card_h: int = 100

@onready var _row: HBoxContainer = $Center/Row


func refresh() -> void:
    for ch in _row.get_children():
        ch.queue_free()
    var hand: Array = Game.state.hand
    for i in hand.size():
        _row.add_child(_make_card(i, hand[i]))


## ไฮไลต์ใบที่เลือก (toggle ปุ่มอื่นออก)
func set_selected(sel: int) -> void:
    var idx := 0
    for ch in _row.get_children():
        (ch as Button).button_pressed = (idx == sel)
        idx += 1


func _make_card(i: int, data_id: StringName) -> Button:
    var d: CardData = Content.card(data_id)
    var b := Button.new()
    b.custom_minimum_size = Vector2(card_w, card_h)
    b.toggle_mode = true
    b.focus_mode = Control.FOCUS_NONE
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.text = "%s\n[%s]" % [d.display_name, _kind_short(d.kind)]
    b.pressed.connect(_on_pick.bind(i))
    return b


func _on_pick(i: int) -> void:
    set_selected(i)
    card_selected.emit(i)


func _kind_short(k: int) -> String:
    match k:
        CardData.Kind.SOLDIER: return "ทหาร"
        CardData.Kind.BASE: return "ฐาน"
        CardData.Kind.BUILDING: return "สิ่งปลูก"
        CardData.Kind.TURRET: return "ป้อม"
        CardData.Kind.BUFF: return "บัฟ"
        CardData.Kind.TOME: return "โทม"
        _: return "?"
