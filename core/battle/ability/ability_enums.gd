class_name AbilityEnums
extends RefCounted

enum Pattern {
	SINGLE_TARGET,
	PROJECTILE,
	BEAM,
	CONE,
	CIRCLE_SELF,
	CIRCLE_TARGET,
	CHAIN,
	MULTI_NEAREST,
	MULTI_RANDOM,
	DASH_STRIKE,
	ZONE,
	SELF,
	ALLY_WEAKEST,
	ALLIES_AREA,
	ALLIES_ALL,
	ENEMIES_ALL,
	TELEPORT,
	GROUND_CIRCLE,
	MOVE_TARGET,
	SWAP,
}


enum EffectKind {
	DAMAGE,
	HEAL,
	SHIELD,
	STUN,
	SLOW, 
	BURN,
	POISON,
	BUFF,
	DEBUFF,
	PUSH,
	PULL,
	DRAIN_ENERGY,
	GAIN_ENERGY,
	INVULNERABLE,
	CLEANSE,
	CAPTURE,
}

const DEFAULT_FX := {
	"SINGLE_TARGET": "res://effects/scenes/punch.tscn",
	"PROJECTILE": "res://effects/scenes/default_orb.tscn",
	"BEAM": "res://effects/scenes/solar_beam.tscn",
	"CONE": "res://effects/scenes/flamethrower.tscn",
	"CIRCLE_SELF": "res://effects/scenes/default_burst.tscn",
	"CIRCLE_TARGET": "res://effects/scenes/default_burst.tscn",
	"CHAIN": "res://effects/scenes/lightning_chain.tscn",
	"MULTI_NEAREST": "res://effects/scenes/default_orb.tscn",
	"MULTI_RANDOM": "res://effects/scenes/default_orb.tscn",
	"DASH_STRIKE": "res://effects/scenes/dash_trail.tscn",
	"ZONE": "res://effects/scenes/poison_cloud.tscn",
	"SELF": "res://effects/scenes/default_aura.tscn",
	"ALLY_WEAKEST": "res://effects/scenes/default_aura.tscn",
	"ALLIES_AREA": "res://effects/scenes/default_aura.tscn",
	"ALLIES_ALL": "res://effects/scenes/default_aura.tscn",
	"ENEMIES_ALL": "res://effects/scenes/default_burst.tscn",
	"TELEPORT": "res://effects/scenes/teleport.tscn",
	"GROUND_CIRCLE": "res://effects/scenes/default_burst.tscn",
	"MOVE_TARGET": "res://effects/scenes/teleport.tscn",
	"SWAP": "res://effects/scenes/teleport.tscn",
}

const DEFAULT_CAST_ANIM := {
	"SINGLE_TARGET": "attack", "DASH_STRIKE": "attack", "CIRCLE_SELF": "attack",
	"PROJECTILE": "shoot", "BEAM": "shoot", "CONE": "shoot", "CIRCLE_TARGET": "shoot", "CHAIN": "shoot",
	"MULTI_NEAREST": "shoot", "MULTI_RANDOM": "shoot", "ZONE": "shoot", "ENEMIES_ALL": "shoot",
	"SELF": "charge", "ALLY_WEAKEST": "charge", "ALLIES_AREA": "charge", "ALLIES_ALL": "charge", "TELEPORT": "charge",
}


static func is_valid_pattern(pattern_name: String) -> bool:
	return Pattern.has(pattern_name)


static func is_valid_effect(effect_name: String) -> bool:
	return EffectKind.has(effect_name)
