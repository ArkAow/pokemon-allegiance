class_name BattleFx
extends Node2D

var kind: String = "ring"
var radius: float = 60.0
var color: Color = Color.WHITE
var p2: Vector2 = Vector2.ZERO
var width: float = 4.0
var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()


static func ring(parent: Node, pos: Vector2, radius_px: float, col: Color, duration: float = 0.45) -> void:
	var fx := BattleFx.new()
	fx.kind = "ring"
	fx.position = pos
	fx.radius = radius_px
	fx.color = col
	fx.z_index = 50
	parent.add_child(fx)
	fx._run(duration)


static func line(parent: Node, a: Vector2, b: Vector2, col: Color, w: float = 4.0, duration: float = 0.3) -> void:
	var fx := BattleFx.new()
	fx.kind = "line"
	fx.position = a
	fx.p2 = b - a
	fx.color = col
	fx.width = w
	fx.z_index = 50
	parent.add_child(fx)
	fx._run(duration)


static func text(parent: Node, pos: Vector2, txt: String, col: Color, font_size: int = 16) -> void:
	var l := Label.new()
	l.text = txt
	l.position = pos - Vector2(24, 0)
	l.z_index = 100
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 30.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(l.queue_free)


func _run(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "progress", 1.0, duration)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var a: float = 1.0 - progress
	match kind:
		"ring":
			var r: float = maxf(1.0, radius * progress)
			draw_circle(Vector2.ZERO, r, Color(color, a * 0.25))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(color, a), 3.0)
		"line":
			draw_line(Vector2.ZERO, p2, Color(color, a), width * a + 1.0)
