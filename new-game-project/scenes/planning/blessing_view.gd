extends Control
## สถานี blessing — เลือก 1 พร (stack ได้) + reroll (gold, +10 ถาวร)
## UI สร้างในโค้ด (dim + panel กลางจอ). refresh() อ่าน Game.state.blessing_choices
signal picked(index: int)
signal reroll_pressed

var _row: HBoxContainer
var _reroll: Button
var _owned: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 300)
	panel.size = Vector2(560, 300)
	panel.position = -0.5 * panel.size
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18; vb.offset_top = 16; vb.offset_right = -18; vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var title := Label.new()
	title.text = "✨ เลือกพร 1 อย่าง"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vb.add_child(title)

	_owned = Label.new()
	_owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owned.add_theme_font_size_override("font_size", 11)
	_owned.modulate = Color(0.8, 0.85, 0.9)
	vb.add_child(_owned)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 12)
	vb.add_child(_row)

	_reroll = Button.new()
	_reroll.focus_mode = Control.FOCUS_NONE
	_reroll.pressed.connect(func(): reroll_pressed.emit())
	vb.add_child(_reroll)


func refresh() -> void:
	var st: GameState = Game.state
	for ch in _row.get_children():
		ch.queue_free()
	for i in st.blessing_choices.size():
		_row.add_child(_choice(i, st.blessing_choices[i]))
	_reroll.text = "รีโรลพร (%dg)" % st.blessing_reroll_cost
	_reroll.disabled = st.gold < st.blessing_reroll_cost
	_owned.text = _owned_text(st)


func _choice(i: int, id: StringName) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(160, 150)
	b.focus_mode = Control.FOCUS_NONE
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var have: int = int(Game.state.blessings.get(id, 0))
	var tag: String = ("  (มีแล้ว x%d)" % have) if have > 0 else ""
	b.text = "%s%s\n\n%s" % [Blessing.name_of(id), tag, Blessing.desc_of(id)]
	b.pressed.connect(func(): picked.emit(i))
	return b


func _owned_text(st: GameState) -> String:
	if st.blessings.is_empty():
		return "ยังไม่มีพร"
	var parts: Array = []
	for id in st.blessings:
		parts.append("%s x%d" % [Blessing.name_of(id), int(st.blessings[id])])
	return "พรที่มี: " + "   ·   ".join(parts)
