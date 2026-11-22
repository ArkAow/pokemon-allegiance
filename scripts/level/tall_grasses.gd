extends Node2D

var tall_grasses: Dictionary = {}

signal player_encountered_pokemon

func _ready():
	for child in get_children():
		if child is TallGrass:
			child.pokemon_encountered.connect(on_child_pokemon_encountered)

func on_child_pokemon_encountered():
	player_encountered_pokemon.emit()
