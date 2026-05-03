extends Area2D
class_name Enemy

@export var move_speed: float = 150.0
@export var mass: float = 1.0
@export var player_mass: float = 1.0 # Approximated player mass for Ek
@export var velocity_threshold: float = 800.0 # Pierce threshold
@export var damage_amount: float = 20.0
@export var bounce_force: float = 1500.0

var player_node: Player

func _ready() -> void:
	# Find player safely (In a real game, you might use Groups or signals)
	var scene_nodes = get_tree().current_scene.get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break

	# Connect collision signal
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_instance_valid(player_node):
		var dir = global_position.direction_to(player_node.global_position)
		global_position += dir * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player_vel = body.linear_velocity.length()

		# Kinetic Energy: Ek = 0.5 * m * v^2
		var player_kinetic_energy = 0.5 * player_mass * pow(player_vel, 2)
		var threshold_kinetic_energy = 0.5 * player_mass * pow(velocity_threshold, 2)

		# Momentum Threshold System
		if player_kinetic_energy >= threshold_kinetic_energy:
			# Player is fast: Pierce & Destroy Enemy
			print("Enemy destroyed! Player Ek: ", player_kinetic_energy)
			queue_free()
		else:
			# Player is slow: Take Damage & Bounce
			print("Player hit! Too slow! Ek: ", player_kinetic_energy)
			body.take_damage(damage_amount)

			# Bounce back away from enemy
			var bounce_dir = global_position.direction_to(body.global_position)
			body.bounce_back(bounce_dir, bounce_force)
