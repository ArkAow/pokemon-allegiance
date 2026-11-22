class_name BattleProjectile
extends Node2D

var source: BattleUnit
var target: BattleUnit
var damage: float = 1.0
var crit: bool = false
var color: Color = Color.WHITE
var speed: float = 520.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(color, 0.3))
	draw_circle(Vector2.ZERO, 5.0, color)


func _process(delta: float) -> void:
	if target == null or target.dead or source == null:
		queue_free()
		return
	var step: float = speed * delta * source.field.speed
	var to: Vector2 = target.chest() - position
	if to.length() <= step + 6.0:
		source.hit_target(target, damage, crit)
		queue_free()
		return
	position += to.normalized() * step
