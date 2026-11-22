extends AttackFx

func _begin() -> void:
	life = 0.7


func _step(_dt: float) -> void:
	if t >= 0.15:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var k: float = clampf(t / life, 0.0, 1.0)
	var out_k: float = clampf(k * 2.0, 0.0, 1.0)
	var in_k: float = clampf(k * 2.0 - 0.6, 0.0, 1.0)
	draw_rect(Rect2(ctx.origin.x - 22.0 * (1.0 - out_k), ctx.origin.y - 80.0 * out_k, 44.0 * (1.0 - out_k), 80.0 * out_k), Color(col, 0.6 * (1.0 - out_k)))
	draw_arc(ctx.origin, 40.0 * out_k, 0.0, TAU, 24, Color(col.lightened(0.4), 1.0 - out_k), 3.0)
	draw_arc(ctx.dest, 40.0 * (1.0 - in_k) + 4.0, 0.0, TAU, 24, Color(col.lightened(0.4), in_k), 3.0)
	for i in range(8):
		var ang: float = TAU * i / 8.0 + t * 4.0
		draw_circle(ctx.dest + Vector2.from_angle(ang) * 40.0 * (1.0 - in_k), 3.0, Color(col, in_k))
