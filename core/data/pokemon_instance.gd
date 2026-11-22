class_name PokemonInstance
extends Resource

const NO_CELL := Vector2i(-1, -1)

@export var uid: int = 0
@export var species_id: String = "1"
@export var nickname: String = ""
@export var level: int = 1
@export var current_exp: int = 0
@export var ivs: Dictionary = {}
@export var item_id: String = ""
@export var cell: Vector2i = NO_CELL


static func create(p_species_id: String, p_level: int = 1, fixed_iv: int = -1) -> PokemonInstance:
	var p := PokemonInstance.new()
	p.species_id = p_species_id
	p.level = p_level
	for k in Balance.STAT_KEYS:
		p.ivs[k] = fixed_iv if fixed_iv >= 0 else randi_range(1, 31)
	return p


func species() -> Dictionary:
	return GlobalData.get_species(species_id)


func display_name() -> String:
	if nickname != "":
		return nickname
	return str(species().get("name", "???"))


func types() -> Array:
	return species().get("types", [])


func is_deployed() -> bool:
	return cell != NO_CELL


func compute_stats() -> Dictionary:
	var base: Dictionary = species().get("base", {})
	var out := {}
	for k in Balance.STAT_KEYS:
		out[k] = Balance.calc_stat(k, int(base.get(k, 50)), int(ivs.get(k, 0)), level)
	return out


func exp_needed() -> int:
	return Balance.exp_to_next(level)


func add_exp(amount: int) -> Dictionary:
	var old_stats: Dictionary = compute_stats()
	var old_level: int = level
	if level < Balance.MAX_LEVEL:
		current_exp += amount
		while level < Balance.MAX_LEVEL and current_exp >= exp_needed():
			current_exp -= exp_needed()
			level += 1
		if level >= Balance.MAX_LEVEL:
			current_exp = 0
	return {
		"levels_gained": level - old_level,
		"old_level": old_level,
		"old_stats": old_stats,
		"new_stats": compute_stats(),
	}


func evolution() -> Dictionary:
	var evo: Variant = species().get("evolves_to", null)
	if evo is Dictionary:
		return evo
	return {}


func can_evolve() -> bool:
	var evo: Dictionary = evolution()
	return not evo.is_empty() and level >= int(evo.get("level", 9999))


func evolve() -> Dictionary:
	if not can_evolve():
		return {"evolved": false}
	var old_stats: Dictionary = compute_stats()
	var old_name: String = display_name()
	species_id = str(evolution()["id"])
	return {
		"evolved": true,
		"old_stats": old_stats,
		"new_stats": compute_stats(),
		"old_name": old_name,
		"new_name": display_name(),
	}


func to_dict() -> Dictionary:
	return {
		"uid": uid, "species": species_id, "nick": nickname, "level": level, "exp": current_exp,
		"ivs": ivs, "item": item_id, "cell": [cell.x, cell.y],
	}


static func from_dict(d: Dictionary) -> PokemonInstance:
	var p := PokemonInstance.new()
	p.uid = int(d.get("uid", 0))
	p.species_id = str(d.get("species", "1"))
	p.nickname = str(d.get("nick", ""))
	p.level = int(d.get("level", 1))
	p.current_exp = int(d.get("exp", 0))
	p.ivs = d.get("ivs", {})
	p.item_id = str(d.get("item", ""))
	var c: Array = d.get("cell", [-1, -1])
	p.cell = Vector2i(int(c[0]), int(c[1]))
	return p
