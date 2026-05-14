extends Area2D
class_name SpeedMerchant

var player: Node2D
var move_speed: float = 800.0
var flee_radius: float = 1200.0
var ui_timer: Timer

func _ready() -> void:
	var sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg")
	sprite.modulate = Color(0.0, 1.0, 1.0, 0.8) # Cyan
	sprite.scale = Vector2(0.6, 0.6)
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	col.shape = shape
	add_child(col)

	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().current_scene.find_child("Player", true, false)
		return

	# Evade player
	if global_position.distance_to(player.global_position) < flee_radius:
		var flee_dir = player.global_position.direction_to(global_position)
		# Add some erratic movement
		flee_dir = flee_dir.rotated(sin(Time.get_ticks_msec() * 0.005) * 0.5)
		global_position += flee_dir * move_speed * delta
	else:
		# Slowly drift
		global_position += Vector2(cos(Time.get_ticks_msec()*0.001), sin(Time.get_ticks_msec()*0.001)) * 50.0 * delta

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		_open_speed_shop()

func _open_speed_shop() -> void:
	move_speed = 0.0 # Stop moving while shop is open

	var shop_ui = Panel.new()
	shop_ui.custom_minimum_size = Vector2(300, 200)
	shop_ui.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_ui.add_child(vbox)

	var title = Label.new()
	title.text = "SPEED MERCHANT
Costs Run Gold!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_spd = Button.new()
	btn_spd.text = "Speed Buff (+20%) - 100G"
	btn_spd.pressed.connect(_buy_spd.bind(btn_spd, shop_ui))
	vbox.add_child(btn_spd)

	var btn_close = Button.new()
	btn_close.text = "Close"
	btn_close.pressed.connect(_close_shop.bind(shop_ui))
	vbox.add_child(btn_close)

	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(shop_ui)
	get_tree().paused = true

func _buy_spd(btn: Button, ui: Panel) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 100:
			eco.add_gold(-100)
			player.max_speed *= 1.2
			_close_shop(ui)

func _close_shop(ui: Panel) -> void:
	get_tree().paused = false
	ui.queue_free()
	queue_free() # Merchant leaves after interacting
