extends Node

var trauma: float = 0.0
var max_offset: Vector2 = Vector2(50, 50)
var max_roll: float = 0.1
var decay: float = 0.8
var time: float = 0.0

func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0.0)
		shake()
		time += delta * 50.0 # Sarsıntı hızı

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var amount = pow(trauma, 2)
		var offset_x = max_offset.x * amount * sin(time)
		var offset_y = max_offset.y * amount * cos(time * 1.3)
		camera.offset = Vector2(offset_x, offset_y)
		camera.rotation = max_roll * amount * sin(time * 0.8)

	if trauma == 0 and camera:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0
