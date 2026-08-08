class_name Combat
extends RefCounted
## tick การต่อสู้ (fixed 30/วิ) — core ล้วน อ่าน state.battle_cfg
## M2: brute-force หาเป้า (spatial hash = M3); dict ต่อยูนิต (SoA = M3)

const TICK: float = 1.0 / 30.0


static func tick(state: GameState, dt: float) -> void:
    if state.phase != &"combat" or state.result != &"":
        return
    var cfg: BattleConfig = state.battle_cfg
    if state.forming:   # ทหารเดินจากช่องมาตั้งแถวก่อน (freeze การสู้ ทุกคนถึงพร้อมกัน)
        _tick_forming(state, cfg, dt)
        return
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

        if u.bombs_left > 0:   # Trapper: วิ่งไปวางระเบิดทีละลูกก่อน แล้วค่อยสู้
            _trapper_lay(state, cfg, u, dt)
            continue

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
    _update_bombs(state)
    _cleanup_deaths(state)
    _check_end(state, touched_base)


## ช่วงตั้งแถว: interpolate ทุกทหาร march_from → march_to ด้วย t เดียวกัน (ถึงพร้อมกันใน form_duration)
static func _tick_forming(state: GameState, cfg: BattleConfig, dt: float) -> void:
    state.form_t += dt
    var t: float = clampf(state.form_t / maxf(cfg.form_duration, 0.001), 0.0, 1.0)
    var te: float = t * t * (3.0 - 2.0 * t)   # smoothstep (ออกตัว/เข้าที่นุ่ม)
    for u in state.units:
        if u.marching:
            u.x = lerpf(u.march_fx, u.march_tx, te)
            u.y = lerpf(u.march_fy, u.march_ty, te)
    if t >= 1.0:
        for u in state.units:
            if u.marching:
                u.x = u.march_tx
                u.y = u.march_ty
                u.marching = false
        state.forming = false


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
    u.attack_timer = u.attack_cd
    u.attacking = true
    if u.shots <= 1:
        _fire_one(state, cfg, u, tid)   # ปกติ: ยิงเป้าเดิม (ใกล้สุด)
        return
    # multishot: N นัด สุ่มเป้าอิสระ (สุ่มซ้ำตัวเดิมได้ → บอสเดี่ยวกินหมด)
    var enemies: Array = _alive_enemies(state, u.team)
    if enemies.is_empty():
        return
    for _s in u.shots:
        var rt: int = enemies[state.rng.randi_range(0, enemies.size() - 1)]
        _fire_one(state, cfg, u, rt)


## ยิง 1 นัดใส่ target tid — roll crit ต่อนัด แล้วยิง projectile (ranged) หรือลงดาเมจ (melee)
static func _fire_one(state: GameState, cfg: BattleConfig, u: Dictionary, tid: int) -> void:
    var t: Dictionary = state.units[tid]
    var dmg: float = u.attack
    if u.crit > 0.0 and state.rng.randf() < u.crit:   # คริ = ดาเมจ × crit_mult (สุ่มผ่าน state.rng)
        dmg *= cfg.crit_mult
    if u.attack_range > cfg.ranged_min_range:
        if u.pierce or u.splash > 0.0:
            # ballistic เส้นตรง (บาริสต้าทะลุ / splash ตีหมู่) — เล็งพิกัดเป้า ณ ตอนยิง
            var dx: float = t.x - u.x
            var dy: float = t.y - u.y
            var dist: float = maxf(sqrt(dx * dx + dy * dy), 0.001)
            var spd: float = cfg.projectile_speed
            state.projectiles.append({
                "mode": &"pierce" if u.pierce else &"splash",
                "x": u.x, "y": u.y, "team": u.team,
                "vx": dx / dist * spd, "vy": dy / dist * spd,
                "damage": dmg, "splash": u.splash,
                "remaining": dist, "hit": {}, "alive": true,
            })
        else:
            # เป้าเดี่ยว = homing (ล็อกเป้า ตามจนโดน — ยิงตัวเคลื่อนที่ไม่พลาด)
            state.projectiles.append({
                "mode": &"homing",
                "x": u.x, "y": u.y, "team": u.team,
                "target_id": tid, "damage": dmg,
                "speed": cfg.projectile_speed, "alive": true,
            })
    else:
        _deal(state, u.team, t.x, t.y, dmg, u.splash, tid)


## index ของศัตรูฝั่งตรงข้ามที่ยังตีได้ (สำหรับ multishot สุ่มเป้า)
static func _alive_enemies(state: GameState, team: int) -> Array:
    var out: Array = []
    for i in state.units.size():
        var o: Dictionary = state.units[i]
        if o.alive and o.targetable and o.team != team:
            out.append(i)
    return out


static func _deal(state: GameState, team: int, x: float, y: float, dmg: float, splash: float, tid: int) -> void:
    if splash <= 0.0:
        var t: Dictionary = state.units[tid]
        if t.alive:
            if t.block > 0:
                t.block -= 1   # เกราะกำบัง: กันดาเมจเต็มครั้ง
                return
            t.hp -= dmg
            if team == 0:   # เราตีศัตรู → ปล่อยเลขดาเมจให้ view วาด
                state.damage_events.append({"x": t.x, "y": t.y, "amount": dmg})
        return
    for o in state.units:
        if o.alive and o.team != team:
            var dx: float = o.x - x
            var dy: float = o.y - y
            if dx * dx + dy * dy <= splash * splash:
                if o.block > 0:
                    o.block -= 1   # เกราะกำบัง: กัน AoE เต็มครั้ง
                    continue
                o.hp -= dmg
                if team == 0:
                    state.damage_events.append({"x": o.x, "y": o.y, "amount": dmg})


static func _update_projectiles(state: GameState, cfg: BattleConfig, dt: float) -> void:
    var any_dead := false
    for p in state.projectiles:
        if not p.alive:
            continue
        var died: bool
        match p.mode:
            &"homing":
                died = _tick_homing(state, p, dt)   # เป้าเดี่ยว: ตามเป้าจนโดน
            &"pierce":
                died = _tick_pierce(state, cfg, p, dt)   # บาริสต้า: เส้นตรง ทะลุตลอดเส้น
            _:
                died = _tick_splash(state, cfg, p, dt)   # splash: เส้นตรง ตกแล้วระเบิด
        if died:
            any_dead = true
    if any_dead:
        state.projectiles = state.projectiles.filter(func(pp): return pp.alive)


## homing: วิ่งเข้าหาเป้าปัจจุบัน (เป้าตาย/หาย = หาย); ถึงเป้า = ลงดาเมจเดี่ยว
static func _tick_homing(state: GameState, p: Dictionary, dt: float) -> bool:
    var tid: int = p.target_id
    if tid < 0 or tid >= state.units.size() or not state.units[tid].alive:
        p.alive = false
        return true
    var t: Dictionary = state.units[tid]
    var dx: float = t.x - p.x
    var dy: float = t.y - p.y
    var dist: float = sqrt(dx * dx + dy * dy)
    var step: float = p.speed * dt
    if dist <= step or dist <= 0.0001:
        if t.block > 0:
            t.block -= 1
        else:
            t.hp -= p.damage
            if p.team == 0:
                state.damage_events.append({"x": t.x, "y": t.y, "amount": p.damage})
        p.alive = false
        return true
    p.x += dx / dist * step
    p.y += dy / dist * step
    return false


## splash ballistic: วิ่งตรงถึงพิกัดที่เล็ง → ระเบิด AoE (splash ครอบตัวที่ขยับหนีไม่ไกล)
static func _tick_splash(state: GameState, cfg: BattleConfig, p: Dictionary, dt: float) -> bool:
    var sx: float = p.vx * dt
    var sy: float = p.vy * dt
    var step_len: float = sqrt(sx * sx + sy * sy)
    if step_len >= p.remaining:
        var f: float = p.remaining / maxf(step_len, 0.0001)
        p.x += sx * f
        p.y += sy * f
        _damage_area(state, p.team, p.x, p.y, p.damage, maxf(p.splash, cfg.projectile_hit_radius))
        p.alive = false
        return true
    p.x += sx
    p.y += sy
    p.remaining -= step_len
    return false


## pierce ballistic: เช็คชนตาม "ช่วงเส้น" ที่วิ่ง tick นี้ (กันทะลุข้ามตัว) โดนศัตรูทุกตัวในเส้น ครั้งละตัว
static func _tick_pierce(state: GameState, cfg: BattleConfig, p: Dictionary, dt: float) -> bool:
    var ax: float = p.x
    var ay: float = p.y
    var bx: float = ax + p.vx * dt
    var by: float = ay + p.vy * dt
    var r2: float = cfg.projectile_pierce_radius * cfg.projectile_pierce_radius
    for i in state.units.size():
        var o: Dictionary = state.units[i]
        if not o.alive or o.team == p.team or not o.targetable or p.hit.has(i):
            continue
        if _dist2_seg(o.x, o.y, ax, ay, bx, by) <= r2:
            p.hit[i] = true
            if o.block > 0:
                o.block -= 1
                continue
            o.hp -= p.damage
            if p.team == 0:
                state.damage_events.append({"x": o.x, "y": o.y, "amount": p.damage})
    p.x = bx
    p.y = by
    return bx < -50.0 or bx > cfg.width + 50.0 or by < -50.0 or by > cfg.height + 50.0


## ลงดาเมจศัตรูในรัศมี r รอบ (x,y) — เคารพ block + ปล่อยเลขดาเมจ
static func _damage_area(state: GameState, team: int, x: float, y: float, dmg: float, r: float) -> void:
    var r2: float = r * r
    for o in state.units:
        if o.alive and o.targetable and o.team != team:
            var dx: float = o.x - x
            var dy: float = o.y - y
            if dx * dx + dy * dy <= r2:
                if o.block > 0:
                    o.block -= 1
                    continue
                o.hp -= dmg
                if team == 0:
                    state.damage_events.append({"x": o.x, "y": o.y, "amount": dmg})


## Trapper วางระเบิดทีละลูก: วิ่งกลับไปจุดหน้ากำแพง (สุ่ม) → ถึงแล้ววาง 1 ลูก → เลือกจุดใหม่
static func _trapper_lay(state: GameState, cfg: BattleConfig, u: Dictionary, dt: float) -> void:
    if u.bomb_tx < 0.0:
        u.bomb_tx = cfg.wall_x + state.rng.randf() * cfg.bomb_scatter
        u.bomb_ty = u.y + (state.rng.randf() - 0.5) * 2.0 * cfg.bomb_scatter
    var dx: float = u.bomb_tx - u.x
    var dy: float = u.bomb_ty - u.y
    var dist: float = sqrt(dx * dx + dy * dy)
    if dist <= 6.0:
        state.bombs.append({"x": u.x, "y": u.y, "damage": u.attack, "radius": u.bomb_radius, "alive": true})
        u.bombs_left -= 1
        u.bomb_tx = -1.0   # เลือกจุดใหม่รอบหน้า
    else:
        _move_toward(u, dx, dy, dist, dt)


## ระเบิด Trapper: ศัตรูเข้าใกล้ (radius/2) → ระเบิด AoE (radius) ใส่ศัตรู, dmg = ที่ bake ไว้
static func _update_bombs(state: GameState) -> void:
    if state.bombs.is_empty():
        return
    var any_dead := false
    for b in state.bombs:
        if not b.alive:
            continue
        var det2: float = (b.radius * 0.5) * (b.radius * 0.5)
        var trigger := false
        for o in state.units:
            if o.alive and o.team == 1 and o.targetable:
                var dx: float = o.x - b.x
                var dy: float = o.y - b.y
                if dx * dx + dy * dy <= det2:
                    trigger = true
                    break
        if trigger:
            _damage_area(state, 0, b.x, b.y, b.damage, b.radius)   # ระเบิดใส่ศัตรู (team 1)
            b.alive = false
            any_dead = true
    if any_dead:
        state.bombs = state.bombs.filter(func(bb): return bb.alive)


## ระยะกำลังสองจากจุด (px,py) ถึงช่วงเส้น (a→b)
static func _dist2_seg(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
    var abx: float = bx - ax
    var aby: float = by - ay
    var ab2: float = abx * abx + aby * aby
    var t: float = 0.0
    if ab2 > 0.0001:
        t = clampf(((px - ax) * abx + (py - ay) * aby) / ab2, 0.0, 1.0)
    var cx: float = ax + abx * t
    var cy: float = ay + aby * t
    var dx: float = px - cx
    var dy: float = py - cy
    return dx * dx + dy * dy


static func _cleanup_deaths(state: GameState) -> void:
    for u in state.units:
        if u.alive and Unit.can_die(u) and u.hp <= 0.0:
            u.alive = false
            if u.team == 1:
                state.kills += 1
            # on_death hooks = M3


static func _check_end(state: GameState, touched_base: bool) -> void:
    if touched_base:
        state.result = &"lose"
        return
    for u in state.units:
        if u.alive and u.team == 1:
            return   # ยังมีศัตรู
    state.result = &"win"
