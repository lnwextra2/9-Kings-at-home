class_name Stats
extends RefCounted
## จุดเดียวที่สร้าง/แก้ stat ตัวเลขของ card instance — เก็บ cur_* แล้ว mutate ตามลำดับ
## (บัฟถาวรไม่มีวันถอน → ไม่ต้อง log; ลำดับ ×%/+flat รักษาไว้เพราะแก้ตามที่ได้จริง)


## สร้าง card instance ใหม่ (level 1) จาก CardData
static func make_instance(data_id: StringName) -> Dictionary:
    var d: CardData = Content.card(data_id)
    var cnt: int = d.base_count if d.kind == CardData.Kind.SOLDIER else 1
    return {
        "data_id": data_id,
        "level": 1,
        "cur_hp": d.max_hp,
        "cur_attack": d.attack,
        "cur_aspd": 1.0,          # ตัวคูณความเร็วโจมตี (1.0 = ปกติ)
        "cur_count": cnt,         # soldier = base_count; โครงสร้าง = 1
        "abilities": d.abilities.duplicate(true),
        "no_spawn": false,
    }


## อัปเลเวล: hp/atk/aspd โต compound %, count (soldier) บวกเชิงเส้น
static func level_up(card: Dictionary) -> void:
    if card.level >= 3:
        return
    var d: CardData = Content.card(card.data_id)
    card.level += 1
    card.cur_hp *= (1.0 + d.growth_hp)
    card.cur_attack *= (1.0 + d.growth_attack)
    card.cur_aspd *= (1.0 + d.growth_attack_speed)
    if d.kind == CardData.Kind.SOLDIER:
        card.cur_count += d.base_count   # Lv1=bc, Lv2=2·bc, Lv3=3·bc


## บัฟ % ทบต้น (mutate ตามลำดับที่เรียก)
static func apply_pct(card: Dictionary, stat: StringName, pct: float) -> void:
    var key: String = "cur_" + stat
    card[key] = card[key] * (1.0 + pct)


## บัฟ flat บวก
static func apply_flat(card: Dictionary, stat: StringName, v: float) -> void:
    var key: String = "cur_" + stat
    card[key] = card[key] + v
