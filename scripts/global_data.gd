extends Node

const POKEDEX_PATH := "res://data/pokedex.json"
const POKEMON_DIR := "res://data/pokemons/"
const TYPES_PATH := "res://data/types.json"
const ITEMS_PATH := "res://data/items.json"
const ABILITIES_PATH := "res://data/abilities.json"
const ZONES_PATH := "res://data/zones.json"
const TRAINERS_PATH := "res://data/trainers.json"
const TRAINER_SPELLS_PATH := "res://data/trainer_spells.json"

var pokedex: Dictionary = {}
var _species_cache: Dictionary = {}
var types_data: Dictionary = {}
var items_data: Dictionary = {}
var abilities_data: Dictionary = {}
var zones_data: Dictionary = {}
var trainers_data: Dictionary = {}
var trainer_spells_data: Dictionary = {}


func _ready() -> void:
	pokedex = load_json_file(POKEDEX_PATH)
	types_data = load_json_file(TYPES_PATH)
	items_data = load_json_file(ITEMS_PATH)
	abilities_data = load_json_file(ABILITIES_PATH)
	zones_data = load_json_file(ZONES_PATH)
	trainers_data = load_json_file(TRAINERS_PATH)
	trainer_spells_data = load_json_file(TRAINER_SPELLS_PATH)
	if OS.is_debug_build():
		validate()


func load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		printerr("data file path invalid: ", file_path)
		return {}
	var data_file := FileAccess.open(file_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(data_file.get_as_text())
	if parsed is Dictionary:
		return parsed
	printerr("error reading data file: ", file_path)
	return {}


func get_species(id: String) -> Dictionary:
	if _species_cache.has(id):
		return _species_cache[id]
	var slug: String = str(pokedex.get(id, ""))
	if slug == "":
		return {}
	var data: Dictionary = load_json_file(POKEMON_DIR + slug + ".json")
	if data.is_empty():
		return {}
	data["id"] = id
	data["slug"] = slug
	_species_cache[id] = data
	return data


func species_ids() -> Array:
	return pokedex.keys()


func clear_species_cache() -> void:
	_species_cache.clear()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for id in pokedex:
		var slug: String = str(pokedex[id])
		var sp: Dictionary = get_species(str(id))
		if sp.is_empty():
			problems.append("pokédex %s : fichier %s%s.json introuvable ou invalide" % [id, POKEMON_DIR, slug])
			continue
		for t in sp.get("types", []):
			if not types_data.has(str(t)):
				problems.append("%s : type inconnu '%s'" % [slug, t])
		if not abilities_data.has(str(sp.get("ability", ""))):
			problems.append("%s : capacité inconnue '%s'" % [slug, sp.get("ability", "")])
		var base: Dictionary = sp.get("base", {})
		for k in Balance.STAT_KEYS:
			if not base.has(k):
				problems.append("%s : stat de base '%s' manquante" % [slug, k])
		var evo: Variant = sp.get("evolves_to", null)
		if evo is Dictionary and not pokedex.has(str(evo.get("id", ""))):
			problems.append("%s : évolution vers l'id '%s' absent du pokédex" % [slug, evo.get("id", "")])
		if DirAccess.open("res://assets/pokemons/" + slug) == null:
			push_warning("%s : pas de dossier de sprites assets/pokemons/%s/ (un placeholder coloré sera utilisé)" % [slug, slug])
	for pr in problems:
		printerr("[données] ", pr)
	return problems


func get_type_info(type_id: String) -> Dictionary:
	return types_data.get(type_id, {})


func get_type_color(type_id: String) -> Color:
	return Color(str(get_type_info(type_id).get("color", "#aaaaaa")))


func get_item(id: String) -> Dictionary:
	return items_data.get(id, {})


func get_ability(id: String) -> Dictionary:
	return abilities_data.get(id, {})


func get_trainer_spell(id: String) -> Dictionary:
	return trainer_spells_data.get(id, {})
