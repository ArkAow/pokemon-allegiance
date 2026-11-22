extends AttackFx

@export_enum("buff", "heal", "shield", "debuff", "sleep", "wind") var style: String = "buff"
@export var rise_height: float = 60.0


func _begin() -> void:
	life = 0.95


func _step(_dt: float) -> void:
	if t >= 0.15:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var k: float = clampf(t / life, 0.0, 1.0)
	var fade: float = sin(k * PI)
	for u in ctx.targets:
		if u.dead:
			continue
		var base: Vector2 = u.position
		var h: float = -u.body_height() * 0.5
		match style:
			"shield":
				draw_circle(base + Vector2(0, h), 38.0 * ease_out(k * 2.0), Color(col, 0.18 * fade))
				draw_arc(base + Vector2(0, h), 38.0 * ease_out(k * 2.0), 0.0, TAU, 32, Color(col.lightened(0.4), fade), 3.0)
			"sleep":
				for i in range(3):
					var p: float = fposmod(k * 1.4 + i * 0.33, 1.0)
					draw_string(ThemeDB.fallback_font, base + Vector2(10 + i * 8, h - 10 - p * 40.0), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 + i * 4), Color(col.lightened(0.4), (1.0 - p) * fade))
			"wind":
				for i in range(3):
					var a0: float = t * 8.0 + i * 2.1
					draw_arc(base + Vector2(0, h), 24.0 + i * 8.0, a0, a0 + 1.8, 14, Color(col, fade * 0.8), 2.5)
			_:
				for i in range(8):
					var ph: float = fposmod(k * 1.3 + i * 0.125, 1.0)
					var px: float = base.x + sin(i * 2.4) * 22.0
					var py: float = base.y + h + 25.0 - ph * rise_height
					var a: float = (1.0 - ph) * fade
					match style:
						"heal":
							draw_line(Vector2(px - 4, py), Vector2(px + 4, py), Color(col, a), 3.0)
							draw_line(Vector2(px, py - 4), Vector2(px, py + 4), Color(col, a), 3.0)
						"debuff":
							var dy: float = base.y + h - 25.0 + ph * rise_height
							draw_colored_polygon(PackedVector2Array([Vector2(px - 5, dy - 3), Vector2(px + 5, dy - 3), Vector2(px, dy + 6)]), Color(col, a))
						_:
							draw_colored_polygon(PackedVector2Array([Vector2(px - 5, py + 3), Vector2(px + 5, py + 3), Vector2(px, py - 6)]), Color(col, a))
		if style == "buff" or style == "heal":
			draw_circle(base + Vector2(0, h), 30.0 * fade, Color(col, 0.15 * fade))
