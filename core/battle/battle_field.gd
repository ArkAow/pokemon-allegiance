class_name BattleField
extends Node2D

signal battle_finished(victory: bool)

const HEX_SIZE := 44.0

var hex_w: float = HexGrid.SQRT3 * HEX_SIZE
var board_origin: Vector2 = Vector2.ZERO
var arena_rect: Rect2 = Rect2()
var units: Array[BattleUnit] = []
var units_root: Node2D
var running: bool = false
var finished: bool = false
var elapsed: float = 0.0
var speed: float = 1.0
var ally_synergies: Array = []
var enemy_synergies: Array = []
var wild: bool = false
var trainer: TrainerCaster = null
var captured: Array = []


func _ready() -> void:
	units_root = Node2D.new()
	units_root.y_sort_enabled = true
	add_child(units_root)
	y_sort_enabled = true


func layout(viewport_size: Vector2) -> void:
	var board_w: float = hex_w * (Balance.BOARD_COLS + 0.5)
	var board_h: float = HEX_SIZE * (1.5 * (Balance.BOARD_ROWS - 1) + 2.0)
	var top_left := Vector2((viewport_size.x - board_w) * 0.5, (viewport_size.y - board_h) * 0.5)
	board_origin = top_left + Vector2(hex_w * 0.5, HEX_SIZE)
	arena_rect = Rect2(top_left + Vector2(hex_w * 0.4, HEX_SIZE * 0.5), Vector2(board_w - hex_w * 0.8, board_h - HEX_SIZE))
	queue_redraw()


func cell_to_world(cell: Vector2i) -> Vector2:
	return board_origin + HexGrid.cell_to_pixel(cell, HEX_SIZE)


func setup(allies: Array, enemy_defs: Array) -> void:
	var ally_ids: Array = []
	for p in allies:
		ally_ids.append(p.species_id)
	ally_synergies = SynergyCalc.compute(ally_ids)

	var enemies: Array = []
	var enemy_ids: Array = []
	for d in enemy_defs:
		var inst: PokemonInstance = PokemonInstance.create(str(d["species"]), int(d["level"]), 15)
		var c: Array = d.get("cell", [3, 1])
		inst.cell = Vector2i(int(c[0]), int(c[1]))
		enemies.append(inst)
		enemy_ids.append(inst.species_id)
	enemy_synergies = SynergyCalc.compute(enemy_ids)

	for p in allies:
		_spawn(p, 0, ally_synergies)
	for e in enemies:
		_spawn(e, 1, enemy_synergies)

	var total_level: float = 0.0
	for p in allies:
		total_level += float(p.level)
	trainer = TrainerCaster.new()
	add_child(trainer)
	trainer.setup_trainer(self, total_level / maxf(1.0, float(allies.size())))


func _spawn(inst: PokemonInstance, team: int, synergies: Array) -> void:
	var u := BattleUnit.new()
	units_root.add_child(u)
	u.setup(self, team, inst, SynergyCalc.mods_for(synergies, inst.types()))
	u.position = cell_to_world(inst.cell)
	units.append(u)


func capture_unit(u: BattleUnit) -> void:
	captured.append({"species": u.instance.species_id, "level": u.instance.level})
	fx_text(u.position + Vector2(0, u.bar_y), "Capturé !", Color(1, 0.95, 0.4), 22)
	u.vanish_captured()


func start_fight() -> void:
	running = true


func _process(delta: float) -> void:
	if not running or finished:
		return
	elapsed += delta * speed
	var a: int = alive_units(0).size()
	var e: int = alive_units(1).size()
	if a == 0 or e == 0:
		_finish(a > 0)
	elif elapsed >= Balance.BATTLE_TIME_LIMIT:
		_finish(_hp_ratio(0) > _hp_ratio(1))


func _hp_ratio(team: int) -> float:
	var cur: float = 0.0
	var mx: float = 0.0
	for u in units:
		if u.team == team:
			cur += maxf(0.0, u.hp)
			mx += u.max_hp
	return cur / maxf(1.0, mx)


func _finish(victory: bool) -> void:
	finished = true
	running = false
	battle_finished.emit(victory)


func _draw() -> void:
	for r in range(Balance.BOARD_ROWS):
		for c in range(Balance.BOARD_COLS):
			var center: Vector2 = cell_to_world(Vector2i(c, r))
			var pts: PackedVector2Array = HexGrid.hex_points(center, HEX_SIZE - 2.0)
			var ally_side: bool = r >= Balance.PLAYER_ROW_START
			var fill: Color = Color(0.2, 0.45, 0.7, 0.16) if ally_side else Color(0.7, 0.25, 0.25, 0.16)
			draw_colored_polygon(pts, fill)
			var outline: PackedVector2Array = pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color(1, 1, 1, 0.18), 1.5)


func alive_units(team: int = -1) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for u in units:
		if not u.dead and (team < 0 or u.team == team):
			out.append(u)
	return out


func enemies_of(u: BattleUnit) -> Array[BattleUnit]:
	return alive_units(1 - u.team)


func allies_of(u: BattleUnit, include_self: bool = true) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for a in alive_units(u.team):
		if include_self or a != u:
			out.append(a)
	return out


func find_target(u: BattleUnit) -> BattleUnit:
	var best: BattleUnit = null
	var best_d: float = INF
	for e in enemies_of(u):
		if not e.is_targetable():
			continue
		var d: float = u.position.distance_squared_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


func nearest_enemies(u: BattleUnit, n: int) -> Array:
	var list: Array[BattleUnit] = enemies_of(u)
	list.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		return u.position.distance_squared_to(a.position) < u.position.distance_squared_to(b.position))
	return list.slice(0, n)


func enemies_in_radius(u: BattleUnit, center: Vector2, radius_px: float) -> Array[BattleUnit]:
	var out: Array[BattleUnit] = []
	for e in enemies_of(u):
		if e.position.distance_to(center) <= radius_px:
			out.append(e)
	return out


func nearest_enemy_to(u: BattleUnit, pos: Vector2, exclude: Array, max_dist: float) -> BattleUnit:
	var best: BattleUnit = null
	var best_d: float = max_dist
	for e in enemies_of(u):
		if exclude.has(e):
			continue
		var d: float = pos.distance_to(e.position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func cells_to_px(cells: float) -> float:
	return cells * hex_w


func clamp_to_arena(p: Vector2) -> Vector2:
	return p.clamp(arena_rect.position, arena_rect.end)


func fx_ring(pos: Vector2, radius_px: float, col: Color, duration: float = 0.45) -> void:
	BattleFx.ring(self, pos, radius_px, col, duration)


func fx_line(a: Vector2, b: Vector2, col: Color, w: float = 4.0, duration: float = 0.3) -> void:
	BattleFx.line(self, a, b, col, w, duration)


func fx_text(pos: Vector2, txt: String, col: Color, font_size: int = 16) -> void:
	BattleFx.text(self, pos, txt, col, font_size)
