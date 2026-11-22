extends AttackFx

@export var segments: int = 16
@export var base_width: float = 8.0
@export var tip_width: float = 3.0
@export var wave_amount: float = 34.0
@export var leaf_tip: bool = true

const WINDUP := 0.16
const STRIKE := 0.14
const HOLD := 0.08
const RETRACT := 0.16


func _begin() -> void:
	life = WINDUP + STRIKE + HOLD + RETRACT


func _reach() -> float:
	if t < WINDUP:
		return -0.12 * (t / WINDUP)
	if t < WINDUP + STRIKE:
		var k: float = (t - WINDUP) / STRIKE
		return -0.12 + 1.12 * ease_out(k)
	if t < WINDUP + STRIKE + HOLD:
		return 1.0
	var r: float = (t - WINDUP - STRIKE - HOLD) / RETRACT
	return 1.0 - clampf(r, 0.0, 1.0)


func _step(_dt: float) -> void:
	if t >= WINDUP + STRIKE * 0.85:
		hit_all()


func _points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dist: float = ctx.origin.distance_to(ctx.dest)
	var dir: Vector2 = ctx.direction()
	var perp := Vector2(-dir.y, dir.x)
	var reach: float = _reach()
	var strike_k: float = clampf((t - WINDUP) / (STRIKE + HOLD), 0.0, 1.0)
	var amp: float = wave_amount * (1.0 - strike_k * 0.85)
	if t < WINDUP:
		amp = wave_amount * 1.2
	for i in range(segments + 1):
		var s: float = float(i) / float(segments)
		var along: float = dist * reach * s
		var wave: float = sin(s * PI * 2.5 - t * 22.0) * amp * sin(s * PI)
		pts.append(ctx.origin + dir * along + perp * wave)
	return pts


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var pts: PackedVector2Array = _points()
	for i in range(pts.size() - 1):
		var s: float = float(i) / float(pts.size() - 1)
		var w: float = lerpf(base_width, tip_width, s)
		draw_line(pts[i], pts[i + 1], col.darkened(0.55), w + 3.0)
	for i in range(pts.size() - 1):
		var s2: float = float(i) / float(pts.size() - 1)
		var w2: float = lerpf(base_width, tip_width, s2)
		draw_line(pts[i], pts[i + 1], col.lightened(0.1 * s2), w2)
		draw_circle(pts[i], w2 * 0.5, col)
	if leaf_tip:
		var tip: Vector2 = pts[pts.size() - 1]
		var dir: Vector2 = (tip - pts[pts.size() - 2]).normalized()
		var perp := Vector2(-dir.y, dir.x)
		var leaf := PackedVector2Array([tip + dir * 12.0, tip + perp * 8.0, tip - dir * 4.0, tip - perp * 8.0])
		draw_colored_polygon(leaf, col.lightened(0.25))
