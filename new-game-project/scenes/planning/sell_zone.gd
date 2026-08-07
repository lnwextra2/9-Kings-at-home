extends Panel
## บ่อขาย — ลากการ์ดจากมือมาปล่อยที่นี่ = ขาย (emit ให้ main เรียก GameSim.step)

signal sell_dropped(hand_index: int)


func _ready() -> void:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.text = "🗑️\nลากมาขาย\n+%dg" % Game.state.sell_value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == &"hand_card"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	sell_dropped.emit(int(data.get("hand_index", -1)))
