extends AttackFx

@export var charge_time: float = 0.3
@export var fire_time: float = 0.35


func _begin() -> void:
	life = charge_time + fire_time + 0.05


func _step(_dt: float) -> void:
	if t >= charge_time:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var w: float = maxf(ctx.width, 30.0)
	if t < charge_time:
		var k: float = t / charge_time
		draw_circle(ctx.origin, 6.0 + k * w * 0.5, Color(col, 0.35 + 0.4 * k))
		draw_circle(ctx.origin, 3.0 + k * w * 0.25, Color(1, 1, 1, 0.9))
		return
	var k2: float = (t - charge_time) / fire_time
	var env: float = sin(clampf(k2, 0.0, 1.0) * PI)       # 0 -> 1 -> 0
	var dir: Vector2 = ctx.direction()
	var perp := Vector2(-dir.y, dir.x)
	var half: float = w * 0.5 * (0.4 + 0.6 * env)
	var a: Vector2 = ctx.origin
	var b: Vector2 = ctx.dest
	draw_colored_polygon(PackedVector2Array([a + perp * half, b + perp * half, b - perp * half, a - perp * half]), Color(col, 0.35 * env + 0.1))
	var core: float = half * 0.45
	draw_colored_polygon(PackedVector2Array([a + perp * core, b + perp * core, b - perp * core, a - perp * core]), Color(col.lightened(0.4), 0.85 * env))
	draw_line(a, b, Color(1, 1, 1, env), maxf(2.0, core * 0.6))
	draw_circle(a, half * 0.9, Color(col, 0.6 * env))
