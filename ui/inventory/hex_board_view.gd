class_name HexBoardView
extends Control


signal pokemon_clicked(inst: PokemonInstance)
signal empty_cell_clicked(cell: Vector2i)

const HEX := 38.0
const PAD := 14.0

var hover_cell: Vector2i = Vector2i(-1, -1)
var selected_uid: int = -1


func _init() -> void:
	custom_minimum_size = board_size()
	mouse_filter = Control.MOUSE_FILTER_STOP


static func rows() -> int:
	return Balance.BOARD_ROWS - Balance.PLAYER_ROW_START


static func board_size() -> Vector2:
	var w: float = HexGrid.hex_width(HEX) * (Balance.BOARD_COLS + 0.5) + PAD * 2.0
	var h: float = HEX * (1.5 * (rows() - 1) + 2.0) + PAD * 2.0
	return Vector2(w, h)


func _center_of(board_cell: Vector2i) -> Vector2:
	var local := Vector2i(board_cell.x, board_cell.y - Balance.PLAYER_ROW_START)
	return Vector2(PAD + HexGrid.hex_width(HEX) * 0.5, PAD + HEX) + HexGrid.cell_to_pixel(local, HEX)


func _cell_at(pos: Vector2) -> Vector2i:
	var origin := Vector2(PAD + HexGrid.hex_width(HEX) * 0.5, PAD + HEX)
	var c: Vector2i = HexGrid.pixel_to_cell(pos - origin, HEX)
	if c.x < 0 or c.x >= Balance.BOARD_COLS or c.y < 0 or c.y >= rows():
		return Vector2i(-1, -1)
	return Vector2i(c.x, c.y + Balance.PLAYER_ROW_START)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for lr in range(rows()):
		for c in range(Balance.BOARD_COLS):
			var cell := Vector2i(c, lr + Balance.PLAYER_ROW_START)
			var center: Vector2 = _center_of(cell)
			var pts: PackedVector2Array = HexGrid.hex_points(center, HEX - 2.0)
			var inst: PokemonInstance = Game.pokemon_at(cell)
			var fill := Color(0.14, 0.2, 0.32)
			if inst != null:
				fill = GlobalData.get_type_color(str(inst.types()[0])).darkened(0.55)
			if cell == hover_cell:
				fill = fill.lightened(0.25)
			draw_colored_polygon(pts, fill)
			var outline: PackedVector2Array = pts.duplicate()
			outline.append(pts[0])
			var sel: bool = inst != null and inst.uid == selected_uid
			draw_polyline(outline, UiStyle.COL_GOLD if sel else Color(0.5, 0.6, 0.78), 3.5 if sel else 1.5)
			if inst != null:
				var tex: Texture2D = SpriteLibrary.get_portrait(inst.species_id)
				draw_texture_rect(tex, Rect2(center - Vector2(25, 28), Vector2(50, 50)), false)
				draw_string(font, center + Vector2(-18, 33), "Nv%d" % inst.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
				if inst.item_id != "":
					draw_circle(center + Vector2(20, -22), 5.0, Color(1, 0.85, 0.3))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c: Vector2i = _cell_at(event.position)
		if c != hover_cell:
			hover_cell = c
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		var clicked_cell: Vector2i = _cell_at(event.position)
		var inst: PokemonInstance = Game.pokemon_at(clicked_cell)
		if inst == null:
			if clicked_cell.x >= 0 and event.button_index == MOUSE_BUTTON_LEFT:
				empty_cell_clicked.emit(clicked_cell)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			pokemon_clicked.emit(inst)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Game.undeploy(inst)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
		hover_cell = Vector2i(-1, -1)
		queue_redraw()


func _get_drag_data(at: Vector2) -> Variant:
	var inst: PokemonInstance = Game.pokemon_at(_cell_at(at))
	if inst == null:
		return null
	set_drag_preview(TeamSlot.make_preview(inst))
	pokemon_clicked.emit(inst)
	return {"type": "pokemon", "uid": inst.uid, "from": "board"}


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or data.get("type", "") != "pokemon":
		return false
	var cell: Vector2i = _cell_at(at)
	hover_cell = cell
	queue_redraw()
	if cell.x < 0:
		return false
	var inst: PokemonInstance = Game.find_by_uid(int(data["uid"]))
	return inst != null and Game.can_deploy(inst, cell)


func _drop_data(at: Vector2, data: Variant) -> void:
	var inst: PokemonInstance = Game.find_by_uid(int(data["uid"]))
	if inst != null:
		Game.deploy(inst, _cell_at(at))
