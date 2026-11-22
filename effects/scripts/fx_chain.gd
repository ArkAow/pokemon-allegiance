extends AttackFx

@export var hop_time: float = 0.12
@export var width: float = 5.0

var _rng := RandomNumberGenerator.new()


func _begin() -> void:
	life = hop_time * ctx.targets.size() + 0.3


func _step(_dt: float) -> void:
	for i in range(ctx.targets.size()):
		if t >= hop_time * i:
			hit(ctx.targets[i])


func _draw() -> void:
	if ctx == null:
		return
	var col: Color = tint()
	var fade: float = clampf((life - t) / 0.25, 0.0, 1.0)
	var prev: Vector2 = ctx.origin
	_rng.seed = int(t * 30.0) + 7
	for i in range(ctx.targets.size()):
		if t < hop_time * i:
			break
		var u: BattleUnit = ctx.targets[i]
		var to: Vector2 = u.chest()
		var pts: PackedVector2Array = jagged(prev, to, 7, 14.0, _rng)
		draw_polyline(pts, Color(col, 0.4 * fade), width + 5.0)
		draw_polyline(pts, Color(col.lightened(0.5), fade), width)
		draw_polyline(pts, Color(1, 1, 1, fade), width * 0.4)
		draw_circle(to, 12.0 * fade, Color(col, 0.5 * fade))
		prev = to
