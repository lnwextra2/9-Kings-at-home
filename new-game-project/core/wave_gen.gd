class_name WaveGen
extends RefCounted
## เวฟศัตรู = การ์ด "ทหาร" สีเวฟ (เด็ค × level, level ทะลุ 3 ได้) — ไม่มี roster ศัตรูแยก
## แยกฝั่งด้วยสี HP bar (ทำใน render); ที่นี่แค่ team = 1

const ENEMY_ID := &"goblin"   # ใช้ใน debug spawn


static func scale_for(floor_num: int) -> float:
    return (1.0 + (floor_num - 1) * 0.13) * pow(1.062, floor_num - 1)


static func count_for(floor_num: int) -> int:
    return 3 + int(ceil(floor_num * floor_num * 0.24))


## enemy level ตาม floor (ทะลุ 3 — ศัตรูไม่มีบัฟ มีแต่ base × level)
static func level_for(floor_num: int) -> int:
    return maxi(1, 1 + int(float(floor_num) / 4.0))


## สีที่มีการ์ดทหาร (ศัตรูสุ่มจากนี้)
static func available_colors() -> Array:
    var seen: Dictionary = {}
    for d in Content.all():
        if d.kind == CardData.Kind.SOLDIER:
            seen[d.color] = true
    return seen.keys()


static func roll_color(rng: Rng) -> StringName:
    var cols: Array = available_colors()
    if cols.is_empty():
        return &"blue"
    return cols[rng.randi_range(0, cols.size() - 1)]


const TRACK_LOOKAHEAD := 6   # วางแผนสีเวฟล่วงหน้ากี่ floor (พอให้แถบสถานีมองไปข้างหน้าได้)


## ต่อ wave_track ให้ครอบคลุมถึง floor นี้ + lookahead (เรียกจาก sim เท่านั้น — ใช้ rng)
static func ensure_track(state: GameState, upto_floor: int) -> void:
    var need: int = upto_floor + TRACK_LOOKAHEAD
    while state.wave_track.size() < need:
        state.wave_track.append(roll_color(state.rng))


## floor นี้เป็นบอสไหม (ตอนนี้ใช้โชว์ไอคอนแถบสถานีอย่างเดียว — กลไกบอส = M5)
static func is_boss_floor(floor_num: int) -> bool:
    return floor_num % 5 == 0


static func _pool(color: StringName) -> Array:
    var out: Array = []
    for d in Content.all():
        if d.kind == CardData.Kind.SOLDIER and d.color == color:
            out.append(d)
    return out


static func make_wave(state: GameState, cfg: BattleConfig) -> Array:
    var out: Array = []
    var pool: Array = _pool(state.wave_color)
    if pool.is_empty():
        pool = _pool(&"blue")
    if pool.is_empty():
        return out
    var level: int = level_for(state.floor_num)
    var target: int = count_for(state.floor_num)
    var span: float = cfg.height - cfg.enemy_y_margin * 2.0
    var placed: int = 0
    var guard: int = 0
    while placed < target and guard < target * 4 + 8:
        guard += 1
        var d: CardData = pool[state.rng.randi_range(0, pool.size() - 1)]
        var inst: Dictionary = Stats.make_instance_at(d.id, level)   # การ์ด 1 ใบ ที่ level นี้
        var n: int = d.base_count * level
        for i in n:
            if placed >= target:
                break
            var t: float = 0.0 if target <= 1 else float(placed) / float(target - 1)
            var y: float = cfg.enemy_y_margin + t * span
            var x: float = cfg.enemy_x + (placed % 3) * cfg.enemy_spread
            out.append(Unit.from_instance(1, inst, x, y))
            placed += 1
    return out
