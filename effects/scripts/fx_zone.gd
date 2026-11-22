extends AttackFx

@export_enum("poison", "fire", "ice", "mist") var style: String = "poison"
@export var bubbles: int = 22

var _tick: float = 1.0
var _next_tick: float = 0.0
var _rng := RandomNumberGenerator.new()
var _seeds: Array = []


func _begin() -> void:
	life = ctx.duration
	_tick = float(ctx.param("tick", 1.0))
	_rng.seed = hash(str(ctx.dest))
	for i in range(bubbles):
		_seeds.append({"a": _rng.randf() * TAU, "d": sqrt(_rng.randf()), "ph": _rng.randf(), "s": _rng.randf_range(4.0, 10.0)})


func _step(_dt: float) -> void:
	if t >= _next_tick:
		_next_tick += _tick
		var team_allies: bool = str(ctx.param("zone_team", "enemies")) == "allies"
		var list: Array = ctx.field.allies_of(ctx.caster, true) if team_allies else ctx.field.enemies_of(ctx.caster)
		for u in list:
			if u.position.distance_to(ctx.dest) <= ctx.radius:
				hit_repeat(u)


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var env: float = clampf(minf(t / 0.3, (life - t) / 0.4), 0.0, 1.0)
	draw_circle(ctx.dest, ctx.radius, Color(col, 0.16 * env))
	draw_arc(ctx.dest, ctx.radius, 0.0, TAU, 48, Color(col, 0.6 * env), 3.0)
	for s in _seeds:
		var ph: float = fposmod(t * 0.7 + float(s["ph"]), 1.0)
		var pos: Vector2 = ctx.dest + Vector2.from_angle(float(s["a"])) * ctx.radius * float(s["d"]) * 0.9
		pos.y -= ph * 28.0
		var a: float = sin(ph * PI) * env
		match style:
			"fire":
				draw_circle(pos, float(s["s"]) * (1.0 - ph * 0.5), Color(1.0, lerpf(0.8, 0.2, ph), 0.1, a))
			"ice":
				draw_line(pos - Vector2(4, 0), pos + Vector2(4, 0), Color(col.lightened(0.5), a), 2.0)
				draw_line(pos - Vector2(0, 4), pos + Vector2(0, 4), Color(col.lightened(0.5), a), 2.0)
			_:
				draw_arc(pos, float(s["s"]) * (0.5 + ph), 0.0, TAU, 12, Color(col.lightened(0.2), a), 2.0)
