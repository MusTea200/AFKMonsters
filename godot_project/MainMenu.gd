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

	var map_sel = get_tree().current_scene.find_child("MapSelectionPanel", true, false)
	if map_sel:
		map_sel.hide()
		var btn_cyber = map_sel.find_child("CyberGridBtn", true, false)
		var btn_neon = map_sel.find_child("NeonHellBtn", true, false)
		var btn_quantum = map_sel.find_child("QuantumVoidBtn", true, false)

		if btn_cyber:
			_setup_map_button(btn_cyber)
			btn_cyber.pressed.connect(func():
				Global.current_selected_map = Global.MapType.CYBER_GRID
				get_tree().change_scene_to_file("res://ShopUI.tscn")
			)
		if btn_neon:
			_setup_map_button(btn_neon)
			btn_neon.pressed.connect(func():
				Global.current_selected_map = Global.MapType.NEON_HELL
				get_tree().change_scene_to_file("res://ShopUI.tscn")
			)
		if btn_quantum:
			_setup_map_button(btn_quantum)
			btn_quantum.pressed.connect(func():
				Global.current_selected_map = Global.MapType.QUANTUM_VOID
				get_tree().change_scene_to_file("res://ShopUI.tscn")
			)

	# Main Menu Title Animation
	var main_title = get_tree().current_scene.find_child("TitleLabel", true, false)
	if main_title:
		var tw = create_tween().set_loops()
		tw.tween_property(main_title, "position:y", main_title.position.y - 10.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(main_title, "position:y", main_title.position.y + 10.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	var map_sel = get_tree().current_scene.find_child("MapSelectionPanel", true, false)
	if map_sel:
		map_sel.show()

		# Animate in
		map_sel.scale = Vector2.ZERO
		map_sel.pivot_offset = map_sel.size / 2.0
		var tw = create_tween()
		tw.tween_property(map_sel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_settings_pressed() -> void:
	lbl_coming_soon.visible = true
	var tween = create_tween()
	tween.tween_property(lbl_coming_soon, "modulate:a", 1.0, 0.2)
	tween.tween_property(lbl_coming_soon, "modulate:a", 0.0, 1.0).set_delay(1.5)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _setup_map_button(btn: Button) -> void:
	btn.mouse_entered.connect(_on_map_btn_hover.bind(btn, true))
	btn.mouse_exited.connect(_on_map_btn_hover.bind(btn, false))

func _on_map_btn_hover(btn: Button, is_hovered: bool) -> void:
	var tween = create_tween()
	if is_hovered:
		tween.tween_property(btn, "modulate:v", 2.0, 0.1) # Brighten the neon color
		btn.text = ">> " + btn.name.replace("Btn", "").to_upper() + " <<"
	else:
		tween.tween_property(btn, "modulate:v", 1.0, 0.1)
		btn.text = btn.name.replace("Btn", "").to_upper()
