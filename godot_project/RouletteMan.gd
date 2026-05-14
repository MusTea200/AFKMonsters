extends Area2D
class_name RouletteMan

var target_node: Node2D
var angle: float = 0.0
var rotate_speed: float = 2.0
var orbit_radius: float = 150.0
var player: Node2D

var last_player_angle: float = 0.0
var total_player_rotation: float = 0.0
var target_rotations: float = 10.0 * 2.0 * PI

var warning_label: Label
var shader_rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "PhoneAudio"
	add_child(audio_player)

	var sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg")
	sprite.modulate = Color(1.0, 0.5, 0.0) # Orange
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	add_child(col)

	area_entered.connect(_on_area_entered)

	warning_label = Label.new()
	warning_label.text = "Benimle ayni yonde don!"
	warning_label.position = Vector2(-50, -50)
	warning_label.visible = false
	add_child(warning_label)

	# Full screen shader rect
	shader_rect = ColorRect.new()
	shader_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shader_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Normally we'd load a wavy shader here
	shader_rect.color = Color(0.5, 0, 0.5, 0.0)
	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(shader_rect)

func _process(delta: float) -> void:
	if is_instance_valid(target_node):
		angle += rotate_speed * delta
		global_position = target_node.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius

		_track_player_rotation()

func _track_player_rotation() -> void:
	if not is_instance_valid(player):
		player = get_tree().current_scene.find_child("Player", true, false)
		return

	var to_player = target_node.global_position.direction_to(player.global_position)
	var current_player_angle = to_player.angle()

	var angle_diff = current_player_angle - last_player_angle
	# Normalize to -PI to PI
	while angle_diff > PI: angle_diff -= 2.0 * PI
	while angle_diff < -PI: angle_diff += 2.0 * PI

	# If player is attached to THIS node
	if player.active_springs.has(target_node):
		if warning_label.visible == false:
			warning_label.visible = true
			var audio = get_node("PhoneAudio") as AudioStreamPlayer2D
			audio.pitch_scale = randf_range(1.5, 2.5) # Toy phone pitch
			audio.play()

		total_player_rotation += angle_diff

		var progress = abs(total_player_rotation) / target_rotations
		shader_rect.color.a = min(progress, 0.8) # Gets darker/purple

		if abs(total_player_rotation) >= target_rotations:
			_trigger_roulette_event()
	else:
		warning_label.visible = false
		total_player_rotation = 0.0
		shader_rect.color.a = 0.0

	last_player_angle = current_player_angle

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		var p = area if area.name == "Player" else area.get_parent()
		# Check direction
		var player_vel = p.linear_velocity
		var my_vel = Vector2(-sin(angle), cos(angle)) * rotate_speed * orbit_radius

		# If dot product is negative, we are moving in opposite directions
		if player_vel.dot(my_vel) < -100.0:
			_instant_death(p)

func _instant_death(p: Node2D) -> void:
	print("Kafa kafaya carpisma! Oldun.")
	p.current_health = 0
	p.take_damage(9999) # Trigger death

func _trigger_roulette_event() -> void:
	total_player_rotation = 0.0 # Prevent re-trigger
	shader_rect.color.a = 0.0
	Global.roulette_universe_unlocked = true
	Global.save_game()

	# Vortex Effect
	var vortex = Sprite2D.new()
	vortex.texture = load("res://icon.svg") # Placeholder for vortex
	vortex.modulate = Color(0.5, 0.0, 1.0, 0.8)
	vortex.scale = Vector2(0.1, 0.1)
	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(vortex)
	vortex.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var v_tween = create_tween()
	v_tween.set_parallel(true)
	v_tween.tween_property(vortex, "scale", Vector2(100.0, 100.0), 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	v_tween.tween_property(vortex, "rotation", 10.0 * PI, 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	v_tween.chain().tween_callback(self._show_roulette_ui.bind(vortex))
	get_tree().paused = true

func _show_roulette_ui(vortex: Node) -> void:
	vortex.queue_free()
	var ui = Panel.new()
	ui.custom_minimum_size = Vector2(400, 300)
	ui.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var lbl = Label.new()
	lbl.text = "Çarkıfelek Evrenine Hoşgeldin!\n100 Run Gold ile çevir."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(lbl)
	lbl.position = Vector2(50, 20)

	var btn = Button.new()
	btn.text = "Çevir (100G)"
	btn.position = Vector2(100, 100)
	btn.pressed.connect(_spin.bind(ui))
	ui.add_child(btn)

	var close = Button.new()
	close.text = "Çıkış"
	close.position = Vector2(100, 150)
	close.pressed.connect(_close_ui.bind(ui))
	ui.add_child(close)

	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(ui)
	get_tree().paused = true

func _spin(ui: Panel) -> void:
	if player.economy_comp.gold >= 100:
		player.economy_comp.add_gold(-100)
		var result = randf()
		if result < 0.01:
			print("JACKPOT! %1 ihtimal. Roulette Universe Mode Aktif!")
			Global.roulette_universe_unlocked = true
		elif result < 0.5:
			player.combat_comp.mermi_hasari += 10.0
			print("Hasar +10")
		else:
			Global.dongu_parcaciklari += 50
			print("Kalıcı 50 Döngü Parçacığı")

		_close_ui(ui)
	else:
		print("Yetersiz bakiye!")

func _close_ui(ui: Panel) -> void:
	ui.queue_free()
	get_tree().paused = false
