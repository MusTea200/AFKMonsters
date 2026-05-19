extends Area2D
class_name Redzone

var player: Node2D
var inside_time: float = 0.0
var debuff_active: bool = false
var debuff_timer: float = 0.0
var captured: bool = false
var capture_time: float = 0.0
var capture_target: float = 10.0
var defense_time: float = 10.0
var last_spawn_percent: float = 0.0
var is_used: bool = false
var original_speed: float = 0.0
var original_regen: float = 0.0

@onready var visual = $ZoneVisual
@onready var progress_bar = $ProgressBar
@onready var countdown_label = $CountdownLabel
@onready var vending_machine = $VendingMachine


func _ready() -> void:
	add_to_group("redzones")

	if not progress_bar:
		push_warning("ProgressBar eksik! Dinamik olarak uretiliyor.")
		progress_bar = ProgressBar.new()
		progress_bar.max_value = 100.0
		progress_bar.custom_minimum_size = Vector2(200, 20)
		progress_bar.position = Vector2(-100, -350)
		add_child(progress_bar)

	if not countdown_label:
		push_warning("CountdownLabel eksik! Dinamik olarak uretiliyor.")
		countdown_label = Label.new()
		countdown_label.add_theme_font_size_override("font_size", 64)
		countdown_label.set_anchors_preset(Control.PRESET_CENTER)
		countdown_label.position = Vector2(-50, -100)
		add_child(countdown_label)

	if not visual:
		push_warning("ZoneVisual eksik! Dinamik olarak uretiliyor.")
		visual = Polygon2D.new()
		add_child(visual)

	if not vending_machine:
		push_warning("VendingMachine eksik! Dinamik olarak uretiliyor.")
		var vending = load("res://VendingMachine.tscn").instantiate()
		call_deferred("add_child", vending)
		vending_machine = vending

	progress_bar.hide()
	countdown_label.hide()
	visual.color = Color("ff00004d")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_used: return

	if captured:
		defense_time -= delta
		if defense_time > 0:
			if not countdown_label.visible:
				countdown_label.show()
				progress_bar.hide()

			countdown_label.text = str(int(defense_time + 1))
			# Lerp color from red (#ff0000) to green (#00ff00)
			var t = 1.0 - (defense_time / 10.0)
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0).lerp(Color(0.0, 1.0, 0.0), t))

		if defense_time <= 0:
			countdown_label.hide()
			_trigger_emp()

			# Mutlak Matrix Renk Dönüşümleri
			visual.color = Color("00ff004d")
			if is_instance_valid(vending_machine):
				vending_machine.activate_green()
			is_used = true
		return

	if is_instance_valid(player):
		progress_bar.show()
		inside_time += delta
		capture_time += delta

		var percent = clamp((capture_time / capture_target) * 100.0, 0.0, 100.0)
		progress_bar.value = percent

		if percent >= last_spawn_percent + 10.0:
			last_spawn_percent += 10.0
			_spawn_redzone_wave(last_spawn_percent)

		if capture_time >= capture_target and not captured:
			captured = true

		if not debuff_active:
			_apply_debuff()

		visual.modulate.a = min(0.5, 0.3 + (inside_time * 0.1))
	else:
		if debuff_active:
			debuff_timer -= delta
			if debuff_timer <= 0:
				_remove_debuff()

		visual.modulate.a = max(0.3, visual.modulate.a - delta * 0.2)
		inside_time = max(0.0, inside_time - delta * 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		if body.has_method("get") and "active_redzone_count" in body:
			body.active_redzone_count += 1

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		if body.has_method("get") and "active_redzone_count" in body:
			body.active_redzone_count -= 1
			if body.active_redzone_count < 0: body.active_redzone_count = 0
		debuff_timer = inside_time / 3.0

func _apply_debuff() -> void:
	debuff_active = true
	var p = player if is_instance_valid(player) else get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p):
		original_speed = p.max_speed
		original_regen = p.combat_comp.can_yenileme

		p.max_speed = original_speed * 0.5
		p.combat_comp.can_yenileme = 0.0
		p.modulate = Color.RED

		# Kesişim vurgusu
		if p.active_redzone_count > 1:
			visual.color = Color(1.0, 0.0, 0.0, 0.4) # Daha koyu plazma
		p.linear_damp = 0.2 # Ice effect (kayganlik)

		# warning ui
		var canvas = CanvasLayer.new()
		canvas.name = "RedzoneVignette"

		var vignette = ColorRect.new()
		vignette.color = Color(1, 0, 0, 0.2)
		vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(vignette)

		var label = Label.new()
		label.name = "RedzoneWarnLabel"
		if p.active_redzone_count > 1:
			label.text = ">> MATRIX BONUS: MULTIPLIER X" + str(p.active_redzone_count) + " <<"
			label.add_theme_color_override("font_color", Color(1.0, 0.0, 1.0)) # Neon Pink bonus
		else:
			label.text = ">> WARNING: OVERHEAT DEBUFF <<"
			label.add_theme_color_override("font_color", Color.RED)
		label.add_theme_font_size_override("font_size", 48)
		label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		label.position = Vector2(get_viewport_rect().size.x / 2.0 - 400, get_viewport_rect().size.y - 150)
		canvas.add_child(label)

		get_tree().current_scene.add_child(canvas)

func _trigger_emp() -> void:
	# EMP Patlaması ve Düşman eritme
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 1500.0:
			if enemy.has_method("_take_damage"): enemy._take_damage(99999.0)

func _remove_debuff() -> void:
	var p = get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p) and p.get("active_redzone_count") != null and p.active_redzone_count > 0:
		return # Hala baska redzone icindeyse debuff i silme!
	debuff_active = false
	p = get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p) and original_speed > 0:
		p.max_speed = original_speed
		p.combat_comp.can_yenileme = original_regen
		p.modulate = Color.WHITE
		p.linear_damp = 1.0 # Normal friction

		var vignette = get_tree().current_scene.find_child("RedzoneVignette", true, false)
		if vignette:
			vignette.queue_free()

		original_speed = 0.0

func _spawn_redzone_wave(percent: float) -> void:
	var arena = get_tree().current_scene
	if not arena or not "enemy_scenes" in arena: return

	var scenes = arena.enemy_scenes
	if scenes.size() == 0: return

	var multiplier = 1.0 + (percent / 100.0) * 3.0 # max 4x stronger
	var count = 3 + int(percent / 20.0)

	for i in range(count):
		var angle = randf() * TAU
		var radius_spawn = 400.0
		var pos = global_position + Vector2(cos(angle), sin(angle)) * radius_spawn

		var enemy = scenes[randi() % scenes.size()].instantiate()
		enemy.global_position = pos
		enemy.max_health *= multiplier
		enemy.damage_amount *= multiplier
		enemy.move_speed *= multiplier

		arena.call_deferred("add_child", enemy)

	# Cyber Shockwave Effect
	var shock = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(32):
		var ang = (i / 32.0) * TAU
		pts.append(Vector2(cos(ang), sin(ang)) * 10.0)
	shock.polygon = pts
	shock.color = Color(1.0, 0.0, 0.0, 0.8) # Red wave
	add_child(shock)

	var tw = create_tween()
	tw.tween_property(shock, "scale", Vector2(40.0, 40.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(shock, "modulate:a", 0.0, 0.5)
	tw.tween_callback(shock.queue_free)
