extends Node

const POKEDEX_PATH := "res://data/pokedex.json"
const TYPES_PATH := "res://data/types.json"
const ITEMS_PATH := "res://data/items.json"
const ABILITIES_PATH := "res://data/abilities.json"
const ZONES_PATH := "res://data/zones.json"
const TRAINERS_PATH := "res://data/trainers.json"
const TRAINER_SPELLS_PATH := "res://data/trainer_spells.json"

var pokemon_data: Dictionary = {}
var types_data: Dictionary = {}
var items_data: Dictionary = {}
var abilities_data: Dictionary = {}
var zones_data: Dictionary = {}
var trainers_data: Dictionary = {}
var trainer_spells_data: Dictionary = {}


func _ready() -> void:
	pokemon_data = load_json_file(POKEDEX_PATH)
	types_data = load_json_file(TYPES_PATH)
	items_data = load_json_file(ITEMS_PATH)
	abilities_data = load_json_file(ABILITIES_PATH)
	zones_data = load_json_file(ZONES_PATH)
	trainers_data = load_json_file(TRAINERS_PATH)
	trainer_spells_data = load_json_file(TRAINER_SPELLS_PATH)


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
	return pokemon_data.get(id, {})


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
