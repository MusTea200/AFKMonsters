extends Area2D
class_name Magnet

@export var pull_speed: float = 1500.0 # Hızı biraz daha makul bir seviyeye çektik
var attracted_coins: Array = []
var is_active: bool = false
var player: Node2D
var original_scale: Vector2

var is_mimic: bool = false
var enemy_scene = preload("res://enemy_triangle.tscn") # Mimics spawn basic triangles

func _ready() -> void:
	if randf() < 0.2:
		is_mimic = true

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	player = get_tree().current_scene.find_child("Player", true, false)
	original_scale = scale

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	# ŞALTER KONTROLÜ: Oyuncu 150 birim yakındaysa aç, uzaklaşınca kapat!
	if global_position.distance_to(player.global_position) < 150.0:
		if not is_active and not player.is_jammed:
			if is_mimic:
				_trigger_mimic_trap()
				return

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

func _trigger_mimic_trap() -> void:
	if is_instance_valid(player) and player.has_method("apply_stun"):
		player.apply_stun(2.0)

	var scene_root = get_tree().current_scene
	var num_enemies = 10
	var radius = 250.0
	var spread = 360.0 / float(num_enemies)
	for i in range(num_enemies):
		var enemy = enemy_scene.instantiate()
		var angle = deg_to_rad(spread * i)
		enemy.global_position = global_position + Vector2(cos(angle), sin(angle)) * radius
		enemy.move_speed = 300.0 # Hızlı düşman
		scene_root.add_child(enemy)

	# Patlama efekti
	CameraShake.add_trauma(0.5)
	queue_free()
