extends CharacterBody2D
class_name Npc

@export var sprite_texture: Texture2D
@export_file("*.dialogue") var dialogue_path: String = "res://dialogues/main.dialogue"
@export var dialogue_ressource: DialogueResource
@export var dialogue_start: String = "start"

var actionable: Actionable
@onready var dialogueBalloon: TextureRect = $DialogueBalloon

var dialogue_icon: Texture2D = load("res://assets/icon/dialog-icon.png")
var mini_dialogue_icon: Texture2D = load("res://assets/icon/mini-dialog-icon.png")


func _ready() -> void:
	change_skin()
	_ensure_actionable()
	if not actionable.actioned.is_connected(_on_dialogue_actioned):
		actionable.actioned.connect(_on_dialogue_actioned)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("nearest_actionable_changed"):
		if not player.nearest_actionable_changed.is_connected(_on_player_nearest_actionable_changed):
			player.nearest_actionable_changed.connect(_on_player_nearest_actionable_changed)


func _ensure_actionable() -> void:
	actionable = get_node_or_null("Actionable")
	if actionable == null:
		actionable = Actionable.new()
		actionable.name = "Actionable"
		actionable.collision_layer = 256
		actionable.collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 18.0
		shape.shape = circle
		shape.position = Vector2(8, 24)
		actionable.add_child(shape)
		add_child(actionable)


func change_skin() -> void:
	var sprite = get_node("Sprite")
	if sprite_texture:
		sprite.set_texture(sprite_texture)


func _on_dialogue_actioned() -> void:
	if Game.in_dialogue:
		return
	var res: Resource = dialogue_ressource
	if res == null and ResourceLoader.exists(dialogue_path):
		res = load(dialogue_path)
	if res == null:
		printerr("Aucun dialogue pour ", name, " (", dialogue_path, ") - le fichier est-il importé ?")
		return
	Game.in_dialogue = true
	DialogueManager.show_example_dialogue_balloon(res, dialogue_start)
	await DialogueManager.dialogue_ended
	Game.in_dialogue = false


func _on_player_nearest_actionable_changed(nearest_actionable: Actionable) -> void:
	if nearest_actionable == actionable:
		dialogueBalloon.set_texture(dialogue_icon)
	else:
		dialogueBalloon.set_texture(mini_dialogue_icon)
