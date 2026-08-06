class_name Spawner
extends RefCounted
## กระดาน → ยูนิตฝั่งเรา (team 0) — ตำแหน่ง map จาก col/row ของช่อง


static func spawn_player(state: GameState, cfg: BattleConfig) -> Array:
    var out: Array = []
    for idx in state.board.size():
        var c = state.board[idx]
        if not (c is Dictionary):
            continue
        var d: CardData = Content.card(c.data_id)
        if not d.goes_to_field():
            continue
        var col: int = idx % state.cols
        var row: int = idx / state.cols
        var px: float = cfg.our_x0 + col * cfg.our_col_dx
        var py: float = cfg.our_y0 + row * cfg.our_row_dy
        if d.kind == CardData.Kind.SOLDIER:
            var cnt: int = int(c.cur_count)
            for n in cnt:
                var off := _cluster_offset(n, cfg.soldier_spread)
                out.append(Unit.from_instance(0, c, px + off.x, py + off.y))
        else:
            out.append(Unit.from_instance(0, c, px, py))
    return out


## กระจายทหารเป็นคลัสเตอร์ 3×N รอบจุด spawn (deterministic — ไม่ใช้ rng)
static func _cluster_offset(n: int, spread: float) -> Vector2:
    var gx: int = (n % 3) - 1
    var gy: int = (n / 3) - 1
    return Vector2(gx * spread, gy * spread)
