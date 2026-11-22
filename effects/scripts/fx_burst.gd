extends AttackFx

@export_enum("ring", "fire", "water", "earth", "poison", "psychic", "electric", "heal", "smoke") var style: String = "ring"
@export var default_radius: float = 80.0
@export var particle_count: int = 26

var _radius: float = 80.0
var _parts: Array = []
var _reach_time: float = 0.45


func _begin() -> void:
	_radius = ctx.radius if ctx.radius > 1.0 else default_radius
	life = 0.75
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(ctx.dest))
	for i in range(particle_count):
		_parts.append({"ang": rng.randf() * TAU, "spd": rng.randf_range(0.5, 1.0), "size": rng.randf_range(3.0, 9.0), "rot": rng.randf() * TAU})


func _step(_dt: float) -> void:
	var cur: float = _radius * ease_out(t / _reach_time)
	for u in ctx.targets:
		if ctx.dest.distance_to(u.position) <= cur + 6.0:
			hit(u)
	if t >= _reach_time:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var k: float = clampf(t / _reach_time, 0.0, 1.0)
	var r: float = _radius * ease_out(k)
	var fade: float = clampf(1.0 - (t - _reach_time * 0.5) / (life - _reach_time * 0.5), 0.0, 1.0)
	var c: Vector2 = ctx.dest
	draw_circle(c, r, Color(col, 0.22 * fade))
	draw_arc(c, maxf(1.0, r), 0.0, TAU, 48, Color(col.lightened(0.3), fade), 4.0)
	for p in _parts:
		var d: float = r * float(p["spd"])
		var pos: Vector2 = c + Vector2(cos(float(p["ang"])), sin(float(p["ang"]))) * d
		var sz: float = float(p["size"]) * (1.0 - 0.5 * k)
		match style:
			"fire":
				draw_circle(pos + Vector2(0, -k * 20.0), sz * 1.2, Color(1.0, lerpf(0.8, 0.2, k), 0.1, fade))
			"water":
				draw_circle(pos, sz, Color(col, fade * 0.8))
				draw_circle(pos + Vector2(-1, -1), sz * 0.35, Color(1, 1, 1, fade))
			"earth":
				var rot: float = float(p["rot"]) + k * 3.0
				var rock := PackedVector2Array([pos + Vector2(cos(rot), sin(rot)) * sz, pos + Vector2(cos(rot + 2.1), sin(rot + 2.1)) * sz, pos + Vector2(cos(rot + 4.2), sin(rot + 4.2)) * sz])
				draw_colored_polygon(rock, Color(col.darkened(0.2), fade))
			"poison":
				draw_arc(pos + Vector2(0, -k * 25.0), sz, 0.0, TAU, 10, Color(col, fade), 2.0)
			"psychic":
				draw_arc(c, r * float(p["spd"]), float(p["ang"]), float(p["ang"]) + 0.6, 8, Color(col.lightened(0.3), fade), 2.0)
			"heal":
				var hy: float = pos.y - k * 30.0
				draw_line(Vector2(pos.x - 4, hy), Vector2(pos.x + 4, hy), Color(col.lightened(0.3), fade), 3.0)
				draw_line(Vector2(pos.x, hy - 4), Vector2(pos.x, hy + 4), Color(col.lightened(0.3), fade), 3.0)
			"smoke":
				draw_circle(pos + Vector2(0, -k * 12.0), sz * 2.2, Color(col, fade * 0.35))
			"electric":
				var rng := RandomNumberGenerator.new()
				rng.seed = int(float(p["ang"]) * 1000.0) + int(t * 25.0)
				draw_polyline(jagged(c, pos, 5, 8.0, rng), Color(1, 1, 0.6, fade), 2.0)
			_:
				draw_circle(pos, sz * 0.6, Color(col, fade * 0.8))
