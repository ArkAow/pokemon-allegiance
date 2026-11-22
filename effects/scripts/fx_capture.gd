extends AttackFx

const FLY := 0.45
const SHAKE := 0.5

var _success: bool = false
var _opened: bool = false


func _begin() -> void:
	_success = bool(ctx.vars.get("capture_success", false))
	life = FLY + SHAKE * 3.0 + 0.7


func _step(_dt: float) -> void:
	var u: BattleUnit = ctx.main_target
	if u == null:
		return
	if t >= FLY and not _opened and t < FLY + SHAKE * 3.0:
		u.visible = false
	if t >= FLY + SHAKE * 3.0 and not _opened:
		_opened = true
		if not _success:
			u.visible = true
		hit(u)


func _draw() -> void:
	if ctx == null or ctx.main_target == null:
		return
	var col: Color = tint()
	var u: BattleUnit = ctx.main_target
	var ground: Vector2 = u.position + Vector2(0, -6)
	var pos: Vector2 = ground
	var rot: float = 0.0
	var alpha: float = 1.0
	if t < FLY:
		var k: float = t / FLY
		pos = ctx.origin.lerp(ctx.dest, k) + Vector2(0, -sin(k * PI) * 70.0)
		rot = k * 12.0
	elif not _opened:
		var st: float = fposmod(t - FLY, SHAKE) / SHAKE
		rot = sin(st * TAU) * 0.45 * (1.0 if st < 0.7 else 0.0)
		pos = ground
	else:
		var after: float = t - (FLY + SHAKE * 3.0)
		pos = ground
		if _success:
			alpha = clampf(1.0 - maxf(0.0, after - 0.35) / 0.35, 0.0, 1.0)
			for i in range(8):
				var a: float = TAU * i / 8.0 + after * 2.0
				var d: float = 14.0 + after * 70.0
				draw_circle(ground + Vector2.from_angle(a) * d, 3.0 * (1.0 - after), Color(1, 0.95, 0.5, 1.0 - after))
		else:
			alpha = clampf(1.0 - after / 0.25, 0.0, 1.0)
			draw_arc(ground, 10.0 + after * 80.0, 0.0, TAU, 20, Color(1, 1, 1, 1.0 - after), 3.0)
	draw_set_transform(pos, rot, Vector2.ONE)
	draw_circle(Vector2.ZERO, 11.0, Color(0.95, 0.95, 0.95, alpha))
	draw_colored_polygon(_half_circle(11.0), Color(col, alpha))
	draw_line(Vector2(-11, 0), Vector2(11, 0), Color(0.1, 0.1, 0.1, alpha), 2.5)
	draw_circle(Vector2.ZERO, 4.0, Color(0.1, 0.1, 0.1, alpha))
	draw_circle(Vector2.ZERO, 2.5, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _half_circle(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(13):
		var a: float = PI + PI * i / 12.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
