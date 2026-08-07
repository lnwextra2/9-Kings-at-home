extends Node2D
## สนามรบ — รัน Combat.tick (fixed timestep)
## sprite วาดด้วย MultiMeshInstance2D (1 ตัวต่อ texture) → หลายพันตัวใน draw call น้อย
## HP bar / projectile / ขอบสนาม / วงฐาน วาดใน _draw() (มีน้อย/เบา)
signal combat_ended

@export var field_origin: Vector2 = Vector2(20.0, 60.0)
@export var unit_radius: float = 7.0
@export var bob_amp: float = 3.0
@export var bob_speed: float = 8.0

var _accum: float = 0.0
var _ended: bool = false
var _mmis: Dictionary = {}   # data_id (StringName) -> MultiMeshInstance2D


func start() -> void:
    _accum = 0.0
    _ended = false
    for mmi in _mmis.values():
        mmi.multimesh.instance_count = 0


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
    _sync_multimesh(st)
    queue_redraw()
    if st.result != &"" and not _ended:
        _ended = true
        combat_ended.emit()


func _sync_multimesh(st: GameState) -> void:
    var t: float = st.combat_time
    var groups: Dictionary = {}
    for u in st.units:
        if u.alive and not u.is_wall and Content.card(u.data_id).sprite != null:
            var arr = groups.get(u.data_id)
            if arr == null:
                arr = []
                groups[u.data_id] = arr
            arr.append(u)
    for data_id in groups:
        var arr: Array = groups[data_id]
        var mm: MultiMesh = _get_mmi(data_id).multimesh
        mm.instance_count = arr.size()
        for i in arr.size():
            var u: Dictionary = arr[i]
            var bob: float = 0.0
            if not u.immobile:
                bob = absf(sin(t * bob_speed + (u.x + u.y) * 0.05)) * bob_amp
            var ang: float = deg_to_rad(45.0) if u.attacking else 0.0
            mm.set_instance_transform_2d(i, Transform2D(ang, Vector2(u.x, u.y - bob)))
    for data_id in _mmis:
        if not groups.has(data_id):
            _mmis[data_id].multimesh.instance_count = 0


func _get_mmi(data_id: StringName) -> MultiMeshInstance2D:
    if _mmis.has(data_id):
        return _mmis[data_id]
    var d: CardData = Content.card(data_id)
    var r: float = _radius_for(d)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_2D
    mm.mesh = _make_quad(r * 2.4, r * 2.4)
    var mmi := MultiMeshInstance2D.new()
    mmi.position = field_origin
    mmi.texture = d.sprite
    mmi.multimesh = mm
    add_child(mmi)
    _mmis[data_id] = mmi
    return mmi


## quad กลางที่ origin + UV แบบ 2D (top-left = 0,0) — เลี่ยง QuadMesh ที่ flip แกน Y
func _make_quad(w: float, h: float) -> ArrayMesh:
    var hw: float = w * 0.5
    var hh: float = h * 0.5
    var verts := PackedVector3Array([
        Vector3(-hw, -hh, 0.0), Vector3(hw, -hh, 0.0),
        Vector3(hw, hh, 0.0), Vector3(-hw, hh, 0.0),
    ])
    var uvs := PackedVector2Array([
        Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
    ])
    var idx := PackedInt32Array([0, 1, 2, 0, 2, 3])
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = idx
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh


## กำแพง = แนวตั้งยาวทั้งสนาม สีเปลี่ยนตาม HP + มิเตอร์ HP ด้านบน
func _draw_wall(u: Dictionary, cfg: BattleConfig) -> void:
    var f: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
    var w: float = 14.0
    var x: float = field_origin.x + u.x - w * 0.5
    draw_rect(Rect2(x, field_origin.y, w, cfg.height), Color(0.55, 0.55, 0.6).lerp(Color(0.72, 0.26, 0.24), 1.0 - f))
    draw_rect(Rect2(x - 3.0, field_origin.y - 7.0, w + 6.0, 3.0), Color(0, 0, 0, 0.6))
    draw_rect(Rect2(x - 3.0, field_origin.y - 7.0, (w + 6.0) * f, 3.0), Color(0.3, 0.9, 0.35))


func _radius_for(d: CardData) -> float:
    if d.kind == CardData.Kind.BASE:
        return 12.0
    if d.kind == CardData.Kind.BUILDING or d.kind == CardData.Kind.TURRET:
        return 10.0
    return unit_radius


func _draw() -> void:
    var st: GameState = Game.state
    if st.phase != &"combat":
        return
    var cfg: BattleConfig = st.battle_cfg
    draw_rect(Rect2(field_origin, Vector2(cfg.width, cfg.height)), Color(0.10, 0.14, 0.11))
    draw_rect(Rect2(field_origin, Vector2(cfg.width, cfg.height)), Color(0.25, 0.35, 0.28), false, 2.0)
    if st.base_unit != -1:
        var b: Dictionary = st.units[st.base_unit]
        draw_arc(field_origin + Vector2(b.x, b.y), cfg.base_touch_radius, 0.0, TAU, 24, Color(1, 0.8, 0.2, 0.4), 1.5)
    for p in st.projectiles:
        if p.alive:
            draw_circle(field_origin + Vector2(p.x, p.y), 2.5, Color(1, 1, 0.55))
    # HP bar (สีตามฝั่ง: เรา=เขียว ศัตรู=แดง) + fallback สี่เหลี่ยมถ้าไม่มี sprite
    for u in st.units:
        if not u.alive:
            continue
        if u.is_wall:
            _draw_wall(u, cfg)
            continue
        var d: CardData = Content.card(u.data_id)
        var pos: Vector2 = field_origin + Vector2(u.x, u.y)
        if d.sprite == null:
            draw_rect(Rect2(pos.x - unit_radius, pos.y - unit_radius, unit_radius * 2.0, unit_radius * 2.0), Color(0.5, 0.5, 0.55))
        if u.max_hp > 0.0:
            var w: float = 18.0
            var f: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
            var by: float = pos.y - _radius_for(d) - 7.0
            var hp_col: Color = Color(0.3, 0.9, 0.35) if u.team == 0 else Color(0.9, 0.3, 0.3)
            draw_rect(Rect2(pos.x - w * 0.5, by, w, 3.0), Color(0, 0, 0, 0.6))
            draw_rect(Rect2(pos.x - w * 0.5, by, w * f, 3.0), hp_col)
