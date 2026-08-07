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
    var total: int = soldiers.size()
    if total == 0:
        return
    var margin: float = cfg.enemy_y_margin
    var zone_h: float = cfg.height - 2.0 * margin
    var rows: int = maxi(1, int(zone_h / cfg.row_dy))
    var cols: int = int(ceil(float(total) / float(rows)))
    var rdy: float = cfg.row_dy
    if cols > cfg.max_cols:
        cols = cfg.max_cols
        rows = int(ceil(float(total) / float(cols)))
        rdy = zone_h / float(rows)   # แถวเต็ม max แล้ว → บีบระยะในแถวให้พอ
    for i in total:
        var col: int = i / rows
        var row: int = i % rows
        var x: float = cfg.front_x - col * cfg.col_dx
        var y: float = margin + row * rdy
        out.append(Unit.from_instance(0, soldiers[i], x, y))
