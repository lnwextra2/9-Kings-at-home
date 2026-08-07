extends Button
## ช่องกระดานที่รับการ์ดที่ลากมาวางได้ (drop target). board_view ตั้ง callable ให้
## can_drop_fn() -> bool (วางช่องนี้ได้ไหม), drop_fn(hand_index) เมื่อปล่อยการ์ด

var can_drop_fn: Callable
var drop_fn: Callable


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or data.get("kind") != &"hand_card":
		return false
	return can_drop_fn.is_valid() and bool(can_drop_fn.call())


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if drop_fn.is_valid():
		drop_fn.call(int(data.get("hand_index", -1)))
