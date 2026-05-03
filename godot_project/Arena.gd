extends Node2D

@export var arena_size: Vector2 = Vector2(4000, 4000)
@export var num_nodes: int = 15
@export var min_distance_between_nodes: float = 600.0

var grapple_node_scene = preload("res://GrappleNode.tscn")
var spawned_nodes: Array[Vector2] = []

func _ready() -> void:
	_spawn_nodes()

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
