class_name UnitRow
extends PanelContainer

signal clicked(unit: BattleUnit)
signal hovered(unit: BattleUnit)

var unit: BattleUnit
var show_damage: bool = true
var _hp_bar: ProgressBar
var _en_bar: ProgressBar
var _status: Label
var _dealt_l: Label
var _taken_l: Label
var _dealt_bar: ProgressBar
var _taken_bar: ProgressBar
var _bucket: int = -1
var _styles: Array[StyleBoxFlat] = []
var _highlight: bool = false


func setup(u: BattleUnit, with_damage: bool) -> void:
	unit = u
	show_damage = with_damage
	custom_minimum_size = Vector2(0, 46)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style(false)
	for c in [UiStyle.hp_color(1.0), UiStyle.hp_color(0.4), UiStyle.hp_color(0.1)]:
		_styles.append(UiStyle.box(c, c.lightened(0.3), 1, 4, 0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var pic := TextureRect.new()
	pic.texture = SpriteLibrary.get_portrait(u.instance.species_id)
	pic.custom_minimum_size = Vector2(36, 36)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mid)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(top)
	var name_l: Label = UiStyle.label(u.instance.display_name(), 13)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_l)
	_status = UiStyle.label("Nv%d" % u.instance.level, 12, UiStyle.COL_GOLD)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_status)
	_hp_bar = UiStyle.bar(u.hp, u.max_hp, UiStyle.hp_color(1.0), 9.0)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_hp_bar)
	_en_bar = UiStyle.bar(u.energy, u.energy_max, Color("4aa3ff"), 4.0)
	_en_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(_en_bar)

	if show_damage:
		var right := VBoxContainer.new()
		right.custom_minimum_size = Vector2(104, 0)
		right.add_theme_constant_override("separation", 1)
		right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(right)
		var d_row: HBoxContainer = _stat_line(right, Color("ff9f43"))
		_dealt_l = d_row.get_child(0)
		_dealt_bar = d_row.get_child(1)
		var t_row: HBoxContainer = _stat_line(right, Color("5fb8ff"))
		_taken_l = t_row.get_child(0)
		_taken_bar = t_row.get_child(1)

	mouse_entered.connect(func() -> void: hovered.emit(unit))
	mouse_exited.connect(func() -> void: hovered.emit(null))


func _stat_line(parent: Control, col: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l: Label = UiStyle.label("0", 11, col)
	l.custom_minimum_size = Vector2(38, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	var b: ProgressBar = UiStyle.bar(0.0, 1.0, col, 5.0)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(b)
	parent.add_child(h)
	return h


func _apply_style(highlight: bool) -> void:
	var team_col: Color = Color("4aa3ff") if unit.team == 0 else Color("ff6b6b")
	var sb: StyleBoxFlat = UiStyle.box(Color("2c4678") if highlight else UiStyle.COL_PANEL_DARK, UiStyle.COL_GOLD if highlight else team_col.darkened(0.2), 2 if highlight else 1, 8, 4)
	sb.shadow_size = 0
	add_theme_stylebox_override("panel", sb)
	_highlight = highlight


func refresh(max_dealt: float, max_taken: float, highlight: bool) -> void:
	if highlight != _highlight:
		_apply_style(highlight)
	_hp_bar.max_value = unit.max_hp
	_hp_bar.value = maxf(0.0, unit.hp)
	var ratio: float = unit.hp / unit.max_hp
	var b: int = 0 if ratio > 0.5 else (1 if ratio > 0.2 else 2)
	if b != _bucket:
		_bucket = b
		_hp_bar.add_theme_stylebox_override("fill", _styles[b])
	_en_bar.max_value = unit.energy_max
	_en_bar.value = unit.energy
	if unit.dead:
		_status.text = "Capturé" if unit.was_captured else "K.O."
		_status.add_theme_color_override("font_color", Color("ff6b6b"))
		modulate = Color(1, 1, 1, 0.5)
	elif unit.stun_time > 0.0:
		_status.text = "Étourdi"
	else:
		_status.text = "Nv%d" % unit.instance.level
	if show_damage:
		_dealt_l.text = str(roundi(unit.dmg_dealt))
		_taken_l.text = str(roundi(unit.dmg_taken))
		_dealt_bar.max_value = maxf(1.0, max_dealt)
		_dealt_bar.value = unit.dmg_dealt
		_taken_bar.max_value = maxf(1.0, max_taken)
		_taken_bar.value = unit.dmg_taken


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit)
