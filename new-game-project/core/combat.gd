class_name Combat
extends RefCounted
## tick การต่อสู้ (fixed 30/วิ) — core ล้วน อ่าน state.battle_cfg
## M2: brute-force หาเป้า (spatial hash = M3); dict ต่อยูนิต (SoA = M3)

const TICK: float = 1.0 / 30.0


static func tick(state: GameState, dt: float) -> void:
    if state.phase != &"combat" or state.result != &"":
        return
    var cfg: BattleConfig = state.battle_cfg
    var units: Array = state.units
    state.combat_time += dt
    var touched_base := false
    var hash := SpatialHash.build(units, cfg.hash_cell)

    for i in units.size():
        var u: Dictionary = units[i]
        if not u.alive:
            continue
        if u.attack_timer > 0.0:
            u.attack_timer -= dt
        if u.retarget_timer > 0.0:
            u.retarget_timer -= dt
        u.attacking = false

        # หาเป้าใหม่เมื่อ: ครบรอบ retarget / เป้าเดิมตาย — ไม่ re-scan ทุก tick ตอนไม่มีเป้า
        if u.retarget_timer <= 0.0 or (u.target_id != -1 and not _valid_target(units, u.target_id, u.team)):
            u.target_id = hash.nearest_enemy(units, u)
            u.retarget_timer = cfg.retarget_interval

        var tid: int = u.target_id
        if tid != -1:
            var t: Dictionary = units[tid]
            var dx: float
            var dy: float
            var dist: float
            if t.is_wall:
                dx = t.x - u.x   # แนวกั้น: ระยะแนวนอน, เข้าหาเส้นกำแพง ณ y ตัวเอง
                dy = 0.0
                dist = absf(dx)
            else:
                dx = t.x - u.x
                dy = t.y - u.y
                dist = sqrt(dx * dx + dy * dy)
            if dist <= u.attack_range:
                if u.attack > 0.0 and u.attack_timer <= 0.0:
                    _do_attack(state, cfg, i, tid)
            else:
                _move_toward(u, dx, dy, dist, dt)
        elif u.team == 1:
            # ศัตรูไม่มีเป้าที่ตีได้แล้ว → มุ่งเข้า "ฐาน" (เกาะกลุ่มเข้าหา)
            if _rush_base(state, cfg, u, dt):
                touched_base = true

    _update_projectiles(state, cfg, dt)
    _cleanup_deaths(state)
    _check_end(state, touched_base)


static func _valid_target(units: Array, tid: int, team: int) -> bool:
    if tid < 0 or tid >= units.size():
        return false
    var t: Dictionary = units[tid]
    return t.alive and t.targetable and t.team != team


static func _move_toward(u: Dictionary, dx: float, dy: float, dist: float, dt: float) -> void:
    if u.immobile or u.move_speed <= 0.0 or dist <= 0.0001:
        return
    var step: float = u.move_speed * dt
    u.x += dx / dist * step
    u.y += dy / dist * step


## คืน true ถ้าแตะฐาน
static func _rush_base(state: GameState, cfg: BattleConfig, u: Dictionary, dt: float) -> bool:
    var bi: int = state.base_unit
    if bi == -1:
        # ไม่มีฐาน → เดินซ้าย ถึงขอบ = แตะ (fallback)
        _move_toward(u, -1.0, 0.0, 1.0, dt)
        return u.x <= 0.0
    var b: Dictionary = state.units[bi]
    var dx: float = b.x - u.x
    var dy: float = b.y - u.y
    var dist: float = sqrt(dx * dx + dy * dy)
    if dist <= cfg.base_touch_radius:
        return true
    _move_toward(u, dx, dy, dist, dt)
    return false


static func _do_attack(state: GameState, cfg: BattleConfig, i: int, tid: int) -> void:
    var u: Dictionary = state.units[i]
    var t: Dictionary = state.units[tid]
    u.attack_timer = u.attack_cd
    u.attacking = true
    if u.attack_range > cfg.ranged_min_range:
        state.projectiles.append({
            "x": u.x, "y": u.y, "team": u.team,
            "target_id": tid, "damage": u.attack, "splash": u.splash,
            "speed": cfg.projectile_speed, "alive": true,
        })
    else:
        _deal(state, u.team, t.x, t.y, u.attack, u.splash, tid)


static func _deal(state: GameState, team: int, x: float, y: float, dmg: float, splash: float, tid: int) -> void:
    if splash <= 0.0:
        var t: Dictionary = state.units[tid]
        if t.alive:
            t.hp -= dmg
        return
    for o in state.units:
        if o.alive and o.team != team:
            var dx: float = o.x - x
            var dy: float = o.y - y
            if dx * dx + dy * dy <= splash * splash:
                o.hp -= dmg


static func _update_projectiles(state: GameState, cfg: BattleConfig, dt: float) -> void:
    var any_dead := false
    for p in state.projectiles:
        if not p.alive:
            continue
        var tid: int = p.target_id
        if tid < 0 or tid >= state.units.size() or not state.units[tid].alive:
            p.alive = false
            any_dead = true
            continue
        var t: Dictionary = state.units[tid]
        var dx: float = t.x - p.x
        var dy: float = t.y - p.y
        var dist: float = sqrt(dx * dx + dy * dy)
        var step: float = p.speed * dt
        if dist <= step or dist <= 0.0001:
            _deal(state, p.team, t.x, t.y, p.damage, p.splash, tid)
            p.alive = false
            any_dead = true
        else:
            p.x += dx / dist * step
            p.y += dy / dist * step
    if any_dead:
        state.projectiles = state.projectiles.filter(func(pp): return pp.alive)


static func _cleanup_deaths(state: GameState) -> void:
    for u in state.units:
        if u.alive and Unit.can_die(u) and u.hp <= 0.0:
            u.alive = false
            # on_death hooks = M3


static func _check_end(state: GameState, touched_base: bool) -> void:
    if touched_base:
        state.result = &"lose"
        return
    for u in state.units:
        if u.alive and u.team == 1:
            return   # ยังมีศัตรู
    state.result = &"win"
