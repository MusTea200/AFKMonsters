extends RigidBody2D
class_name Player

@export var move_force: float = 1000.0
@export var spring_damping: float = 1.0
@export var slingshot_multiplier: float = 2.0

# Store dictionary of { joint: Line2D } to manage visual ropes
var active_springs: Dictionary = {}

func _ready() -> void:
	# Ensure zero gravity for top-down view
	gravity_scale = 0.0
	# Add some damping so we don't slide forever
	linear_damp = 3.0

func _physics_process(delta: float) -> void:
	# WASD Movement
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

func _unhandled_input(event: InputEvent) -> void:
	# Mouse click logic
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_attach_spring(get_global_mouse_position())

	# Spacebar logic
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		if not event.echo:
			_release_slingshot()

func _try_attach_spring(click_pos: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = click_pos
	query.collide_with_bodies = true

	var result = space_state.intersect_point(query)
	for hit in result:
		var collider = hit["collider"]

		# Check if it's our new GrappleNode
		if collider is GrappleNode:
			var dist = global_position.distance_to(collider.global_position)
			# Only connect if within max_rope_length
			if dist <= collider.max_rope_length:
				_create_spring_joint(collider)
			break
		elif collider is StaticBody2D or collider is AnimatableBody2D or (collider is RigidBody2D and collider.freeze):
			# Fallback for normal static bodies (using default stiffness 20.0)
			_create_spring_joint(collider, 20.0)
			break

func _create_spring_joint(target_body: Node2D, override_stiffness: float = -1.0) -> void:
	var joint = DampedSpringJoint2D.new()
	get_tree().current_scene.add_child(joint)

	joint.global_position = global_position
	var dir = global_position.direction_to(target_body.global_position)
	joint.rotation = dir.angle() - PI / 2.0

	# Determine stiffness
	var applied_stiffness = 20.0
	if override_stiffness > 0:
		applied_stiffness = override_stiffness
	elif target_body is GrappleNode:
		applied_stiffness = target_body.stiffness

	joint.stiffness = applied_stiffness
	joint.damping = spring_damping

	var current_distance = global_position.distance_to(target_body.global_position)
	joint.length = current_distance
	joint.rest_length = 0.0

	joint.node_a = joint.get_path_to(self)
	joint.node_b = joint.get_path_to(target_body)

	# Create visual rope
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

				# Update visual position
				line.clear_points()
				line.add_point(global_position)
				line.add_point(target_node.global_position)

				# Change color based on tension (stretch vs initial length)
				var tension_ratio = min(1.0, stretch / max(1.0, joint.length))
				# Interpolate from White to Red based on tension
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

	var total_impulse = Vector2.ZERO

	for joint in active_springs:
		if is_instance_valid(joint):
			var target_node = joint.get_node_or_null(joint.node_b)
			if target_node:
				var dir = global_position.direction_to(target_node.global_position)
				var dist = global_position.distance_to(target_node.global_position)

				var stretch = max(0.0, dist - joint.rest_length)
				var force_magnitude = stretch * joint.stiffness

				total_impulse += dir * force_magnitude * slingshot_multiplier

			if is_instance_valid(active_springs[joint]):
				active_springs[joint].queue_free()
			joint.queue_free()

	active_springs.clear()

	if total_impulse.length() > 0:
		apply_central_impulse(total_impulse)
