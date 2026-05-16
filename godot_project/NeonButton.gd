extends TouchScreenButton

@export var base_color: Color = Color(0, 1, 1, 0.5)
@export var radius: float = 60.0
@export var label_text: String = ""

var current_scale: Vector2 = Vector2.ONE
var is_active: bool = false
var font: Font

func _ready() -> void:
	# Dokunma alanı şekli
	var c_shape = CircleShape2D.new()
	c_shape.radius = radius
	shape = c_shape

	pressed.connect(_on_pressed)
	released.connect(_on_released)

func _on_pressed() -> void:
	get_viewport().set_input_as_handled()
	is_active = true
	var tween = create_tween()
	tween.tween_property(self, "current_scale", Vector2(0.85, 0.85), 0.05)
	queue_redraw()

func _on_released() -> void:
	is_active = false
	var tween = create_tween()
	tween.tween_property(self, "current_scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)
	queue_redraw()

func _process(delta: float) -> void:
	if is_active:
		queue_redraw()

func _draw() -> void:
	# Kendimizi current_scale e gore cizecegiz
	var center = Vector2.ZERO
	var r = radius * current_scale.x
	var alpha = 0.8 if is_active else 0.4

	var c = base_color
	c.a = alpha

	draw_circle(center, r, c * Color(1,1,1,0.5)) # Ic dolgu
	draw_arc(center, r, 0, TAU, 32, c * 1.5, 4.0) # Dis cerceve parlak

	if label_text != "":
		# Basit custom metin cizimi, ortalama hesabi
		# Not: SystemFont veya default font Godot 4'te ozel olarak ThemeDB den alinabilir
		var default_font = ThemeDB.fallback_font
		var string_size = default_font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		draw_string(default_font, center - Vector2(string_size.x/2, -string_size.y/4), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
