extends Area2D
class_name Enemy

@export var move_speed: float = 150.0
@export var base_mass: float = 1.0
@export var velocity_threshold: float = 800.0 # Pierce threshold
@export var damage_amount: float = 20.0
@export var bounce_force: float = 1500.0
@export var max_health: float = 100.0

var current_health: float
var player_node: Player
var coin_scene = preload("res://Coin.tscn")
var progress_bar: ProgressBar

# Juice Variables
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0
var audio_player: AudioStreamPlayer2D
var is_boss: bool = false
var poison_pool_scene = preload("res://Redzone.gd")
var poison_timer: float = 0.0
enum EnemyType { CIRCLE, TRIANGLE_RANGED, SQUARE_GHOST, PENTAGON_TANK, HEXAGON_POISON, OCTAGON_GRAVITY }
var type: EnemyType = EnemyType.CIRCLE

var ghost_timer: float = 0.0
var is_ghosting: bool = false
var shoot_timer: float = 0.0

var jammer_visual: ColorRect


func _ready() -> void:
	add_to_group("enemies")
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	current_health = max_health
	# Randomize Type
	if not is_boss:
		var rand_val = randf()
		if rand_val < 0.2:
			type = EnemyType.TRIANGLE_RANGED
			modulate = Color.ORANGE
		elif rand_val < 0.4:
			type = EnemyType.SQUARE_GHOST
			modulate = Color.PURPLE



	# Attempt to find the user's manually added ProgressBar named HealthBar
	if is_boss:
		jammer_visual = ColorRect.new()
		jammer_visual.color = Color(0.8, 0, 0, 0.2)
		jammer_visual.custom_minimum_size = Vector2(2000, 2000)
		jammer_visual.position = Vector2(-1000, -1000)
		jammer_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(jammer_visual)

	progress_bar = find_child("HealthBar", true, false) as ProgressBar
	if progress_bar:
		progress_bar.max_value = max_health
		progress_bar.value = current_health

	var scene_nodes = get_tree().current_scene.get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var movement = Vector2.ZERO
	# Kuzeye bakan polygon'u ilerledigi yone dondur
	if movement != Vector2.ZERO and not is_boss:
		rotation = movement.angle() + PI/2.0 # Polygon is pointing north (up), so angle + 90 deg
	if is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)
		var dir = global_position.direction_to(player_node.global_position)

		# Roulette Universe Movement modifier
		if Global.roulette_universe_unlocked:
			# Lissajous / Chaotic Elliptical approach
			var t = Time.get_ticks_msec() * 0.003
			var lissajous_offset = Vector2(sin(4.0 * t), sin(3.0 * t)) * 1.5
			var tangent = Vector2(-dir.y, dir.x)
			# LERP ile sapmayı yumuşatarak sarsıntıyı ve kilitlenmeyi engelle
			var chaotic_dir = (dir + tangent * lissajous_offset.x * 2.0 + dir * lissajous_offset.y).normalized()
			dir = dir.lerp(chaotic_dir, 0.5).normalized()

		match type:
			EnemyType.CIRCLE:
				movement = dir * move_speed * delta
			EnemyType.TRIANGLE_RANGED:
				if dist > 400.0:
					movement = dir * move_speed * delta
				else:
					# Stay away and shoot
					movement = -dir * move_speed * 0.5 * delta
					shoot_timer += delta
					if shoot_timer > 2.0:
						shoot_timer = 0.0
						_shoot_plasma(dir)
			EnemyType.PENTAGON_TANK:
				movement = dir * move_speed * 0.7 * delta
			EnemyType.HEXAGON_POISON:
				movement = dir * move_speed * 0.9 * delta
				poison_timer += delta
				if poison_timer >= 1.0:
					poison_timer = 0.0
					if poison_pool_scene:
						var pool = poison_pool_scene.instantiate()
						pool.global_position = global_position
						pool.scale = Vector2(0.5, 0.5) # Smaller than normal redzone
						get_tree().current_scene.add_child(pool)
			EnemyType.OCTAGON_GRAVITY:
				movement = dir * move_speed * 0.8 * delta
				if is_instance_valid(player_node):
					var dist_to_player = global_position.distance_to(player_node.global_position)
					if dist_to_player < 500.0:
						var pull_dir = player_node.global_position.direction_to(global_position)
						player_node.apply_central_force(pull_dir * 1500.0)
			EnemyType.SQUARE_GHOST:
				ghost_timer += delta
				if ghost_timer > 3.0:
					ghost_timer = 0.0
					is_ghosting = !is_ghosting
					modulate.a = 0.3 if is_ghosting else 1.0

				if not is_ghosting:
					movement = dir * move_speed * delta

	if knockback_velocity.length() > 0:
		movement += knockback_velocity * delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)

	global_position += movement

	if is_boss and is_instance_valid(player_node):
		if global_position.distance_to(player_node.global_position) < 1000.0:
			player_node.is_jammed = true
			if is_instance_valid(jammer_visual): jammer_visual.visible = true
		else:
			player_node.is_jammed = false
			if is_instance_valid(jammer_visual): jammer_visual.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player_vel = body.linear_velocity.length()

		# Kinetic Energy: Ek = 0.5 * m * v^2
		var current_player_mass = body.mass
		var player_kinetic_energy = 0.5 * current_player_mass * pow(player_vel, 2)
		
		# Apply combo multiplier if player has it
		if "combo_multiplier" in body:
			player_kinetic_energy *= body.combo_multiplier
			
		var threshold_kinetic_energy = 0.5 * current_player_mass * pow(velocity_threshold, 2)

		if player_kinetic_energy >= threshold_kinetic_energy:
			# Fast player = massive damage equivalent to their kinetic energy
			take_damage(player_kinetic_energy)
		else:
			# Phase Shield check: If player has shield, don't bounce them, let them pass
			if "shield_charges" in body and body.shield_charges > 0:
				body.take_damage(damage_amount) # This will consume a charge but NOT bounce
			else:
				# Slow player = player takes damage and bounces
				body.take_damage(damage_amount)
				
				# Check for Thorns
				if "dikenli_deri" in body and body.dikenli_deri > 0:
					take_damage(body.dikenli_deri)

				var bounce_dir = global_position.direction_to(body.global_position)
				body.bounce_back(bounce_dir, bounce_force)

func take_damage(amount: float, knock_dir: Vector2 = Vector2.ZERO) -> void:
	if type == EnemyType.SQUARE_GHOST and is_ghosting:
		return # Immune while ghosting
	if type == EnemyType.PENTAGON_TANK:
		# Tank takes half damage from bullets, but 1.5x from momentum
		if knock_dir != Vector2.ZERO:
			amount *= 1.5
		else:
			amount *= 0.5

	current_health -= amount
	if is_boss:
		HitstopManager.hitstop(0.02, 0.2)

	if CameraShake:
		CameraShake.add_trauma(0.1)
	_show_floating_damage(amount)

	# Knockback
	if knock_dir != Vector2.ZERO:
		knockback_velocity = knock_dir * 1500.0

	# Hit Flash Tween
	var tween = create_tween()
	# Micro-shrink juice
	tween.parallel().tween_property(self, "scale", scale * 0.8, 0.05)
	tween.tween_property(self, "scale", scale, 0.1).set_trans(Tween.TRANS_BOUNCE)
	modulate = Color(10, 10, 10, 1)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	# Play Audio
	audio_player.pitch_scale = randf_range(0.85, 1.15)
	audio_player.play()

	if is_instance_valid(progress_bar):
		progress_bar.value = current_health

	if current_health <= 0:
		if type == EnemyType.OCTAGON_GRAVITY:
			# Spawn 4 triangles
			for i in range(4):
				var tri = load("res://enemy_triangle.tscn").instantiate()
				tri.global_position = global_position + Vector2(cos(i * PI/2), sin(i * PI/2)) * 50
				get_tree().current_scene.call_deferred("add_child", tri)
		_die(knock_dir)

func _show_floating_damage(amount: float) -> void:
	var label = Label.new()
	# Format to show an integer if possible, or 1 decimal place
	label.text = "-" + str(round(amount))
	label.modulate = Color(1.0, 0.2, 0.2, 1.0) # Red color

	# Add the label to the root scene so it doesn't move/delete with the enemy
	var scene_root = get_tree().current_scene
	scene_root.add_child(label)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -30)

	var tween = label.create_tween()
	# Animate position up
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Animate alpha to fade out at the same time
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)

	# Queue free after animation completes
	tween.tween_callback(label.queue_free)

func _die(knock_dir: Vector2 = Vector2.ZERO) -> void:

	# --- Loop Particle Economy ---
	var p = get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p) and p.get("active_redzone_count") != null:
		var redzone_multiplier = p.active_redzone_count
		var drop_chance = 0.2 + (Global.particle_drop_chance_level * 0.1)
		var base_amount = 1 + Global.particle_drop_amount_level

		var should_drop = false
		var final_amount = 0

		if redzone_multiplier > 0:
			# 100% drop in redzone, multiplied by layers
			should_drop = true
			final_amount = base_amount * redzone_multiplier
		else:
			# Chance outside redzone
			if randf() < drop_chance:
				should_drop = true
				final_amount = base_amount

		if should_drop:
			var particle_scene = load("res://LoopParticle.gd")
			if particle_scene:
				var particle = Area2D.new()
				particle.set_script(particle_scene)
				particle.amount = final_amount
				particle.global_position = global_position
				get_tree().current_scene.call_deferred("add_child", particle)
	# -----------------------------
	Global.current_run_kills += 1

	HitstopManager.hitstop(0.05, 0.1)

	if is_boss and is_instance_valid(player_node):
		player_node.is_jammed = false

	CameraShake.add_trauma(0.4)

	_spawn_death_particles(knock_dir)

	# Direct EXP
	if is_instance_valid(player_node):
		player_node.add_exp(35.0) # Base exp
		
	_spawn_coin()
	queue_free()

func _spawn_death_particles(dir: Vector2) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.spread = 45.0
	particles.initial_velocity_min = 200.0
	particles.initial_velocity_max = 400.0
	particles.direction = dir if dir != Vector2.ZERO else Vector2(0, -1)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color(1.0, 0.2, 0.2, 1.0)

	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true

	var timer = Timer.new()
	timer.wait_time = particles.lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)

func _spawn_coin() -> void:
	if coin_scene:
		var coin = coin_scene.instantiate() as Coin
		coin.global_position = global_position
		# Randomize value maybe
		if randf() < 0.2:
			coin.value = 5.0
			coin.modulate = Color.GOLD
		else:
			coin.value = 1.0
		get_tree().current_scene.call_deferred("add_child", coin)

func _shoot_plasma(dir: Vector2) -> void:
	var plasma = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	plasma.add_child(col)

	var mesh = MeshInstance2D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(20, 20)
	mesh.mesh = quad
	mesh.modulate = Color.ORANGE
	plasma.add_child(mesh)

	plasma.global_position = global_position
	get_tree().current_scene.add_child(plasma)

	# Basic projectile movement via tween since we don't have a dedicated enemy bullet script
	var tw = create_tween()
	tw.tween_property(plasma, "global_position", plasma.global_position + dir * 1000.0, 2.0)
	tw.tween_callback(plasma.queue_free)

	plasma.body_entered.connect(func(body):
		if body is Player or body.name == "Player":
			body.take_damage(damage_amount)
			plasma.queue_free()
	)
