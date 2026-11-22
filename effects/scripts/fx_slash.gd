extends AttackFx

@export_enum("slash", "bite", "punch") var style: String = "slash"


func _begin() -> void:
	life = 0.5


func _step(_dt: float) -> void:
	if t >= 0.12:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var c: Vector2 = ctx.dest
	var k: float = clampf(t / life, 0.0, 1.0)
	var fade: float = 1.0 - k
	match style:
		"bite":
			var open: float = (1.0 - ease_out(clampf(t / 0.14, 0.0, 1.0))) * 22.0
			var w: float = 22.0
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for i in range(5):
				var x: float = -w + i * w * 0.5
				up.append(c + Vector2(x, -open - 4))
				up.append(c + Vector2(x + w * 0.25, -open + 12))
				dn.append(c + Vector2(x, open + 4))
				dn.append(c + Vector2(x + w * 0.25, open - 12))
			draw_polyline(up, Color(1, 1, 1, fade), 3.0)
			draw_polyline(dn, Color(1, 1, 1, fade), 3.0)
			draw_circle(c, 18.0 * ease_out(k), Color(col, 0.35 * fade))
		"punch":
			for i in range(8):
				var ang: float = TAU * i / 8.0
				var inner: float = 8.0 + 10.0 * ease_out(k)
				draw_line(c + Vector2.from_angle(ang) * inner, c + Vector2.from_angle(ang) * (inner + 14.0), Color(col.lightened(0.3), fade), 4.0)
			draw_arc(c, 10.0 + 30.0 * ease_out(k), 0.0, TAU, 24, Color(1, 1, 1, fade), 3.0)
		_:
			for i in range(3):
				var off: float = (i - 1) * 9.0
				var prog: float = ease_out(clampf((t - i * 0.03) / 0.15, 0.0, 1.0))
				var a: Vector2 = c + Vector2(-20 + off, -26)
				var b: Vector2 = a + Vector2(34, 52) * prog
				draw_line(a, b, Color(col.lightened(0.4), fade), 4.0 - i * 0.6)
