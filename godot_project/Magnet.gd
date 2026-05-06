extends Area2D
class_name Magnet

@export var pull_speed: float = 200.0
var attracted_coins: Array[Coin] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	var coins_to_remove = []
	for coin in attracted_coins:
		if is_instance_valid(coin):
			# Move coin towards the magnet center
			coin.global_position = coin.global_position.move_toward(global_position, pull_speed * delta)
		else:
			coins_to_remove.append(coin)
			
	for c in coins_to_remove:
		attracted_coins.erase(c)

func _on_area_entered(area: Area2D) -> void:
	if area is Coin:
		if not attracted_coins.has(area):
			attracted_coins.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area is Coin:
		attracted_coins.erase(area)
