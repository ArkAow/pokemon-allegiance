extends Level
class_name MapLevel


const T := 16
const TILESET_PATH := "res://assets/tileset/overworld_tileset.tres"
const TREE_SCENE := "res://assets/level/tree.tscn"
const GRASS_SCENE := "res://assets/level/tall_grass.tscn"
const NPC_SCENE := "res://assets/character/npc/tutorialNpc/tutorialNpc.tscn"
const PLAYER_SCENE := "res://player/player.tscn"
const UI_SCENE := "res://player/UI.tscn"
const FLOWER_TEX := "res://assets/tileset/nature/red_flower.png"
const NPC_SKINS := {
	"npc1": "res://assets/character/npc/tutorialNpc/tutorialNpc.png",
	"npc2": "res://assets/character/npc/tutorialNpc/npc-2.png",
}

const SRC_GRASS := 0
const SRC_WATER := 5
const TERRAIN_SAND := 0
const TERRAIN_PATH := 1

@export_file("*.txt") var map_path: String = ""

var cols: int = 0
var rows: int = 0
var meta: Dictionary = {}
var tilemap: TileMap
var overworld: Node2D
var tall_grasses: Node2D
var decor: Node2D
var _grid: Array[String] = []
var _legend: Dictionary = {}


func _ready() -> void:
	if _load_map():
		_build()
	else:
		printerr("MapLevel : carte introuvable ou vide : ", map_path)
	super._ready()


func _load_map() -> bool:
	if map_path == "" or not FileAccess.file_exists(map_path):
		return false
	var section: int = 0
	for raw in FileAccess.get_file_as_string(map_path).split("\n"):
		var line: String = raw.trim_suffix("\r")
		if line.strip_edges() == "---":
			section += 1
			continue
		match section:
			0:
				var l0: String = line.strip_edges()
				if l0 == "" or l0.begins_with("#") or not l0.contains("="):
					continue
				var kv: PackedStringArray = l0.split("=", true, 1)
				meta[kv[0].strip_edges()] = kv[1].strip_edges()
			1:
				_grid.append(line)
			2:
				_parse_legend(line.strip_edges())
	while not _grid.is_empty() and _grid[_grid.size() - 1].strip_edges() == "":
		_grid.pop_back()
	rows = _grid.size()
	for l in _grid:
		cols = maxi(cols, l.length())
	zone_id = str(meta.get("zone", zone_id))
	return rows > 0 and cols > 0


func _parse_legend(line: String) -> void:
	if line == "" or line.begins_with("#"):
		return
	var parts: PackedStringArray = line.split(" ", false)
	if parts.size() < 2:
		return
	var props: Dictionary = {"type": parts[1]}
	for i in range(2, parts.size()):
		if parts[i].contains("="):
			var kv: PackedStringArray = parts[i].split("=", true, 1)
			props[kv[0]] = kv[1].replace("_", " ") if kv[0] == "name" else kv[1]
	_legend[parts[0]] = props


func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= rows or x < 0 or x >= _grid[y].length():
		return "."
	return _grid[y][x]


func _ground_at(x: int, y: int) -> String:
	var c: String = _char_at(x, y)
	if _legend.has(c):
		match str(_legend[c].get("ground", "grass")):
			"path":
				return "="
			"sand":
				return ","
		return "."
	if c == "T" or c == "\"" or c == "f":
		return "."
	return c


func _build() -> void:
	map_size = Vector2i(cols * T, rows * T)
	tilemap = TileMap.new()
	tilemap.name = "OverworldTileMap"
	tilemap.tile_set = load(TILESET_PATH)
	add_child(tilemap)
	decor = Node2D.new()
	decor.name = "Decor"
	add_child(decor)
	overworld = Node2D.new()
	overworld.name = "OverworldObject"
	overworld.y_sort_enabled = true
	add_child(overworld)
	tall_grasses = Node2D.new()
	tall_grasses.name = "TallGrasses"
	overworld.add_child(tall_grasses)

	_paint_ground()
	_place_player()
	_place_objects()
	_add_walls()
	var ui: Node = (load(UI_SCENE) as PackedScene).instantiate()
	ui.name = "Ui"
	add_child(ui)


func _paint_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260419
	var sand: Array[Vector2i] = []
	var path: Array[Vector2i] = []
	var water: Dictionary = {}
	for y in range(rows):
		for x in range(cols):
			var c := Vector2i(x, y)
			tilemap.set_cell(0, c, SRC_GRASS, Vector2i(3, rng.randi_range(0, 3)))
			match _ground_at(x, y):
				",":
					sand.append(c)
				"=":
					path.append(c)
				"~":
					water[c] = true
	if not sand.is_empty():
		tilemap.set_cells_terrain_connect(0, sand, 0, TERRAIN_SAND)
	if not path.is_empty():
		tilemap.set_cells_terrain_connect(0, path, 0, TERRAIN_PATH)
	for c in water:
		var left: bool = water.has(c + Vector2i(-1, 0))
		var right: bool = water.has(c + Vector2i(1, 0))
		var up: bool = water.has(c + Vector2i(0, -1))
		var down: bool = water.has(c + Vector2i(0, 1))
		var ax: int = 0 if not left else (2 if not right else 1)
		var ay: int = 0 if not up else (2 if not down else 1)
		tilemap.set_cell(0, c, SRC_WATER, Vector2i(ax, ay))


func _feet_pos(cx: int, cy: int) -> Vector2:
	return Vector2(cx * T, cy * T - T)


func _place_player() -> void:
	for y in range(rows):
		for x in range(cols):
			var c: String = _char_at(x, y)
			if _legend.has(c) and str(_legend[c].get("type", "")) == "player":
				var player: Node2D = (load(PLAYER_SCENE) as PackedScene).instantiate()
				player.position = _feet_pos(x, y)
				overworld.add_child(player)
				_add_marker("Start", _feet_pos(x, y))
				return
	printerr("MapLevel : aucun joueur (P type player) dans ", map_path)


func _add_marker(marker_name: String, pos: Vector2) -> void:
	var m := Marker2D.new()
	m.name = marker_name
	m.position = pos
	add_child(m)


func _place_objects() -> void:
	var grass_scene: PackedScene = load(GRASS_SCENE)
	var tree_scene: PackedScene = load(TREE_SCENE)
	var flower_tex: Texture2D = load(FLOWER_TEX)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for y in range(rows):
		for x in range(cols):
			var c: String = _char_at(x, y)
			match c:
				"T":
					var tree: Node2D = tree_scene.instantiate()
					tree.position = Vector2(x * T, y * T)
					overworld.add_child(tree)
				"\"":
					var g: TallGrass = grass_scene.instantiate()
					g.position = Vector2(x * T, y * T - T)
					tall_grasses.add_child(g)
					g.pokemon_encountered.connect(_on_tall_grass_encounter)
				"f":
					var f := Sprite2D.new()
					f.texture = flower_tex
					f.hframes = 5
					f.frame = rng.randi_range(0, 4)
					f.centered = false
					f.position = Vector2(x * T, y * T)
					decor.add_child(f)
				_:
					if _legend.has(c):
						_place_legend_object(x, y, _legend[c])


func _place_legend_object(x: int, y: int, props: Dictionary) -> void:
	match str(props.get("type", "")):
		"spawn":
			_add_marker(str(props.get("name", "Spawn")), _feet_pos(x, y))
		"npc":
			var npc: Npc = (load(NPC_SCENE) as PackedScene).instantiate()
			npc.position = _feet_pos(x, y)
			npc.dialogue_start = str(props.get("dialogue", "start"))
			if props.has("path"):
				npc.dialogue_path = str(props["path"])
			var skin: String = str(NPC_SKINS.get(str(props.get("skin", "npc1")), NPC_SKINS["npc1"]))
			npc.sprite_texture = load(skin)
			npc.name = str(props.get("name", "Npc_%d_%d" % [x, y])).replace(" ", "_")
			overworld.add_child(npc)
		"exit":
			var size_txt: PackedStringArray = str(props.get("size", "1x1")).split("x")
			var sz := Vector2(float(size_txt[0]) * T, float(size_txt[1]) * T)
			var ex := LevelExit.new()
			ex.target_scene = str(props.get("scene", ""))
			ex.target_spawn = str(props.get("spawn", ""))
			ex.position = Vector2(x * T, y * T)
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = sz
			shape.shape = rect
			shape.position = sz * 0.5
			ex.add_child(shape)
			add_child(ex)


func _add_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "MapBounds"
	add_child(body)
	var w: float = float(cols * T)
	var h: float = float(rows * T)
	for r in [Rect2(-32, -32, w + 64, 32), Rect2(-32, h, w + 64, 32), Rect2(-32, 0, 32, h), Rect2(w, 0, 32, h)]:
		var s := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		s.shape = rs
		s.position = r.position + r.size * 0.5
		body.add_child(s)
