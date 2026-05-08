extends Area2D
class_name Enemy


enum EnemyType { NORMAL, SNIPER, TANK, MINI_BUG }
enum State { CHASE, ATTACK }

@export var enemy_type: EnemyType = EnemyType.NORMAL
var state: State = State.CHASE
var attack_timer: float = 0.0
var has_enraged: bool = false
var market_multiplier: float = 1.0

signal enemy_killed(type)

class EnemyBullet extends Area2D:
    var direction: Vector2 = Vector2.ZERO
    var speed: float = 600.0
    var damage: float = 30.0
    var _traveled_distance: float = 0.0

    func _ready():
        var collision_shape = CollisionShape2D.new()
        var circle = CircleShape2D.new()
        circle.radius = 10.0
        collision_shape.shape = circle
        add_child(collision_shape)

        var polygon = Polygon2D.new()
        polygon.color = Color(0, 1, 1) # Cyan
        var points = PackedVector2Array()
        for i in range(8):
            var angle = i * PI / 4.0
            points.append(Vector2(cos(angle), sin(angle)) * 10.0)
        polygon.polygon = points
        add_child(polygon)

        area_entered.connect(_on_area_entered)
        body_entered.connect(_on_body_entered)

    func _process(delta: float):
        var move_vec = direction * speed * delta
        global_position += move_vec
        _traveled_distance += move_vec.length()
        if _traveled_distance >= 2000.0:
            queue_free()

    func _on_area_entered(area: Area2D) -> void:
        # Avoid hitting other enemies
        pass

    func _on_body_entered(body: Node2D) -> void:
        if body is Player:
            body.take_damage(damage)
            queue_free()

@export var move_speed: float = 150.0
@export var base_mass: float = 1.0
@export var velocity_threshold: float = 800.0 # Pierce threshold
@export var damage_amount: float = 20.0
@export var bounce_force: float = 1500.0
@export var max_health: float = 100.0

var current_health: float
var player_node: Player
var coin_scene = preload("res://Coin.tscn")
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
		var dist = global_position.distance_to(player_node.global_position)
		var dir = global_position.direction_to(player_node.global_position)

		if enemy_type == EnemyType.SNIPER:
			if dist <= 800.0:
				state = State.ATTACK
			else:
				state = State.CHASE

			if state == State.ATTACK:
				attack_timer += delta
				if attack_timer > 2.0:
					attack_timer = 0.0
					var bullet = EnemyBullet.new()
					bullet.direction = dir
					bullet.global_position = global_position
					# Add as top-level so it doesn't move with enemy
					get_tree().current_scene.add_child(bullet)
			elif state == State.CHASE:
				global_position += dir * move_speed * delta
		else:
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

	if enemy_type == EnemyType.TANK and current_health / max_health < 0.2 and not has_enraged:
		move_speed *= 2.0
		has_enraged = true

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
	enemy_killed.emit(enemy_type)

	if enemy_type == EnemyType.TANK:
		var scene_path = "res://Enemy.tscn"
		if ResourceLoader.exists(scene_path):
			var packed_scene = load(scene_path)
			for i in range(3):
				var mini = packed_scene.instantiate()
				mini.enemy_type = EnemyType.MINI_BUG
				mini.move_speed = 300.0
				mini.max_health = 20.0
				mini.damage_amount = 5.0
				# Scatter them slightly
				var offset = Vector2(cos(i * 2.0 * PI / 3.0), sin(i * 2.0 * PI / 3.0)) * 50.0
				mini.global_position = global_position + offset
				get_tree().current_scene.call_deferred("add_child", mini)

	# Direct EXP
	if is_instance_valid(player_node):
		player_node.add_exp(35.0 * market_multiplier) # Base exp with market
		
	_spawn_coin()
	queue_free()

func _spawn_coin() -> void:
	if coin_scene:
		var coin = coin_scene.instantiate() as Coin
		coin.global_position = global_position
		# Randomize value maybe
		if randf() < 0.2:
			coin.value = 5.0 * market_multiplier
			coin.modulate = Color.GOLD
		else:
			coin.value = 1.0 * market_multiplier
		get_tree().current_scene.call_deferred("add_child", coin)
