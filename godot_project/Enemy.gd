extends Area2D
class_name Enemy

@export var move_speed: float = 150.0
@export var base_mass: float = 1.0
@export var velocity_threshold: float = 800.0 # Pierce threshold
@export var damage_amount: float = 20.0
@export var bounce_force: float = 1500.0
@export var max_health: float = 100.0

var current_health: float
var player_node: Player
var drop_scene = preload("res://Drop.tscn")
var progress_bar: ProgressBar

func _ready() -> void:
	current_health = max_health


	# Attempt to find the user's manually added ProgressBar named HealthBar
	progress_bar = find_child("HealthBar", true, false) as ProgressBar
	if progress_bar:
		progress_bar.max_value = max_health
		progress_bar.value = current_health

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
		var current_player_mass = body.mass
		var player_kinetic_energy = 0.5 * current_player_mass * pow(player_vel, 2)

		# Apply combo multiplier if player has it
		if "combo_multiplier" in body:
			player_kinetic_energy *= body.combo_multiplier

		var threshold_kinetic_energy = 0.5 * current_player_mass * pow(velocity_threshold, 2)

		if player_kinetic_energy >= threshold_kinetic_energy:
			# Fast player = massive damage equivalent to their kinetic energy
			_take_damage(player_kinetic_energy)
		else:
			# Slow player = player takes damage and bounces
			body.take_damage(damage_amount)

			# Check for Thorns
			if "dikenli_deri" in body and body.dikenli_deri > 0:
				_take_damage(body.dikenli_deri)

			var bounce_dir = global_position.direction_to(body.global_position)
			body.bounce_back(bounce_dir, bounce_force)

func _take_damage(amount: float) -> void:
	current_health -= amount
	_show_floating_damage(amount)

	if is_instance_valid(progress_bar):
		progress_bar.value = current_health

	if current_health <= 0:
		_die()

func _show_floating_damage(amount: float) -> void:
	var label = Label.new()
	# Format to show an integer if possible, or 1 decimal place
	label.text = "-" + str(round(amount))
	label.modulate = Color(1.0, 0.2, 0.2, 1.0) # Red color

	# Add the label to the root scene so it doesn't move/delete with the enemy
	var scene_root = get_tree().current_scene
	scene_root.add_child(label)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -30)

	var tween = label.create_tween()
	# Animate position up
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Animate alpha to fade out at the same time
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)

	# Queue free after animation completes
	tween.tween_callback(label.queue_free)

func _die() -> void:
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	if drop_scene:
		var drop = drop_scene.instantiate() as Drop
		drop.global_position = global_position

		if randf() < 0.2:
			drop.drop_type = Drop.DropType.GOLD
			drop.value = 5.0
		else:
			drop.drop_type = Drop.DropType.EXP
			drop.value = 35.0

		get_tree().current_scene.call_deferred("add_child", drop)
