extends Area2D

var is_captured: bool = false
var audio: AudioStreamPlayer2D
var visual: Polygon2D
var interact_cooldown: float = 0.0

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = 80.0
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	visual = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-30, -50), Vector2(30, -50), Vector2(30, 50), Vector2(-30, 50)
	])
	visual.color = Color(1.0, 0.2, 0.2) # Sinsi kızıl
	add_child(visual)

	audio = AudioStreamPlayer2D.new()
	add_child(audio)

	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(func():
		if not is_captured:
			# Bip-Bop sesleri (mock)
			pass
	)
	add_child(timer)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if interact_cooldown > 0:
		interact_cooldown -= delta

func set_captured() -> void:
	is_captured = true
	visual.color = Color(0.8, 0.8, 0.8) # Temiz beyaz eşya

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and interact_cooldown <= 0:
		get_tree().paused = true
		_open_gacha_shop()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		interact_cooldown = 2.0

func _open_gacha_shop() -> void:
	var gacha = load("res://GachaUI.tscn").instantiate()
	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(gacha)
