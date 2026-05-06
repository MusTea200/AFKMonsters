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

var player_node: Player
var pause_menu: Control
var stats_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure Arena can process ESC key when paused
	# Find player
	var scene_nodes = get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break

	# Setup Pause Menu
	pause_menu = get_tree().current_scene.find_child("PauseMenu", true, false) as Control
	if pause_menu:
		pause_menu.hide()
		stats_label = pause_menu.find_child("StatsLabel", true, false) as Label

	_setup_enemy_spawner()
	_initial_node_spawn()

func _process(delta: float) -> void:
	if not is_instance_valid(player_node):
		return
		
	_cull_distant_objects()
	_maintain_node_count()

func _initial_node_spawn() -> void:
	if not is_instance_valid(player_node):
		return
		
	var player_pos = player_node.global_position
	for i in range(max_nodes_in_world):
		_try_spawn_node_around(player_pos, 0, spawn_radius)

func _maintain_node_count() -> void:
	if not is_instance_valid(player_node):
		return
		
	var current_nodes = 0
	for child in get_children():
		if child is GrappleNode:
			current_nodes += 1
			
	if current_nodes < max_nodes_in_world:
		# Spawn new nodes just outside the immediate view, up to spawn_radius
		_try_spawn_node_around(player_node.global_position, spawn_radius * 0.8, spawn_radius)

func _try_spawn_node_around(center: Vector2, min_rad: float, max_rad: float) -> void:
	var angle = randf() * 2.0 * PI
	var dist = randf_range(min_rad, max_rad)
	var potential_pos = center + Vector2(cos(angle), sin(angle)) * dist
	
	# Check distance against existing nodes
	var is_valid = true
	for child in get_children():
		if child is GrappleNode or child is Magnet:
			if potential_pos.distance_to(child.global_position) < min_distance_between_nodes:
				is_valid = false
				break
				
	if is_valid:
		if randf() < 0.1: # 10% chance to spawn a Magnet instead of GrappleNode
			var magnet = magnet_scene.instantiate() as Magnet
			magnet.global_position = potential_pos
			add_child(magnet)
		else:
			_create_node_instance(potential_pos)

func _create_node_instance(pos: Vector2) -> void:
	var node_instance = grapple_node_scene.instantiate() as GrappleNode
	node_instance.global_position = pos
	# Type is randomized in GrappleNode._ready() now
	add_child(node_instance)

func _setup_enemy_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = enemy_spawn_rate
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player_node):
		return
		
	# Spawn enemy at a random angle at spawn_radius
	var angle = randf() * 2.0 * PI
	var spawn_pos = player_node.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	var enemy_instance = enemy_scene.instantiate()
	enemy_instance.global_position = spawn_pos
	add_child(enemy_instance)

func _cull_distant_objects() -> void:
	var player_pos = player_node.global_position
	
	for child in get_children():
		if child is GrappleNode or child is Enemy or child is Drop:
			if child.global_position.distance_to(player_pos) > cull_radius:
				child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo):
		_toggle_pause()

func _toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	if pause_menu:
		pause_menu.visible = new_pause_state
		
		if new_pause_state and stats_label and is_instance_valid(player_node):
			_update_stats_label()

func _update_stats_label() -> void:
	var stats_text = "[center][b]--- PLAYER STATS ---[/b][/center]\n\n"
	stats_text += "Level: " + str(player_node.level) + "\n"
	stats_text += "Health: " + str(round(player_node.current_health)) + " / " + str(player_node.max_health) + "\n"
	stats_text += "Health Regen: " + str(player_node.can_yenileme) + " / sec\n"
	stats_text += "Armor (Damage Reduction): " + str(player_node.hasar_azaltma * 100.0) + "%\n"
	stats_text += "Thorns: " + str(player_node.dikenli_deri) + "\n"
	stats_text += "Dodge Chance: " + str(player_node.kacis_sansi * 100.0) + "%\n"
	stats_text += "Rope Length: " + str(player_node.ip_uzunlugu) + "\n"
	stats_text += "Fire Rate: " + str(player_node.atis_hizi) + " / sec\n"
	stats_text += "Bullet Count: " + str(player_node.mermi_sayisi) + "\n"
	stats_text += "Piercing: " + str(player_node.delip_gecme) + "\n"
	stats_text += "Bullet Damage: " + str(player_node.mermi_hasari) + "\n"
	
	stats_label.text = stats_text
