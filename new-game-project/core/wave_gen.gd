class_name WaveGen
extends RefCounted
## สร้างเวฟศัตรู (team 1) ตาม floor — สูตร scale/count จาก design doc 8.1
## (ระบบสีศัตรู/ใช้การ์ดสีนั้น = M4; M2 ใช้ goblin ล้วน)

const ENEMY_ID := &"goblin"


static func scale_for(floor_num: int) -> float:
    return (1.0 + (floor_num - 1) * 0.13) * pow(1.062, floor_num - 1)


static func count_for(floor_num: int) -> int:
    return 3 + int(ceil(floor_num * floor_num * 0.24))


static func make_wave(state: GameState, cfg: BattleConfig) -> Array:
    var out: Array = []
    var n: int = count_for(state.floor_num)
    var scale: float = scale_for(state.floor_num)
    var span: float = cfg.height - cfg.enemy_y_margin * 2.0
    for i in n:
        var t: float = 0.0 if n <= 1 else float(i) / float(n - 1)
        var y: float = cfg.enemy_y_margin + t * span
        var x: float = cfg.enemy_x + (i % 3) * cfg.enemy_spread
        out.append(Unit.from_data_scaled(1, ENEMY_ID, x, y, scale))
    return out
