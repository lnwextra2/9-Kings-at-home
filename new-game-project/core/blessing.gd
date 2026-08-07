class_name Blessing
extends RefCounted
## พรจากสถานี blessing — global run modifier (ผู้เล่นเท่านั้น), stack ได้ (state.blessings[id] = stacks)
## ค่าตัวเลขเป็น balance — ย้ายไป .tres/config ได้ภายหลัง (ตอนนี้รวมไว้ที่เดียวก่อน)

## รายการพรพื้นฐาน (id, ชื่อ, คำอธิบาย) — เพิ่มพรใหม่ที่นี่
const CATALOG := [
	{"id": &"dmg50", "name": "พลังโจมตี", "desc": "+50% ดาเมจการ์ดทั้งหมด"},
	{"id": &"hp2x", "name": "อึดทน", "desc": "HP ทหาร +100% (x2/stack)"},
	{"id": &"crit30", "name": "จุดตาย", "desc": "+30% คริทุกการ์ด (บวกตรงๆ)"},
	{"id": &"count1", "name": "กองทัพ", "desc": "+1 จำนวนทหารทุกเวฟ"},
	{"id": &"gold10", "name": "มั่งคั่ง", "desc": "+10 ทองทุกเวฟ"},
	{"id": &"shop50", "name": "ต่อรอง", "desc": "ลดราคาร้าน 50%/stack"},
]


static func _stacks(state: GameState, id: StringName) -> int:
	return int(state.blessings.get(id, 0))


static func name_of(id: StringName) -> String:
	for b in CATALOG:
		if b.id == id:
			return b.name
	return str(id)


static func desc_of(id: StringName) -> String:
	for b in CATALOG:
		if b.id == id:
			return b.desc
	return ""


## สุ่มพร 1 อัน (เสนอทีละอัน — รับหรือรีโรล)
static func roll_one(state: GameState) -> StringName:
	return CATALOG[state.rng.randi_range(0, CATALOG.size() - 1)].id


static func pick(state: GameState, id: StringName) -> void:
	state.blessings[id] = _stacks(state, id) + 1


# ── aggregate modifiers (ใช้ตอนสปอว์นผู้เล่น / ร้าน / รับทอง) ──
static func dmg_mult(state: GameState) -> float:
	return 1.0 + 0.5 * _stacks(state, &"dmg50")

static func hp_mult(state: GameState) -> float:
	return 1.0 + 1.0 * _stacks(state, &"hp2x")   # +100%/stack

static func crit_add(state: GameState) -> float:
	return 0.3 * _stacks(state, &"crit30")

static func count_add(state: GameState) -> int:
	return _stacks(state, &"count1")

static func gold_per_wave(state: GameState) -> int:
	return 10 * _stacks(state, &"gold10")

static func shop_price_mult(state: GameState) -> float:
	return pow(0.5, _stacks(state, &"shop50"))
