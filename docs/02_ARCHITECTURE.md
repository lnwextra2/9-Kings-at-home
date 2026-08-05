# Kingdom Battle — Architecture Guide (Godot 4.x / GDScript)

> Source of truth ของ **"โค้ดจัดโครงยังไง"**
> เป้าหมาย: เพิ่มการ์ดใหม่ 50 ใบได้โดย **ไม่แตะไฟล์ใน `core/` เลย**

---

## 0. หลักการ 4 ข้อ (non-negotiable)

1. **Data-driven** — การ์ด/ศัตรู/เวฟ เป็น `.tres` เพิ่มของ = เพิ่มไฟล์ ไม่ใช่แก้ logic
2. **Sim ≠ Render** — `core/` เป็น GDScript ล้วน ห้ามรู้จัก Node/Scene/Input/Time
3. **Deterministic** — สุ่มผ่าน seeded RNG เท่านั้น, state serialize เป็น Dictionary ได้
4. **Engine ไม่รู้จักชื่อการ์ด** — ห้ามมี `if card.id == "farm"` ใน `core/` เด็ดขาด

> ทำไมสำคัญ: 4 ข้อนี้ทำให้ได้ save/load, replay, unit test, balance tuning มาแทบฟรี
> และเป็นบทเรียนตรงจาก prototype เดิม — โค้ดเละเพราะ logic การ์ดกระจายไปทั่ว engine

---

## 1. Folder Structure

```
res://
├── project.godot
├── CLAUDE.md                     # กฎเขียนโค้ด (Claude Code อ่านอัตโนมัติ)
├── docs/                         # เอกสาร 3 ไฟล์นี้
│
├── data_types/                   # SCHEMA (นิยาม Resource)
│   ├── card_data.gd              # class_name CardData
│   ├── effect_data.gd            # class_name EffectData     (declarative effect)
│   ├── modifier_data.gd          # class_name ModifierData   (stat pipeline)
│   ├── wave_data.gd              # class_name WaveData
│   └── run_config.gd             # class_name RunConfig      (ตัวเลขสมดุลรวม)
│
├── data/                         # CONTENT (.tres) — เพิ่มของตรงนี้
│   ├── cards/blue/               # แยกโฟลเดอร์ตามสี
│   ├── cards/red/  …
│   ├── waves/
│   └── config/default_run.tres
│
├── core/                         # LOGIC ล้วน — ห้าม import Node
│   ├── game_state.gd             # สถานะทั้งหมด (serialize ได้)
│   ├── game_sim.gd               # step(state, action) — planning actions
│   ├── board.gd                  # กระดาน 5×5: neighbors, diagonals, merge, place
│   ├── turn_resolver.gd          # จบเทิร์น: ยิง on_end_turn ทุกใบ
│   ├── spawner.gd                # กระดาน → ยูนิตในสนามรบ
│   ├── wave_gen.gd               # สร้างเวฟศัตรูตาม floor + สี
│   ├── combat.gd                 # tick การต่อสู้
│   ├── spatial_hash.gd           # หาเป้าเร็ว (สำคัญมาก ดูข้อ 7)
│   ├── stats.gd                  # คำนวณ stat จริงหลัง level + modifier
│   ├── rng.gd                    # seeded RNG
│   └── hooks/                    # hook script เฉพาะการ์ดที่พิเศษจริงๆ
│       ├── card_hooks.gd         # base class (virtual methods เปล่า)
│       ├── bloodfort_hooks.gd
│       └── egg_hooks.gd
│
├── scenes/                       # PRESENTATION — render + input เท่านั้น
│   ├── main.tscn / main.gd       # ตัวสลับ phase
│   ├── planning/
│   │   ├── board_view.tscn/.gd   # กระดาน 5×5 (Control/GridContainer)
│   │   ├── hand_view.tscn/.gd
│   │   └── shop_view.tscn/.gd
│   ├── battle/
│   │   └── battlefield_view.gd   # วาดยูนิตทั้งหมดใน _draw() ตัวเดียว
│   └── ui/  (hud, reward_screen, run_summary)
│
├── autoload/
│   └── game.gd                   # singleton บางๆ ถือ GameState + signals
└── assets/
```

**กฎเหล็ก:** ไฟล์ใน `core/` ห้าม `preload()` scene, ห้าม `get_node()`, ห้ามใช้ `Input`/`Time`/`randi()` ตรงๆ

---

## 2. Data Model

### 2.1 CardData — การ์ดทุกใบใช้ schema เดียว

```gdscript
# data_types/card_data.gd
class_name CardData
extends Resource

enum Kind { SOLDIER, BASE, BUILDING, TURRET, BUFF, TOME }

@export_group("Identity")
@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var color: StringName = &"blue"     # blue/red/mint/gold/gray/green/purple/orange/indigo/rainbow
@export var kind: Kind = Kind.SOLDIER
@export var description: String

@export_group("Combat Stats")
@export var max_hp: float = 20.0            # 0 = ไม่มี HP (ตีไม่ได้)
@export var attack: float = 4.0
@export var attack_cd: float = 1.2          # วินาทีต่อครั้ง
@export var attack_range: float = 30.0
@export var move_speed: float = 60.0        # px/วินาที (0 = อยู่กับที่)
@export var splash_radius: float = 0.0

@export_group("Scaling")
@export var count_per_level: PackedInt32Array = PackedInt32Array([1, 3, 9])
@export var growth_hp: float = 0.3          # compound: stat × (1+growth)^(lv-1)
@export var growth_attack: float = 0.3
@export var growth_attack_speed: float = 0.1

@export_group("Behavior")
@export var effects: Array[EffectData] = [] # tier 1: declarative (ไม่ต้องเขียนโค้ด)
@export var hooks_script: Script            # tier 2: เฉพาะการ์ดที่พิเศษจริงๆ

func is_structure() -> bool:
    return kind == Kind.BASE or kind == Kind.BUILDING or kind == Kind.TURRET

func spawns_units() -> bool:
    return kind == Kind.SOLDIER or kind == Kind.TURRET or kind == Kind.BASE
```

### 2.2 Behavior 2 ระดับ — สำคัญที่สุดในไฟล์นี้

**Tier 1 — Declarative `EffectData` (ครอบคลุมการ์ด ~80%)**
เพิ่มการ์ดพวกนี้ = คลิกใน editor อย่างเดียว ไม่ต้องเขียนโค้ด

```gdscript
# data_types/effect_data.gd
class_name EffectData
extends Resource

enum Trigger { END_TURN, ON_DEATH, ON_SPAWN, ON_UPGRADE, ON_KILL }
enum Action { GRANT_GOLD, MODIFY_STAT, UPGRADE_RANDOM, SPAWN_EXTRA, DAMAGE_AREA }
enum Target { SELF, NEIGHBORS_4, DIAGONALS_4, RANDOM_CARD, ALL_CARDS, SAME_COLOR }

@export var trigger: Trigger = Trigger.END_TURN
@export var action: Action = Action.GRANT_GOLD
@export var target: Target = Target.SELF
@export var value: float = 3.0
@export var scales_with_level: bool = true   # value × level
@export var stat_name: StringName = &""      # ใช้เมื่อ action = MODIFY_STAT
```

ตัวอย่าง: **ฟาร์ม** = `{END_TURN, GRANT_GOLD, SELF, 3.0, scales=true}` — จบ

**Tier 2 — Hook Script (เฉพาะการ์ดที่ logic ซับซ้อนจริง)**

```gdscript
# core/hooks/card_hooks.gd
class_name CardHooks
extends RefCounted

func on_end_turn(_state, _card, _idx) -> void: pass
func on_death(_state, _unit) -> void: pass
func on_spawn(_state, _unit) -> void: pass
func on_upgrade(_state, _card, _idx) -> void: pass
```

```gdscript
# core/hooks/bloodfort_hooks.gd  — ป้อมระเบิดเลือด
extends CardHooks

func on_end_turn(state, card, idx) -> void:
    var lv: int = card.level
    var picks: Array = state.rng.shuffle(Board.neighbors_4(idx)).slice(0, lv)
    var sacrificed: int = 0
    for n_idx in picks:
        var victim = state.board[n_idx]
        if victim == null or victim.data.kind != CardData.Kind.SOLDIER:
            continue
        victim.no_spawn = true                      # ไม่ลงสนามเทิร์นนี้
        sacrificed += Stats.unit_count(victim)
        TurnResolver.fire_death_effects(state, victim)  # แพะให้ทอง / demon ได้บัฟ
    card.flat_attack_bonus += 2.0 * sacrificed
```

> **กติกา:** hook script อ่าน/เขียน state ผ่าน API ของ `core/` เท่านั้น ห้ามแตะ Node

### 2.3 Card Instance (การ์ดบนกระดาน ≠ CardData)
`CardData` = แม่แบบ (shared, read-only) / **card instance** = ของจริงบนกระดาน (mutable)

```gdscript
# อยู่ใน game_state.gd — เก็บเป็น Dictionary เพื่อ serialize ง่าย
{
    "data_id": &"swordsman",   # ชี้กลับไปยัง CardData
    "level": 1,
    "attack_mult": 1.0,        # จาก buff/tome
    "hp_mult": 1.0,
    "aspd_mult": 1.0,
    "flat_attack_bonus": 0.0,
    "no_spawn": false,         # flag ชั่วคราวต่อเทิร์น
}
```

---

## 3. GameState (serialize ได้ทั้งก้อน)

```gdscript
# core/game_state.gd
class_name GameState
extends RefCounted

var phase: StringName = &"planning"    # planning / combat / reward / gameover
var floor_num: int = 1
var gold: int = 30

var board: Array = []                  # 25 ช่อง: null / &"locked" / card instance Dictionary
var hand: Array = []
var shop: Array = []

# combat (ใช้เฉพาะ phase = combat)
var units: Array = []
var projectiles: Array = []
var combat_time: float = 0.0
var result: StringName = &""           # "" / "win" / "lose"

# reward + สีเวฟ
var reward_cards: Array = []
var wave_color: StringName = &""
var enemy_reroll_cost: int = 10        # แพงขึ้นถาวร
var reward_reroll_cost: int = 10       # รีเซ็ตทุกหน้า reward

var rng: Rng

func to_dict() -> Dictionary: ...
static func from_dict(d: Dictionary) -> GameState: ...
```

---

## 4. Core Loop

```gdscript
# core/game_sim.gd — planning actions (turn-based, ไม่มี dt)
class_name GameSim
extends RefCounted

static func step(state: GameState, action: Dictionary) -> void:
    match action.type:
        &"place_card":   Board.place(state, action.hand_index, action.slot)
        &"use_tome":     Board.apply_tome(state, action.hand_index, action.slot)
        &"buy":          Shop.buy(state, action.shop_index)
        &"reroll_shop":  Shop.reroll(state)
        &"reroll_color": WaveGen.reroll_color(state)
        &"end_turn":     _start_combat(state)
        &"pick_reward":  _pick_reward(state, action.index)

static func _start_combat(state: GameState) -> void:
    TurnResolver.resolve(state)                 # ยิง on_end_turn ทุกใบ
    state.units = Spawner.spawn_player(state)
    state.units.append_array(WaveGen.make_wave(state))
    state.projectiles.clear()
    state.combat_time = 0.0
    state.result = &""
    state.phase = &"combat"
```

```gdscript
# core/combat.gd — เรียกทุก fixed tick ระหว่างสู้
class_name Combat
extends RefCounted

const TICK: float = 1.0 / 30.0

static func tick(state: GameState, dt: float) -> void:
    var hash := SpatialHash.build(state.units)   # ดูข้อ 7
    _update_units(state, dt, hash)
    _update_projectiles(state, dt, hash)
    _cleanup_dead(state)
    _check_end(state)
```

**Fixed timestep ในฝั่ง view:**
```gdscript
# scenes/battle/battlefield_view.gd
func _process(delta: float) -> void:
    if Game.state.phase != &"combat":
        return
    _accum += delta
    while _accum >= Combat.TICK:
        Combat.tick(Game.state, Combat.TICK)
        _accum -= Combat.TICK
    queue_redraw()
```

---

## 5. Stats Pipeline (จุดเดียวที่คำนวณ stat จริง)

```gdscript
# core/stats.gd
static func attack_of(card: Dictionary) -> float:
    var d: CardData = Content.card(card.data_id)
    var lv: int = card.level
    var base: float = d.attack * pow(1.0 + d.growth_attack, lv - 1)
    return (base + card.flat_attack_bonus) * card.attack_mult
```

> ห้ามคำนวณ stat ที่อื่นเด็ดขาด — ไม่งั้นจะเจอบั๊ก "ตัวเลขไม่ตรงกันระหว่าง UI กับสนามรบ" แบบ prototype เดิม

---

## 6. Presentation Layer

- View **อ่าน** `GameState` แล้ววาด — ห้ามแก้ state เอง
- Input → สร้าง `action` Dictionary → `GameSim.step()` → `Game.state_changed.emit()` → view refresh
- **Planning UI** ใช้ Control node (GridContainer 5×5 + TextureButton) — เหมาะกับ UI ที่เป็นตาราง
- **Battlefield** ใช้ **Node2D ตัวเดียว วาดทุกอย่างใน `_draw()`** (ห้ามสร้าง Node ต่อยูนิต — ดูข้อ 7)

```gdscript
func _draw() -> void:
    for u in Game.state.units:
        if not u.alive: continue
        draw_texture(_tex_for(u), Vector2(u.x, u.y) - _half)
        if u.max_hp > 0.0:
            draw_rect(Rect2(u.x - 10, u.y - 16, 20 * (u.hp / u.max_hp), 3), Color.GREEN)
```

---

## 7. ⚠️ Performance — ต้องรองรับ 200+ ยูนิต

Floor 30 = **219 ศัตรู + ยูนิตเราอีกหลายสิบ** นี่คือข้อจำกัดที่กำหนดสถาปัตยกรรมทั้งหมด

**สามกฎที่ห้ามฝ่าฝืน:**

1. **ห้ามสร้าง Node ต่อ 1 ยูนิต** — 300 Node + script `_process` ต่อตัว = เฟรมตก
   → ยูนิตเป็น Dictionary ใน array, วาดทั้งหมดด้วย `_draw()` ตัวเดียว
   → ถ้าเกิน ~800 ตัวค่อยย้ายไป `MultiMeshInstance2D`

2. **ห้ามหาเป้าแบบ O(n²) ทุก tick** — 300 ยูนิต = 90,000 การเทียบ × 30 tick/วิ = 2.7M/วินาที GDScript ไม่ไหว
   → ใช้ **spatial hash** (แบ่งสนามเป็นตาราง 64px เทียบเฉพาะช่องข้างเคียง)
   → **cache เป้าไว้ ไม่หาใหม่ทุก tick** — หาใหม่ทุก 0.2 วิ หรือเมื่อเป้าตาย

```gdscript
# core/combat.gd
if u.target_id == -1 or not _is_alive(state, u.target_id) or u.retarget_timer <= 0.0:
    u.target_id = SpatialHash.nearest_enemy(hash, u)
    u.retarget_timer = 0.2
```

3. **ห้าม allocate array ใหม่ใน loop** — reuse buffer, ใช้ `PackedFloat32Array` ถ้าทำได้

**Benchmark gate:** ก่อนปิด M3 ต้องรัน stress test 300 ยูนิต ให้ได้ **60 FPS บนเครื่อง dev** ถ้าไม่ผ่าน หยุดแล้ว optimize ก่อนไปต่อ

---

## 8. RNG (deterministic)

```gdscript
# core/rng.gd
class_name Rng
extends RefCounted

var _rng := RandomNumberGenerator.new()

func seed_with(s: int) -> void: _rng.seed = s
func randi_range(a: int, b: int) -> int: return _rng.randi_range(a, b)
func pick(arr: Array): return arr[_rng.randi_range(0, arr.size() - 1)]
func shuffle(arr: Array) -> Array: ...   # Fisher-Yates ใช้ _rng
```

**ห้ามใช้ `randi()` / `randf()` global เด็ดขาด** — ทุกการสุ่มต้องผ่าน `state.rng`

---

## 9. Content Registry

```gdscript
# autoload/content.gd — โหลด .tres ทั้งหมดตอนเริ่มเกม
var _cards: Dictionary = {}      # StringName -> CardData

func card(id: StringName) -> CardData: return _cards[id]
func cards_by_color(c: StringName) -> Array[CardData]: ...
func cards_by_kind(k: CardData.Kind) -> Array[CardData]: ...
```
โหลดด้วยการสแกนโฟลเดอร์ `data/cards/` — เพิ่มไฟล์ `.tres` แล้วเกมเห็นเองทันที ไม่ต้องลงทะเบียน

---

## 10. Testing
- ใช้ **GUT** (Godot Unit Test) addon — เทสต์เฉพาะ `core/`
- เพราะ sim เป็น pure + deterministic → เขียนเทสต์ตรงๆ ได้:
  - `place_card` แล้ว board มีการ์ดถูกช่อง
  - merge การ์ดชนิดเดียวกัน → level 2, มือลดลง 1
  - seed เดียวกัน → เวฟเหมือนกันเป๊ะ
  - combat 1000 tick แล้วไม่มียูนิต HP ติดลบค้าง
- **บทเรียนจาก prototype:** ระบบสุ่มต้องเทสต์หลายรอบ รอบเดียวผ่านไม่ได้แปลว่าถูก
