extends RigidBody2D
class_name Player

@export var move_force: float = 1000.0
@export var max_speed: float = 1200.0
@export var spring_damping: float = 0.5 # Lower damping for smoother swinging
@export var slingshot_multiplier: float = 1.0 # Reduced since we rely on actual spring physics now
@export var max_health: float = 100.0
@export var grapple_radius: float = 600.0

var current_health: float
var active_springs: Dictionary = {}
var current_target_node: Node2D = null

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
var orbital_scene = preload("res://Orbital.tscn")

# Reference to UI (You would typically inject this or autoload it)
var level_up_ui: LevelUpUI

func _ready() -> void:
	current_health = max_health
	gravity_scale = 0.0
	# Lower linear damp allows for more natural "Spider-Man" style swinging and gliding
	linear_damp = 1.0
	lock_rotation = true

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

	_update_ropes()
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
	var joint = DampedSpringJoint2D.new()
	get_tree().current_scene.add_child(joint)

	joint.global_position = global_position
	var dir = global_position.direction_to(target_body.global_position)
	joint.rotation = dir.angle() - PI / 2.0

	var applied_stiffness = 20.0
	if override_stiffness > 0:
		applied_stiffness = override_stiffness
	elif target_body is GrappleNode:
		applied_stiffness = target_body.stiffness

	joint.stiffness = applied_stiffness * stiffness_multiplier
	joint.damping = spring_damping

	var current_distance = global_position.distance_to(target_body.global_position)
	joint.length = current_distance
	joint.rest_length = 0.0

	joint.node_a = joint.get_path_to(self)
	joint.node_b = joint.get_path_to(target_body)

	var line = Line2D.new()
	line.width = 4.0
	line.default_color = Color.WHITE
	get_tree().current_scene.add_child(line)

	active_springs[joint] = line

func _update_ropes() -> void:
	var joints_to_remove = []
	for joint in active_springs:
		if is_instance_valid(joint):
			var line = active_springs[joint]
			var target_node = joint.get_node_or_null(joint.node_b)
			if target_node and is_instance_valid(line):
				var dist = global_position.distance_to(target_node.global_position)
				var stretch = max(0.0, dist - joint.rest_length)

				line.clear_points()
				line.add_point(global_position)
				line.add_point(target_node.global_position)

				var tension_ratio = min(1.0, stretch / max(1.0, joint.length))
				line.default_color = Color.WHITE.lerp(Color.RED, tension_ratio)
		else:
			joints_to_remove.append(joint)

	for j in joints_to_remove:
		if active_springs.has(j):
			if is_instance_valid(active_springs[j]):
				active_springs[j].queue_free()
			active_springs.erase(j)

func _release_slingshot() -> void:
	if active_springs.is_empty():
		return

	# Just destroy the joints. The physics engine has already built up velocity
	# due to the springs pulling the player over time.
	for joint in active_springs:
		if is_instance_valid(joint):
			if is_instance_valid(active_springs[joint]):
				active_springs[joint].queue_free()
			joint.queue_free()

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
		"mass":
			mass_multiplier += 0.5
			mass = 1.0 * mass_multiplier
		"stiffness":
			stiffness_multiplier += 0.5
		"orbital":
			if orbital_scene:
				var orb = orbital_scene.instantiate()
				add_child(orb)
				_rearrange_orbitals()

func _rearrange_orbitals() -> void:
	var orbitals = []
	for child in get_children():
		if child is OrbitalPivot:
			orbitals.append(child)

	var count = orbitals.size()
	if count == 0:
		return

	var angle_step = (PI * 2.0) / float(count)
	for i in range(count):
		orbitals[i].rotation = angle_step * i

# Combat
func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		print("Player died!")

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
