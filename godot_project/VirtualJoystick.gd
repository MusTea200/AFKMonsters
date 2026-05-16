extends Control
class_name VirtualJoystick

var base_pos: Vector2
var stick_pos: Vector2
var is_dragging: bool = false
var max_length: float = 50.0

func _ready() -> void:
	# Sadece Touch modu aktifse goster
	if Global.current_input_type != Global.InputType.TOUCH:
		hide()

func _input(event: InputEvent) -> void:
	if Global.current_input_type != Global.InputType.TOUCH: return

	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position):
			is_dragging = true
			base_pos = event.position
			stick_pos = base_pos
		elif not event.pressed:
			is_dragging = false
			stick_pos = base_pos

	if event is InputEventScreenDrag and is_dragging:
		stick_pos = event.position
		if base_pos.distance_to(stick_pos) > max_length:
			stick_pos = base_pos + base_pos.direction_to(stick_pos) * max_length

func get_joystick_vector() -> Vector2:
	if not is_dragging: return Vector2.ZERO
	return base_pos.direction_to(stick_pos) * (base_pos.distance_to(stick_pos) / max_length)
