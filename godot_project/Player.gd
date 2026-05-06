extends RigidBody2D
class_name Player

@export var move_force: float = 1000.0
@export var max_speed: float = 1200.0


@export var max_health: float = 100.0
@export var grapple_radius: float = 600.0

var current_health: float
var active_springs: Dictionary = {}
var current_target_node: Node2D = null

# RPG Stats
@export var can_yenileme: float = 1.0
@export var hasar_azaltma: float = 0.0 # percentage (0.0 to 1.0)
@export var dikenli_deri: float = 0.0
@export var kacis_sansi: float = 0.0 # percentage (0.0 to 1.0)
@export var ip_uzunlugu: float = 600.0 # Replaces grapple_radius for physical length
@export var atis_hizi: float = 1.0 # Shots per second
@export var mermi_sayisi: int = 1
@export var delip_gecme: int = 0
@export var mermi_hasari: float = 25.0

var shoot_timer: float = 0.0
var bullet_scene = preload("res://Bullet.tscn")
var health_bar: ProgressBar
var balance_label: Label


# Combo System
var combo_multiplier: int = 1
var combo_timer: float = 0.0
var combo_speed_threshold: float = 800.0
var combo_drop_threshold: float = 300.0
var combo_label: Label

# Economy & Level
var exp: float = 0.0
var level: int = 1
var gold: float = 0.0
var next_level_exp: float = 100.0

var exp_bar: ProgressBar
var camera: Camera2D
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1

# Upgrades
var mass_multiplier: float = 1.0
var stiffness_multiplier: float = 1.0


# Reference to UI (You would typically inject this or autoload it)
var level_up_ui: LevelUpUI

func _ready() -> void:
	current_health = max_health
	gravity_scale = 0.0
	# Lower linear damp allows for more natural "Spider-Man" style swinging and gliding
	linear_damp = 1.0
	lock_rotation = true

	health_bar = get_tree().current_scene.find_child("PlayerHealthBar", true, false) as ProgressBar
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health



	# Find ExpBar and initialize
	exp_bar = get_tree().current_scene.find_child("ExpBar", true, false) as ProgressBar
	if is_instance_valid(exp_bar):
		exp_bar.max_value = next_level_exp
		exp_bar.value = exp

	# Find Camera2D
	for child in get_children():
		if child is Camera2D:
			camera = child
			break

	# Find ComboLabel
	combo_label = get_tree().current_scene.find_child("ComboLabel", true, false) as Label
	if is_instance_valid(combo_label):
		combo_label.text = ""
		combo_label.visible = false



	var ui_scene = preload("res://LevelUpUI.tscn")
	if ui_scene:
		level_up_ui = ui_scene.instantiate()
		add_child(level_up_ui)
		level_up_ui.upgrade_selected.connect(_apply_upgrade)

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()
	if input_vector.length() > 0:
		apply_central_force(input_vector * move_force)

	# Apply custom rope physics
	for node in active_springs.keys():
		if is_instance_valid(node):
			var dist = global_position.distance_to(node.global_position)
			if dist > ip_uzunlugu:
				var pull_dir = global_position.direction_to(node.global_position)
				# Spring force = k * x. 'stiffness' from node, default 20.
				var stretch = dist - ip_uzunlugu
				var force_mag = stretch * 20.0 * stiffness_multiplier
				apply_central_force(pull_dir * force_mag)
	_update_ropes()
	# Health Regen
	if current_health < max_health and current_health > 0:
		current_health += can_yenileme * delta
		current_health = min(current_health, max_health)
		if is_instance_valid(health_bar):
			health_bar.value = current_health


	# Auto Shooting
	shoot_timer += delta
	if shoot_timer >= (1.0 / atis_hizi):
		shoot_timer = 0.0
		_shoot_closest_enemy()

	_update_targeting()
	_update_combo(delta)
	queue_redraw()

# Limit the maximum velocity safely through physics integration
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.linear_velocity.length() > max_speed:
		state.linear_velocity = state.linear_velocity.limit_length(max_speed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_attach_spring(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_release_slingshot()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if is_instance_valid(camera):
				var new_zoom = clamp(camera.zoom.x + zoom_speed, min_zoom, max_zoom)
				camera.zoom = Vector2(new_zoom, new_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if is_instance_valid(camera):
				var new_zoom = clamp(camera.zoom.x - zoom_speed, min_zoom, max_zoom)
				camera.zoom = Vector2(new_zoom, new_zoom)

	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		if not event.echo:
			_release_slingshot()

func _try_attach_spring(click_pos: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = grapple_radius

	query.shape = circle_shape
	query.transform = global_transform # Shape centered on player
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query)

	var closest_node = null
	var closest_dist = INF

	for hit in results:
		var collider = hit["collider"]
		if collider is GrappleNode:
			var dist_to_mouse = collider.global_position.distance_to(click_pos)
			if dist_to_mouse < closest_dist:
				closest_dist = dist_to_mouse
				closest_node = collider

	if closest_node:
		closest_node.modulate = Color(2.0, 2.0, 2.0) # Bright white
		var dist_to_player = global_position.distance_to(closest_node.global_position)
		if dist_to_player <= closest_node.max_rope_length:
			_create_spring_joint(closest_node)
		else:
			_create_spring_joint(closest_node) # User requested auto-aim, we can probably attach even if slightly further, or just fallback to generic? Let's attach.
	else:
		# Fallback to direct point query for static bodies (walls) if we didn't find any GrappleNodes
		var pt_query = PhysicsPointQueryParameters2D.new()
		pt_query.position = click_pos
		pt_query.collide_with_bodies = true

		var pt_results = space_state.intersect_point(pt_query)
		for hit in pt_results:
			var collider = hit["collider"]
			if collider is StaticBody2D or collider is AnimatableBody2D or (collider is RigidBody2D and collider.freeze):
				_create_spring_joint(collider, 20.0)
				break
func _create_spring_joint(target_body: Node2D, override_stiffness: float = -1.0) -> void:
	if not active_springs.has(target_body):
		var line = Line2D.new()
		line.width = 4.0
		line.default_color = Color.WHITE
		get_tree().current_scene.add_child(line)
		active_springs[target_body] = line

		# Trigger effect if GrappleNode
		if target_body is GrappleNode:
			if target_body.has_method("trigger_effect"):
				target_body.trigger_effect(self)

func _update_ropes() -> void:
	var nodes_to_remove = []
	for node in active_springs:
		if is_instance_valid(node):
			var line = active_springs[node]
			if is_instance_valid(line):
				var dist = global_position.distance_to(node.global_position)
				var stretch = max(0.0, dist - ip_uzunlugu)

				line.clear_points()
				line.add_point(global_position)
				line.add_point(node.global_position)

				var tension_ratio = min(1.0, stretch / max(1.0, ip_uzunlugu * 0.5))
				line.default_color = Color.WHITE.lerp(Color.RED, tension_ratio)
		else:
			nodes_to_remove.append(node)

	for n in nodes_to_remove:
		if active_springs.has(n):
			if is_instance_valid(active_springs[n]):
				active_springs[n].queue_free()
			active_springs.erase(n)
func _release_slingshot() -> void:
	for node in active_springs:
		if is_instance_valid(active_springs[node]):
			active_springs[node].queue_free()
	active_springs.clear()
# Economy & Stats
func add_exp(amount: float) -> void:
	exp += amount
	if is_instance_valid(exp_bar):
		exp_bar.value = exp
	while exp >= next_level_exp:
		_level_up()

func add_gold(amount: float) -> void:
	gold += amount
	if is_instance_valid(balance_label):
		balance_label.text = "Gold: " + str(gold)

func _level_up() -> void:
	exp -= next_level_exp
	level += 1
	next_level_exp *= 1.5

	if is_instance_valid(exp_bar):
		exp_bar.max_value = next_level_exp
		exp_bar.value = exp

	if is_instance_valid(level_up_ui):
		level_up_ui.show_upgrades()

func _apply_upgrade(type: String) -> void:
	match type:
		"max_health":
			max_health += 20.0
			current_health += 20.0
			if is_instance_valid(health_bar):
				health_bar.max_value = max_health
				health_bar.value = current_health

		"regen":
			can_yenileme += 0.5
		"armor":
			hasar_azaltma = min(hasar_azaltma + 0.05, 0.8) # Max 80%
		"thorns":
			dikenli_deri += 5.0
		"dodge":
			kacis_sansi = min(kacis_sansi + 0.05, 0.6) # Max 60%
		"rope_len":
			ip_uzunlugu += 100.0
		"fire_rate":
			atis_hizi += 0.5
		"bullet_count":
			mermi_sayisi += 1
		"piercing":
			delip_gecme += 1
		"damage":
			mermi_hasari += 10.0
		# Fallbacks for old upgrades just in case
		"mass":
			mass_multiplier += 0.5
			mass = 1.0 * mass_multiplier
		"stiffness":
			stiffness_multiplier += 0.5

# Combat
func take_damage(amount: float) -> void:
	if randf() < kacis_sansi:
		# Dodged!
		_show_floating_text("Dodge!", Color.AQUA)
		return

	var actual_damage = amount * (1.0 - hasar_azaltma)
	current_health -= actual_damage

	if is_instance_valid(health_bar):
		health_bar.value = current_health


	if current_health <= 0:
		print("Player died!")

func _show_floating_text(text_str: String, color: Color) -> void:
	var label = Label.new()
	label.text = text_str
	label.modulate = color
	var scene_root = get_tree().current_scene
	scene_root.add_child(label)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -30)
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func bounce_back(dir: Vector2, force: float) -> void:
	linear_velocity = Vector2.ZERO
	apply_central_impulse(dir * force)

func _draw() -> void:
	# Draw dashed circle for grapple radius
	var points = 64
	var dash_length = 10.0
	var space_length = 10.0
	var current_angle = 0.0
	var total_circumference = 2.0 * PI * grapple_radius
	var num_segments = int(total_circumference / (dash_length + space_length))
	var angle_step = (2.0 * PI) / num_segments

	for i in range(num_segments):
		var start_angle = current_angle
		var end_angle = current_angle + (dash_length / total_circumference) * 2.0 * PI

		# Local coords since draw is local
		var p1 = Vector2(cos(start_angle), sin(start_angle)) * grapple_radius
		var p2 = Vector2(cos(end_angle), sin(end_angle)) * grapple_radius

		draw_line(p1, p2, Color(1, 1, 1, 0.5), 2.0)

		current_angle += angle_step


func _update_targeting() -> void:
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = grapple_radius

	query.shape = circle_shape
	query.transform = global_transform
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query)

	var closest_node = null
	var closest_dist = INF

	for hit in results:
		var collider = hit["collider"]
		if collider is GrappleNode:
			var dist_to_mouse = collider.global_position.distance_to(mouse_pos)
			if dist_to_mouse < closest_dist:
				closest_dist = dist_to_mouse
				closest_node = collider

	if current_target_node != closest_node:
		if is_instance_valid(current_target_node):
			current_target_node.modulate = Color.WHITE
			current_target_node.scale = Vector2.ONE

		current_target_node = closest_node

		if is_instance_valid(current_target_node):
			current_target_node.modulate = Color(1.0, 1.0, 0.0) # Yellow
			current_target_node.scale = Vector2(1.2, 1.2)

func _update_combo(delta: float) -> void:
	var speed = linear_velocity.length()
	if speed > combo_speed_threshold:
		combo_timer += delta
		if combo_timer >= 0.5:
			combo_timer -= 0.5
			combo_multiplier += 1
			_animate_combo_label()
	elif speed < combo_drop_threshold:
		if combo_multiplier > 1:
			combo_multiplier = 1
			combo_timer = 0.0
			_animate_combo_label()

func _animate_combo_label() -> void:
	if not is_instance_valid(combo_label):
		return

	if combo_multiplier > 1:
		combo_label.text = "x" + str(combo_multiplier)
		combo_label.visible = true
	else:
		combo_label.text = ""
		combo_label.visible = false
		return

	var tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _shoot_closest_enemy() -> void:
	if not bullet_scene:
		return

	var enemies = get_tree().get_nodes_in_group("enemies") # Wait, we don't have enemies group. We can find by class.
	var closest_enemy = null
	var closest_dist = INF
	var scene_root = get_tree().current_scene

	for child in scene_root.get_children():
		if child is Enemy:
			var dist = global_position.distance_to(child.global_position)
			if dist < 1500.0: # Range limit
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy = child

	if closest_enemy:
		var base_dir = global_position.direction_to(closest_enemy.global_position)
		var spread_angle = deg_to_rad(15.0)

		var start_angle = -spread_angle * (mermi_sayisi - 1) / 2.0
		for i in range(mermi_sayisi):
			var current_angle = start_angle + (spread_angle * i if mermi_sayisi > 1 else 0.0)
			var final_dir = base_dir.rotated(current_angle)

			var bullet = bullet_scene.instantiate() as Bullet
			bullet.global_position = global_position
			bullet.direction = final_dir
			bullet.damage = mermi_hasari * combo_multiplier # Apply combo to bullet!
			bullet.pierce_count = delip_gecme
			scene_root.add_child(bullet)
