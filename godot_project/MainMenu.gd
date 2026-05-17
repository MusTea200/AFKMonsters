extends CanvasLayer

@onready var btn_play = $VBoxContainer/VBoxContainer/BtnPlay
@onready var btn_settings = $VBoxContainer/VBoxContainer/BtnSettings
@onready var btn_quit = $VBoxContainer/VBoxContainer/BtnQuit
@onready var lbl_coming_soon = $VBoxContainer/LblComingSoon

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false

	lbl_coming_soon.visible = false

	_setup_button_hover(btn_play)
	_setup_button_hover(btn_settings)
	_setup_button_hover(btn_quit)

	btn_play.pressed.connect(_on_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _setup_button_hover(btn: Button) -> void:
	btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
	btn.pivot_offset = btn.size / 2.0

func _on_btn_hover(btn: Button, is_hovered: bool) -> void:
	var tween = create_tween()
	if is_hovered:
		tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
		btn.modulate = Color(1.5, 1.5, 2.0) # Slight glow
	else:
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		btn.modulate = Color.WHITE

func _on_play_pressed() -> void:
	# Harita secim menusu ac
	_show_map_selection()

func _show_map_selection() -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)

	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 400)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = ">> SELECT PROTOCOL <<"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var btn1 = Button.new()
	btn1.text = "CYBER GRID (Standard)"
	btn1.modulate = Color.CYAN
	btn1.custom_minimum_size = Vector2(400, 60)
	btn1.pressed.connect(func():
		Global.current_selected_map = Global.MapType.CYBER_GRID
		get_tree().change_scene_to_file("res://ShopUI.tscn")
	)
	vbox.add_child(btn1)

	var btn2 = Button.new()
	btn2.text = "NEON HELL (Hard)"
	btn2.modulate = Color.RED
	btn2.custom_minimum_size = Vector2(400, 60)
	btn2.pressed.connect(func():
		Global.current_selected_map = Global.MapType.NEON_HELL
		get_tree().change_scene_to_file("res://ShopUI.tscn")
	)
	vbox.add_child(btn2)

	var btn3 = Button.new()
	btn3.text = "QUANTUM VOID (Nightmare)"
	btn3.modulate = Color.VIOLET
	btn3.custom_minimum_size = Vector2(400, 60)
	btn3.pressed.connect(func():
		Global.current_selected_map = Global.MapType.QUANTUM_VOID
		get_tree().change_scene_to_file("res://ShopUI.tscn")
	)
	vbox.add_child(btn3)

	get_tree().current_scene.add_child(panel)

	# Animate in
	panel.scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

func _on_settings_pressed() -> void:
	lbl_coming_soon.visible = true
	var tween = create_tween()
	tween.tween_property(lbl_coming_soon, "modulate:a", 1.0, 0.2)
	tween.tween_property(lbl_coming_soon, "modulate:a", 0.0, 1.0).set_delay(1.5)

func _on_quit_pressed() -> void:
	get_tree().quit()
