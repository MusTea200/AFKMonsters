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
	get_tree().change_scene_to_file("res://Arena.tscn")

func _on_settings_pressed() -> void:
	lbl_coming_soon.visible = true
	var tween = create_tween()
	tween.tween_property(lbl_coming_soon, "modulate:a", 1.0, 0.2)
	tween.tween_property(lbl_coming_soon, "modulate:a", 0.0, 1.0).set_delay(1.5)

func _on_quit_pressed() -> void:
	get_tree().quit()
