extends AttackFx

@export_enum("orb", "flame", "leaf", "bolt", "water", "shadow", "crescent", "star") var style: String = "orb"
@export var speed: float = 620.0
@export var size: float = 10.0
@export var texture: Texture2D

var _arrived: bool = false
var _pos: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _arrive_t: float = 0.0


func _begin() -> void:
	life = 6.0
	_pos = ctx.origin
	_angle = ctx.direction().angle()


func _step(_dt: float) -> void:
	if _arrived:
		if t - _arrive_t > 0.18:
			end()
		return
	var total: float = ctx.origin.distance_to(ctx.dest)
	var k: float = clampf(speed * t / maxf(1.0, total), 0.0, 1.0)
	_pos = ctx.origin.lerp(ctx.dest, k)
	if k >= 1.0:
		_arrived = true
		_arrive_t = t
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var a: float = 1.0
	if _arrived:
		a = clampf(1.0 - (t - _arrive_t) / 0.18, 0.0, 1.0)
	draw_set_transform(_pos, _angle, Vector2.ONE)
	if texture != null:
		draw_texture(texture, -texture.get_size() * 0.5, Color(1, 1, 1, a))
	else:
		_draw_style(col, a)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_style(col: Color, a: float) -> void:
	var s: float = size * (1.0 + (0.8 * (1.0 - a) if _arrived else 0.0))
	var flick: float = 1.0 + 0.15 * sin(t * 40.0)
	match style:
		"flame":
			var pts := PackedVector2Array([
				Vector2(s * 0.9, 0), Vector2(0, -s * 0.7 * flick), Vector2(-s * 1.4, -s * 0.3),
				Vector2(-s * 2.4 * flick, 0), Vector2(-s * 1.4, s * 0.3), Vector2(0, s * 0.7 * flick)])
			draw_colored_polygon(pts, Color(col, a * 0.9))
			var inner := PackedVector2Array([Vector2(s * 0.5, 0), Vector2(0, -s * 0.35), Vector2(-s * 1.0, 0), Vector2(0, s * 0.35)])
			draw_colored_polygon(inner, Color(1, 0.95, 0.5, a))
		"leaf":
			var pts2 := PackedVector2Array([Vector2(s * 1.3, 0), Vector2(0, -s * 0.6), Vector2(-s * 1.2, 0), Vector2(0, s * 0.6)])
			draw_colored_polygon(pts2, Color(col, a))
			draw_line(Vector2(-s * 1.2, 0), Vector2(s * 1.2, 0), Color(0.1, 0.35, 0.1, a), 1.5)
		"bolt":
			var pts3 := PackedVector2Array([Vector2(s, -s * 0.4), Vector2(-s * 0.2, -s * 0.1), Vector2(s * 0.3, s * 0.1), Vector2(-s, s * 0.5), Vector2(-s * 0.1, s * 0.05), Vector2(-s * 0.5, -s * 0.1)])
			draw_colored_polygon(pts3, Color(col, a))
		"water":
			draw_circle(Vector2(-s * 0.8, 0), s * 0.5, Color(col, a * 0.4))
			draw_circle(Vector2.ZERO, s * 0.8, Color(col, a * 0.85))
			draw_circle(Vector2(s * 0.2, -s * 0.25), s * 0.25, Color(1, 1, 1, a * 0.8))
		"shadow":
			draw_circle(Vector2.ZERO, s * 1.5, Color(col, a * 0.25))
			draw_circle(Vector2.ZERO, s * 1.1, Color(col.darkened(0.3), a))
			draw_arc(Vector2.ZERO, s * 1.3, t * 6.0, t * 6.0 + 4.0, 16, Color(0.9, 0.7, 1.0, a), 2.0)
		"crescent":
			draw_arc(Vector2.ZERO, s * 1.4, -1.0, 1.0, 14, Color(col, a), 4.0)
			draw_arc(Vector2(-s * 0.4, 0), s * 1.2, -0.9, 0.9, 12, Color(1, 1, 1, a * 0.7), 2.0)
		"star":
			for i in range(5):
				var ang: float = TAU * i / 5.0 + t * 8.0
				draw_line(Vector2.ZERO, Vector2(cos(ang), sin(ang)) * s * 1.3, Color(col, a), 3.0)
			draw_circle(Vector2.ZERO, s * 0.5, Color(1, 1, 1, a))
		_:
			draw_circle(Vector2.ZERO, s * 1.5, Color(col, a * 0.25))
			draw_circle(Vector2.ZERO, s, Color(col, a))
			draw_circle(Vector2.ZERO, s * 0.5, Color(1, 1, 1, a * 0.9))
