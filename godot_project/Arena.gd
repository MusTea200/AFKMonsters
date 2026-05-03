extends Node2D

@export var arena_size: Vector2 = Vector2(4000, 4000)
@export var num_nodes: int = 15
@export var min_distance_between_nodes: float = 600.0
@export var enemy_spawn_rate: float = 3.0

var grapple_node_scene = preload("res://GrappleNode.tscn")
var enemy_scene = preload("res://Enemy.tscn")
var spawned_nodes: Array[Vector2] = []
var spawn_timer: Timer

func _ready() -> void:
	_spawn_nodes()
	_setup_enemy_spawner()

func _spawn_nodes() -> void:
	var attempts = 0
	var max_attempts = 1000

	while spawned_nodes.size() < num_nodes and attempts < max_attempts:
		attempts += 1
		# Random position within arena bounds (with some padding)
		var rand_x = randf_range(100, arena_size.x - 100)
		var rand_y = randf_range(100, arena_size.y - 100)
		var potential_pos = Vector2(rand_x, rand_y)

		# Check distance against existing nodes
		var is_valid = true
		for existing_pos in spawned_nodes:
			if potential_pos.distance_to(existing_pos) < min_distance_between_nodes:
				is_valid = false
				break

		if is_valid:
			_create_node_instance(potential_pos)
			spawned_nodes.append(potential_pos)

	print("Spawned ", spawned_nodes.size(), " nodes out of ", num_nodes, " requested.")

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
	# Spawn enemy at a random edge
	var edge = randi() % 4
	var spawn_pos = Vector2.ZERO

	# Small padding to ensure they spawn just outside or on the border
	var padding = 50.0

	match edge:
		0: # Top
			spawn_pos.x = randf_range(0, arena_size.x)
			spawn_pos.y = -padding
		1: # Bottom
			spawn_pos.x = randf_range(0, arena_size.x)
			spawn_pos.y = arena_size.y + padding
		2: # Left
			spawn_pos.x = -padding
			spawn_pos.y = randf_range(0, arena_size.y)
		3: # Right
			spawn_pos.x = arena_size.x + padding
			spawn_pos.y = randf_range(0, arena_size.y)

	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos
	add_child(enemy_instance)
