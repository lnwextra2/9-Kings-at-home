class_name CardHooks
extends RefCounted
## Tier 2 — base ของ hook script (เฉพาะการ์ดที่ logic ซับซ้อนจริง)
## กติกา: อ่าน/เขียน state ผ่าน API ของ core/ เท่านั้น ห้ามแตะ Node, สุ่มผ่าน state.rng
## การ์ดปกติใช้ EffectData tier-1 พอ — มาที่นี่เมื่อ effect แบบ declarative ทำไม่ได้

## จบเทิร์น (การ์ดอยู่บนกระดาน ช่อง idx)
func on_end_turn(_state: GameState, _card: Dictionary, _idx: int) -> void:
	pass

## ยูนิตตายในสนามรบ
func on_death(_state: GameState, _unit: Dictionary) -> void:
	pass

## ยูนิตเกิดในสนามรบ
func on_spawn(_state: GameState, _unit: Dictionary) -> void:
	pass

## การ์ดถูกอัปเลเวล (merge)
func on_upgrade(_state: GameState, _card: Dictionary, _idx: int) -> void:
	pass

## ใช้การ์ด active จากมือลงช่อง slot (โทม/สแตมป์แบบสั่งเอง) — คืน true = สำเร็จ (การ์ดถูกกินจากมือ)
func on_use(_state: GameState, _data_id: StringName, _slot: int) -> bool:
	return false
