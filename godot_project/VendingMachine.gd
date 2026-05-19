extends Area2D

var is_captured: bool = false
var audio: AudioStreamPlayer2D
var visual: Polygon2D
var interact_cooldown: float = 0.0

func _ready() -> void:
	visual = $Visual
	audio = $AudioStreamPlayer2D
	visual.color = Color("ff3333")

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
	visual.color = Color("00ff33")

func _on_body_entered(body: Node2D) -> void:
	if not is_captured:
		return
	if body.name == "Player" and interact_cooldown <= 0:
		get_tree().paused = true
		_open_gacha_shop()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		interact_cooldown = 2.0

func _open_gacha_shop() -> void:
	var gacha = load("res://GachaUI.tscn").instantiate()
	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(gacha)

	gacha.tree_exited.connect(func():
		is_captured = false
		visual.color = Color("7c7c7c")
	)

func activate_green() -> void:
	is_captured = true
	visual.color = Color("00ff33")
