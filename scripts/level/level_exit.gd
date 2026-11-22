extends Area2D
class_name LevelExit

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0xFFFFFFFF
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player and target_scene != "" and not Game.is_input_blocked():
		Game.change_level(target_scene, target_spawn)
