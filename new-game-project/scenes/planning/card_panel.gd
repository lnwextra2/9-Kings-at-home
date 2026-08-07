extends Control
## แผงรายละเอียดการ์ด (ซ้ายบน) — เลือกการ์ดในมือ = base stat / เลือกการ์ดบนกระดาน = current stat
## การ์ด: ครึ่งบน=รูป, ครึ่งล่าง=คำอธิบายสกิล, มุมซ้ายบน=ประเภท

@onready var _bg: ColorRect = $Card/Bg
@onready var _img: ColorRect = $Card/Image
@onready var _badge: Label = $Card/Badge
@onready var _name: Label = $Card/NameLabel
@onready var _desc: Label = $Card/Desc
signal sell_pressed

@onready var _stats: Label = $Stats

var _portrait: TextureRect
var _sell: Button


func _ready() -> void:
    _portrait = TextureRect.new()
    _portrait.position = _img.position
    _portrait.size = _img.size
    _portrait.custom_minimum_size = _img.size
    _portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _img.get_parent().add_child(_portrait)
    _sell = Button.new()
    _sell.text = "ขาย"
    _sell.position = Vector2(2, 474)
    _sell.custom_minimum_size = Vector2(196, 28)
    _sell.size = Vector2(196, 28)
    _sell.focus_mode = Control.FOCUS_NONE
    _sell.visible = false
    _sell.pressed.connect(func(): sell_pressed.emit())
    add_child(_sell)


func clear() -> void:
    visible = false


func show_base(data_id: StringName) -> void:
    var d: CardData = Content.card(data_id)
    if d == null:
        clear()
        return
    _fill_card(d, -1, d.abilities)
    _stats.text = _stat_lines_base(d)
    _sell.text = "ขาย (%dg)" % Game.state.sell_value
    _sell.visible = true
    visible = true


func show_current(card: Dictionary) -> void:
    var d: CardData = Content.card(card.data_id)
    if d == null:
        clear()
        return
    _fill_card(d, int(card.level), card.abilities)
    _stats.text = _stat_lines_current(card, d)
    _sell.visible = false
    visible = true


func _fill_card(d: CardData, level: int, abilities: Dictionary) -> void:
    var base_col := _color_of(d.color)
    _bg.color = base_col
    _img.color = base_col.darkened(0.4)
    _portrait.texture = d.sprite
    _badge.text = _kind_label(d.kind)
    _name.text = d.display_name if level < 0 else "%s  Lv%d" % [d.display_name, level]
    _desc.text = _desc_text(d, abilities)


func _desc_text(d: CardData, abilities: Dictionary) -> String:
    var s: String = d.description
    if not abilities.is_empty():
        s += "\n\n★ สกิลติดตัว:"
        for k in abilities:
            s += "\n• %s ×%d" % [str(k), int(abilities[k])]
    return s


func _stat_lines_base(d: CardData) -> String:
    var lines: Array = ["— Base —"]
    lines.append("HP      %s" % _fmt(d.max_hp))
    lines.append("ATK     %s" % _fmt(d.attack))
    if d.attack > 0.0:
        lines.append("CD      %.2fs" % d.attack_cd)
        lines.append("RANGE   %.0f" % d.attack_range)
    if d.move_speed > 0.0:
        lines.append("MOVE    %.0f" % d.move_speed)
    if d.kind == CardData.Kind.SOLDIER:
        lines.append("จำนวน   %d /Lv" % d.base_count)
    return "\n".join(lines)


func _stat_lines_current(card: Dictionary, d: CardData) -> String:
    var lines: Array = ["— Current (Lv%d) —" % int(card.level)]
    lines.append("HP      %s" % _fmt(card.cur_hp))
    lines.append("ATK     %s" % _fmt(card.cur_attack))
    if card.cur_attack > 0.0:
        lines.append("CD      %.2fs" % (d.attack_cd / maxf(card.cur_aspd, 0.01)))
        lines.append("RANGE   %.0f" % d.attack_range)
    if d.move_speed > 0.0:
        lines.append("MOVE    %.0f" % d.move_speed)
    if d.kind == CardData.Kind.SOLDIER:
        lines.append("จำนวน   %d" % int(card.cur_count))
    return "\n".join(lines)


func _fmt(v: float) -> String:
    return "—" if v <= 0.0 else str(snappedf(v, 0.1))


func _kind_label(k: int) -> String:
    match k:
        CardData.Kind.SOLDIER: return "[ ทหาร ]"
        CardData.Kind.BASE: return "[ ฐาน ]"
        CardData.Kind.BUILDING: return "[ สิ่งปลูก ]"
        CardData.Kind.TURRET: return "[ ป้อม ]"
        CardData.Kind.BUFF: return "[ บัฟ ]"
        CardData.Kind.TOME: return "[ โทม ]"
        _: return "?"


func _color_of(c: StringName) -> Color:
    match c:
        &"blue": return Color(0.24, 0.40, 0.72)
        &"red": return Color(0.72, 0.26, 0.24)
        &"mint": return Color(0.20, 0.55, 0.50)
        &"gold": return Color(0.75, 0.60, 0.20)
        &"green": return Color(0.28, 0.55, 0.32)
        &"gray": return Color(0.42, 0.45, 0.50)
        &"purple": return Color(0.48, 0.34, 0.66)
        &"orange": return Color(0.74, 0.46, 0.20)
        &"indigo": return Color(0.32, 0.34, 0.66)
        _: return Color(0.40, 0.42, 0.48)
