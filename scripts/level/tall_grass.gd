extends StaticBody2D
class_name TallGrass

@onready var sprite: Sprite2D = $Sprite

const NORMAL_FRAME: int = 0
const STEPPED_ON_FRAME: int = 1
const CHANCE_TO_ENCOUNTER_POKEMON = 10

signal pokemon_encountered

func _ready():
	sprite.frame = NORMAL_FRAME

func _on_player_body_entered(body):
	if "Player" in body.name:
		sprite.frame = STEPPED_ON_FRAME
		try_encounter_pokemon()
		await get_tree().create_timer(0.3).timeout
		sprite.frame = NORMAL_FRAME

func try_encounter_pokemon():
	var chance = randi_range(1, 100)
	if chance <= CHANCE_TO_ENCOUNTER_POKEMON:
		encounter_pokemon()

func encounter_pokemon():
	pokemon_encountered.emit()
