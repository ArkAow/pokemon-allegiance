class_name InventoryMenu
extends CanvasLayer

const LEFT_W := 320.0
const RIGHT_W := 360.0

var selected: PokemonInstance = null
var board: HexBoardView
var team_list: VBoxContainer
var count_label: Label
var gold_label: Label
var synergy_text: RichTextLabel
var detail_box: VBoxContainer
var loadout_box: HBoxContainer
var status_text: String = ""


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Game.team_changed.connect(_refresh_deferred)
	Game.inventory_changed.connect(_refresh_deferred)
	if selected == null and not Game.roster.is_empty():
		selected = Game.roster[0]
	_refresh()


func _exit_tree() -> void:
	if Game.team_changed.is_connected(_refresh_deferred):
		Game.team_changed.disconnect(_refresh_deferred)
	if Game.inventory_changed.is_connected(_refresh_deferred):
		Game.inventory_changed.disconnect(_refresh_deferred)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiStyle.get_theme()
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(UiStyle.COL_BG, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	root.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	var top_bar: PanelContainer = UiStyle.header_bar()
	outer.add_child(top_bar)
	var top_row := HBoxContainer.new()
	top_bar.add_child(top_row)
	var title: Label = UiStyle.label("FORMATION & ÉQUIPE", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)
	gold_label = UiStyle.label("", 18, UiStyle.COL_GOLD)
	top_row.add_child(gold_label)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	outer.add_child(cols)

	var left := TeamDropZone.new()
	left.custom_minimum_size = Vector2(LEFT_W, 0)
	cols.add_child(left)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 6)
	left.add_child(lbox)
	count_label = UiStyle.label("", 15, UiStyle.COL_GOLD)
	lbox.add_child(count_label)
	var hint: Label = UiStyle.label("Glissez un Pokémon sur le plateau, double-cliquez dessus, ou sélectionnez-le puis cliquez une case. Déposez un Pokémon du plateau ici pour le retirer.", 12, UiStyle.COL_TEXT_DIM, true)
	lbox.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lbox.add_child(scroll)
	team_list = VBoxContainer.new()
	team_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_list.add_theme_constant_override("separation", 4)
	scroll.add_child(team_list)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	cols.add_child(center)
	var board_panel := UiStyle.panel(true)
	center.add_child(board_panel)
	var bbox := VBoxContainer.new()
	bbox.add_theme_constant_override("separation", 4)
	board_panel.add_child(bbox)
	bbox.add_child(UiStyle.label("Terrain — vos ennemis arrivent par le haut", 14, UiStyle.COL_TEXT_DIM))
	var board_holder := CenterContainer.new()
	bbox.add_child(board_holder)
	board = HexBoardView.new()
	board.pokemon_clicked.connect(_select)
	board.empty_cell_clicked.connect(_on_empty_cell)
	board_holder.add_child(board)

	var loadout_panel := UiStyle.panel(true)
	center.add_child(loadout_panel)
	var lo_outer := VBoxContainer.new()
	lo_outer.add_theme_constant_override("separation", 4)
	loadout_panel.add_child(lo_outer)
	lo_outer.add_child(UiStyle.label("Objets du dresseur — 3 sorts emportés en combat (touches 1 · 2 · 3)", 14, Color("8fd3ff")))
	loadout_box = HBoxContainer.new()
	loadout_box.add_theme_constant_override("separation", 8)
	lo_outer.add_child(loadout_box)

	var syn_panel := UiStyle.panel()
	syn_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(syn_panel)
	var syn_box := VBoxContainer.new()
	syn_box.add_theme_constant_override("separation", 4)
	syn_panel.add_child(syn_box)
	syn_box.add_child(UiStyle.label("Synergies (espèces différentes déployées)", 15, UiStyle.COL_GOLD))
	var syn_scroll := ScrollContainer.new()
	syn_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	syn_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	syn_box.add_child(syn_scroll)
	synergy_text = RichTextLabel.new()
	synergy_text.bbcode_enabled = true
	synergy_text.fit_content = true
	synergy_text.scroll_active = false
	synergy_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synergy_text.custom_minimum_size = Vector2(300, 0)
	syn_scroll.add_child(synergy_text)

	var right := UiStyle.panel()
	right.custom_minimum_size = Vector2(RIGHT_W, 0)
	cols.add_child(right)
	var rscroll := ScrollContainer.new()
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rscroll)
	detail_box = VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.custom_minimum_size = Vector2(RIGHT_W - 44.0, 0)
	detail_box.add_theme_constant_override("separation", 6)
	rscroll.add_child(detail_box)

	outer.add_child(UiStyle.label("Tab / Échap : fermer     Double-clic sur un Pokémon : placer / retirer     Clic droit sur le plateau : retirer     Max %d déployés" % Balance.MAX_DEPLOYED, 12, UiStyle.COL_TEXT_DIM))


func _select(p: PokemonInstance) -> void:
	selected = p
	status_text = ""
	for slot in team_list.get_children():
		if slot is TeamSlot:
			slot.set_selected(slot.inst == p)
	board.selected_uid = p.uid if p != null else -1
	board.queue_redraw()
	_build_detail()


func _on_slot_activated(p: PokemonInstance) -> void:
	_select(p)
	if p.is_deployed():
		Game.undeploy(p)
	elif not Game.auto_deploy(p):
		status_text = "Le terrain est plein (%d max)." % Balance.MAX_DEPLOYED
		_build_detail()


func _on_empty_cell(cell: Vector2i) -> void:
	if selected == null:
		return
	if not Game.deploy(selected, cell):
		status_text = "Le terrain est plein (%d max)." % Balance.MAX_DEPLOYED
		_build_detail()


func _refresh_deferred() -> void:
	call_deferred("_refresh")


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _refresh() -> void:
	if not is_inside_tree():
		return
	if selected != null and not Game.roster.has(selected):
		selected = null
	gold_label.text = "Or : %d" % Game.gold
	count_label.text = "Équipe : %d    Déployés : %d/%d" % [Game.roster.size(), Game.deployed().size(), Balance.MAX_DEPLOYED]

	_clear(team_list)
	for p in Game.roster:
		var slot := TeamSlot.new()
		team_list.add_child(slot)
		slot.setup(p, p == selected)
		slot.selected.connect(_select)
		slot.activated.connect(_on_slot_activated)

	board.selected_uid = selected.uid if selected != null else -1
	board.queue_redraw()

	var ids: Array = []
	for p in Game.deployed():
		ids.append(p.species_id)
	var syn: Array = SynergyCalc.compute(ids)
	synergy_text.text = SynergyCalc.to_bbcode(syn, true) if not syn.is_empty() else "[color=#9fb0cc]Aucun Pokémon déployé.[/color]"
	_build_loadout()
	_build_detail()


func _build_loadout() -> void:
	_clear(loadout_box)
	var owned: Array = Game.owned_trainer_items()
	for slot in range(TrainerSpellbook.SLOTS):
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size = Vector2(150, 0)
		col.add_theme_constant_override("separation", 3)
		loadout_box.add_child(col)
		col.add_child(UiStyle.label("Emplacement %d" % (slot + 1), 12, UiStyle.COL_GOLD))
		var opt := OptionButton.new()
		opt.focus_mode = Control.FOCUS_NONE
		opt.clip_text = true
		opt.fit_to_longest_item = false
		opt.add_item("— vide —")
		var ids: Array[String] = [""]
		var current: String = str(Game.loadout[slot])
		var sel: int = 0
		for id in owned:
			var d: Dictionary = GlobalData.get_trainer_spell(str(id))
			var label: String = str(d.get("name", id))
			if bool(d.get("consumable", true)):
				label += "  x%d" % Game.trainer_count(str(id))
			opt.add_item(label)
			ids.append(str(id))
			if str(id) == current:
				sel = ids.size() - 1
		opt.select(sel)
		opt.item_selected.connect(func(idx: int) -> void: Game.set_loadout(slot, ids[idx]))
		col.add_child(opt)
		var d2: Dictionary = GlobalData.get_trainer_spell(current)
		var desc: String = str(d2.get("desc", "Choisissez un objet."))
		if not d2.is_empty():
			var mode: String = str(d2.get("targeting", "none"))
			var mode_txt: Dictionary = {"none": "Instantané", "enemy": "Vise un ennemi", "ally": "Vise un allié", "point": "Vise un lieu", "ally_point": "Allié puis lieu", "ally_ally": "Deux alliés"}
			desc += "  [%s]" % str(mode_txt.get(mode, mode))
		col.add_child(UiStyle.label(desc, 11, UiStyle.COL_TEXT_DIM, true))


func _build_detail() -> void:
	_clear(detail_box)
	if selected == null:
		detail_box.add_child(UiStyle.label("Sélectionnez un Pokémon.", 16, UiStyle.COL_TEXT_DIM, true))
		return
	var p: PokemonInstance = selected
	var sp: Dictionary = p.species()

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	detail_box.add_child(head)
	var pic := TextureRect.new()
	pic.texture = SpriteLibrary.get_portrait(p.species_id)
	pic.custom_minimum_size = Vector2(88, 88)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(pic)
	var hb := VBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 4)
	head.add_child(hb)
	hb.add_child(UiStyle.label(p.display_name(), 24))
	hb.add_child(UiStyle.label("Niveau %d" % p.level, 16, UiStyle.COL_GOLD))
	hb.add_child(UiStyle.type_pills(p.types()))


	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 8)
	var exp_l: Label = UiStyle.label("EXP", 13, UiStyle.COL_TEXT_DIM)
	exp_l.custom_minimum_size = Vector2(78, 0)
	exp_row.add_child(exp_l)
	exp_row.add_child(UiStyle.bar(float(p.current_exp), float(p.exp_needed()), Color("4aa3ff"), 8.0))
	var exp_v: Label = UiStyle.label("%d/%d" % [p.current_exp, p.exp_needed()], 12, UiStyle.COL_TEXT_DIM)
	exp_v.custom_minimum_size = Vector2(64, 0)
	exp_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	exp_row.add_child(exp_v)
	detail_box.add_child(exp_row)

	var stats: Dictionary = p.compute_stats()
	var stat_colors := {"hp": Color("ff5959"), "atk": Color("f5ac78"), "def": Color("fae078"), "speAtk": Color("9db7f5"), "speDef": Color("a7db8d"), "spd": Color("fa92b2")}
	for k in Balance.STAT_KEYS:
		var max_v: float = 120.0 + p.level * 5.0 if k == "hp" else 50.0 + p.level * 3.0
		detail_box.add_child(UiStyle.stat_row(str(Balance.STAT_LABELS[k]), int(stats[k]), max_v, stat_colors[k]))
	detail_box.add_child(UiStyle.label("IV : " + "  ".join(Balance.STAT_KEYS.map(func(k: String) -> String: return str(int(p.ivs.get(k, 0))))), 11, UiStyle.COL_TEXT_DIM))

	var rng: int = int(sp.get("range", 1))
	var kind: String = "Spécial" if str(sp.get("attack_kind", "physical")) == "special" else "Physique"
	var rng_txt: String = "corps à corps" if rng <= 1 else "distance, portée %d" % rng
	detail_box.add_child(UiStyle.label("Attaque %s — %s" % [kind, rng_txt], 14, UiStyle.COL_TEXT, true))

	var ab: Dictionary = GlobalData.get_ability(str(sp.get("ability", "")))
	if not ab.is_empty():
		var ab_panel := UiStyle.panel(true)
		detail_box.add_child(ab_panel)
		var ab_box := VBoxContainer.new()
		ab_box.add_theme_constant_override("separation", 3)
		ab_panel.add_child(ab_box)
		ab_box.add_child(UiStyle.label("%s   (énergie %d)" % [str(ab["name"]), int(ab["cost"])], 15, Color("8fd3ff")))
		ab_box.add_child(UiStyle.label(str(ab["desc"]), 13, UiStyle.COL_TEXT, true))

	detail_box.add_child(UiStyle.label("Objet tenu", 14, UiStyle.COL_TEXT_DIM))
	var ids: Array[String] = [""]
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.add_item("— Aucun —")
	var current_idx: int = 0
	if p.item_id != "":
		ids.append(p.item_id)
		opt.add_item(str(GlobalData.get_item(p.item_id).get("name", p.item_id)) + " (équipé)")
		current_idx = 1
	var bag_ids: Array = Game.items.keys()
	bag_ids.sort()
	for id in bag_ids:
		if Game.item_count(str(id)) > 0:
			ids.append(str(id))
			opt.add_item("%s  ×%d" % [str(GlobalData.get_item(str(id)).get("name", id)), Game.item_count(str(id))])
	opt.select(current_idx)
	opt.item_selected.connect(func(idx: int) -> void: Game.equip_item(p, ids[idx]))
	detail_box.add_child(opt)
	if p.item_id != "":
		var it: Dictionary = GlobalData.get_item(p.item_id)
		detail_box.add_child(UiStyle.label(str(it.get("desc", "")), 13, UiStyle.COL_GOOD, true))
		detail_box.add_child(UiStyle.label(str(it.get("flavor", "")), 12, UiStyle.COL_TEXT_DIM, true))

	var evo: Dictionary = p.evolution()
	if not evo.is_empty():
		var evo_name: String = str(GlobalData.get_species(str(evo["id"])).get("name", "?"))
		detail_box.add_child(UiStyle.label("Évolue en %s au niveau %d" % [evo_name, int(evo["level"])], 14, UiStyle.COL_EVO, true))
		var eb := Button.new()
		eb.text = "ÉVOLUER"
		eb.focus_mode = Control.FOCUS_NONE
		eb.disabled = not p.can_evolve()
		eb.pressed.connect(func() -> void: _do_evolve(p))
		detail_box.add_child(eb)

	var place_btn := Button.new()
	place_btn.focus_mode = Control.FOCUS_NONE
	if p.is_deployed():
		place_btn.text = "Retirer du terrain"
		place_btn.pressed.connect(func() -> void: Game.undeploy(p))
	else:
		place_btn.text = "Placer sur le terrain"
		place_btn.disabled = Game.deployed().size() >= Balance.MAX_DEPLOYED
		place_btn.pressed.connect(func() -> void: Game.auto_deploy(p))
	detail_box.add_child(place_btn)

	if status_text != "":
		detail_box.add_child(UiStyle.label(status_text, 14, UiStyle.COL_GOLD, true))


func _do_evolve(p: PokemonInstance) -> void:
	var res: Dictionary = Game.evolve(p)
	if not res.get("evolved", false):
		return
	var parts: Array[String] = []
	for k in Balance.STAT_KEYS:
		var d: int = int(res["new_stats"][k]) - int(res["old_stats"][k])
		if d > 0:
			parts.append("%s +%d" % [Balance.STAT_LABELS[k], d])
	status_text = "%s a évolué en %s !\n%s" % [res["old_name"], res["new_name"], ", ".join(parts)]
	_refresh_deferred()
