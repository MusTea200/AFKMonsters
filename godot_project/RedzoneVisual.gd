extends Control

var radius: float = 300.0

func _draw() -> void:
	# Draw pulsing border
	var t = Time.get_ticks_msec() * 0.005
	var alpha = 0.5 + sin(t) * 0.3
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(1.0, 0.0, 0.0, alpha), 5.0)

func _process(delta: float) -> void:
	queue_redraw()
