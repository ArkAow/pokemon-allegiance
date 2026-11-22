class_name BattleHud
extends Control

signal spell_clicked(index: int)
signal unit_clicked(unit: BattleUnit)
signal unit_hovered(unit: BattleUnit)

const SIDE_W := 330.0

var field: BattleField
var book: TrainerSpellbook
var ally_rows: Array[UnitRow] = []
var enemy_rows: Array[UnitRow] = []
var slots: Array[SpellSlot] = []
var hint_label: Label
var selected_slot: int = -1
var highlight_unit: BattleUnit = null
var _timer: float = 0.0
var _hint_left: float = 0.0


func build(p_field: BattleField, p_book: TrainerSpellbook, enemy_title: String) -> void:
	field = p_field
	book = p_book
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	var cols := HBoxContainer.new()
	cols.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(cols)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(SIDE_W, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cols.add_child(left)
	var ally_panel: PanelContainer = _team_panel(left, "Votre équipe   (▲ dégâts infligés  ▼ subis)", Color("ffd54a"), 0, ally_rows, field.ally_synergies)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cols.add_child(center)
	hint_label = UiStyle.label("", 18, UiStyle.COL_GOLD)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(hint_label)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(SIDE_W, 0)
	right.add_theme_constant_override("separation", 8)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cols.add_child(right)
	_team_panel(right, enemy_title, Color("ff8a80"), 1, enemy_rows, field.enemy_synergies)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(spacer)
	right.add_child(_spell_panel())
	ally_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	refresh()


func _team_panel(parent: Control, title: String, title_col: Color, team: int, rows: Array[UnitRow], synergies: Array) -> PanelContainer:
	var panel := UiStyle.panel(true)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UiStyle.label(title, 14, title_col))
	for u in field.units:
		if u.team != team:
			continue
		var row := UnitRow.new()
		box.add_child(row)
		row.setup(u, team == 0)
		row.clicked.connect(func(unit: BattleUnit) -> void: unit_clicked.emit(unit))
		row.hovered.connect(func(unit: BattleUnit) -> void:
			highlight_unit = unit
			unit_hovered.emit(unit))
		rows.append(row)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 3)
	box.add_child(flow)
	for s in synergies:
		var info: Dictionary = s["info"]
		var tier: int = int(s["tier"])
		var bps: Array = s["breakpoints"]
		var goal: int = int(bps[mini(tier + 1, bps.size() - 1)])
		var pill: PanelContainer = UiStyle.type_pill(str(s["type"]), true)
		(pill.get_child(0) as Label).text = "%s %d/%d" % [str(info.get("name", "?")), int(s["count"]), goal]
		var tiers: Array = info.get("tiers", [])
		pill.tooltip_text = "%s : %s" % [str(info.get("synergy", "")), str(tiers[tier].get("desc", "")) if tier >= 0 and tier < tiers.size() else "inactive"]
		if tier < 0:
			pill.modulate = Color(1, 1, 1, 0.45)
		flow.add_child(pill)
	return panel


func _spell_panel() -> PanelContainer:
	var panel := UiStyle.panel(true)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UiStyle.label("Sorts du dresseur   (clic ou touches 1 · 2 · 3)", 14, Color("8fd3ff")))
	for i in range(TrainerSpellbook.SLOTS):
		var s := SpellSlot.new()
		box.add_child(s)
		s.setup(i, book.ids[i])
		s.clicked.connect(func(idx: int) -> void: spell_clicked.emit(idx))
		slots.append(s)
	return panel


func set_selected_slot(i: int) -> void:
	selected_slot = i


func set_hint(text: String, temp: bool = false) -> void:
	hint_label.text = text
	_hint_left = 2.5 if temp else 0.0


func _process(delta: float) -> void:
	if field == null:
		return
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			hint_label.text = ""
	_timer += delta
	if _timer >= 0.08:
		_timer = 0.0
		refresh()


func refresh() -> void:
	var max_dealt: float = 1.0
	var max_taken: float = 1.0
	for r in ally_rows:
		max_dealt = maxf(max_dealt, r.unit.dmg_dealt)
		max_taken = maxf(max_taken, r.unit.dmg_taken)
	for r in ally_rows:
		r.refresh(max_dealt, max_taken, r.unit == highlight_unit)
	for r in enemy_rows:
		r.refresh(1.0, 1.0, r.unit == highlight_unit)
	for i in range(slots.size()):
		slots[i].refresh(book.cooldown_ratio(i), book.count_text(i), book.block_reason(i, field) == "", i == selected_slot)
