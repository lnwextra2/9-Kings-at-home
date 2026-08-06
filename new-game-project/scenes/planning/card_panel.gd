extends Control
## แผงรายละเอียดการ์ด (ซ้ายบน) — เลือกการ์ดในมือ = base stat / เลือกการ์ดบนกระดาน = current stat
## การ์ด: ครึ่งบน=รูป, ครึ่งล่าง=คำอธิบายสกิล, มุมซ้ายบน=ประเภท

@onready var _bg: ColorRect = $Card/Bg
@onready var _img: ColorRect = $Card/Image
@onready var _badge: Label = $Card/Badge
@onready var _name: Label = $Card/NameLabel
@onready var _desc: Label = $Card/Desc
@onready var _stats: Label = $Stats


func clear() -> void:
    visible = false


func show_base(data_id: StringName) -> void:
    var d: CardData = Content.card(data_id)
    if d == null:
        clear()
        return
    _fill_card(d, -1, d.abilities)
    _stats.text = _stat_lines_base(d)
    visible = true


func show_current(card: Dictionary) -> void:
    var d: CardData = Content.card(card.data_id)
    if d == null:
        clear()
        return
    _fill_card(d, int(card.level), card.abilities)
    _stats.text = _stat_lines_current(card, d)
    visible = true


func _fill_card(d: CardData, level: int, abilities: Dictionary) -> void:
    var base_col := _color_of(d.color)
    _bg.color = base_col
    _img.color = base_col.darkened(0.4)
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
        &"gold": return Color(0.75, 0.60, 0.20)
        &"green": return Color(0.28, 0.55, 0.32)
        _: return Color(0.40, 0.42, 0.48)
