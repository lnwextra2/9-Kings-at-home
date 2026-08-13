class_name Spawner
extends RefCounted
## กระดาน → ยูนิตฝั่งเรา (team 0)
## - ทหาร: ตั้งแถวด้านหน้า (แนวตั้ง) เติมแถวใหม่ไปทางฐาน, จำกัดจำนวนแถว (เกินแล้วบีบระยะ)
## - กำแพง: รวมทุกใบเป็น unit เดียว HP รวมกัน วางเป็นแนวกั้นหลังทหาร
## - ฐาน/ป้อม: ที่ตำแหน่ง map จากช่องกระดาน (ป้อมยิงทั้งสนาม — ดู Unit.from_instance)


## ทุกการ์ดบนกระดานโผล่ในสนามที่ "ตำแหน่งช่อง"; ทหารสปอว์นที่ช่องแล้วเดินไปตั้งแถว;
## ซัพพอร์ต (ฟาร์ม/ตลาด ฯลฯ) โผล่แบบ inert (ตีไม่โดน ไม่ทำอะไร); กำแพงรวม HP เป็นแนวกั้น
static func spawn_player(state: GameState, cfg: BattleConfig) -> Array:
    var out: Array = []
    var soldiers: Array = []   # {inst, bx, by} — ทหาร 1 ยูนิต + ตำแหน่งช่องที่ออก
    var wall_hp: float = 0.0
    for idx in state.board.size():
        var c = state.board[idx]
        if not (c is Dictionary):
            continue
        var d: CardData = Content.card(c.data_id)
        var col: int = idx % state.cols
        var row: int = idx / state.cols
        var bx: float = cfg.our_x0 + col * cfg.our_col_dx
        var by: float = cfg.our_y0 + row * cfg.our_row_dy
        if d.kind == CardData.Kind.SOLDIER:
            var cnt: int = int(c.cur_count)
            if d.count_per_gold > 0:                              # mercenary: fix count ตามทอง (ไม่ขึ้น level)
                cnt = 1 + state.gold / d.count_per_gold
            for n in cnt + Blessing.count_add(state):             # พร +count ทุกเวฟ
                soldiers.append({"inst": c, "bx": bx, "by": by})
        elif d.kind == CardData.Kind.BUILDING and d.max_hp > 0.0:
            wall_hp += float(c.cur_hp)   # กำแพง — รวม HP ทุกใบ
        else:
            out.append(Unit.from_instance(0, c, bx, by))   # ฐาน/ป้อม/ซัพพอร์ต ที่ช่อง
    _place_formation(out, soldiers, cfg)
    if wall_hp > 0.0:
        out.append(Unit.make_wall(wall_hp, cfg.wall_x, cfg.height * 0.5))
    _apply_blessings(state, out)
    return out


## พร global: +dmg/crit ทุกยูนิตที่ตี, +hp เฉพาะทหาร (ฝั่งเราเท่านั้น — ศัตรูไม่ได้)
static func _apply_blessings(state: GameState, out: Array) -> void:
    var dm: float = Blessing.dmg_mult(state)
    var ca: float = Blessing.crit_add(state)
    var hm: float = Blessing.hp_mult(state)
    for u in out:
        if u.attack > 0.0:
            u.attack *= dm
        if ca > 0.0:
            u.crit = minf(u.crit + ca, 1.0)
        if u.kind == CardData.Kind.SOLDIER and hm != 1.0:
            u.hp *= hm
            u.max_hp *= hm


static func _place_formation(out: Array, soldiers: Array, cfg: BattleConfig) -> void:
    var melee: Array = []
    var ranged: Array = []
    for e in soldiers:
        if Content.card(e.inst.data_id).attack_range > cfg.ranged_min_range:
            ranged.append(e)
        else:
            melee.append(e)
    var melee_cols: int = _fill_group(out, melee, cfg, cfg.front_x)          # ตีใกล้ = แถวหน้า
    _fill_group(out, ranged, cfg, cfg.front_x - melee_cols * cfg.col_dx)     # ยิงไกล = แถวหลัง


## เติมทหาร 1 กลุ่ม: สปอว์นที่ช่อง (e.bx,e.by) + ตั้ง march target = จุดยืนในแถว
## คืนจำนวนคอลัมน์ที่ใช้
static func _fill_group(out: Array, group: Array, cfg: BattleConfig, front: float) -> int:
    var total: int = group.size()
    if total == 0:
        return 0
    var margin: float = cfg.enemy_y_margin
    var zone_h: float = cfg.height - 2.0 * margin
    var max_rows: int = maxi(1, int(zone_h / cfg.row_dy))
    var cols: int = clampi(int(ceil(float(total) / float(max_rows))), 1, cfg.max_cols)
    var base_n: int = total / cols
    var rem: int = total % cols
    for i in total:
        var col: int = i % cols
        var row: int = i / cols
        var count_in_col: int = base_n + (1 if col < rem else 0)   # จำนวนตัวในคอลัมน์นี้
        var tx: float = front - col * cfg.col_dx
        var ty: float = margin + (row + 0.5) * (zone_h / float(count_in_col))   # กระจายเต็มความสูง
        var e: Dictionary = group[i]
        var u: Dictionary = Unit.from_instance(0, e.inst, e.bx, e.by)   # ออกจากช่อง
        u.marching = true
        u.march_fx = e.bx
        u.march_fy = e.by
        u.march_tx = tx
        u.march_ty = ty
        if Content.card(e.inst.data_id).warp_backline:   # goblin: ตั้งแถวเสร็จแล้วกระโดดไป backline
            u.will_leap = true
            u.leap_tx = cfg.warp_x
            u.leap_ty = ty
        out.append(u)
    return cols
