extends Node
class_name CombatComponent

var player: RigidBody2D
var combo_multiplier: int = 1
var combo_timer: float = 0.0
var combo_speed_threshold: float = 800.0
var combo_drop_threshold: float = 300.0
var combo_label: Label

# RPG Stats (Combat)
var can_yenileme: float = 1.0
var hasar_azaltma: float = 0.0 # percentage (0.0 to 1.0)
var dikenli_deri: float = 0.0
var kacis_sansi: float = 0.0 # percentage (0.0 to 1.0)
var atis_hizi: float = 1.0 # Shots per second
var mermi_sayisi: int = 1
var delip_gecme: int = 0
var mermi_hasari: float = 25.0

var shoot_timer: Timer

func initialize(_player: RigidBody2D) -> void:
	player = _player
	mermi_hasari = Global.perm_starting_damage

	combo_label = get_tree().current_scene.find_child("ComboLabel", true, false) as Label
	if is_instance_valid(combo_label):
		combo_label.text = ""
		combo_label.visible = false

	shoot_timer = Timer.new()
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_shoot_closest_enemy)
	update_fire_rate()

func update_fire_rate() -> void:
	if is_instance_valid(shoot_timer):
		shoot_timer.wait_time = 1.0 / atis_hizi
		shoot_timer.start()

func take_damage(amount: float) -> void:
	if randf() < kacis_sansi:
		# Dodged!
		_show_floating_text("Dodge!", Color.AQUA)
		return

	var actual_damage = amount * (1.0 - hasar_azaltma)
	player.current_health -= actual_damage

	if is_instance_valid(player.health_bar):
		player.health_bar.value = player.current_health

	if player.current_health <= 0:
		player.economy_comp.finalize_run()

func process_combat(delta: float) -> void:
	_update_combo(delta)

	# Health Regen
	if player.current_health < player.max_health and player.current_health > 0:
		player.current_health += can_yenileme * delta
		player.current_health = min(player.current_health, player.max_health)
		if is_instance_valid(player.health_bar):
			player.health_bar.value = player.current_health

func _update_combo(delta: float) -> void:
	var speed = player.linear_velocity.length()
	if speed > combo_speed_threshold:
		combo_timer += delta
		if combo_timer >= 0.5:
			combo_timer -= 0.5
			combo_multiplier += 1
			_animate_combo_label()
	elif speed < combo_drop_threshold:
		if combo_multiplier > 1:
			combo_multiplier = 1
			combo_timer = 0.0
			_animate_combo_label()

func _animate_combo_label() -> void:
	if not is_instance_valid(combo_label):
		return

	if combo_multiplier > 1:
		combo_label.text = "x" + str(combo_multiplier)
		combo_label.visible = true
	else:
		combo_label.text = ""
		combo_label.visible = false
		return

	var tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _show_floating_text(text_str: String, color: Color) -> void:
	var label = Label.new()
	label.text = text_str
	label.modulate = color
	var scene_root = get_tree().current_scene
	scene_root.add_child(label)
	label.global_position = player.global_position + Vector2(randf_range(-20, 20), -30)
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _shoot_closest_enemy() -> void:
	if not player.bullet_scene:
		return

	var closest_enemy = null
	var closest_dist = INF
	var scene_root = get_tree().current_scene

	# Sahnedeki tüm düğümleri tara
	for child in scene_root.get_children():
		# DİKKAT: İsim ("Enemy") kontrolünü kaldırdık.
		# Sadece "_take_damage" metodu olan her şeyi düşman kabul ediyoruz!
		if child is Node2D and child.has_method("_take_damage"):

			# YENİ ZIRH: Düşman zaten öldüyse (canı 0 veya altındaysa) görmezden gel
			var child_health = child.get("current_health")
			if child_health != null and child_health <= 0:
				continue # Bu düşmanla işimiz bitti, döngüdeki sonrakine geç!

			var dist = player.global_position.distance_to(child.global_position)
			if dist < 1500.0: # Menzil sınırı
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy = child

	# Eğer geçerli ve hayatta olan bir düşman bulduysak ateş et
	if closest_enemy:
		var base_dir = player.global_position.direction_to(closest_enemy.global_position)
		var spread_angle = deg_to_rad(15.0)

		var start_angle = -spread_angle * (mermi_sayisi - 1) / 2.0
		for i in range(mermi_sayisi):
			var current_angle = start_angle + (spread_angle * i if mermi_sayisi > 1 else 0.0)
			var final_dir = base_dir.rotated(current_angle)

			var bullet = player.bullet_scene.instantiate()
			bullet.global_position = player.global_position
			bullet.direction = final_dir
			bullet.damage = mermi_hasari * combo_multiplier
			bullet.pierce_count = delip_gecme
			scene_root.add_child(bullet)
