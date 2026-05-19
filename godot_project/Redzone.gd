extends Area2D
class_name Redzone

var player: Node2D
var inside_time: float = 0.0
var debuff_active: bool = false
var debuff_timer: float = 0.0
var captured: bool = false
var capture_time: float = 0.0
var capture_target: float = 100.0
var defense_time: float = 10.0
var vending_machine: Node2D

var original_speed: float = 0.0
var original_regen: float = 0.0

var visual: Polygon2D

func _ready() -> void:
	add_to_group("redzones")

	# Circular neon visuals using custom drawing
	var poly = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 300.0
	for i in range(64):
		var angle = (i / 64.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = Color(1.0, 0.0, 0.0, 0.2)

	# Create a visual node to override _draw
	var visual_node = Control.new()
	visual_node.name = "Visual"
	visual_node.set_script(load("res://RedzoneVisual.gd"))
	visual_node.set("radius", radius)

	add_child(poly)
	add_child(visual_node)
	self.visual = poly # keep reference
	visual.texture = load("res://icon.svg")
	visual.modulate = Color(1.0, 0.0, 0.0, 0.3)


	area_entered.connect(_on_area_entered)

	# Vending Machine Ekle
	var vending = load("res://VendingMachine.tscn").instantiate()
	vending.position = Vector2.ZERO # Sahne agaci altinda 0,0 a koy
	call_deferred("add_child", vending)
	vending_machine = vending
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	if captured:
		defense_time -= delta
		if defense_time <= 0:
			_trigger_emp()
		return
	if is_instance_valid(player):
		inside_time += delta

		capture_time += delta * (0.5 if vending_machine else 1.0) # Yavas ele gecirme
		if capture_time >= capture_target and not captured:
			captured = true
			if is_instance_valid(vending_machine):
				vending_machine.set_captured()
				vending_machine.set_captured()
			visual.color = Color(0.0, 1.0, 0.0, 0.2) # Yesile doner

		# Anında debuff uygula
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

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player" or (area.get_parent() and area.get_parent().name == "Player"):
		var p = area if area.name == "Player" else area.get_parent()
		if p.has_method("get"):
			if "active_redzone_count" in p:
				p.active_redzone_count += 1
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		player = area if area.name == "Player" else area.get_parent()

func _on_area_exited(area: Area2D) -> void:
	if area.name == "Player" or (area.get_parent() and area.get_parent().name == "Player"):
		var p = area if area.name == "Player" else area.get_parent()
		if p.has_method("get"):
			if "active_redzone_count" in p:
				p.active_redzone_count -= 1
				if p.active_redzone_count < 0: p.active_redzone_count = 0
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		player = null
		# Çıkınca sürenin 1/3'ü kadar debuff devam eder
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
	queue_free()
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
