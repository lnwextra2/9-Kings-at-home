class_name CardData
extends Resource
## แม่แบบการ์ด (shared, read-only) — เพิ่มการ์ด = เพิ่มไฟล์ .tres ไม่ใช่แก้โค้ด

enum Kind { SOLDIER, BASE, BUILDING, TURRET, BUFF, TOME }
## วิธีเลือกเป้า: NEAREST=ใกล้สุด (default), BACKLINE=รั้งท้ายในระยะ (sniper), LOWEST_HP=HP น้อยสุดในระยะ (executioner)
enum TargetMode { NEAREST, BACKLINE, LOWEST_HP }

@export_group("Identity")
@export var id: StringName
@export var display_name: String = ""
@export var icon: Texture2D               # รูปการ์ด (UI) — ยังไม่ใช้
@export var sprite: Texture2D             # โมเดลในสนามรบ (ว่าง = วาดสี่เหลี่ยม fallback)
@export var color: StringName = &"blue"   # blue/red/mint/gold/gray/green/purple/orange/indigo/rainbow
@export var kind: Kind = Kind.SOLDIER
@export_multiline var description: String = ""

@export_group("Combat Stats")
@export var max_hp: float = 20.0          # 0 = ไม่มี HP (ตีไม่โดน)
@export var attack: float = 4.0
@export var attack_cd: float = 1.2        # วินาทีต่อครั้ง
@export var attack_range: float = 30.0
@export var move_speed: float = 60.0      # px/วินาที (0 = อยู่กับที่)
@export var splash_radius: float = 0.0
@export var crit: float = 0.0             # โอกาสคริติคอล 0..1 (คริ = ดาเมจ × crit_mult)
@export var target_mode: TargetMode = TargetMode.NEAREST   # passive เลือกเป้า (sniper/executioner)

@export_group("Scaling")
@export var base_count: int = 1           # จำนวนทหารพื้นฐาน (soldier); count = base_count × level
@export var growth_hp: float = 0.3        # compound %: stat × (1+growth)^(lv-1)
@export var growth_attack: float = 0.3
@export var growth_attack_speed: float = 0.1
@export var growth_crit: float = 0.0      # +crit ต่อ level (additive; cap 1.0)

@export_group("Behavior")
@export var abilities: Dictionary = {}    # {ability_id: base_stacks} — soldier ability
@export var effects: Array[EffectData] = []   # tier 1 declarative
@export var hooks_script: Script          # tier 2 script (การ์ดที่พิเศษจริงๆ)
@export var multishot: bool = false       # true = ยิง cur_count นัด/ครั้ง สุ่มเป้า (ป้อมยิงหลายเป้า)
@export var pierce: bool = false          # true = กระสุนวิ่งตรงจนสุดแมพ ทะลุโดนทุกตัวในเส้นทาง (บาริสต้า)
@export var bomb_count: int = 0           # >0 = วางระเบิด N ลูกตอนสปอว์น (Trapper)
@export var bomb_radius: float = 0.0      # รัศมีระเบิด (detection = ครึ่งนึง), aoe dmg = attack

@export_group("Economy")
@export var cost: int = 4                 # ราคาในร้าน


func is_structure() -> bool:
    return kind == Kind.BASE or kind == Kind.BUILDING or kind == Kind.TURRET


## ลงสนามไหม แยกด้วย stat ไม่ใช่ kind: soldier เสมอ / โครงสร้างที่ยิงได้หรือมี HP
func goes_to_field() -> bool:
    return kind == Kind.SOLDIER or attack > 0.0 or max_hp > 0.0
