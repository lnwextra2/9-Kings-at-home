extends Button
## การ์ดในมือที่ "ลากได้" (drag source) — ใช้ระบบ drag-and-drop ของ Control (รองรับ touch)
## ลากออกไปวาง: board cell = วาง/merge/ใช้, SellZone = ขาย. drop → GameSim.step (ไม่แตะ core)
## แตะเฉยๆ (ไม่ลาก) = เลือกการ์ด (toggle เดิม) ยังทำงานปกติ

var hand_index: int = -1
var card_data_id: StringName = &""


func _get_drag_data(_at_position: Vector2) -> Variant:
	# ภาพผีตามนิ้ว = ก็อปหน้าการ์ดตัวเอง (จางลง, คลิกทะลุ, จัดกึ่งกลางเคอร์เซอร์)
	var ghost := duplicate() as Control
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ghost is Button:
		(ghost as Button).button_pressed = false
	ghost.modulate = Color(1, 1, 1, 0.8)
	ghost.position = -0.5 * size
	var wrap := Control.new()
	wrap.add_child(ghost)
	set_drag_preview(wrap)
	return {"kind": &"hand_card", "hand_index": hand_index, "data_id": card_data_id}
