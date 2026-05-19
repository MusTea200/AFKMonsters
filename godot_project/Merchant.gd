extends Area2D
class_name Merchant

var player: Node2D
var is_shop_open: bool = false
var shop_ui: Panel

func _ready() -> void:
	# Add visual
	var icon = Sprite2D.new()
	icon.texture = load("res://icon.svg")
	icon.modulate = Color(0.2, 1.0, 0.2, 1.0)
	add_child(icon)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 100.0
	col.shape = shape
	add_child(col)

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		player = area if area.name == "Player" else area.get_parent()
		_open_shop()

func _on_area_exited(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		_close_shop()

func _open_shop() -> void:
	if is_shop_open: return
	is_shop_open = true

	shop_ui = Panel.new()
	shop_ui.custom_minimum_size = Vector2(300, 200)
	shop_ui.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_ui.add_child(vbox)

	var title = Label.new()
	title.text = "In-Run Merchant\nCosts Run Gold!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_dmg = Button.new()
	btn_dmg.text = "Damage Buff (+50) - 50G"
	btn_dmg.pressed.connect(_buy_dmg.bind(btn_dmg))
	vbox.add_child(btn_dmg)

	var btn_heal = Button.new()
	btn_heal.text = "Full Heal - 30G"
	btn_heal.pressed.connect(_buy_heal.bind(btn_heal))
	vbox.add_child(btn_heal)

	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(shop_ui)

func _close_shop() -> void:
	if not is_shop_open: return
	is_shop_open = false
	if is_instance_valid(shop_ui):
		shop_ui.queue_free()

func _buy_dmg(btn: Button) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 50:
			eco.add_gold(-50)
			player.combat_comp.mermi_hasari += 50.0
			btn.text = "Sold Out!"
			btn.disabled = true

func _buy_heal(btn: Button) -> void:
	if is_instance_valid(player) and player.has_node("EconomyComponent"):
		var eco = player.get_node("EconomyComponent")
		if eco.gold >= 30:
			eco.add_gold(-30)
			player.current_health = player.max_health
			if player.health_bar:
				player.health_bar.value = player.current_health
			btn.text = "Sold Out!"
			btn.disabled = true
