extends Area2D
class_name Enemy

@export var move_speed: float = 150.0
@export var base_mass: float = 1.0
@export var velocity_threshold: float = 800.0 # Pierce threshold
@export var damage_amount: float = 20.0
@export var bounce_force: float = 1500.0
@export var health: float = 100.0

var player_node: Player
var drop_scene = preload("res://Drop.tscn")

func _ready() -> void:
	var scene_nodes = get_tree().current_scene.get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_instance_valid(player_node):
		var dir = global_position.direction_to(player_node.global_position)
		global_position += dir * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player_vel = body.linear_velocity.length()

		# Kinetic Energy: Ek = 0.5 * m * v^2
		# Use dynamic body mass to reward Mass Upgrades!
		var current_player_mass = body.mass
		var player_kinetic_energy = 0.5 * current_player_mass * pow(player_vel, 2)
		var threshold_kinetic_energy = 0.5 * current_player_mass * pow(velocity_threshold, 2)

		# Momentum Threshold System
		if player_kinetic_energy >= threshold_kinetic_energy:
			# Player is fast: Pierce & Destroy
			_die()
		else:
			# Player is slow: Take Damage & Bounce
			body.take_damage(damage_amount)
			var bounce_dir = global_position.direction_to(body.global_position)
			body.bounce_back(bounce_dir, bounce_force)

func take_orbital_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	if drop_scene:
		var drop = drop_scene.instantiate() as Drop
		drop.global_position = global_position

		# 20% chance for Gold, 80% for EXP
		if randf() < 0.2:
			drop.drop_type = Drop.DropType.GOLD
			drop.value = 5.0
		else:
			drop.drop_type = Drop.DropType.EXP
			drop.value = 35.0

		# Add to the main scene, not the enemy (so it isn't deleted)
		get_tree().current_scene.add_child(drop)
