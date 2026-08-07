extends Control
## การ์ดในมือ — เลือกได้ 1 ใบ (toggle) แล้ว emit ให้ controller เอาไปวาง
signal card_selected(index: int)

@export var card_w: int = 92
@export var card_h: int = 100

const HAND_CARD := preload("res://scenes/planning/hand_card.gd")

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


## หน้าการ์ดจริง: พื้นสีตามสีการ์ด + สไปรต์ + ป้ายชนิด(บนซ้าย) + ชื่อ(ล่าง)
## เลือกอยู่ = ขอบเหลือง (ใช้ stylebox "pressed" ของ toggle)
func _make_card(i: int, data_id: StringName) -> Button:
    var d: CardData = Content.card(data_id)
    var b := Button.new()
    b.set_script(HAND_CARD)   # ลากได้ (drag source)
    b.set(&"hand_index", i)
    b.set(&"card_data_id", data_id)
    b.custom_minimum_size = Vector2(card_w, card_h)
    b.toggle_mode = true
    b.focus_mode = Control.FOCUS_NONE
    var base: Color = _card_color(d.color)
    var sb := StyleBoxFlat.new()
    sb.bg_color = base
    sb.set_corner_radius_all(8)
    sb.set_border_width_all(2)
    sb.border_color = base.darkened(0.4)
    var sb_sel := sb.duplicate() as StyleBoxFlat
    sb_sel.border_color = Color(1.0, 0.92, 0.4)
    sb_sel.set_border_width_all(3)
    b.add_theme_stylebox_override("normal", sb)
    b.add_theme_stylebox_override("hover", sb_sel)
    b.add_theme_stylebox_override("pressed", sb_sel)   # toggled = เลือกอยู่
    b.add_theme_stylebox_override("focus", sb)

    var has_sprite: bool = d.sprite != null
    if has_sprite:
        var tr := TextureRect.new()
        tr.texture = d.sprite
        tr.position = Vector2(8, 16)
        tr.size = Vector2(card_w - 16, card_h - 46)
        tr.custom_minimum_size = tr.size
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(tr)

    b.add_child(_label(_kind_short(d.kind), Vector2(5, 3), card_w - 10, 9, HORIZONTAL_ALIGNMENT_LEFT))
    # ชื่อ: มีสไปรต์ = แถบล่าง / ไม่มีสไปรต์ = กลางใบ (ตัวใหญ่ขึ้น)
    if has_sprite:
        b.add_child(_label(d.display_name, Vector2(2, card_h - 22), card_w - 4, 12, HORIZONTAL_ALIGNMENT_CENTER))
    else:
        var nm := _label(d.display_name, Vector2(3, card_h * 0.4), card_w - 6, 13, HORIZONTAL_ALIGNMENT_CENTER)
        nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.add_child(nm)
    b.pressed.connect(_on_pick.bind(i))
    return b


## label ลูกการ์ด (คลิกทะลุ, มีเงาดำอ่านง่ายบนพื้นสี)
func _label(text: String, pos: Vector2, w: int, fsize: int, halign: int) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.size = Vector2(w, 18)
    l.custom_minimum_size = Vector2(w, 18)
    l.horizontal_alignment = halign
    l.clip_text = true
    l.add_theme_font_size_override("font_size", fsize)
    l.add_theme_color_override("font_color", Color(1, 1, 1))
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    l.add_theme_constant_override("outline_size", 4)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return l


## สีพื้นการ์ดตามสี (โทนเข้มพอให้ตัวหนังสือขาวอ่านออก) — เพิ่มสีใหม่ที่นี่
func _card_color(c: StringName) -> Color:
    match c:
        &"blue": return Color(0.24, 0.40, 0.72)
        &"red": return Color(0.72, 0.26, 0.24)
        &"mint": return Color(0.20, 0.55, 0.50)
        &"green": return Color(0.28, 0.55, 0.32)
        &"gold": return Color(0.70, 0.56, 0.20)
        &"gray": return Color(0.42, 0.45, 0.50)
        &"purple": return Color(0.48, 0.34, 0.66)
        &"orange": return Color(0.74, 0.46, 0.20)
        &"indigo": return Color(0.32, 0.34, 0.66)
        _: return Color(0.40, 0.42, 0.48)


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
