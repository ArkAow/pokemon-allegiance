class_name AbilityEffects
extends RefCounted

static func apply_list(effects: Array, ctx: AttackContext, target: BattleUnit) -> void:
	for i in range(effects.size()):
		var e: Dictionary = effects[i]
		match str(e.get("on", "target")):
			"self":
				var key: String = "once_%d" % i
				if ctx.vars.has(key):
					continue
				ctx.vars[key] = true
				apply(e, ctx, ctx.caster)
			"main":
				if target == ctx.main_target:
					apply(e, ctx, target)
			_:
				apply(e, ctx, target)


static func apply(e: Dictionary, ctx: AttackContext, t: BattleUnit) -> void:
	if t == null or t.dead:
		return
	var c: BattleUnit = ctx.caster
	var hex: float = ctx.field.hex_w
	var dur: float = float(e.get("dur", 3.0))
	match str(e.get("type", "DAMAGE")):
		"DAMAGE":
			var ratio: float = float(e.get("ratio", 1.0))
			if e.has("main_mult") and t == ctx.main_target:
				ratio *= float(e["main_mult"])
			if e.has("execute_below") and t.hp / t.max_hp < float(e["execute_below"]):
				ratio *= float(e.get("execute_mult", 1.5))
			ratio += float(ctx.vars.get("drained", 0.0)) * float(e.get("bonus_per_drained", 0.0))
			if ctx.params.has("falloff"):
				ratio *= pow(float(ctx.params["falloff"]), float(ctx.hop_index(t)))
			var dealt: float = t.take_damage(c.spell(ratio), c, str(e.get("kind", c.damage_kind)))
			if e.has("lifesteal"):
				c.heal(dealt * float(e["lifesteal"]), true)
		"HEAL":
			t.heal(t.max_hp * float(e.get("pct", 0.0)) + c.power() * float(e.get("ratio", 0.0)))
		"SHIELD":
			t.add_shield(t.max_hp * float(e.get("pct", 0.2)), dur)
		"STUN":
			t.stun(dur)
			ctx.field.fx_text(t.position + Vector2(0, t.bar_y), "Étourdi", Color(1, 0.9, 0.3), 13)
		"SLOW":
			t.slow(float(e.get("amount", 0.3)), dur)
		"BURN":
			t.apply_dot("burn", t.max_hp * float(e.get("pct", 0.02)), dur, c)
		"POISON":
			t.apply_dot("poison", t.max_hp * float(e.get("pct", 0.02)), dur, c)
		"BUFF":
			t.add_buff(e.get("mods", {}), dur)
			ctx.field.fx_text(t.position + Vector2(0, t.bar_y), "Boost", Color(1, 0.8, 0.3), 13)
		"DEBUFF":
			t.add_buff(e.get("mods", {}), dur)
			ctx.field.fx_text(t.position + Vector2(0, t.bar_y), "Affaibli", Color(0.8, 0.5, 1.0), 13)
		"PUSH":
			t.push(c.position, float(e.get("cells", 1.0)) * hex)
		"PULL":
			t.push(c.position, -float(e.get("cells", 1.0)) * hex)
		"DRAIN_ENERGY":
			ctx.vars["drained"] = float(ctx.vars.get("drained", 0.0)) + t.drain_energy(float(e.get("amount", 30.0)))
		"GAIN_ENERGY":
			t.gain_energy(float(e.get("amount", 20.0)))
		"INVULNERABLE":
			t.make_invulnerable(dur)
		"CLEANSE":
			t.stun_time = 0.0
			t.slow_time = 0.0
			t.dots.clear()
		"CAPTURE":
			t.capturing = false
			if bool(ctx.vars.get("capture_success", false)):
				ctx.field.capture_unit(t)
			else:
				ctx.field.fx_text(t.position + Vector2(0, t.bar_y), "Il s'est échappé !", Color(1, 0.65, 0.5), 15)
				t.stun(0.6)
		_:
			printerr("Effet inconnu : ", e.get("type", "?"))


static func capture_chance(e: Dictionary, t: BattleUnit) -> float:
	var rate: float = float(t.species.get("catch_rate", 0.5))
	var ratio: float = clampf(t.hp / t.max_hp, 0.0, 1.0)
	var chance: float = float(e.get("ball", 1.0)) * rate * (1.0 - 0.7 * ratio)
	if t.stun_time > 0.0:
		chance += 0.15
	if not t.dots.is_empty():
		chance += 0.10
	chance *= clampf(1.2 - 0.01 * float(t.instance.level), 0.6, 1.2)
	return clampf(chance, 0.03, 0.97)


static func roll_capture(e: Dictionary, t: BattleUnit) -> bool:
	return randf() < capture_chance(e, t)
