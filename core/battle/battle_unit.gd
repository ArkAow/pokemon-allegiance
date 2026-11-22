class_name BattleUnit
extends Node2D

signal died(unit: BattleUnit)

var field: BattleField
var team: int = 0
var instance: PokemonInstance
var species: Dictionary = {}
var types: Array = []
var damage_kind: String = "physical"
var attack_range_cells: float = 1.0
var is_ranged: bool = false

var base_stats: Dictionary = {}
var mods: Dictionary = {}
var buffs: Array = []
var max_hp: float = 1.0
var hp: float = 1.0
var shield: float = 0.0
var shield_time: float = 0.0
var energy: float = 0.0
var energy_max: float = 100.0
var ability_id: String = ""
var ability: Dictionary = {}

var target: BattleUnit = null
var attack_cd: float = 0.0
var action_lock: float = 0.0
var stun_time: float = 0.0
var slow_time: float = 0.0
var slow_amount: float = 0.0
var invuln_time: float = 0.0
var dots: Array = []
var dead: bool = false
var was_captured: bool = false
var capturing: bool = false
var facing: String = "down"

var dmg_dealt: float = 0.0
var dmg_taken: float = 0.0

var aim_point: Vector2 = Vector2.ZERO
var aim_target2: BattleUnit = null
var moving: bool = false

var sprite: AnimatedSprite2D
var entry: SpriteLibrary.Entry
var bar_y: float = -40.0
var flash: float = 0.0


func setup(p_field: BattleField, p_team: int, p_inst: PokemonInstance, p_mods: Dictionary) -> void:
	field = p_field
	team = p_team
	instance = p_inst
	species = p_inst.species()
	types = species.get("types", [])
	damage_kind = str(species.get("attack_kind", "physical"))
	attack_range_cells = float(species.get("range", 1))
	is_ranged = attack_range_cells > 1.5
	mods = p_mods.duplicate()
	SynergyCalc.merge_mods(mods, GlobalData.get_item(p_inst.item_id).get("mods", {}))
	base_stats = p_inst.compute_stats()
	max_hp = float(base_stats["hp"]) * Balance.HP_MULT * (1.0 + mod("hp_pct"))
	hp = max_hp
	ability_id = str(species.get("ability", ""))
	ability = GlobalData.get_ability(ability_id)
	energy_max = float(ability.get("cost", 100))
	energy = clampf(mod("energy_start"), 0.0, energy_max * 0.9)
	shield = max_hp * mod("shield_start")
	shield_time = 9999.0
	facing = "up" if team == 0 else "down"
	_build_visuals()


func _build_visuals() -> void:
	entry = SpriteLibrary.get_entry(instance.species_id)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = entry.frames
	sprite.scale = Vector2(entry.scale, entry.scale)
	add_child(sprite)
	bar_y = -body_height() - 14.0
	_play("idle")


func body_height() -> float:
	return entry.body_height("idle") * entry.scale


func chest() -> Vector2:
	return position + Vector2(0, -body_height() * 0.5)


func mod(key: String) -> float:
	var v: float = float(mods.get(key, 0.0))
	for b in buffs:
		var bm: Dictionary = b["mods"]
		v += float(bm.get(key, 0.0))
	return v


func stat(key: String) -> float:
	return float(base_stats[key]) * maxf(0.1, 1.0 + mod(key + "_pct"))


func power() -> float:
	return stat("atk") if damage_kind == "physical" else stat("speAtk")


func spell(ratio: float) -> float:
	return power() * ratio * (1.0 + mod("ability_power_pct"))


func defense_for(kind: String) -> float:
	return stat("def") if kind == "physical" else stat("speDef")


func slow_factor() -> float:
	return maxf(0.2, 1.0 - slow_amount) if slow_time > 0.0 else 1.0


func attack_speed() -> float:
	return (0.5 + float(base_stats["spd"]) / 250.0) * maxf(0.2, 1.0 + mod("aspd_pct")) * slow_factor()


func move_speed() -> float:
	return (60.0 + float(base_stats["spd"]) * 0.8) * maxf(0.2, 1.0 + mod("move_pct")) * slow_factor()


func range_px() -> float:
	return (attack_range_cells + mod("range_bonus") + 0.2) * field.hex_w


func is_dead() -> bool:
	return dead


func is_targetable() -> bool:
	return not dead and invuln_time <= 0.0 and not capturing


func _process(delta: float) -> void:
	if field == null:
		return
	queue_redraw()
	if dead:
		return
	var dt: float = delta * field.speed
	flash = maxf(0.0, flash - dt)
	var inv: float = 0.5 if invuln_time > 0.0 else 1.0
	sprite.modulate = Color(1.7, 1.7, 1.7, inv) if flash > 0.0 else Color(1, 1, 1, inv)
	if not field.running or capturing:
		moving = false
		if not capturing:
			_play("idle")
		return
	_tick_effects(dt)
	if dead:
		return
	attack_cd -= dt
	if stun_time > 0.0:
		moving = false
		_play("idle")
		return
	if action_lock > 0.0:
		action_lock -= dt
		return
	if target == null or not target.is_targetable():
		target = field.find_target(self)
	if target == null:
		moving = false
		_play("idle")
		return
	if energy >= energy_max and ability_id != "":
		_cast_ability()
		return
	var to: Vector2 = target.position - position
	if to.length() <= range_px():
		moving = false
		facing = SpriteLibrary.dir_from_vector(to)
		if attack_cd <= 0.0:
			_do_attack()
		else:
			_play("idle")
	else:
		moving = true
		_move_toward(to, dt)


func _move_toward(to: Vector2, dt: float) -> void:
	facing = SpriteLibrary.dir_from_vector(to)
	var v: Vector2 = to.normalized() * move_speed()
	var sep := Vector2.ZERO
	var min_d: float = field.hex_w * 0.8
	for u in field.units:
		if u == self or u.dead:
			continue
		var off: Vector2 = position - u.position
		var l: float = off.length()
		if l < min_d and l > 0.001:
			sep += off / l * (min_d - l)
	position = field.clamp_to_arena(position + v * dt + sep * minf(1.0, dt * 8.0))
	_play("walk")


func _tick_effects(dt: float) -> void:
	var regen: float = mod("regen_pct")
	if regen > 0.0:
		hp = minf(max_hp, hp + max_hp * regen * dt)
	var eps: float = mod("energy_per_sec")
	if eps > 0.0:
		energy = minf(energy_max, energy + eps * dt)
	stun_time = maxf(0.0, stun_time - dt)
	slow_time = maxf(0.0, slow_time - dt)
	invuln_time = maxf(0.0, invuln_time - dt)
	if shield > 0.0:
		shield_time -= dt
		if shield_time <= 0.0:
			shield = 0.0
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i]["time"] = float(buffs[i]["time"]) - dt
		if float(buffs[i]["time"]) <= 0.0:
			buffs.remove_at(i)
	for i in range(dots.size() - 1, -1, -1):
		var d: Dictionary = dots[i]
		take_damage(float(d["dps"]) * dt, d.get("src", null), "true", true)
		if dead:
			return
		d["time"] = float(d["time"]) - dt
		if float(d["time"]) <= 0.0:
			dots.remove_at(i)


func _do_attack() -> void:
	attack_cd = 1.0 / attack_speed()
	var anim: String = attack_anim()
	_play(anim)
	var anim_len: float = entry.length(anim)
	action_lock = clampf(anim_len, 0.2, maxf(0.2, attack_cd * 0.85))
	if not entry.has_anim(anim) and not is_ranged:
		_lunge()
	var dmg: float = power() * Balance.BASIC_ATTACK_RATIO
	var crit: bool = randf() < mod("crit_chance")
	if crit:
		dmg *= 1.5 + mod("crit_mult")
	gain_energy(Balance.ENERGY_PER_ATTACK + mod("energy_per_hit"))
	var delay: float = entry.hit_time(anim) / maxf(field.speed, 0.1)
	if delay > 0.02:
		field.get_tree().create_timer(delay).timeout.connect(_resolve_attack.bind(target, dmg, crit))
	else:
		_resolve_attack(target, dmg, crit)


func attack_anim() -> String:
	var forced: String = str(species.get("attack_anim", ""))
	if forced != "":
		return forced
	return "shoot" if is_ranged else "attack"


func _resolve_attack(t: BattleUnit, dmg: float, crit: bool) -> void:
	if dead or t == null or t.dead or field.finished:
		return
	if is_ranged:
		var pr := BattleProjectile.new()
		pr.source = self
		pr.target = t
		pr.damage = dmg
		pr.crit = crit
		pr.color = GlobalData.get_type_color(str(types[0]))
		pr.position = chest()
		field.add_child(pr)
	else:
		hit_target(t, dmg, crit)


func _lunge() -> void:
	if target == null:
		return
	var dir: Vector2 = (target.position - position).normalized()
	var tw := create_tween()
	tw.tween_property(sprite, "position", dir * 9.0, 0.07)
	tw.tween_property(sprite, "position", Vector2.ZERO, 0.12)


func _cast_ability() -> void:
	energy = 0.0
	moving = false
	var first: String = AbilityRunner.first_pattern(ability_id)
	var anim: String = str(ability.get("cast_anim", AbilityEnums.DEFAULT_CAST_ANIM.get(first, "attack")))
	_play(anim)
	action_lock = maxf(float(ability.get("cast_time", 0.6)), entry.length(anim) * 0.6)
	field.fx_text(position + Vector2(0, bar_y - 14.0), str(ability.get("name", "")), Color(0.7, 0.9, 1.0), 18)
	AbilityRunner.run(ability_id, self, field)


func hit_target(t: BattleUnit, dmg: float, crit: bool) -> void:
	if t == null or t.dead:
		return
	if randf() < t.mod("dodge"):
		field.fx_text(t.position + Vector2(0, t.bar_y), "Esquive", Color.WHITE, 14)
		return
	var dealt: float = t.take_damage(dmg, self, damage_kind, false, crit)
	var ls: float = mod("lifesteal")
	if ls > 0.0:
		heal(dealt * ls, true)
	var tdp: float = mod("true_damage_pct")
	if tdp > 0.0:
		t.take_damage(t.max_hp * tdp, self, "true", true)
	var b: float = mod("burn_on_hit")
	if b > 0.0:
		t.apply_dot("burn", t.max_hp * b, 3.0, self)
	var po: float = mod("poison_on_hit")
	if po > 0.0:
		t.apply_dot("poison", t.max_hp * po, 5.0, self)
	var sl: float = mod("slow_on_hit")
	if sl > 0.0:
		t.slow(sl, 2.0)
	var th: float = t.mod("thorns")
	if th > 0.0 and not dead:
		take_damage(dealt * th, t, "true", true)


func deal_spell(t: BattleUnit, ratio: float) -> float:
	if t == null or t.dead:
		return 0.0
	return t.take_damage(spell(ratio), self, damage_kind)


func take_damage(amount: float, source: BattleUnit, kind: String = "physical", silent: bool = false, crit: bool = false) -> float:
	if dead or invuln_time > 0.0 or capturing:
		return 0.0
	var dmg: float = amount
	if kind != "true":
		dmg = dmg * Balance.ARMOR_SCALE / (Balance.ARMOR_SCALE + defense_for(kind))
		dmg *= 1.0 - clampf(mod("dmg_reduction"), 0.0, 0.8)
		dmg = maxf(1.0, dmg)
	var shown: float = minf(dmg, hp + shield)
	if shield > 0.0:
		var absorbed: float = minf(shield, dmg)
		shield -= absorbed
		dmg -= absorbed
	hp -= dmg
	dmg_taken += shown
	if source != null and source != self:
		source.dmg_dealt += shown
	if not silent:
		flash = 0.12
		gain_energy(Balance.ENERGY_ON_HIT_TAKEN)
		var col: Color = Color(1.0, 0.9, 0.3) if crit else Color(1, 1, 1)
		field.fx_text(position + Vector2(randf_range(-10, 10), bar_y), str(roundi(shown)), col, 20 if crit else 15)
	if hp <= 0.0:
		_die()
	return shown


func heal(amount: float, silent: bool = false) -> void:
	if dead or amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	if not silent and amount >= 1.0:
		field.fx_text(position + Vector2(0, bar_y), "+" + str(roundi(amount)), Color(0.4, 1.0, 0.5), 14)


func gain_energy(a: float) -> void:
	energy = clampf(energy + a, 0.0, energy_max)


func drain_energy(a: float) -> float:
	var taken: float = minf(energy, a)
	energy -= taken
	return taken


func add_shield(amount: float, duration: float) -> void:
	shield += amount
	shield_time = maxf(shield_time if shield_time < 9000.0 else 0.0, duration)


func add_buff(m: Dictionary, duration: float) -> void:
	buffs.append({"mods": m, "time": duration})


func stun(t: float) -> void:
	stun_time = maxf(stun_time, t)


func slow(amount: float, t: float) -> void:
	slow_amount = maxf(slow_amount if slow_time > 0.0 else 0.0, amount)
	slow_time = maxf(slow_time, t)


func make_invulnerable(t: float) -> void:
	invuln_time = maxf(invuln_time, t)


func apply_dot(kind: String, dps: float, duration: float, source: BattleUnit = null) -> void:
	for d in dots:
		if d["kind"] == kind:
			d["dps"] = maxf(float(d["dps"]), dps)
			d["time"] = maxf(float(d["time"]), duration)
			d["src"] = source
			return
	dots.append({"kind": kind, "dps": dps, "time": duration, "src": source})


func push(from_pos: Vector2, dist_px: float) -> void:
	var dir: Vector2 = (position - from_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var dest: Vector2 = field.clamp_to_arena(position + dir * dist_px)
	var tw := create_tween()
	tw.tween_property(self, "position", dest, 0.2)


func vanish_captured() -> void:
	was_captured = true
	dead = true
	capturing = false
	hp = 0.0
	hide()


func _die() -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	moving = false
	sprite.flip_h = entry.needs_flip(facing)
	var dn: String = entry.resolve("die", facing)
	sprite.offset = entry.anchor_offset(dn)
	sprite.play(dn)
	sprite.modulate = Color.WHITE
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(hide)
	died.emit(self)


func _play(anim: String) -> void:
	var n: String = entry.resolve(anim, facing)
	sprite.flip_h = entry.needs_flip(facing)
	sprite.speed_scale = field.speed
	var looping: bool = anim == "idle" or anim == "walk"
	if looping and sprite.animation == StringName(n) and sprite.is_playing():
		return
	sprite.offset = entry.anchor_offset(n)
	sprite.play(n)


func _draw() -> void:
	if dead or field == null:
		return
	var team_col: Color = Color(0.3, 0.8, 1.0) if team == 0 else Color(1.0, 0.35, 0.3)
	draw_arc(Vector2(0, 0), 20.0, 0.0, TAU, 24, Color(team_col, 0.8), 2.0)
	var w: float = 48.0
	var x: float = -w * 0.5
	var y: float = bar_y
	draw_rect(Rect2(x - 1, y - 1, w + 2, 13), Color(0, 0, 0, 0.75))
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(x, y, w * ratio, 6), Color(0.35, 0.9, 0.4) if team == 0 else Color(0.95, 0.35, 0.3))
	if shield > 0.0:
		draw_rect(Rect2(x, y, w * clampf(shield / max_hp, 0.0, 1.0), 2), Color(0.85, 0.95, 1.0))
	draw_rect(Rect2(x, y + 7, w, 4), Color(0.1, 0.1, 0.25))
	draw_rect(Rect2(x, y + 7, w * clampf(energy / energy_max, 0.0, 1.0), 4), Color(0.3, 0.6, 1.0))
	var label: String = "%s  Nv%d" % [instance.display_name(), instance.level]
	var font: Font = ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-70, y - 4), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 13, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(-70, y - 4), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color(1, 1, 1) if team == 0 else Color(1, 0.85, 0.85))

	var sx: float = x + w + 4.0
	if stun_time > 0.0:
		draw_circle(Vector2(sx, y + 3), 3.5, Color(1, 0.9, 0.2))
		sx += 8.0
	if slow_time > 0.0:
		draw_circle(Vector2(sx, y + 3), 3.5, Color(0.5, 0.9, 1.0))
		sx += 8.0
	for d in dots:
		draw_circle(Vector2(sx, y + 3), 3.5, Color(1, 0.5, 0.15) if d["kind"] == "burn" else Color(0.7, 0.3, 0.8))
		sx += 8.0
