class_name TeamSlot
extends PanelContainer

signal selected(inst: PokemonInstance)
signal activated(inst: PokemonInstance)

var inst: PokemonInstance
var is_selected: bool = false


func setup(p: PokemonInstance, sel: bool) -> void:
	inst = p
	is_selected = sel
	custom_minimum_size = Vector2(0, 58)
	set_selected(sel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	var pic := TextureRect.new()
	pic.texture = SpriteLibrary.get_portrait(p.species_id)
	pic.custom_minimum_size = Vector2(46, 46)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var name_l: Label = UiStyle.label(p.display_name(), 15)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_l)
	var lv: Label = UiStyle.label("Nv%d" % p.level, 14, UiStyle.COL_GOLD)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(lv)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bottom)
	var pills: HBoxContainer = UiStyle.type_pills(p.types(), true)
	pills.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in pills.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(pills)
	var tags := ""
	if p.is_deployed():
		tags += " ★"
	if p.item_id != "":
		tags += " ◆"
	if p.can_evolve():
		tags += " ✦"
	var tag_l: Label = UiStyle.label(tags, 13, UiStyle.COL_EVO if p.can_evolve() else UiStyle.COL_GOLD)
	tag_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(tag_l)


func set_selected(sel: bool) -> void:
	is_selected = sel
	var fill: Color = Color("2c4678") if sel else UiStyle.COL_PANEL_DARK
	var border: Color = UiStyle.COL_GOLD if sel else Color("3a4a6e")
	var sb: StyleBoxFlat = UiStyle.box(fill, border, 3 if sel else 1, 8, 5)
	sb.shadow_size = 0
	add_theme_stylebox_override("panel", sb)


static func make_preview(p: PokemonInstance) -> Control:
	var pic := TextureRect.new()
	pic.texture = SpriteLibrary.get_portrait(p.species_id)
	pic.custom_minimum_size = Vector2(56, 56)
	pic.size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.modulate = Color(1, 1, 1, 0.85)
	return pic


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			activated.emit(inst)
		else:
			selected.emit(inst)


func _get_drag_data(_at: Vector2) -> Variant:
	set_drag_preview(make_preview(inst))
	return {"type": "pokemon", "uid": inst.uid, "from": "list"}
