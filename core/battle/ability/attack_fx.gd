class_name AttackFx
extends Node2D
## BASE de toutes les scènes d'effets d'attaque (effects/scenes/*.tscn).
##
## Pour créer ton propre effet :
##   1. Crée une scène dont le nœud racine est un Node2D avec un script `extends AttackFx`.
##   2. Surcharge _begin() (initialisation), _step(dt) (animation) et _draw() (dessin) — ou ajoute
##      des Sprite2D / AnimatedSprite2D / GPUParticles2D comme enfants et déplace-les dans _step().
##   3. Appelle hit(unit) / hit_all() au moment où l'impact doit se produire : c'est À CE MOMENT que
##      les effets du step (dégâts, statuts...) sont appliqués. Appelle end() pour te terminer (ou règle `life`).
## Le nœud est placé à (0,0) du terrain : dessine directement avec les coordonnées de `ctx`.

signal impact(target: BattleUnit)
signal finished

@export var color: Color = Color(1, 1, 1, 1)
## Durée de vie maximale en secondes (certains fx la recalculent dans _begin).
@export var life: float = 0.6

var ctx: AttackContext
var t: float = 0.0
var _hit: Dictionary = {}
var _ended: bool = false


func start(c: AttackContext) -> void:
	ctx = c
	z_index = 60
	position = Vector2.ZERO
	_begin()


## Couleur à utiliser : celle du step JSON si précisée, sinon celle exportée par la scène.
func tint() -> Color:
	if ctx != null and ctx.color.a > 0.0:
		return ctx.color
	return color


func _begin() -> void:
	pass


func _step(_dt: float) -> void:
	pass


func _process(delta: float) -> void:
	if ctx == null or _ended:
		return
	var dt: float = delta * ctx.field.speed
	t += dt
	_step(dt)
	queue_redraw()
	if t >= life:
		end()


## Déclenche l'impact sur `target` (une seule fois par cible).
func hit(target: BattleUnit) -> void:
	if target == null or _hit.has(target):
		return
	_hit[target] = true
	impact.emit(target)


func hit_all() -> void:
	for u in ctx.targets:
		hit(u)


## Impact répétable (zones qui "tick").
func hit_repeat(target: BattleUnit) -> void:
	if target != null:
		impact.emit(target)


func end() -> void:
	if _ended:
		return
	_ended = true
	finished.emit()
	queue_free()


# --- petits utilitaires de dessin / maths pour les fx ---

static func ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)


static func jagged(a: Vector2, b: Vector2, segments: int, amount: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dir: Vector2 = (b - a)
	var perp: Vector2 = Vector2(-dir.y, dir.x).normalized()
	pts.append(a)
	for i in range(1, segments):
		var k: float = float(i) / float(segments)
		pts.append(a + dir * k + perp * rng.randf_range(-amount, amount))
	pts.append(b)
	return pts
