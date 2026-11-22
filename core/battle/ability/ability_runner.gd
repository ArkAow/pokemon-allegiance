class_name AbilityRunner
extends RefCounted
## Exécute une capacité décrite dans data/abilities.json :
##   pour chaque "step" -> choisit les cibles selon le Pattern, instancie la scène d'effet (fx),
##   et applique les Effets au moment où la scène déclenche l'impact (AttackFx.hit).
## Tu n'as normalement JAMAIS à modifier ce fichier : tu ajoutes des capacités en JSON et des fx en scènes.
## (Pour une capacité 100% sur mesure : "script": "res://chemin.gd" dans le JSON, avec `static func cast(caster, field, def)`.)


static func run(ability_id: String, caster: BattleUnit, field: BattleField) -> void:
	run_def(GlobalData.get_ability(ability_id), caster, field)


## Exécute une définition {steps:[...]} (capacité de Pokémon OU sort du dresseur).
## Pour un sort du dresseur, on renseigne avant : caster.target / caster.aim_point / caster.aim_target2.
static func run_def(def: Dictionary, caster: BattleUnit, field: BattleField) -> void:
	if def.has("script") and ResourceLoader.exists(str(def["script"])):
		var custom: GDScript = load(str(def["script"]))
		custom.call("cast", caster, field, def)
		return
	var steps: Array = def.get("steps", [])
	if steps.is_empty():
		printerr("Capacité sans steps")
		return
	for step in steps:
		var delay: float = float(step.get("delay", 0.0))
		if delay <= 0.0:
			_run_step(step, caster, field)
		else:
			var timer: SceneTreeTimer = field.get_tree().create_timer(delay / maxf(field.speed, 0.1))
			timer.timeout.connect(_run_step.bind(step, caster, field))


static func first_pattern(ability_id: String) -> String:
	var steps: Array = GlobalData.get_ability(ability_id).get("steps", [])
	if steps.is_empty():
		return "SINGLE_TARGET"
	return str(steps[0].get("pattern", "SINGLE_TARGET"))


static func _run_step(step: Dictionary, caster: BattleUnit, field: BattleField) -> void:
	if field.finished or field == null:
		return
	var pat: String = str(step.get("pattern", "SINGLE_TARGET"))
	if not AbilityEnums.is_valid_pattern(pat):
		printerr("Pattern inconnu : ", pat)
		return
	var hex: float = field.hex_w
	var ctx := _new_ctx(step, caster, field)
	var tgt: BattleUnit = caster.target
	match pat:
		"SINGLE_TARGET", "PROJECTILE":
			if tgt == null:
				return
			ctx.targets = [tgt]
			ctx.main_target = tgt
			ctx.dest = tgt.chest()
			_spawn(step, ctx, pat)
		"BEAM":
			if tgt == null:
				return
			var dir: Vector2 = (tgt.position - caster.position).normalized()
			var length: float = caster.range_px() + float(step.get("length", 2.5)) * hex
			ctx.dest = ctx.origin + dir * length
			ctx.main_target = tgt
			ctx.targets = _units_on_segment(field.enemies_of(caster), ctx.origin, ctx.dest, maxf(ctx.width, hex * 0.5) * 0.5)
			_spawn(step, ctx, pat)
		"CONE":
			if tgt == null:
				return
			var cdir: Vector2 = (tgt.position - caster.position).normalized()
			var reach: float = maxf(ctx.radius, hex * 2.0)
			var half: float = deg_to_rad(float(step.get("angle", 60.0)) * 0.5)
			ctx.dest = ctx.origin + cdir * reach
			ctx.main_target = tgt
			ctx.radius = reach
			for e in field.enemies_of(caster):
				var to: Vector2 = e.position - caster.position
				if to.length() <= reach and absf(cdir.angle_to(to)) <= half:
					ctx.targets.append(e)
			_spawn(step, ctx, pat)
		"CIRCLE_SELF":
			ctx.radius = maxf(ctx.radius, hex)
			ctx.origin = caster.position
			ctx.dest = caster.position
			ctx.main_target = tgt
			ctx.targets = field.enemies_in_radius(caster, caster.position, ctx.radius)
			_spawn(step, ctx, pat)
		"CIRCLE_TARGET":
			if tgt == null:
				return
			ctx.radius = maxf(ctx.radius, hex)
			ctx.dest = tgt.position
			ctx.main_target = tgt
			ctx.targets = field.enemies_in_radius(caster, tgt.position, ctx.radius)
			_spawn(step, ctx, pat)
		"CHAIN":
			if tgt == null:
				return
			var chain: Array = [tgt]
			var reach_px: float = maxf(ctx.radius, hex * 2.0)
			for i in range(int(step.get("bounces", 3))):
				var nxt: BattleUnit = field.nearest_enemy_to(caster, chain[chain.size() - 1].position, chain, reach_px)
				if nxt == null:
					break
				chain.append(nxt)
			ctx.targets = chain
			ctx.main_target = tgt
			ctx.dest = tgt.chest()
			_spawn(step, ctx, pat)
		"MULTI_NEAREST":
			for e in field.nearest_enemies(caster, int(step.get("count", 3))):
				var sub := _new_ctx(step, caster, field)
				sub.targets = [e]
				sub.main_target = e
				sub.dest = e.chest()
				_spawn(step, sub, pat)
		"MULTI_RANDOM":
			var count: int = int(step.get("count", 5))
			var stagger: float = float(step.get("stagger", 0.1))
			for i in range(count):
				if i == 0:
					_spawn_random(step, caster, field)
				else:
					var timer: SceneTreeTimer = field.get_tree().create_timer(stagger * i / maxf(field.speed, 0.1))
					timer.timeout.connect(_spawn_random.bind(step, caster, field))
		"DASH_STRIKE":
			if tgt == null:
				return
			var back: Vector2 = (caster.position - tgt.position).normalized()
			if back == Vector2.ZERO:
				back = Vector2.UP
			ctx.origin = caster.chest()
			caster.position = field.clamp_to_arena(tgt.position + back * hex * 0.95)
			ctx.dest = caster.chest()
			ctx.main_target = tgt
			ctx.targets = [tgt]
			_spawn(step, ctx, pat)
		"ZONE":
			var center: BattleUnit = tgt
			if str(step.get("zone_on", "target")) == "self" or center == null:
				center = caster
			ctx.radius = maxf(ctx.radius, hex)
			ctx.origin = center.position
			ctx.dest = center.position
			ctx.duration = maxf(ctx.duration, 1.0)
			ctx.main_target = tgt
			_spawn(step, ctx, pat)
		"SELF":
			ctx.targets = [caster]
			ctx.main_target = caster
			ctx.origin = caster.position
			ctx.dest = caster.position
			_spawn(step, ctx, pat)
		"ALLY_WEAKEST":
			var weakest: BattleUnit = null
			var worst: float = 1.01
			for a in field.allies_of(caster, bool(step.get("include_self", false))):
				var r: float = a.hp / a.max_hp
				if r < worst:
					worst = r
					weakest = a
			if weakest == null:
				return
			ctx.targets = [weakest]
			ctx.main_target = weakest
			ctx.origin = weakest.position
			ctx.dest = weakest.position
			_spawn(step, ctx, pat)
		"ALLIES_AREA":
			ctx.radius = maxf(ctx.radius, hex * 2.0)
			ctx.origin = caster.position
			ctx.dest = caster.position
			for a in field.allies_of(caster, true):
				if a.position.distance_to(caster.position) <= ctx.radius:
					ctx.targets.append(a)
			_spawn(step, ctx, pat)
		"ALLIES_ALL":
			ctx.targets = field.allies_of(caster, true)
			ctx.origin = caster.position
			ctx.dest = caster.position
			_spawn(step, ctx, pat)
		"ENEMIES_ALL":
			ctx.targets = field.enemies_of(caster)
			ctx.main_target = tgt
			ctx.dest = field.arena_rect.get_center()
			ctx.radius = field.arena_rect.size.length() * 0.5
			_spawn(step, ctx, pat)
		"GROUND_CIRCLE":
			var center: Vector2 = field.clamp_to_arena(caster.aim_point)
			ctx.radius = maxf(ctx.radius, hex)
			ctx.origin = center
			ctx.dest = center
			var pool: Array = field.allies_of(caster, true) if str(step.get("team", "enemies")) == "allies" else field.enemies_of(caster)
			for u in pool:
				if u.position.distance_to(center) <= ctx.radius:
					ctx.targets.append(u)
			_spawn(step, ctx, pat)
		"MOVE_TARGET":
			if tgt == null:
				return
			ctx.origin = tgt.position
			tgt.position = field.clamp_to_arena(caster.aim_point)
			tgt.target = null
			ctx.dest = tgt.position
			ctx.targets = [tgt]
			ctx.main_target = tgt
			_spawn(step, ctx, pat)
		"SWAP":
			var other: BattleUnit = caster.aim_target2
			if tgt == null or other == null or tgt == other:
				return
			var pa: Vector2 = tgt.position
			tgt.position = other.position
			other.position = pa
			tgt.target = null
			other.target = null
			ctx.origin = pa
			ctx.dest = tgt.position
			ctx.targets = [tgt, other]
			ctx.main_target = tgt
			_spawn(step, ctx, pat)
		"TELEPORT":
			ctx.origin = caster.position
			caster.position = _best_teleport_spot(caster, field)
			caster.target = null
			ctx.dest = caster.position
			ctx.targets = [caster]
			ctx.main_target = caster
			_spawn(step, ctx, pat)


static func _new_ctx(step: Dictionary, caster: BattleUnit, field: BattleField) -> AttackContext:
	var ctx := AttackContext.new()
	ctx.caster = caster
	ctx.field = field
	ctx.params = step
	ctx.origin = caster.chest()
	ctx.dest = ctx.origin
	ctx.radius = float(step.get("radius", 0.0)) * field.hex_w
	ctx.width = float(step.get("width", 0.0)) * field.hex_w
	ctx.duration = float(step.get("duration", 0.0))
	if step.has("color"):
		ctx.color = Color(str(step["color"]))
	return ctx


static func _spawn_random(step: Dictionary, caster: BattleUnit, field: BattleField) -> void:
	if field.finished:
		return
	var foes: Array[BattleUnit] = field.enemies_of(caster)
	if foes.is_empty():
		return
	var e: BattleUnit = foes.pick_random()
	var ctx := _new_ctx(step, caster, field)
	ctx.targets = [e]
	ctx.main_target = e
	ctx.dest = e.chest()
	_spawn(step, ctx, "MULTI_RANDOM")


## Instancie la scène d'effet et branche les impacts sur les effets du step.
static func _spawn(step: Dictionary, ctx: AttackContext, pat: String) -> void:
	for e in step.get("effects", []):
		if str(e.get("type", "")) == "CAPTURE" and ctx.main_target != null:
			# le résultat est tiré AVANT l'animation (la scène d'effet le lit dans ctx.vars) ; la cible est figée
			ctx.vars["capture_success"] = AbilityEffects.roll_capture(e, ctx.main_target)
			ctx.main_target.capturing = true
	var path: String = str(step.get("fx", AbilityEnums.DEFAULT_FX.get(pat, "")))
	var fx: AttackFx = null
	if path != "" and ResourceLoader.exists(path):
		var scene: PackedScene = load(path)
		fx = scene.instantiate() as AttackFx
	if fx == null:
		if path != "":
			printerr("Scène d'effet introuvable ou invalide : ", path)
		for t in ctx.targets:
			AbilityEffects.apply_list(step.get("effects", []), ctx, t)
		return
	var repeatable: bool = pat == "ZONE"
	var applied: Dictionary = {}
	var on_impact := func(target: BattleUnit) -> void:
		if target == null:
			return
		if not repeatable:
			if applied.has(target):
				return
			applied[target] = true
		AbilityEffects.apply_list(step.get("effects", []), ctx, target)
	var on_finished := func() -> void:
		if repeatable:
			return
		for u in ctx.targets:   # filet de sécurité : un fx qui oublie hit() n'empêche pas l'effet
			if not applied.has(u):
				applied[u] = true
				AbilityEffects.apply_list(step.get("effects", []), ctx, u)
	fx.impact.connect(on_impact)
	fx.finished.connect(on_finished)
	ctx.field.add_child(fx)
	fx.start(ctx)


static func _units_on_segment(units: Array, a: Vector2, b: Vector2, half_width: float) -> Array:
	var out: Array = []
	for u in units:
		var c: Vector2 = u.chest()
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(c, a, b)
		if closest.distance_to(c) <= half_width + 14.0:
			out.append(u)
	return out


static func _best_teleport_spot(c: BattleUnit, f: BattleField) -> Vector2:
	var foes: Array[BattleUnit] = f.enemies_of(c)
	var best: Vector2 = c.position
	var best_score: float = -1.0
	for i in range(14):
		var cand := Vector2(
			randf_range(f.arena_rect.position.x, f.arena_rect.end.x),
			randf_range(f.arena_rect.position.y, f.arena_rect.end.y))
		var score: float = INF
		for e in foes:
			score = minf(score, cand.distance_to(e.position))
		if score > best_score:
			best_score = score
			best = cand
	return best
