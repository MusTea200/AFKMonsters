extends Area2D
class_name Magnet

@export var pull_speed: float = 1500.0 # Hızı biraz daha makul bir seviyeye çektik
var attracted_coins: Array = []
var is_active: bool = false
var player: Node2D
var original_scale: Vector2

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	player = get_tree().current_scene.find_child("Player", true, false)
	original_scale = scale

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	# ŞALTER KONTROLÜ: Oyuncu 150 birim yakındaysa aç, uzaklaşınca kapat!
	if global_position.distance_to(player.global_position) < 150.0:
		if not is_active:
			is_active = true
			scale = original_scale * 1.3 # Orijinal boyutunu (5) 1.3 ile çarparak büyütür
			modulate = Color.GOLD
	else:
		if is_active:
			is_active = false
			scale = original_scale # Orijinal boyutu neyse (5) tam olarak ona geri döner
			modulate = Color.WHITE

	# Sadece mıknatıs aktifken paraları çek
	if is_active:
		var coins_to_remove = []
		for coin in attracted_coins:
			if is_instance_valid(coin):
				coin.global_position = coin.global_position.move_toward(global_position, pull_speed * delta)
			else:
				coins_to_remove.append(coin)
				
		for c in coins_to_remove:
			attracted_coins.erase(c)

func _on_area_entered(area: Area2D) -> void:
	# O KARA DELİK KODUNU SİLDİK: Artık sadece adı Coin olanları listeye alır
	if "Coin" in area.name or area is Coin:
		if not attracted_coins.has(area):
			attracted_coins.append(area)

func _on_area_exited(area: Area2D) -> void:
	if attracted_coins.has(area):
		attracted_coins.erase(area)
