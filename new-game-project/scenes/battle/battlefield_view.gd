extends Node2D
## สนามรบ — รัน Combat.tick (fixed timestep) แล้ววาดยูนิตทั้งหมดใน _draw()
## M2: วาดด้วยรูปทรง (เอียง 45° ตอนตี, เด้งตอนเดิน); MultiMesh + SoA = M3
signal combat_ended

@export var field_origin: Vector2 = Vector2(140.0, 88.0)
@export var unit_radius: float = 7.0
@export var bob_amp: float = 3.0
@export var bob_speed: float = 8.0

var _accum: float = 0.0
var _ended: bool = false


func start() -> void:
    _accum = 0.0
    _ended = false


func _process(delta: float) -> void:
    var st: GameState = Game.state
    if st.phase != &"combat":
        return
    if st.result == &"":
        _accum += delta
        while _accum >= Combat.TICK:
            Combat.tick(st, Combat.TICK)
            _accum -= Combat.TICK
            if st.result != &"":
                break
    queue_redraw()
    if st.result != &"" and not _ended:
        _ended = true
        combat_ended.emit()


func _draw() -> void:
    var st: GameState = Game.state
    if st.phase != &"combat":
        return
    var cfg: BattleConfig = st.battle_cfg
    var t: float = st.combat_time
    # ขอบสนาม
    draw_rect(Rect2(field_origin, Vector2(cfg.width, cfg.height)), Color(0.10, 0.14, 0.11))
    draw_rect(Rect2(field_origin, Vector2(cfg.width, cfg.height)), Color(0.25, 0.35, 0.28), false, 2.0)
    # วงรัศมีแตะฐาน
    if st.base_unit != -1:
        var b: Dictionary = st.units[st.base_unit]
        draw_arc(field_origin + Vector2(b.x, b.y), cfg.base_touch_radius, 0.0, TAU, 24, Color(1, 0.8, 0.2, 0.4), 1.5)
    # projectiles
    for p in st.projectiles:
        if p.alive:
            draw_circle(field_origin + Vector2(p.x, p.y), 2.5, Color(1, 1, 0.55))
    # ยูนิต
    for u in st.units:
        if u.alive:
            _draw_unit(u, t)


func _draw_unit(u: Dictionary, t: float) -> void:
    var bob: float = 0.0
    if not u.immobile:
        bob = absf(sin(t * bob_speed + (u.x + u.y) * 0.05)) * bob_amp
    var pos: Vector2 = field_origin + Vector2(u.x, u.y - bob)
    var r: float = unit_radius
    if u.is_base:
        r = 12.0
    elif u.kind == CardData.Kind.BUILDING or u.kind == CardData.Kind.TURRET:
        r = 10.0
    var ang: float = deg_to_rad(45.0) if u.attacking else 0.0
    draw_set_transform(pos, ang, Vector2.ONE)
    draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), _color_for(u))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if u.max_hp > 0.0:
        var w: float = 18.0
        var f: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
        var bar_y: float = pos.y - r - 7.0
        draw_rect(Rect2(pos.x - w * 0.5, bar_y, w, 3.0), Color(0, 0, 0, 0.6))
        draw_rect(Rect2(pos.x - w * 0.5, bar_y, w * f, 3.0), Color(0.3, 0.9, 0.35))


func _color_for(u: Dictionary) -> Color:
    if u.team == 1:
        return Color(0.85, 0.25, 0.2)
    match u.kind:
        CardData.Kind.BASE: return Color(0.95, 0.8, 0.2)
        CardData.Kind.TURRET: return Color(0.3, 0.7, 0.9)
        CardData.Kind.BUILDING: return Color(0.6, 0.6, 0.65)
        _: return Color(0.3, 0.5, 0.95)
