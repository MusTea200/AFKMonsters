extends Node2D

var target: Node2D = null
var shoot_timer: float = 0.0
var fire_rate: float = 2.0 # Shots per second
var bullet_scene = preload("res://Bullet.tscn")
var range_radius: float = 800.0
var damage: float = 30.0

func _ready() -> void:
	# Visual base
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-20, 20),
		Vector2(20, 20),
		Vector2(0, -30)
	])
	base.color = Color(1.0, 0.5, 0.0, 0.8) # Orange
	add_child(base)

	# Glow
	var glow = PointLight2D.new()
	glow.texture = load("res://icon.svg")
	glow.color = Color(1.0, 0.5, 0.0)
	glow.scale = Vector2(0.5, 0.5)
	glow.energy = 0.5
	add_child(glow)

func _process(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= (1.0 / fire_rate):
		_find_target()
		if is_instance_valid(target):
			_shoot()
			shoot_timer = 0.0
		else:
			# Prevent overflow
			shoot_timer = 1.0 / fire_rate

func _find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = INF
	target = null

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < range_radius and dist < closest_dist:
				closest_dist = dist
				target = enemy

func _shoot() -> void:
	if not is_instance_valid(target): return

	var dir = global_position.direction_to(target.global_position)
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.damage = damage
	get_tree().current_scene.add_child(bullet)

	# Recoil/Flash visual
	rotation = dir.angle() + PI/2.0
	var tw = create_tween()
	scale = Vector2(1.2, 0.8)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
