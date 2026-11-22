extends NpcState
class_name NpcWatch

var looking_direction: Vector2
var dialogue_balloon: TextureRect

func enter():
	print("watch")
	set_npc_variables()
	dialogue_balloon = npc.get_node("DialogueBalloon")
	if dialogue_balloon:
		dialogue_balloon.visible = true

func exit():
	if dialogue_balloon:
		dialogue_balloon.visible = false

func physics_update(_delta):
	var direction = player.global_position - npc.global_position
	if direction.length() > DETECTION_DISTANCE:
		transitioned.emit(self, "idle")
	process_looking_direction(direction)

func process_looking_direction(direction: Vector2):
	var look_direction: Vector2 = Vector2(0,0)
	var last_looked_direction: Vector2 = looking_direction
	
	if direction.x < -16:
		look_direction.x = -1
	elif direction.x > 16:
		look_direction.x = 1
	else:
		if last_looked_direction.y == 0:
			look_direction.x = last_looked_direction.x
		
	if direction.y < -16:
		look_direction.y = -1
	elif direction.y > 16:
		look_direction.y = 1
	else:
		if look_direction.x == 0:
			look_direction.y = last_looked_direction.y

	looking_direction = look_direction
	anim_tree.set("parameters/Idle/blend_position", looking_direction)
