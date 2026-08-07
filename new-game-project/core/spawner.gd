class_name Spawner
extends RefCounted
## กระดาน → ยูนิตฝั่งเรา (team 0)
## - ทหาร: ตั้งแถวด้านหน้า (แนวตั้ง) เติมแถวใหม่ไปทางฐาน, จำกัดจำนวนแถว (เกินแล้วบีบระยะ)
## - กำแพง: รวมทุกใบเป็น unit เดียว HP รวมกัน วางเป็นแนวกั้นหลังทหาร
## - ฐาน/ป้อม: ที่ตำแหน่ง map จากช่องกระดาน (ป้อมยิงทั้งสนาม — ดู Unit.from_instance)


static func spawn_player(state: GameState, cfg: BattleConfig) -> Array:
    var out: Array = []
    var soldiers: Array = []   # card instance ต่อ 1 ยูนิต
    var wall_hp: float = 0.0
    for idx in state.board.size():
        var c = state.board[idx]
        if not (c is Dictionary):
            continue
        var d: CardData = Content.card(c.data_id)
        if not d.goes_to_field():
            continue
        if d.kind == CardData.Kind.SOLDIER:
            for n in int(c.cur_count):
                soldiers.append(c)
        elif d.kind == CardData.Kind.BUILDING and d.max_hp > 0.0:
            wall_hp += float(c.cur_hp)   # กำแพง — รวม HP ทุกใบ
        else:
            var col: int = idx % state.cols
            var row: int = idx / state.cols
            out.append(Unit.from_instance(0, c, cfg.our_x0 + col * cfg.our_col_dx, cfg.our_y0 + row * cfg.our_row_dy))
    _place_formation(out, soldiers, cfg)
    if wall_hp > 0.0:
        out.append(Unit.make_wall(wall_hp, cfg.wall_x, cfg.height * 0.5))
    return out


static func _place_formation(out: Array, soldiers: Array, cfg: BattleConfig) -> void:
    var melee: Array = []
    var ranged: Array = []
    for c in soldiers:
        if Content.card(c.data_id).attack_range > cfg.ranged_min_range:
            ranged.append(c)
        else:
            melee.append(c)
    var melee_cols: int = _fill_group(out, melee, cfg, cfg.front_x)          # ตีใกล้ = แถวหน้า
    _fill_group(out, ranged, cfg, cfg.front_x - melee_cols * cfg.col_dx)     # ยิงไกล = แถวหลัง


## เติมทหาร 1 กลุ่มเป็นคอลัมน์ (แนวลึกไปทางฐาน) — กระจายเต็มความสูงต่อคอลัมน์ (จัดกึ่งกลาง)
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
        var x: float = front - col * cfg.col_dx
        var y: float = margin + (row + 0.5) * (zone_h / float(count_in_col))   # กระจายเต็มความสูง
        out.append(Unit.from_instance(0, group[i], x, y))
    return cols
