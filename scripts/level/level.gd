extends Node2D
class_name Level


@export var zone_id: String = "meadow"
@export var map_size: Vector2i = Vector2i.ZERO

var _battle_running: bool = false


func _ready() -> void:
	Game.battle_requested.connect(_on_battle_requested)
	_place_player_at_spawn()
	_apply_camera_limits()


func _exit_tree() -> void:
	if Game.battle_requested.is_connected(_on_battle_requested):
		Game.battle_requested.disconnect(_on_battle_requested)


func _apply_camera_limits() -> void:
	if map_size == Vector2i.ZERO:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = map_size.x
		cam.limit_bottom = map_size.y


func _on_tall_grass_encounter() -> void:
	if Game.is_input_blocked() or Game.deployed().is_empty():
		return
	_on_player_start_battle()


func _place_player_at_spawn() -> void:
	if Game.next_spawn == "":
		return
	var marker: Node = find_child(Game.next_spawn, true, false)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if marker is Node2D and player != null:
		player.global_position = marker.global_position
	Game.next_spawn = ""


func _on_player_start_battle() -> void:
	_run_battle(Game.generate_wild_encounter(zone_id))


func _on_battle_requested(encounter: Dictionary) -> void:
	_run_battle(encounter)


func _run_battle(encounter: Dictionary) -> void:
	if _battle_running or Game.in_battle:
		return
	_battle_running = true
	Game.in_battle = true
	var anim: AnimationPlayer = get_node_or_null("Ui/AnimationPlayer")
	if anim != null:
		anim.play("transition_in")
		await get_tree().create_timer(1.5).timeout
	get_tree().paused = true
	var screen := BattleScreen.new()
	add_child(screen)
	screen.start(encounter)
	if anim != null:
		anim.play("transition_out")
	await screen.finished
	get_tree().paused = false
	Game.in_battle = false
	_battle_running = false
