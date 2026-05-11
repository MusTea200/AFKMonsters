extends CanvasLayer

@onready var coin_label: Label = $VBoxContainer/Header/CoinBalance
@onready var item_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer

var display_coins: int = 0

func _ready() -> void:
	display_coins = Global.dongu_parcaciklari
	_update_coin_label(display_coins)
	_refresh_items()

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

		var lvl_lbl = item.get_node("HBox/VBox/LvlLabel") as Label
		var price_lbl = item.get_node("HBox/VBox/PriceLabel") as Label
		var buy_btn = item.get_node("HBox/BuyButton") as Button

		lvl_lbl.text = "Lvl " + str(current_lvl)
		price_lbl.text = "Fiyat: " + str(cost)

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
