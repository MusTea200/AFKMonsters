extends Node2D

var target: Node2D
var camera: Camera2D
var visual: Polygon2D

func _ready() -> void:
	z_index = 100
	visual = Polygon2D.new()
	# Draw a neon triangle arrow pointing right
	visual.polygon = PackedVector2Array([
		Vector2(-15, -15),
		Vector2(15, 0),
		Vector2(-15, 15)
	])
	visual.color = Color(0, 1, 1, 0.8) # Neon Cyan
	add_child(visual)

	# Try to find camera
	camera = get_viewport().get_camera_2d()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
		if not is_instance_valid(camera):
			hide()
			return

	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size / camera.zoom
	var screen_rect = Rect2(cam_pos - viewport_size/2.0, viewport_size)

	if screen_rect.has_point(target.global_position):
		hide()
	else:
		show()
		var dir = cam_pos.direction_to(target.global_position)
		var intersection = _get_screen_intersection(cam_pos, target.global_position, screen_rect)
		global_position = intersection
		rotation = dir.angle()

func _get_screen_intersection(cam_pos: Vector2, target_pos: Vector2, rect: Rect2) -> Vector2:
	var padding = 50.0 # Kenarlardan bosluk
	var r_pos = rect.position + Vector2(padding, padding)
	var r_size = rect.size - Vector2(padding*2, padding*2)

	var min_x = r_pos.x
	var max_x = r_pos.x + r_size.x
	var min_y = r_pos.y
	var max_y = r_pos.y + r_size.y

	var slope = (target_pos.y - cam_pos.y) / (target_pos.x - cam_pos.x) if (target_pos.x - cam_pos.x) != 0 else 99999.0

	var pt_x = Vector2.ZERO
	if target_pos.x > cam_pos.x:
		pt_x = Vector2(max_x, cam_pos.y + slope * (max_x - cam_pos.x))
	else:
		pt_x = Vector2(min_x, cam_pos.y + slope * (min_x - cam_pos.x))

	var pt_y = Vector2.ZERO
	if target_pos.y > cam_pos.y:
		pt_y = Vector2(cam_pos.x + (max_y - cam_pos.y) / slope, max_y)
	else:
		pt_y = Vector2(cam_pos.x + (min_y - cam_pos.y) / slope, min_y)

	if pt_x.y >= min_y and pt_x.y <= max_y:
		return pt_x
	return pt_y
