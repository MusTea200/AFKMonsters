extends Node2D

@export var min_distance_between_nodes: float = 600.0
@export var enemy_spawn_rate: float = 3.0
@export var spawn_radius: float = 1500.0
@export var cull_radius: float = 2500.0
@export var max_nodes_in_world: int = 30

var grapple_node_scene = preload("res://GrappleNode.tscn")
var enemy_scene = preload("res://Enemy.tscn")
var spawn_timer: Timer

var player_node: Player

func _ready() -> void:
	# Find player
	var scene_nodes = get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break

	_setup_enemy_spawner()
	_initial_node_spawn()

func _process(delta: float) -> void:
	if not is_instance_valid(player_node):
		return

	_cull_distant_objects()
	_maintain_node_count()

func _initial_node_spawn() -> void:
	if not is_instance_valid(player_node):
		return

	var player_pos = player_node.global_position
	for i in range(max_nodes_in_world):
		_try_spawn_node_around(player_pos, 0, spawn_radius)

func _maintain_node_count() -> void:
	if not is_instance_valid(player_node):
		return

	var current_nodes = 0
	for child in get_children():
		if child is GrappleNode:
			current_nodes += 1

	if current_nodes < max_nodes_in_world:
		# Spawn new nodes just outside the immediate view, up to spawn_radius
		_try_spawn_node_around(player_node.global_position, spawn_radius * 0.8, spawn_radius)

func _try_spawn_node_around(center: Vector2, min_rad: float, max_rad: float) -> void:
	var angle = randf() * 2.0 * PI
	var dist = randf_range(min_rad, max_rad)
	var potential_pos = center + Vector2(cos(angle), sin(angle)) * dist

	# Check distance against existing nodes
	var is_valid = true
	for child in get_children():
		if child is GrappleNode:
			if potential_pos.distance_to(child.global_position) < min_distance_between_nodes:
				is_valid = false
				break

	if is_valid:
		_create_node_instance(potential_pos)

func _create_node_instance(pos: Vector2) -> void:
	var node_instance = grapple_node_scene.instantiate() as GrappleNode
	node_instance.global_position = pos

	# Randomize rarity based on some weights
	var rand_val = randf()
	if rand_val < 0.6:
		node_instance.rarity = GrappleNode.Rarity.WHITE # 60% chance
	elif rand_val < 0.9:
		node_instance.rarity = GrappleNode.Rarity.BLUE # 30% chance
	else:
		node_instance.rarity = GrappleNode.Rarity.PURPLE # 10% chance

	add_child(node_instance)

func _setup_enemy_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player_node):
		return

	# Spawn enemy at a random angle at spawn_radius
	var angle = randf() * 2.0 * PI
	var spawn_pos = player_node.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos
	add_child(enemy_instance)

func _cull_distant_objects() -> void:
	var player_pos = player_node.global_position

	for child in get_children():
		if child is GrappleNode or child is Enemy or child is Drop:
			if child.global_position.distance_to(player_pos) > cull_radius:
				child.queue_free()
