class_name TrainerSpellbook
extends RefCounted

const SLOTS := 3

var ids: Array[String] = []
var cooldowns: Array[float] = []
var charges: Dictionary = {}


func _init(loadout: Array) -> void:
	for i in range(SLOTS):
		var id: String = str(loadout[i]) if i < loadout.size() else ""
		ids.append(id)
		cooldowns.append(0.0)
		var d: Dictionary = GlobalData.get_trainer_spell(id)
		if not d.is_empty() and not bool(d.get("consumable", true)):
			charges[id] = int(d.get("charges", 2))


func spell(i: int) -> Dictionary:
	return GlobalData.get_trainer_spell(ids[i])


func update(dt: float) -> void:
	for i in range(SLOTS):
		cooldowns[i] = maxf(0.0, cooldowns[i] - dt)


func cooldown_ratio(i: int) -> float:
	var cd: float = float(spell(i).get("cooldown", 1.0))
	return clampf(cooldowns[i] / maxf(cd, 0.01), 0.0, 1.0)


func count_text(i: int) -> String:
	var d: Dictionary = spell(i)
	if d.is_empty():
		return ""
	if bool(d.get("consumable", true)):
		return "x%d" % Game.trainer_count(ids[i])
	return "%d/%d" % [int(charges.get(ids[i], 0)), int(d.get("charges", 2))]


func block_reason(i: int, field: BattleField) -> String:
	var d: Dictionary = spell(i)
	if d.is_empty():
		return "Emplacement vide"
	if not field.running or field.finished:
		return "Le combat n'est pas en cours"
	if cooldowns[i] > 0.0:
		return "En recharge"
	if bool(d.get("consumable", true)):
		if Game.trainer_count(ids[i]) <= 0:
			return "Plus en stock"
	elif int(charges.get(ids[i], 0)) <= 0:
		return "Plus de charges"
	if bool(d.get("wild_only", false)) and not field.wild:
		return "Seulement contre des Pokémon sauvages"
	return ""


func targeting(i: int) -> String:
	return str(spell(i).get("targeting", "none"))


func radius_cells(i: int) -> float:
	for step in spell(i).get("steps", []):
		if step.has("radius"):
			return float(step["radius"])
	return 0.0


func find_effect(i: int, effect_type: String) -> Dictionary:
	for step in spell(i).get("steps", []):
		for e in step.get("effects", []):
			if str(e.get("type", "")) == effect_type:
				return e
	return {}


func cast(i: int, aim: Dictionary, field: BattleField) -> void:
	var d: Dictionary = spell(i)
	cooldowns[i] = float(d.get("cooldown", 1.0))
	if bool(d.get("consumable", true)):
		Game.use_trainer_item(ids[i])
	else:
		charges[ids[i]] = int(charges.get(ids[i], 1)) - 1
	var caster: TrainerCaster = field.trainer
	caster.target = aim.get("target", null)
	caster.aim_target2 = aim.get("target2", null)
	caster.aim_point = aim.get("point", caster.position)
	field.fx_text(caster.position + Vector2(0, -20), str(d.get("name", "")), Color(str(d.get("color", "#ffffff"))), 20)
	AbilityRunner.run_def(d, caster, field)
