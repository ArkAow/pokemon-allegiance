extends AttackFx

@export var ghosts: int = 6


func _begin() -> void:
	life = 0.45


func _step(_dt: float) -> void:
	if t >= 0.1:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var fade: float = clampf(1.0 - t / life, 0.0, 1.0)
	for i in range(ghosts):
		var k: float = float(i) / float(ghosts)
		var p: Vector2 = ctx.origin.lerp(ctx.dest, k)
		draw_circle(p, 15.0 * (0.4 + k * 0.6), Color(col, fade * 0.35 * (0.3 + k)))
	draw_line(ctx.origin, ctx.dest, Color(1, 1, 1, fade * 0.8), 4.0)
	var burst: float = clampf((t - 0.08) / 0.3, 0.0, 1.0)
	draw_arc(ctx.dest, 8.0 + 26.0 * burst, 0.0, TAU, 20, Color(col.lightened(0.4), (1.0 - burst) * fade), 3.0)
