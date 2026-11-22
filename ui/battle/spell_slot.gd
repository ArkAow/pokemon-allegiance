class_name SpellSlot
extends PanelContainer

signal clicked(index: int)

var index: int = 0
var spell_id: String = ""
var _cool: ProgressBar
var _count: Label
var _sel: bool = false
var _usable: bool = true


func setup(i: int, id: String) -> void:
	index = i
	spell_id = id
	custom_minimum_size = Vector2(0, 58)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style(false)
	var d: Dictionary = GlobalData.get_trainer_spell(id)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var icon := PanelContainer.new()
	var col: Color = Color(str(d.get("color", "#555555"))) if not d.is_empty() else Color("333b4f")
	var isb: StyleBoxFlat = UiStyle.box(col.darkened(0.25), col.lightened(0.3), 2, 10, 2)
	isb.shadow_size = 0
	icon.add_theme_stylebox_override("panel", isb)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g: Label = UiStyle.label(str(d.get("glyph", "")), 22, Color.WHITE)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(g)
	row.add_child(icon)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 1)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mid)
	var title: Label = UiStyle.label(str(d.get("name", "— vide —")), 14, UiStyle.COL_TEXT if not d.is_empty() else UiStyle.COL_TEXT_DIM)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(title)
	var desc: Label = UiStyle.label(str(d.get("desc", "")), 11, UiStyle.COL_TEXT_DIM)
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size = Vector2(10, 0)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(desc)
	tooltip_text = str(d.get("desc", ""))

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(46, 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)
	var key: Label = UiStyle.label("[%d]" % (i + 1), 14, UiStyle.COL_GOLD)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(key)
	_count = UiStyle.label("", 13)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_count)

	_cool = ProgressBar.new()
	_cool.min_value = 0.0
	_cool.max_value = 1.0
	_cool.value = 0.0
	_cool.fill_mode = ProgressBar.FILL_TOP_TO_BOTTOM
	_cool.show_percentage = false
	_cool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cool.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var veil := StyleBoxFlat.new()
	veil.bg_color = Color(0, 0, 0, 0.62)
	veil.set_corner_radius_all(8)
	_cool.add_theme_stylebox_override("fill", veil)
	add_child(_cool)


func _style(selected: bool) -> void:
	var sb: StyleBoxFlat = UiStyle.box(Color("2c4678") if selected else UiStyle.COL_PANEL_DARK, UiStyle.COL_GOLD if selected else Color("5a6a90"), 3 if selected else 2, 8, 6)
	sb.shadow_size = 0
	add_theme_stylebox_override("panel", sb)
	_sel = selected


func refresh(cooldown_ratio: float, count_text: String, usable: bool, selected: bool) -> void:
	if selected != _sel:
		_style(selected)
	_cool.value = cooldown_ratio
	_count.text = count_text
	if usable != _usable:
		_usable = usable
		modulate = Color(1, 1, 1, 1) if usable else Color(1, 1, 1, 0.6)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(index)
