extends CanvasLayer

@onready var coin_label: Label = $VBoxContainer/Header/CoinBalance
@onready var item_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer

var display_coins: int = 0

func _ready() -> void:
	display_coins = Global.dongu_parcaciklari
	_update_coin_label(display_coins)
	_setup_hover_effects()
	_refresh_items()

func _setup_hover_effects() -> void:
	for item in item_container.get_children():
		if item is PanelContainer:
			# Make a unique copy of the stylebox so glow/shadow animates individually
			var stylebox = item.get_theme_stylebox("panel").duplicate()
			item.add_theme_stylebox_override("panel", stylebox)

			item.mouse_entered.connect(self._on_item_hovered.bind(item, true))
			item.mouse_exited.connect(self._on_item_hovered.bind(item, false))

func _on_item_hovered(item: PanelContainer, is_hovered: bool) -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	var stylebox = item.get_theme_stylebox("panel") as StyleBoxFlat

	if is_hovered:
		tween.tween_property(item, "position:y", item.position.y - 5.0, 0.1)
		if stylebox:
			tween.tween_property(stylebox, "shadow_color:a", 0.5, 0.1) # Glow up
	else:
		tween.tween_property(item, "position:y", item.position.y + 5.0, 0.1)
		if stylebox:
			tween.tween_property(stylebox, "shadow_color:a", 0.0, 0.1) # Glow down

func _update_coin_label(val: int) -> void:
	coin_label.text = "Döngü Parçacığı: " + str(val)

func _animate_coins_to(target_amount: int) -> void:
	var tween = create_tween()
	tween.tween_method(self._update_coin_label, display_coins, target_amount, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	display_coins = target_amount

func _refresh_items() -> void:
	for item in item_container.get_children():
		if not item.has_meta("upgrade_type"):
			continue

		var type = item.get_meta("upgrade_type")
		var current_lvl = Global.upgrade_levels.get(type, 0)
		var cost = Global.get_upgrade_cost(type)

		var lvl_bar = item.get_node("HBox/VBox/LvlBar") as HBoxContainer
		var price_lbl = item.get_node("HBox/VBox/PriceLabel") as Label
		var buy_btn = item.get_node("HBox/BuyButton") as Button
		var icon_color = item.get_node("HBox/Icon").color if item.has_node("HBox/Icon") else Color(0,1,1,1)

		price_lbl.text = "Fiyat: " + str(cost)

		# Clear existing level pips
		for child in lvl_bar.get_children():
			child.queue_free()

		# Add new level pips
		for i in range(current_lvl):
			var pip = ColorRect.new()
			pip.custom_minimum_size = Vector2(10, 10)
			pip.color = icon_color # Match icon color
			lvl_bar.add_child(pip)

			# Add empty pip if level 0
		if current_lvl == 0:
			var empty_lbl = Label.new()
			empty_lbl.text = "Lvl 0"
			empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			lvl_bar.add_child(empty_lbl)

		# Sinyali temizle ki tekrar tekrar bağlanmasın
		if buy_btn.pressed.is_connected(self._on_buy_pressed):
			buy_btn.pressed.disconnect(self._on_buy_pressed)

		buy_btn.pressed.connect(self._on_buy_pressed.bind(type, item))

func _on_buy_pressed(type: String, item_node: Node) -> void:
	var cost = Global.get_upgrade_cost(type)
	var price_lbl = item_node.get_node("HBox/VBox/PriceLabel") as Label
	var buy_btn = item_node.get_node("HBox/BuyButton") as Button

	if Global.dongu_parcaciklari >= cost:
		# Satın alma başarılı
		Global.dongu_parcaciklari -= cost
		Global.upgrade_levels[type] = Global.upgrade_levels.get(type, 0) + 1

		match type:
			"health":
				Global.perm_max_health += 20.0
			"damage":
				Global.perm_starting_damage += 10.0

		Global.save_game()

		_animate_coins_to(Global.dongu_parcaciklari)
		_refresh_items()

		# Juice: Bounce
		var tween = create_tween()
		buy_btn.pivot_offset = buy_btn.size / 2.0
		tween.tween_property(buy_btn, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(buy_btn, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		# Yetersiz Bakiye Juice: Kırmızı Parlama
		var tween = create_tween()
		tween.tween_property(price_lbl, "modulate", Color.RED, 0.1)
		tween.tween_property(price_lbl, "modulate", Color.WHITE, 0.3)

func _on_start_run_pressed() -> void:
	get_tree().change_scene_to_file("res://Arena.tscn")
