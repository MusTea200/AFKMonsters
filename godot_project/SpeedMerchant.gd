extends Area2D
class_name SpeedMerchant

var player: Node2D
var move_speed: float = 800.0
var flee_radius: float = 1200.0
var can_interact: bool = false
var is_shop_open: bool = false
var interact_label: Label

func _ready() -> void:
	var sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg")
	sprite.modulate = Color(0.0, 1.0, 1.0, 0.8) # Cyan
	sprite.scale = Vector2(0.6, 0.6)
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 150.0 # Interaction radius increased
	col.shape = shape
	add_child(col)

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	interact_label = Label.new()
	interact_label.text = "[E] GİZLİ MARKET"
	interact_label.modulate = Color.CYAN
	interact_label.position = Vector2(-50, -60)
	interact_label.visible = false
	add_child(interact_label)

func _process(delta: float) -> void:
	if is_shop_open: return

	if not is_instance_valid(player):
		player = get_tree().current_scene.find_child("Player", true, false)
		return

	# Omni-Input Dynamic Label
	match Global.current_input_type:
		Global.InputType.KEYBOARD:
			interact_label.text = "[E] GİZLİ MARKET"
		Global.InputType.JOYPAD:
			interact_label.text = "[X/Kare] GİZLİ MARKET"
		Global.InputType.TOUCH:
			interact_label.text = "[DOKUN] GİZLİ MARKET"

	# Evade player
	if global_position.distance_to(player.global_position) < flee_radius:
		var flee_dir = player.global_position.direction_to(global_position)
		# Add some erratic movement
		flee_dir = flee_dir.rotated(sin(Time.get_ticks_msec() * 0.005) * 0.5)
		global_position += flee_dir * move_speed * delta
	else:
		# Slowly drift
		global_position += Vector2(cos(Time.get_ticks_msec()*0.001), sin(Time.get_ticks_msec()*0.001)) * 50.0 * delta

func _unhandled_input(event: InputEvent) -> void:
	if not can_interact or is_shop_open: return

	var interacted = false

	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		interacted = true
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_X and event.pressed:
		interacted = true
	elif event is InputEventScreenTouch and event.pressed:
		interacted = true

	if interacted:
		_open_speed_shop()

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		can_interact = true
		interact_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		can_interact = false
		interact_label.visible = false

func _create_glass_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 1.0, 1.0, 1.0) # Neon Cyan
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style

func _open_speed_shop() -> void:
	can_interact = false
	is_shop_open = true
	move_speed = 0.0
	Engine.time_scale = 0.1 # Slow motion

	var shop_ui = PanelContainer.new()
	shop_ui.add_theme_stylebox_override("panel", _create_glass_style())
	shop_ui.custom_minimum_size = Vector2(600, 300)
	shop_ui.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var vbox = VBoxContainer.new()
	shop_ui.add_child(vbox)

	var title = Label.new()
	title.text = ">> BLACK MARKET <<"
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	# Option 1: Temporary Speed (Run Gold)
	var card1 = _create_card("AŞIRI YÜKLEME
+Hız (Geçici)", "100 Altın", _buy_spd.bind(shop_ui))
	hbox.add_child(card1)

	# Option 2: Temporary Pierce (Run Gold)
	var card2 = _create_card("DELİCİ MERMİ
+Delme (Geçici)", "150 Altın", _buy_pierce.bind(shop_ui))
	hbox.add_child(card2)

	# Option 3: Permanent Loop Fragment (Run Gold)
	var card3 = _create_card("YASAK BİLGİ
+50 Kalıcı Döngü", "500 Altın", _buy_perm.bind(shop_ui))
	hbox.add_child(card3)

	var btn_close = Button.new()
	btn_close.text = "Ayrıl"
	btn_close.pressed.connect(_close_shop.bind(shop_ui))
	vbox.add_child(btn_close)

	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(shop_ui)

func _create_card(desc: String, cost_text: String, callback: Callable) -> PanelContainer:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _create_glass_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var cvbox = VBoxContainer.new()
	cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(cvbox)

	var lbl = Label.new()
	lbl.text = desc
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(lbl)

	var btn = Button.new()
	btn.text = cost_text
	btn.pressed.connect(callback)
	cvbox.add_child(btn)

	return card

func _buy_spd(ui: PanelContainer) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 100:
			eco.add_gold(-100)
			player.max_speed *= 1.3
			_close_shop(ui)

func _buy_pierce(ui: PanelContainer) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 150:
			eco.add_gold(-150)
			player.combat_comp.delip_gecme += 1
			_close_shop(ui)

func _buy_perm(ui: PanelContainer) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 500:
			eco.add_gold(-500)
			Global.dongu_parcaciklari += 50
			Global.save_game()
			_close_shop(ui)

func _buy_time(ui: PanelContainer) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 300:
			eco.add_gold(-300)
			var arena = get_tree().current_scene
			if is_instance_valid(arena) and "remaining_time" in arena:
				arena.remaining_time += 60.0
			_close_shop(ui)


func _close_shop(ui: PanelContainer) -> void:
	Engine.time_scale = 1.0
	ui.queue_free()
	queue_free() # Merchant leaves after interacting
