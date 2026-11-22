class_name TargetOverlay
extends Node2D

var active: bool = false
var need: String = ""
var valid_units: Array = []
var hover_unit: BattleUnit = null
var first_unit: BattleUnit = null
var radius_px: float = 0.0
var labels: Dictionary = {}
var accent: Color = Color(1, 0.9, 0.3)
var arena: Rect2 = Rect2()


func _process(_delta: float) -> void:
	if active or hover_unit != null:
		queue_redraw()


func _draw() -> void:
	var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
	if hover_unit != null and not hover_unit.dead:
		draw_arc(hover_unit.position, 30.0, 0.0, TAU, 28, Color(1, 1, 1, 0.9), 3.0)
	if not active:
		return
	for u in valid_units:
		if u.dead:
			continue
		var c: Color = Color(accent, pulse)
		draw_arc(u.position, 26.0, 0.0, TAU, 28, c, 3.0)
		draw_circle(u.position, 26.0, Color(accent, 0.10 * pulse))
		if labels.has(u):
			var font: Font = ThemeDB.fallback_font
			var txt: String = str(labels[u])
			draw_string_outline(font, u.position + Vector2(-30, 24), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, 5, Color.BLACK)
			draw_string(font, u.position + Vector2(-30, 24), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, Color(1, 0.95, 0.5))
	var mouse: Vector2 = get_local_mouse_position()
	if first_unit != null and not first_unit.dead:
		draw_arc(first_unit.position, 30.0, 0.0, TAU, 28, Color(0.5, 1, 0.6, 0.95), 4.0)
		if need == "point":
			draw_line(first_unit.chest(), mouse, Color(0.5, 1, 0.6, 0.6), 2.0)
	if need == "point" and arena.has_point(mouse):
		if radius_px > 1.0:
			draw_circle(mouse, radius_px, Color(accent, 0.16))
			draw_arc(mouse, radius_px, 0.0, TAU, 40, Color(accent, 0.9), 3.0)
		else:
			draw_arc(mouse, 14.0, 0.0, TAU, 20, Color(accent, 0.9), 3.0)
