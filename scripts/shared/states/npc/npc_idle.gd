extends NpcState
class_name NpcIdle

var looking_direction: Vector2
var idle_time: float

func enter():
	print("idle")
	set_npc_variables()
	randomize_looking_direction()

func update(delta: float):
	if idle_time > 0:
		idle_time -= delta
	else:
		randomize_looking_direction()

func physics_update(_delta):
	var direction = player.global_position - npc.global_position
	if direction.length() < DETECTION_DISTANCE: #if a player come close, look at him
		transitioned.emit(self, "watch")

func randomize_looking_direction():
	if npc and anim_tree:
		looking_direction = Vector2(roundf(randf_range(-1,1)), roundf(randf_range(-1,1)))
		anim_tree.set("parameters/Idle/blend_position", looking_direction)
	idle_time = randf_range(2, 3)
