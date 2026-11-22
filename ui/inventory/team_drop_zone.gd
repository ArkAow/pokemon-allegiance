class_name TeamDropZone
extends PanelContainer


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "pokemon" and data.get("from", "") == "board"


func _drop_data(_at: Vector2, data: Variant) -> void:
	var p: PokemonInstance = Game.find_by_uid(int(data["uid"]))
	if p != null:
		Game.undeploy(p)
