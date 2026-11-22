class_name TrainerCaster
extends BattleUnit


func setup_trainer(p_field: BattleField, avg_level: float) -> void:
	field = p_field
	team = 0
	damage_kind = "special"
	var p: float = 6.0 + avg_level * 1.5
	base_stats = {"hp": 100.0, "atk": p, "def": 0.0, "speAtk": p, "speDef": 0.0, "spd": 50.0}
	max_hp = 100.0
	hp = 100.0
	position = Vector2(p_field.arena_rect.get_center().x, p_field.arena_rect.end.y + 24.0)


func _process(_delta: float) -> void:
	pass


func _draw() -> void:
	pass


func body_height() -> float:
	return 40.0


func is_targetable() -> bool:
	return false
