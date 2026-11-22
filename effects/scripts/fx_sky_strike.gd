extends AttackFx

@export_enum("thunder", "fire", "light") var style: String = "thunder"
@export var fall_time: float = 0.3
@export var default_radius: float = 90.0

var _rng := RandomNumberGenerator.new()
var _radius: float = 90.0


func _begin() -> void:
	life = fall_time + 0.5
	_radius = ctx.radius if ctx.radius > 1.0 else default_radius


func _step(_dt: float) -> void:
	if t >= fall_time:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var c: Vector2 = ctx.dest
	if t < fall_time:
		var k: float = t / fall_time
		draw_circle(c, _radius * 0.5 * k, Color(col, 0.18))
		var top: Vector2 = c + Vector2(0, -420.0)
		var head: Vector2 = top.lerp(c, k)
		if style == "thunder":
			_rng.seed = int(t * 40.0)
			draw_polyline(jagged(c + Vector2(0, -420), c, 9, 22.0, _rng), Color(col, 0.35 * k), 8.0)
			draw_polyline(jagged(c + Vector2(0, -420), head, 9, 22.0, _rng), Color(1, 1, 0.8, k), 3.0)
		else:
			draw_circle(head, 16.0, Color(col, 0.35))
			draw_circle(head, 11.0, Color(col, 1.0))
			draw_circle(head, 5.0, Color(1, 1, 0.7, 1.0))
			draw_line(head, head + Vector2(0, -60) * k, Color(col, 0.6), 8.0)
		return
	var k2: float = clampf((t - fall_time) / 0.5, 0.0, 1.0)
	var fade: float = 1.0 - k2
	if style == "thunder":
		draw_rect(Rect2(c.x - 14, c.y - 420, 28, 420), Color(1, 1, 0.9, fade * 0.8))
	draw_circle(c, _radius * ease_out(k2), Color(col, 0.3 * fade))
	draw_arc(c, maxf(1.0, _radius * ease_out(k2)), 0.0, TAU, 40, Color(col.lightened(0.4), fade), 5.0)
	draw_circle(c, 26.0 * fade, Color(1, 1, 0.85, fade))
