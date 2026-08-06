class_name Unit
extends RefCounted
## โรงงานสร้าง unit dict สำหรับสนามรบ (M2 = dict ต่อยูนิต; SoA เป็นงาน M3)
## team: 0 = เรา, 1 = ศัตรู


static func from_instance(team: int, inst: Dictionary, x: float, y: float) -> Dictionary:
    var d: CardData = Content.card(inst.data_id)
    var u := _blank(team, d, x, y)
    u.hp = inst.cur_hp
    u.max_hp = inst.cur_hp
    u.attack = inst.cur_attack
    u.attack_cd = d.attack_cd / maxf(inst.cur_aspd, 0.01)   # aspd_mult ย่น cooldown
    return u


static func from_data_scaled(team: int, data_id: StringName, x: float, y: float, scale: float) -> Dictionary:
    var d: CardData = Content.card(data_id)
    var u := _blank(team, d, x, y)
    u.hp = d.max_hp * scale
    u.max_hp = u.hp
    u.attack = d.attack * scale
    u.attack_cd = d.attack_cd
    return u


static func _blank(team: int, d: CardData, x: float, y: float) -> Dictionary:
    var targetable := true    # ศัตรูตีได้ไหม
    var immobile := false
    var is_base := false
    match d.kind:
        CardData.Kind.BASE:
            targetable = false
            immobile = true
            is_base = true
        CardData.Kind.TURRET:
            targetable = false    # untargetable
            immobile = true
        CardData.Kind.BUILDING:
            immobile = true
            targetable = d.max_hp > 0.0   # กำแพง (มี HP) ตีได้ / ซัพพอร์ตไม่ลงสนามอยู่แล้ว
    return {
        "team": team,
        "data_id": d.id,
        "kind": d.kind,
        "x": x, "y": y,
        "hp": 0.0, "max_hp": 0.0,
        "attack": 0.0,
        "attack_cd": 1.0,
        "attack_range": d.attack_range,
        "move_speed": d.move_speed,
        "splash": d.splash_radius,
        "targetable": targetable,
        "immobile": immobile,
        "is_base": is_base,
        "attack_timer": 0.0,      # นับถอยหลังถึงตีครั้งถัดไป
        "target_id": -1,
        "retarget_timer": 0.0,
        "attacking": false,       # ใช้ตอน render (เอียง 45°)
        "alive": true,
    }


## ตายได้เฉพาะ unit ที่มี HP จริง (max_hp>0) — ฐาน/ป้อม (max_hp 0) ไม่มีวันตาย
static func can_die(u: Dictionary) -> bool:
    return u.max_hp > 0.0
