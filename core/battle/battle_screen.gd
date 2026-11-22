class_name BattleScreen
extends CanvasLayer

signal finished(report: Dictionary)

const KEY_SLOTS := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_KP_1: 0, KEY_KP_2: 1, KEY_KP_3: 2}

var encounter: Dictionary = {}
var field: BattleField
var root: Control
var hud: BattleHud
var overlay: TargetOverlay
var book: TrainerSpellbook
var banner: Label
var speed_label: Label
var _done: bool = false
var _result_shown: bool = false
var _report: Dictionary = {}
var _tgt_slot: int = -1
var _tgt_phase: int = 0
var _tgt_aim: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.get_theme()
	add_child(root)

	var bg_path := "res://assets/battle_backgrounds/battle-background.png"
	if ResourceLoader.exists(bg_path):
		var bg := TextureRect.new()
		bg.texture = load(bg_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.COL_BG, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	field = BattleField.new()
	root.add_child(field)
	field.battle_finished.connect(_on_field_finished)
	overlay = TargetOverlay.new()
	overlay.z_index = 100
	root.add_child(overlay)

	hud = BattleHud.new()
	root.add_child(hud)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	banner = Label.new()
	banner.add_theme_font_size_override("font_size", 52)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 10)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(banner)

	var bottom := CenterContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -30
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	speed_label = UiStyle.label("Espace : vitesse x1", 14, UiStyle.COL_TEXT_DIM)
	bottom.add_child(speed_label)


func start(enc: Dictionary) -> void:
	encounter = enc
	field.wild = bool(enc.get("wild", false))
	field.layout(root.get_viewport_rect().size)
	field.setup(Game.deployed(), enc.get("enemies", []))
	overlay.arena = field.arena_rect
	book = TrainerSpellbook.new(Game.loadout)
	hud.build(field, book, str(enc.get("name", "Ennemis")))
	hud.spell_clicked.connect(_on_spell_pressed)
	hud.unit_clicked.connect(_on_unit_picked)
	hud.unit_hovered.connect(func(u: BattleUnit) -> void: overlay.hover_unit = u)
	banner.text = "COMBAT !"
	banner.modulate = Color.WHITE
	await get_tree().create_timer(1.2).timeout
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 0.0, 0.4)
	field.start_fight()


func _process(delta: float) -> void:
	if book == null:
		return
	if field.running:
		book.update(delta * field.speed)
	if _tgt_slot >= 0:
		var m: Vector2 = field.get_local_mouse_position()
		var near: BattleUnit = null
		var nd: float = 36.0
		for u in overlay.valid_units:
			var d: float = minf(m.distance_to(u.position), m.distance_to(u.chest()))
			if d < nd:
				nd = d
				near = u
		overlay.hover_unit = near if near != null else overlay.hover_unit
		hud.highlight_unit = overlay.hover_unit
	if _tgt_slot >= 0:
		if field.finished:
			_cancel_targeting()
			return
		_update_overlay()


func _on_spell_pressed(i: int) -> void:
	if _result_shown or book == null:
		return
	if _tgt_slot == i:
		_cancel_targeting()
		return
	var reason: String = book.block_reason(i, field)
	if reason != "":
		hud.set_hint("%s : %s" % [str(book.spell(i).get("name", "")), reason], true)
		return
	_cancel_targeting()
	if book.targeting(i) == "none":
		book.cast(i, {}, field)
		return
	_tgt_slot = i
	_tgt_phase = 0
	_tgt_aim = {}
	_refresh_targeting()


func _need() -> String:
	match book.targeting(_tgt_slot):
		"enemy":
			return "enemy"
		"ally":
			return "ally"
		"point":
			return "point"
		"ally_point":
			return "ally" if _tgt_phase == 0 else "point"
		"ally_ally":
			return "ally"
	return ""


func _refresh_targeting() -> void:
	var need: String = _need()
	var d: Dictionary = book.spell(_tgt_slot)
	overlay.active = true
	overlay.need = need
	overlay.accent = Color(str(d.get("color", "#ffd54a"))).lightened(0.2)
	overlay.radius_px = book.radius_cells(_tgt_slot) * field.hex_w if need == "point" and book.targeting(_tgt_slot) == "point" else 0.0
	overlay.first_unit = _tgt_aim.get("target", null) if _tgt_phase > 0 else null
	hud.set_selected_slot(_tgt_slot)
	var msg: String = ""
	match need:
		"enemy":
			msg = "Choisissez un ennemi (terrain ou avatar)"
		"ally":
			msg = "Choisissez un allié (terrain ou avatar)" if _tgt_phase == 0 else "Choisissez le 2e allié"
		"point":
			msg = "Cliquez sur le terrain pour placer l'effet" if book.targeting(_tgt_slot) == "point" else "Cliquez sur la destination"
	hud.set_hint("%s — %s   (clic droit / Échap : annuler)" % [str(d.get("name", "")), msg])


func _is_valid(u: BattleUnit) -> bool:
	if u.dead:
		return false
	match _need():
		"enemy":
			return u.team == 1 and u.is_targetable()
		"ally":
			return u.team == 0 and (_tgt_phase == 0 or u != _tgt_aim.get("target", null))
	return false


func _update_overlay() -> void:
	var list: Array = []
	var labels: Dictionary = {}
	var cap: Dictionary = book.find_effect(_tgt_slot, "CAPTURE")
	for u in field.units:
		if _is_valid(u):
			list.append(u)
			if not cap.is_empty():
				labels[u] = "%d%%" % roundi(AbilityEffects.capture_chance(cap, u) * 100.0)
	overlay.valid_units = list
	overlay.labels = labels


func _cancel_targeting() -> void:
	_tgt_slot = -1
	_tgt_phase = 0
	_tgt_aim = {}
	overlay.active = false
	overlay.first_unit = null
	overlay.hover_unit = null
	hud.highlight_unit = null
	hud.set_selected_slot(-1)
	hud.set_hint("")


func _on_unit_picked(u: BattleUnit) -> void:
	if _tgt_slot < 0 or not _is_valid(u):
		return
	match book.targeting(_tgt_slot):
		"enemy", "ally":
			_tgt_aim["target"] = u
			_finish_cast()
		"ally_point":
			_tgt_aim["target"] = u
			_tgt_phase = 1
			_refresh_targeting()
		"ally_ally":
			if _tgt_phase == 0:
				_tgt_aim["target"] = u
				_tgt_phase = 1
				_refresh_targeting()
			else:
				_tgt_aim["target2"] = u
				_finish_cast()


func _on_point_picked(p: Vector2) -> void:
	if _tgt_slot < 0 or _need() != "point":
		return
	_tgt_aim["point"] = field.clamp_to_arena(p)
	_finish_cast()


func _finish_cast() -> void:
	var slot: int = _tgt_slot
	var aim: Dictionary = _tgt_aim
	_cancel_targeting()
	var reason: String = book.block_reason(slot, field)
	if reason != "":
		hud.set_hint(reason, true)
		return
	book.cast(slot, aim, field)


func _click_on_field() -> void:
	var mouse: Vector2 = field.get_local_mouse_position()
	if _need() == "point":
		if field.arena_rect.grow(30.0).has_point(mouse):
			_on_point_picked(mouse)
		return
	var best: BattleUnit = null
	var best_d: float = 42.0
	for u in overlay.valid_units:
		var d: float = minf(mouse.distance_to(u.position), mouse.distance_to(u.chest()))
		if d < best_d:
			best_d = d
			best = u
	if best != null:
		_on_unit_picked(best)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _tgt_slot >= 0:
		_cancel_targeting()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _result_shown:
			_close()
		elif field.running:
			field.speed = 2.0 if field.speed < 1.5 else 1.0
			speed_label.text = "Espace : vitesse x%d" % int(field.speed)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and KEY_SLOTS.has(event.physical_keycode):
		_on_spell_pressed(int(KEY_SLOTS[event.physical_keycode]))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and _tgt_slot >= 0:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_targeting()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_click_on_field()
		get_viewport().set_input_as_handled()


func _on_field_finished(victory: bool) -> void:
	if _done:
		return
	_done = true
	_cancel_targeting()
	banner.modulate = Color.WHITE
	banner.text = "VICTOIRE !" if victory else "DÉFAITE..."
	banner.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if victory else Color(1, 0.5, 0.5))
	await get_tree().create_timer(1.6).timeout
	_report = Game.apply_battle_rewards(encounter, victory, field.captured)
	var stats: Dictionary = {}
	for u in field.units:
		if u.team == 0:
			stats[u.instance.uid] = {"dealt": u.dmg_dealt, "taken": u.dmg_taken}
	_report["stats"] = stats
	_show_result(_report)


func _show_result(report: Dictionary) -> void:
	_result_shown = true
	banner.text = ""
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := UiStyle.panel()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(580, 0)
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var victory: bool = report.get("victory", false)
	box.add_child(UiStyle.header("VICTOIRE !" if victory else "DÉFAITE...", 24))
	if victory:
		box.add_child(UiStyle.label("+%d EXP par Pokémon déployé    +%d or" % [int(report["exp_each"]), int(report["gold"])], 16, UiStyle.COL_GOLD, true))
		for id in report.get("items", []):
			box.add_child(UiStyle.label("Objet obtenu : " + str(GlobalData.get_item(str(id)).get("name", id)), 15, UiStyle.COL_GOOD, true))
		for id in report.get("trainer_items", []):
			box.add_child(UiStyle.label("Objet de dresseur obtenu : " + str(GlobalData.get_trainer_spell(str(id)).get("name", id)), 15, UiStyle.COL_GOOD, true))
	else:
		box.add_child(UiStyle.label("Vos Pokémon sont soignés. Revoyez votre formation (Tab) et réessayez.", 16, UiStyle.COL_TEXT, true))
	for c in report.get("captured", []):
		box.add_child(UiStyle.label("★ Capturé : %s  Nv%d !" % [str(c["name"]), int(c["level"])], 17, Color("ffe066"), true))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	box.add_child(list)
	for entry in report.get("pokemon", []):
		list.add_child(_pokemon_row(entry, report.get("stats", {})))

	var btn := Button.new()
	btn.text = "CONTINUER  (Entrée)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_close)
	box.add_child(btn)


func _pokemon_row(e: Dictionary, stats: Dictionary) -> Control:
	var row := PanelContainer.new()
	var sb: StyleBoxFlat = UiStyle.box(UiStyle.COL_PANEL_DARK, Color("3a4a6e"), 1, 8, 6)
	sb.shadow_size = 0
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)
	var pic := TextureRect.new()
	pic.texture = SpriteLibrary.get_portrait(str(e["species"]))
	pic.custom_minimum_size = Vector2(44, 44)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(pic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var st: Dictionary = stats.get(int(e.get("uid", -1)), {})
	var head: String = "%s   Nv%d" % [str(e["name"]), int(e["new_level"])]
	if not st.is_empty():
		head += "      ▲ %d   ▼ %d" % [roundi(float(st["dealt"])), roundi(float(st["taken"]))]
	col.add_child(UiStyle.label(head, 15))
	if int(e["new_level"]) > int(e["old_level"]):
		col.add_child(UiStyle.label("Niveau %d → %d" % [int(e["old_level"]), int(e["new_level"])], 14, UiStyle.COL_GOLD))
		var gains: Dictionary = e["gains"]
		var parts: Array[String] = []
		for k in Balance.STAT_KEYS:
			if int(gains.get(k, 0)) > 0:
				parts.append("%s +%d" % [Balance.STAT_LABELS[k], int(gains[k])])
		col.add_child(UiStyle.label(", ".join(parts), 13, UiStyle.COL_GOOD, true))
	if e.get("can_evolve", false):
		col.add_child(UiStyle.label("✦ Peut évoluer ! (menu Tab)", 14, UiStyle.COL_EVO))
	return row


func _close() -> void:
	finished.emit(_report)
	queue_free()
