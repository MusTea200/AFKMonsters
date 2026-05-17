extends Area2D

var player: Node2D
var speed: float = 0.0
var max_speed: float = 1000.0
var acceleration: float = 1500.0

var amount: int = 1

func _ready() -> void:
	# Visual
	var mesh = MeshInstance2D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 10.0
	sphere.height = 20.0
	mesh.mesh = sphere
	mesh.modulate = Color(0, 0.8, 1.0, 1.2) # Neon Blue/Cyan
	add_child(mesh)

	# Light/Glow
	var light = PointLight2D.new()
	light.texture = load("res://icon.svg") # Simple fallback glow
	light.color = Color(0, 0.5, 1.0)
	light.energy = 0.5
	light.scale = Vector2(0.5, 0.5)
	add_child(light)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	col.shape = shape
	add_child(col)

	player = get_tree().current_scene.find_child("Player", true, false)

	# Initial pop animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return

	var dist = global_position.distance_to(player.global_position)
	if dist < 800.0: # Magnet range for particles
		speed = min(speed + acceleration * delta, max_speed)
		var dir = global_position.direction_to(player.global_position)
		global_position += dir * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.dongu_parcaciklari += amount

		# Feedback
		var audio = AudioStreamPlayer2D.new()
		audio.pitch_scale = randf_range(1.8, 2.2)
		# Ses dosyası olmadığı için sessiz ama görsel feedback:

		var pop = CPUParticles2D.new()
		pop.emitting = false
		pop.one_shot = true
		pop.lifetime = 0.3
		pop.spread = 180.0
		pop.initial_velocity_min = 100.0
		pop.initial_velocity_max = 200.0
		pop.color = Color(0, 0.8, 1.0)
		get_tree().current_scene.add_child(pop)
		pop.global_position = global_position
		pop.emitting = true

		queue_free()
