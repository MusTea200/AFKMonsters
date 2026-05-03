extends RigidBody2D
class_name Player

@export var move_force: float = 1000.0
@export var spring_stiffness: float = 20.0
@export var spring_damping: float = 1.0
@export var slingshot_multiplier: float = 2.0

var active_springs: Array[DampedSpringJoint2D] = []

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

func _unhandled_input(event: InputEvent) -> void:
	# Mouse click logic
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_attach_spring(get_global_mouse_position())

	# Spacebar logic
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		if not event.echo:
			_release_slingshot()

func _try_attach_spring(click_pos: Vector2) -> void:
	# Perform a point query to find what we clicked
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = click_pos
	query.collide_with_bodies = true

	var result = space_state.intersect_point(query)
	for hit in result:
		var collider = hit["collider"]
		# Only attach to static or immovable bodies
		if collider is StaticBody2D or collider is AnimatableBody2D or (collider is RigidBody2D and collider.freeze):
			_create_spring_joint(collider)
			break

func _create_spring_joint(target_body: Node2D) -> void:
	var joint = DampedSpringJoint2D.new()

	# Add to the tree first before setting global transform properties
	get_tree().current_scene.add_child(joint)

	# Fix for Joint Anchors:
	# Anchor A (local Y=0) goes on the player
	joint.global_position = global_position

	# Anchor B depends on the length and the Y rotation axis
	var dir = global_position.direction_to(target_body.global_position)
	joint.rotation = dir.angle() - PI / 2.0

	joint.stiffness = spring_stiffness
	joint.damping = spring_damping

	var current_distance = global_position.distance_to(target_body.global_position)
	joint.length = current_distance
	joint.rest_length = 0.0 # Pulls towards the anchor

	# Assign node paths relative to the joint
	joint.node_a = joint.get_path_to(self)
	joint.node_b = joint.get_path_to(target_body)

	active_springs.append(joint)

func _release_slingshot() -> void:
	if active_springs.is_empty():
		return

	var total_impulse = Vector2.ZERO

	for joint in active_springs:
		if is_instance_valid(joint):
			var target_node = joint.get_node_or_null(joint.node_b)
			if target_node:
				# Calculate slingshot force (potential energy)
				var dir = global_position.direction_to(target_node.global_position)
				var dist = global_position.distance_to(target_node.global_position)

				# F = k * x (Hooke's law). x is stretch distance.
				var stretch = max(0.0, dist - joint.rest_length)
				var force_magnitude = stretch * joint.stiffness

				total_impulse += dir * force_magnitude * slingshot_multiplier

			# Delete the spring
			joint.queue_free()

	active_springs.clear()

	# Apply the accumulated slingshot impulse
	if total_impulse.length() > 0:
		apply_central_impulse(total_impulse)
