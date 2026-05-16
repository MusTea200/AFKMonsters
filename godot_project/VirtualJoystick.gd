extends Control
class_name VirtualJoystick

var base_pos: Vector2
var stick_pos: Vector2
var is_dragging: bool = false
var max_length: float = 75.0
var touch_id: int = -1
var radius: float = 120.0

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2, radius * 2)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if Global.current_input_type != Global.InputType.TOUCH: return

	if event is InputEventScreenTouch:
		if event.pressed and not is_dragging:
			# Dış kutuyu tıklarsa
			if get_global_rect().has_point(event.position):
				is_dragging = true
				touch_id = event.index
				base_pos = get_global_rect().get_center()
				stick_pos = event.position
				get_viewport().set_input_as_handled()
				queue_redraw()
		elif not event.pressed and event.index == touch_id:
			is_dragging = false
			touch_id = -1
			stick_pos = base_pos
			queue_redraw()

	if event is InputEventScreenDrag and is_dragging and event.index == touch_id:
		stick_pos = event.position
		if base_pos.distance_to(stick_pos) > max_length:
			stick_pos = base_pos + base_pos.direction_to(stick_pos) * max_length
		queue_redraw()

func get_joystick_vector() -> Vector2:
	if not is_dragging: return Vector2.ZERO
	return base_pos.direction_to(stick_pos) * (base_pos.distance_to(stick_pos) / max_length)

func _draw() -> void:
	# VirtualJoystick.gd draw function
	var center = size / 2.0
	var alpha = 0.8 if is_dragging else 0.2
	var s_pos = stick_pos - get_global_rect().position if is_dragging else center

	# Draw base
	draw_circle(center, radius, Color(0, 1, 1, alpha * 0.5))
	draw_arc(center, radius, 0, TAU, 32, Color(0, 1, 1, alpha), 2.0)

	# Draw stick
	draw_circle(s_pos, radius * 0.4, Color(1, 0, 1, alpha))
	draw_arc(s_pos, radius * 0.4, 0, TAU, 16, Color(1, 1, 1, alpha), 2.0)
