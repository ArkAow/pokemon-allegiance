extends AttackFx

@export_enum("fire", "water", "poison", "ice") var style: String = "fire"
@export var particles: int = 46
@export var duration: float = 0.8

var _angle_half: float = 0.5


func _begin() -> void:
	life = duration
	_angle_half = deg_to_rad(float(ctx.param("angle", 50.0)) * 0.5)


func _step(_dt: float) -> void:
	if t >= 0.2:
		hit_all()


func _draw() -> void:
	if ctx == null:
		return
	var dir_angle: float = ctx.direction().angle()
	var reach: float = maxf(ctx.radius, 160.0)
	var env: float = sin(clampf(t / life, 0.0, 1.0) * PI)
	var col: Color = tint()
	for i in range(particles):
		var seed_f: float = float(i) * 12.9898
		var ph: float = fposmod(t * 2.4 + float(i) / float(particles), 1.0)
		var off: float = (fposmod(sin(seed_f) * 43758.5453, 1.0) - 0.5) * 2.0 * _angle_half
		var pos: Vector2 = ctx.origin + Vector2.from_angle(dir_angle + off * ph) * reach * ph
		var sz: float = lerpf(4.0, 15.0, ph)
		var c: Color = col
		if style == "fire":
			c = Color(1.0, lerpf(0.9, 0.15, ph), 0.1)
		elif style == "ice":
			c = Color(0.7, 0.95, 1.0)
		draw_circle(pos, sz, Color(c, (1.0 - ph) * env * 0.85))
