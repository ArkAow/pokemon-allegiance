@icon("res://assets/icon/player-icon.png")
extends CharacterBody2D
class_name Player

signal start_battle

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var action_finder = $Direction/ActionableFinder

const WALK_SPEED: float = 100.0
const ACCELERATION: float = 1000.0
const FRICTION: float = 1000.0

var initial_position: Vector2 = Vector2(0, 0)
var input_direction: Vector2 = Vector2(0, 0)
var nearest_actionable: Area2D
var can_move: bool = true

signal nearest_actionable_changed(nearest_actionable: Actionable)

func _ready():
	initial_position = position
	
func _physics_process(delta):	
	input_direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	can_move = not Game.is_input_blocked() and not get_tree().paused
	check_nearest_actionable()
	player_animation()
	player_movement(input_direction, delta)
	move_and_slide()

func player_animation():
	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Run/blend_position", input_direction)

	if velocity == Vector2.ZERO:
		anim_state.travel("Idle")
	else:
		anim_state.travel("Run")

func player_movement(input, delta):
	if can_move:
		if input: velocity = velocity.move_toward(input * WALK_SPEED , delta * ACCELERATION)
		else: velocity = velocity.move_toward(Vector2(0,0), delta * FRICTION)
	else:
		velocity = Vector2.ZERO

func _unhandled_input(_event):
	if Game.is_input_blocked():
		return
	if Input.is_action_just_pressed("interact"):
		if is_instance_valid(nearest_actionable):
			nearest_actionable.actioned.emit()
		return
		
func check_nearest_actionable():
	var areas: Array[Area2D] = action_finder.get_overlapping_areas()
	var shortest_distance: float = INF
	var next_nearest_actionable: Actionable = null
	for area in areas:
		var distance: float = area.global_position.distance_to(global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			next_nearest_actionable = area
	if next_nearest_actionable != nearest_actionable:
		nearest_actionable = next_nearest_actionable
		nearest_actionable_changed.emit(nearest_actionable)

func _on_player_encountered_pokemon():
	if Game.is_input_blocked() or Game.deployed().is_empty():
		return
	start_battle.emit()


func _on_battle_finished():
	pass
