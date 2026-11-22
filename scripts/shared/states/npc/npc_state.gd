extends State
class_name NpcState

@export var npc: CharacterBody2D
var player: CharacterBody2D
var anim_tree: AnimationTree
const DETECTION_DISTANCE: float = 100.0

func set_npc_variables():
	anim_tree = npc.get_node("AnimationTree")
	player = get_tree().get_first_node_in_group("player")
