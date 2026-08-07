extends Control
## สถานี blessing (window ทับ planning) — เสนอพร 1 อัน: รับ หรือ รีโรล (gold, +10 ถาวร)
## UI สร้างในโค้ด (dim + panel กลางจอ). refresh() อ่าน Game.state.blessing_choice
signal picked
signal reroll_pressed

var _card: Button
var _reroll: Button
var _owned: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 340)
	panel.size = Vector2(360, 340)
	panel.position = -0.5 * panel.size
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18; vb.offset_top = 16; vb.offset_right = -18; vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vb)

	var title := Label.new()
	title.text = "✨ พร"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vb.add_child(title)

	_owned = Label.new()
	_owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_owned.add_theme_font_size_override("font_size", 11)
	_owned.modulate = Color(0.8, 0.85, 0.9)
	_owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_owned)

	_card = Button.new()
	_card.custom_minimum_size = Vector2(300, 150)
	_card.focus_mode = Control.FOCUS_NONE
	_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.pressed.connect(func(): picked.emit())
	vb.add_child(_card)

	_reroll = Button.new()
	_reroll.focus_mode = Control.FOCUS_NONE
	_reroll.pressed.connect(func(): reroll_pressed.emit())
	vb.add_child(_reroll)


func refresh() -> void:
	var st: GameState = Game.state
	var id: StringName = st.blessing_choice
	var have: int = int(st.blessings.get(id, 0))
	var tag: String = ("  (มีแล้ว x%d)" % have) if have > 0 else ""
	_card.text = "%s%s\n\n%s\n\n[ กดเพื่อรับพร ]" % [Blessing.name_of(id), tag, Blessing.desc_of(id)]
	_reroll.text = "รีโรลพร (%dg)" % st.blessing_reroll_cost
	_reroll.disabled = st.gold < st.blessing_reroll_cost
	_owned.text = _owned_text(st)


func _owned_text(st: GameState) -> String:
	if st.blessings.is_empty():
		return "ยังไม่มีพร"
	var parts: Array = []
	for id in st.blessings:
		parts.append("%s x%d" % [Blessing.name_of(id), int(st.blessings[id])])
	return "พรที่มี: " + "   ·   ".join(parts)
