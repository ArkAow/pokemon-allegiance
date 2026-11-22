extends Node

signal team_changed
signal inventory_changed
signal battle_requested(encounter: Dictionary)

const DEBUG_KEYS := true
const SAVE_PATH := "user://save.json"

var trainer_items: Dictionary = {}
var loadout: Array = ["", "", ""]
var roster: Array[PokemonInstance] = []
var items: Dictionary = {}
var gold: int = 0
var flags: Dictionary = {}
var next_uid: int = 1

var in_battle: bool = false
var menu: InventoryMenu = null
var next_spawn: String = ""
var pending_encounter: Dictionary = {}

var in_dialogue: bool = false:
	set(v):
		in_dialogue = v
		if not v and not pending_encounter.is_empty():
			var enc: Dictionary = pending_encounter
			pending_encounter = {}
			call_deferred("emit_signal", "battle_requested", enc)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_new_game()


func _new_game() -> void:
	roster.clear()
	items.clear()
	flags.clear()
	gold = 0
	var starter: PokemonInstance = add_pokemon("1", 5)
	starter.cell = Vector2i(3, 6)
	var second: PokemonInstance = add_pokemon("4", 5)
	second.cell = Vector2i(2, 6)
	give_item("oran_berry", 2)
	give_item("scope_lens", 1)
	trainer_items.clear()
	var starter_kit: Dictionary = {"poke_ball": 8, "great_ball": 2, "potion": 4, "fire_bomb": 2, "x_attack": 2, "heal_song": 1, "swap_whistle": 1, "warp_whistle": 1}
	for id in starter_kit:
		give_trainer_item(str(id), int(starter_kit[id]))
	loadout = ["poke_ball", "potion", "fire_bomb"]


func add_pokemon(species_id: String, level: int = 1) -> PokemonInstance:
	var p: PokemonInstance = PokemonInstance.create(species_id, level)
	p.uid = next_uid
	next_uid += 1
	roster.append(p)
	team_changed.emit()
	return p


func find_by_uid(uid: int) -> PokemonInstance:
	for p in roster:
		if p.uid == uid:
			return p
	return null


func deployed() -> Array[PokemonInstance]:
	var out: Array[PokemonInstance] = []
	for p in roster:
		if p.is_deployed():
			out.append(p)
	return out


func pokemon_at(cell: Vector2i) -> PokemonInstance:
	for p in roster:
		if p.cell == cell:
			return p
	return null


func is_player_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Balance.BOARD_COLS and cell.y >= Balance.PLAYER_ROW_START and cell.y < Balance.BOARD_ROWS


func can_deploy(p: PokemonInstance, cell: Vector2i) -> bool:
	if not is_player_cell(cell):
		return false
	if p.is_deployed() or pokemon_at(cell) != null:
		return true
	return deployed().size() < Balance.MAX_DEPLOYED


func deploy(p: PokemonInstance, cell: Vector2i) -> bool:
	if not can_deploy(p, cell):
		return false
	var occupant: PokemonInstance = pokemon_at(cell)
	if occupant == p:
		return true
	if occupant != null:
		occupant.cell = p.cell
	p.cell = cell
	team_changed.emit()
	return true


func auto_deploy(p: PokemonInstance) -> bool:
	if p.is_deployed() or deployed().size() >= Balance.MAX_DEPLOYED:
		return false
	var ranged: bool = int(p.species().get("range", 1)) > 1
	var rows: Array = range(Balance.PLAYER_ROW_START, Balance.BOARD_ROWS)
	if ranged:
		rows.reverse()
	var cols: Array = [3, 2, 4, 1, 5, 0, 6]
	for r in rows:
		for c in cols:
			var cell := Vector2i(c, r)
			if pokemon_at(cell) == null:
				return deploy(p, cell)
	return false


func undeploy(p: PokemonInstance) -> void:
	p.cell = PokemonInstance.NO_CELL
	team_changed.emit()


func evolve(p: PokemonInstance) -> Dictionary:
	var res: Dictionary = p.evolve()
	team_changed.emit()
	return res


func give_item(id: String, n: int = 1) -> void:
	items[id] = int(items.get(id, 0)) + n
	inventory_changed.emit()


func item_count(id: String) -> int:
	return int(items.get(id, 0))


func equip_item(p: PokemonInstance, id: String) -> bool:
	if id == p.item_id:
		return true
	if id != "" and item_count(id) <= 0:
		return false
	if p.item_id != "":
		items[p.item_id] = item_count(p.item_id) + 1
	if id != "":
		items[id] = item_count(id) - 1
	p.item_id = id
	inventory_changed.emit()
	team_changed.emit()
	return true


func give_trainer_item(id: String, n: int = 1) -> void:
	if GlobalData.get_trainer_spell(id).is_empty():
		printerr("objet de dresseur inconnu : ", id)
		return
	trainer_items[id] = int(trainer_items.get(id, 0)) + n
	inventory_changed.emit()


func trainer_count(id: String) -> int:
	return int(trainer_items.get(id, 0))


func use_trainer_item(id: String) -> void:
	if bool(GlobalData.get_trainer_spell(id).get("consumable", true)):
		trainer_items[id] = maxi(0, trainer_count(id) - 1)
		inventory_changed.emit()


func owned_trainer_items() -> Array:
	var out: Array = []
	for id in trainer_items:
		if trainer_count(str(id)) > 0:
			out.append(str(id))
	out.sort_custom(func(a: String, b: String) -> bool:
		return str(GlobalData.get_trainer_spell(a).get("name", a)) < str(GlobalData.get_trainer_spell(b).get("name", b)))
	return out


func set_loadout(slot: int, id: String) -> void:
	var old: String = str(loadout[slot])
	if id != "":
		for i in range(loadout.size()):
			if i != slot and str(loadout[i]) == id:
				loadout[i] = old
	loadout[slot] = id
	inventory_changed.emit()


func has_flag(f: String) -> bool:
	return flags.has(f)


func set_flag(f: String) -> void:
	flags[f] = true


func generate_wild_encounter(zone_id: String) -> Dictionary:
	var zone: Dictionary = GlobalData.zones_data.get(zone_id, {})
	var pool: Array = zone.get("pool", ["16"])
	var lv: Array = zone.get("level_range", [3, 5])
	var n: int = deployed().size()
	var count: int = clampi(randi_range(maxi(1, n - 1), n + 1), 1, 8)
	var cells: Array[Vector2i] = []
	for r in range(0, Balance.PLAYER_ROW_START):
		for c in range(Balance.BOARD_COLS):
			cells.append(Vector2i(c, r))
	cells.shuffle()
	var enemies: Array = []
	for i in range(count):
		enemies.append({
			"species": str(pool.pick_random()),
			"level": randi_range(int(lv[0]), int(lv[1])),
			"cell": [cells[i].x, cells[i].y],
		})
	return {"name": "Pokémon sauvages", "enemies": enemies, "gold": count * 3, "items": [], "wild": true}


func request_battle(trainer_id: String) -> void:
	var t: Dictionary = GlobalData.trainers_data.get(trainer_id, {})
	if t.is_empty():
		printerr("dresseur inconnu : ", trainer_id)
		return
	var enc: Dictionary = t.duplicate(true)
	enc["trainer_id"] = trainer_id
	if in_dialogue:
		pending_encounter = enc
	else:
		call_deferred("emit_signal", "battle_requested", enc)


func apply_battle_rewards(enc: Dictionary, victory: bool, captured: Array = []) -> Dictionary:
	var report := {"victory": victory, "exp_each": 0, "gold": 0, "items": [], "trainer_items": [], "pokemon": [], "captured": []}
	for c in captured:       # les captures sont gardées même en cas de défaite
		var np: PokemonInstance = add_pokemon(str(c["species"]), int(c["level"]))
		report["captured"].append({"name": np.display_name(), "species": np.species_id, "level": np.level})
	if not victory:
		return report
	var exp_total: int = 0
	for e in enc.get("enemies", []):
		exp_total += int(e["level"]) * Balance.EXP_PER_ENEMY_LEVEL + Balance.EXP_BASE_PER_ENEMY
	report["exp_each"] = exp_total
	report["gold"] = int(enc.get("gold", 0))
	gold += int(report["gold"])
	for id in enc.get("items", []):
		give_item(str(id))
		report["items"].append(id)
	for id in enc.get("trainer_items", []):
		give_trainer_item(str(id))
		report["trainer_items"].append(id)
	if enc.has("once_flag"):
		set_flag(str(enc["once_flag"]))
	for p in deployed():
		var res: Dictionary = p.add_exp(exp_total)
		var gains := {}
		for k in Balance.STAT_KEYS:
			gains[k] = int(res["new_stats"][k]) - int(res["old_stats"][k])
		report["pokemon"].append({
			"uid": p.uid, "name": p.display_name(), "species": p.species_id, "old_level": res["old_level"], "new_level": p.level,
			"gains": gains, "can_evolve": p.can_evolve(),
		})
	team_changed.emit()
	return report


func change_level(scene_path: String, spawn_name: String = "") -> void:
	next_spawn = spawn_name
	get_tree().change_scene_to_file.call_deferred(scene_path)


func is_input_blocked() -> bool:
	return in_battle or in_dialogue


func open_inventory() -> void:
	if menu != null and is_instance_valid(menu):
		return
	menu = InventoryMenu.new()
	get_tree().root.add_child(menu)
	get_tree().paused = true


func close_inventory() -> void:
	if menu != null and is_instance_valid(menu):
		menu.queue_free()
	menu = null
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if menu != null and is_instance_valid(menu):
			close_inventory()
		elif not is_input_blocked():
			open_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and menu != null and is_instance_valid(menu):
		close_inventory()
		get_viewport().set_input_as_handled()
	elif DEBUG_KEYS and event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F9:
				add_pokemon(str(GlobalData.pokemon_data.keys().pick_random()), randi_range(3, 12))
			KEY_F10:
				for id in GlobalData.items_data:
					give_item(str(id))
				for id in GlobalData.trainer_spells_data:
					give_trainer_item(str(id), 3)
			KEY_F5:
				save_game()
			KEY_F8:
				load_game()


func save_game() -> void:
	var data := {"gold": gold, "items": items, "flags": flags, "next_uid": next_uid, "roster": [], "trainer_items": trainer_items, "loadout": loadout}
	for p in roster:
		data["roster"].append(p.to_dict())
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	print("partie sauvegardée : ", ProjectSettings.globalize_path(SAVE_PATH))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text())
	if not (parsed is Dictionary):
		return false
	gold = int(parsed.get("gold", 0))
	items = parsed.get("items", {})
	flags = parsed.get("flags", {})
	next_uid = int(parsed.get("next_uid", 1))
	trainer_items = parsed.get("trainer_items", {})
	loadout = parsed.get("loadout", ["", "", ""])
	roster.clear()
	for d in parsed.get("roster", []):
		roster.append(PokemonInstance.from_dict(d))
	team_changed.emit()
	inventory_changed.emit()
	return true
