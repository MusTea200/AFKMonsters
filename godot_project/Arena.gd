extends Node2D

@export var min_distance_between_nodes: float = 600.0
@export var enemy_spawn_rate: float = 3.0
@export var spawn_radius: float = 1500.0
@export var cull_radius: float = 2500.0
@export var max_nodes_in_world: int = 30

var grapple_node_scene = preload("res://GrappleNode.tscn")
var enemy_scene = preload("res://Enemy.tscn")
var magnet_scene = preload("res://Magnet.tscn")
var spawn_timer: Timer

var player_node: Node2D
var pause_menu: Control
var stats_label # Türü serbest bıraktık (Label veya RichTextLabel olabilir)
var balance_label: Label

var kill_counts: Dictionary = {
	0: 0, # NORMAL
	1: 0, # SNIPER
	2: 0  # TANK
}
var market_values: Dictionary = {
	0: 1.0, # NORMAL
	1: 1.0, # SNIPER
	2: 1.0  # TANK
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Arena zaman dursa da çalışsın (ESC için)
	
	for n in get_children():
		if n.name == "Player": 
			player_node = n
			break

	pause_menu = get_tree().current_scene.find_child("PauseMenu", true, false) as Control
	if pause_menu:
		pause_menu.hide()
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS # Menü oyun durunca donmasın
		
		stats_label = pause_menu.find_child("StatsLabel", true, false)
		# Eğer StatsLabel RichTextLabel ise, BBCode'u otomatik aç!
		if stats_label and "bbcode_enabled" in stats_label:
			stats_label.bbcode_enabled = true

	balance_label = get_tree().current_scene.find_child("BalanceLabel", true, false) as Label
	update_balance_ui() 

	_setup_enemy_spawner()
	_initial_node_spawn()

func _process(delta: float) -> void:
	if get_tree().paused or not is_instance_valid(player_node):
		return # Oyun durduysa motoru hiç yorma
		
	_cull_distant_objects()
	_maintain_node_count()

func _initial_node_spawn() -> void:
	if not is_instance_valid(player_node): return
	for i in range(max_nodes_in_world):
		_try_spawn_node_around(player_node.global_position, 0, spawn_radius)

func _maintain_node_count() -> void:
	if not is_instance_valid(player_node): return
	var current_nodes = get_tree().get_nodes_in_group("grapple_nodes").size()
	if current_nodes < max_nodes_in_world:
		_try_spawn_node_around(player_node.global_position, spawn_radius * 0.8, spawn_radius)

func _try_spawn_node_around(center: Vector2, min_rad: float, max_rad: float) -> void:
	var angle = randf() * 2.0 * PI
	var dist = randf_range(min_rad, max_rad)
	var potential_pos = center + Vector2(cos(angle), sin(angle)) * dist
	
	var is_valid = true
	for child in get_children():
		if child.is_in_group("grapple_nodes") or child.is_in_group("magnets"):
			if potential_pos.distance_to(child.global_position) < min_distance_between_nodes:
				is_valid = false
				break
				
	if is_valid:
		if randf() < 0.1: 
			var magnet = magnet_scene.instantiate()
			magnet.global_position = potential_pos
			magnet.add_to_group("magnets")
			add_child(magnet)
		else:
			_create_node_instance(potential_pos)

func _create_node_instance(pos: Vector2) -> void:
	var node_instance = grapple_node_scene.instantiate()
	node_instance.global_position = pos
	node_instance.add_to_group("grapple_nodes")
	add_child(node_instance)

func _setup_enemy_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = enemy_spawn_rate * pow(0.95, Global.successful_loops)
	spawn_timer.autostart = true
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	var market_timer = Timer.new()
	market_timer.wait_time = 10.0
	market_timer.autostart = true
	market_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	market_timer.timeout.connect(_evaluate_market)
	add_child(market_timer)

func _on_enemy_killed(enemy_type: int) -> void:
	if kill_counts.has(enemy_type):
		kill_counts[enemy_type] += 1

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player_node) or get_tree().paused:
		return
	var angle = randf() * 2.0 * PI
	var spawn_pos = player_node.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos

	# Random type assignment (0=NORMAL, 1=SNIPER, 2=TANK)
	var type = randi() % 3
	enemy_instance.enemy_type = type
	enemy_instance.market_multiplier = market_values[type]

	# Attempt to set visual cue (Turquoise for SNIPER, Dark Red for TANK)
	var poly = enemy_instance.find_child("Polygon2D", true, false)
	if poly:
		if type == 1:
			poly.color = Color(0, 1, 1) # Turquoise
		elif type == 2:
			poly.color = Color(0.5, 0, 0) # Dark Red

	enemy_instance.enemy_killed.connect(_on_enemy_killed)

	add_child(enemy_instance)

func _cull_distant_objects() -> void:
	var player_pos = player_node.global_position
	for child in get_children():
		if child.is_in_group("grapple_nodes") or child.is_in_group("magnets") or "Enemy" in child.name or "Drop" in child.name:
			if child.global_position.distance_to(player_pos) > cull_radius:
				child.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo):
		_toggle_pause()

func _toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	if pause_menu:
		pause_menu.visible = new_pause_state
		if new_pause_state and is_instance_valid(player_node):
			_update_stats_label()

func _update_stats_label() -> void:
	if not stats_label: return
	
	var stats_text = "[center][b]--- OYUNCU İSTATİSTİKLERİ ---[/b][/center]\n\n"
	stats_text += "Seviye: " + str(player_node.get_node("EconomyComponent").level) + "\n"
	stats_text += "Can: " + str(round(player_node.get("current_health"))) + " / " + str(player_node.get("max_health")) + "\n"
	stats_text += "Can Yenileme: " + str(player_node.get("can_yenileme")) + " / sn\n"
	stats_text += "Zırh: %" + str(float(player_node.get("hasar_azaltma")) * 100.0) + "\n"
	stats_text += "Dikenli Deri: " + str(player_node.get("dikenli_deri")) + "\n"
	stats_text += "Kaçış Şansı: %" + str(float(player_node.get("kacis_sansi")) * 100.0) + "\n"
	stats_text += "İp Uzunluğu: " + str(player_node.get("ip_uzunlugu")) + "\n"
	stats_text += "Atış Hızı: " + str(player_node.get("atis_hizi")) + " / sn\n"
	stats_text += "Mermi Sayısı: " + str(player_node.get("mermi_sayisi")) + "\n"
	stats_text += "Delip Geçme: " + str(player_node.get("delip_gecme")) + "\n"
	stats_text += "Mermi Hasarı: " + str(player_node.get("mermi_hasari")) + "\n"
	
	stats_label.text = stats_text # RichTextLabel ise kodların görünmesini engeller

func update_balance_ui() -> void:
	if is_instance_valid(player_node) and is_instance_valid(balance_label):
		balance_label.text = str(int(player_node.get_node("EconomyComponent").gold))

func _evaluate_market() -> void:
	var max_kills = -1
	var min_kills = 999999
	var max_type = -1
	var min_type = -1

	for type in kill_counts.keys():
		var count = kill_counts[type]
		if count > max_kills:
			max_kills = count
			max_type = type
		if count < min_kills:
			min_kills = count
			min_type = type

	if max_type != -1 and min_type != -1 and max_type != min_type:
		# Over-farmed logic: decrease by 10%
		market_values[max_type] = max(0.1, market_values[max_type] - 0.1)
		# Under-farmed logic: increase by 10%
		market_values[min_type] = min(3.0, market_values[min_type] + 0.1)

	# Reset tracking
	for type in kill_counts.keys():
		kill_counts[type] = 0
