extends Area2D

var player: Node2D
var duration: float = 10.0
var pull_strength: float = 2000.0

func _ready() -> void:
	player = get_tree().current_scene.find_child("Player", true, false)

	var shape = CircleShape2D.new()
	shape.radius = 1000.0
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	# Visual
	var visual = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(32):
		pts.append(Vector2(cos(i/32.0*TAU), sin(i/32.0*TAU)) * 1000.0)
	visual.polygon = pts
	visual.color = Color(1.0, 0.0, 1.0, 0.05)
	add_child(visual)

	var tw = create_tween()
	tw.tween_property(visual, "color:a", 0.0, duration)
	tw.tween_callback(self.queue_free)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return

	global_position = player.global_position

	var overlapping = get_overlapping_areas()
	for area in overlapping:
		if area is Coin or area.name.find("LoopParticle") != -1:
			var dir = area.global_position.direction_to(global_position)
			# Coin has speed logic, we can override or just pull coordinates directly for a portable magnet
			area.global_position += dir * pull_strength * delta
