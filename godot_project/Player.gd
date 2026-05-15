extends RigidBody2D
class_name Player

@export var move_force: float = 1000.0
@export var max_speed: float = 1200.0

@export var max_health: float = 100.0
@export var grapple_radius: float = 600.0

var current_health: float
var active_springs: Dictionary = {}
var current_target_node: Node2D = null

@export var ip_uzunlugu: float = 600.0
@export var bullet_scene: PackedScene
var health_bar: ProgressBar

var camera: Camera2D
var is_stunned: bool = false
var is_jammed: bool = false
var shield_charges: int = 0
var orbit_count: int = 0
var orbit_radius: float = 120.0
var orbital_angle_offset: float = 0.0

var orbitals: Array = []

var stun_icon: Sprite2D
var momentum_label: Label
var speed_lines: ColorRect

@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 0.1

var mass_multiplier: float = 1.0
var stiffness_multiplier: float = 1.0

var level_up_ui: LevelUpUI
var economy_comp: EconomyComponent
var combat_comp: CombatComponent

func _ready() -> void:
	max_health = Global.perm_max_health
	max_speed = Global.base_speed
	shield_charges = Global.shield_capacity
	orbit_count = Global.orbital_count
	_create_orbitals()
	current_health = max_health
	Global.start_run()
	gravity_scale = 0.0
	linear_damp = 1.0
	lock_rotation = true
	

	var canvas = get_tree().current_scene.find_child("CanvasLayer", true, false)
	if canvas:
		momentum_label = canvas.find_child("MomentumLabel", true, false) as Label
		speed_lines = canvas.find_child("SpeedLines", true, false) as ColorRect

	health_bar = get_tree().current_scene.find_child("PlayerHealthBar", true, false) as ProgressBar
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	var exp_bar = get_tree().current_scene.find_child("ExpBar", true, false) as ProgressBar

	for child in get_children():
		if child is Camera2D:
			camera = child
			break
			
	var ui_scene = preload("res://LevelUpUI.tscn")
	if ui_scene:
		level_up_ui = ui_scene.instantiate()
		add_child(level_up_ui)

	# Components Initialization
	economy_comp = EconomyComponent.new()
	economy_comp.name = "EconomyComponent"
	add_child(economy_comp)

	combat_comp = CombatComponent.new()
	combat_comp.name = "CombatComponent"
	add_child(combat_comp)

	economy_comp.initialize(self, exp_bar, level_up_ui)
	combat_comp.initialize(self)

	if is_instance_valid(level_up_ui):
		level_up_ui.upgrade_selected.connect(economy_comp.apply_upgrade)

func _physics_process(delta: float) -> void:
	if is_stunned:
		linear_velocity = linear_velocity.move_toward(Vector2.ZERO, 50.0 * delta)
		if stun_icon:
			stun_icon.rotation += 5.0 * delta
		return

	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector.length() > 0:
		apply_central_force(input_vector * move_force)

	# Apply custom rope physics
	for node in active_springs.keys():
		if is_instance_valid(node):
			if node is GrappleNode and node.node_type == GrappleNode.NodeType.VORTEX:
				# VORTEX: no dampening, continuous high pull
				var pull_dir = global_position.direction_to(node.global_position)
				apply_central_force(pull_dir * 10000.0) # High constant pull
			else:
				var dist = global_position.distance_to(node.global_position)
				if dist > ip_uzunlugu:
					var pull_dir = global_position.direction_to(node.global_position)
					var stretch = dist - ip_uzunlugu

					if node is GrappleNode and node.node_type == GrappleNode.NodeType.RIGID:
						# RIGID: act like a steel rod
						var node_stiffness = node.stiffness if node is GrappleNode else 20.0
						var force_mag = stretch * node_stiffness * stiffness_multiplier
						apply_central_force(pull_dir * force_mag)
					else:
						var node_stiffness = node.stiffness if node is GrappleNode else 20.0
						var force_mag = stretch * node_stiffness * stiffness_multiplier
						apply_central_force(pull_dir * force_mag)
	
	_update_ropes()
	combat_comp.process_combat(delta)

	# Omni-Input Gamepad Grapple Aim
	if Global.current_input_type == Global.InputType.JOYPAD:
		var aim_dir = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if aim_dir.length() > 0.2:
			_try_attach_spring_dir(aim_dir.normalized())
		else:
			_release_slingshot() # Release if analog stick returns to center
	_update_targeting()
	# Update Orbitals Geometry
	if orbitals.size() > 0:
		var speed_factor = linear_velocity.length() / max_speed
		var rot_speed = 2.0 + speed_factor * 8.0 # Faster when moving
		orbital_angle_offset += rot_speed * delta

		for i in range(orbitals.size()):
			var angle = orbital_angle_offset + (i * 2.0 * PI / orbitals.size())
			orbitals[i].global_position = global_position + Vector2(cos(angle), sin(angle)) * orbit_radius

	queue_redraw()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.linear_velocity.length() > max_speed:
		state.linear_velocity = state.linear_velocity.limit_length(max_speed)

	# RIGID Logic execution in _integrate_forces for better physics stability
	for node in active_springs.keys():
		if is_instance_valid(node) and node is GrappleNode and node.node_type == GrappleNode.NodeType.RIGID:
			var dist = global_position.distance_to(node.global_position)
			if dist > ip_uzunlugu:
				var pull_dir = global_position.direction_to(node.global_position)
				# Cancel outward velocity (projection of velocity onto outward direction)
				var outward_vel = state.linear_velocity.dot(-pull_dir)
				if outward_vel > 0:
					state.linear_velocity += pull_dir * outward_vel

func _unhandled_input(event: InputEvent) -> void:
	if is_stunned: return

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
	query.transform = global_transform
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
		# Removed outside scale/modulate alteration
		_create_spring_joint(closest_node)
	else:
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

# Pass-through for signals / economy logic
func add_exp(amount: float) -> void:
	economy_comp.add_exp(amount)

func add_gold(amount: float) -> void:
	economy_comp.add_gold(amount)

# Pass-through for combat
func take_damage(amount: float) -> void:
	combat_comp.take_damage(amount)

func bounce_back(dir: Vector2, force: float) -> void:
	linear_velocity = Vector2.ZERO
	apply_central_impulse(dir * force)

func _draw() -> void:
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
		var p1 = Vector2(cos(start_angle), sin(start_angle)) * grapple_radius
		var p2 = Vector2(cos(end_angle), sin(end_angle)) * grapple_radius
		draw_line(p1, p2, Color(1, 1, 1, 0.5), 2.0)
		current_angle += angle_step

func _update_targeting() -> void:
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = grapple_radius # 600 birimlik menzil
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
				
	# HEDEF DEĞİŞTİĞİNDE GÖRSEL EFEKTİ YÖNET
	if current_target_node != closest_node:
		# 1. Eski hedefin büyümesini geri al
		if is_instance_valid(current_target_node):
			# Eğer düğümün kendi original_scale değişkeni varsa onu kullan, yoksa 1.0 yap
			var old_scale = current_target_node.get("original_scale") if current_target_node.has_method("get") and current_target_node.get("original_scale") != null else Vector2.ONE
			current_target_node.scale = old_scale
			current_target_node.modulate.v = 1.0 # Parlaklığı normale döndür

		current_target_node = closest_node # Yeni hedefi kaydet

		# 2. Yeni hedefi büyüt ve parlat
		if is_instance_valid(current_target_node):
			var new_scale = current_target_node.get("original_scale") if current_target_node.has_method("get") and current_target_node.get("original_scale") != null else Vector2.ONE
			current_target_node.scale = new_scale * 1.3 # %30 büyüt
			current_target_node.modulate.v = 1.5 # Daha parlak yap (HDR/Glow efekti için)

func apply_stun(duration: float) -> void:
	if is_stunned: return
	is_stunned = true
	_release_slingshot()

	# Create visual stun effect
	stun_icon = Sprite2D.new()
	# Fallback to godot icon if no special stun icon exists
	stun_icon.texture = load("res://icon.svg")
	stun_icon.scale = Vector2(0.3, 0.3)
	stun_icon.modulate = Color(1.0, 1.0, 0.0, 0.8)
	stun_icon.position = Vector2(0, -60)
	add_child(stun_icon)

	await get_tree().create_timer(duration).timeout
	is_stunned = false
	if is_instance_valid(stun_icon):
		stun_icon.queue_free()

func _create_orbitals() -> void:
	for i in range(orbit_count):
		var orb = Area2D.new()
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 15.0
		col.shape = shape
		orb.add_child(col)

		var mesh = MeshInstance2D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(20, 20)
		mesh.mesh = quad
		mesh.modulate = Color(0.0, 1.0, 1.0, 0.8) # Cyan Neon
		orb.add_child(mesh)

		orb.area_entered.connect(self._on_orbital_hit.bind(orb))
		get_tree().current_scene.call_deferred("add_child", orb)
		orbitals.append(orb)

func _on_orbital_hit(area: Area2D, orb: Area2D) -> void:
	if area is Enemy:
		area._take_damage(combat_comp.mermi_hasari * 2.0)

		# Juice: Sparks
		var sparks = CPUParticles2D.new()
		sparks.emitting = false
		sparks.one_shot = true
		sparks.lifetime = 0.3
		sparks.spread = 180.0
		sparks.initial_velocity_min = 100.0
		sparks.initial_velocity_max = 200.0
		sparks.color = Color.CYAN
		get_tree().current_scene.add_child(sparks)
		sparks.global_position = orb.global_position
		sparks.emitting = true

func _try_attach_spring_dir(dir: Vector2) -> void:
	var target_pos = global_position + dir * grapple_radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = grapple_radius

	query.shape = circle_shape
	query.transform = global_transform
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query)
	var closest_node = null
	var closest_angle_diff = INF

	for hit in results:
		var collider = hit["collider"]
		if collider is GrappleNode:
			var node_dir = global_position.direction_to(collider.global_position)
			var angle_diff = abs(dir.angle_to(node_dir))
			# If within 45 degrees of aiming stick
			if angle_diff < deg_to_rad(45.0) and angle_diff < closest_angle_diff:
				closest_angle_diff = angle_diff
				closest_node = collider

	if closest_node:
		_create_spring_joint(closest_node)
