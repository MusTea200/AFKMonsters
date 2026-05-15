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
var arena_time: float = 0.0
var horde_triggered: bool = false
var boss_triggered: bool = false
var current_spawn_multiplier: int = 1
var is_horde_mode: bool = false

var countdown_label: Label
var base_time_limit: float = 600.0 # 10 minutes
var remaining_time: float = 600.0
var difficulty_multiplier: float = 1.0
var last_minute_checked: int = 10
var last_20s_checked: int = 3



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
		
		var return_btn = Button.new()
		return_btn.text = "Return to Market"
		return_btn.custom_minimum_size = Vector2(200, 60)
		return_btn.position = Vector2(pause_menu.size.x / 2.0 - 100, pause_menu.size.y - 100)
		pause_menu.add_child(return_btn)
		return_btn.pressed.connect(self._on_return_market_pressed)

		stats_label = pause_menu.find_child("StatsLabel", true, false)
		# Eğer StatsLabel RichTextLabel ise, BBCode'u otomatik aç!
		if stats_label and "bbcode_enabled" in stats_label:
			stats_label.bbcode_enabled = true

	balance_label = get_tree().current_scene.find_child("BalanceLabel", true, false) as Label
	update_balance_ui()
	_ready_countdown()


	_setup_enemy_spawner()
	_initial_node_spawn()

func _process(delta: float) -> void:
	if get_tree().paused or not is_instance_valid(player_node):
		return # Oyun durduysa motoru hiç yorma
	if not get_tree().paused:
		arena_time += delta
		_check_time_events()
		remaining_time -= delta
		_update_countdown_ui()
		_check_dynamic_difficulty()


		
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

	# 10% chance to spawn Redzone instead of a normal node
	if randf() < 0.1:
		var rz = load("res://Redzone.gd").new()
		rz.global_position = pos
		add_child(rz)
		return

	node_instance.global_position = pos
	node_instance.add_to_group("grapple_nodes")
	add_child(node_instance)

	# 5% chance to spawn RouletteMan on a node
	if randf() < 0.05 and not get_meta("roulette_spawned", false):
		set_meta("roulette_spawned", true)
		var rman = load("res://RouletteMan.gd").new()
		rman.target_node = node_instance
		add_child(rman)

func _setup_enemy_spawner() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = enemy_spawn_rate * pow(0.95, Global.successful_loops)
	spawn_timer.autostart = true
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE # Timer oyun durunca dursun!
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player_node) or get_tree().paused:
		return
	var angle = randf() * 2.0 * PI
	var spawn_pos = player_node.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

	for i in range(current_spawn_multiplier):
		var final_pos = spawn_pos + Vector2(cos(angle), sin(angle)) * randf_range(0, 200)
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.global_position = final_pos
		enemy_instance.max_health *= difficulty_multiplier
		if is_horde_mode:
			enemy_instance.move_speed = 150.0 * 1.2
		else:
			enemy_instance.move_speed *= (1.0 + (difficulty_multiplier - 1.0) * 0.5)
			enemy_instance.damage_amount *= difficulty_multiplier
		add_child(enemy_instance)

func _cull_distant_objects() -> void:
	var player_pos = player_node.global_position
	for child in get_children():
		# Do NOT cull important mechanics
		if child is RouletteMan or child is Merchant or child is SpeedMerchant or child is DeathLine:
			continue

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
	stats_text += "Seviye: " + str(player_node.economy_comp.level) + "\n"
	stats_text += "Can: " + str(round(player_node.current_health)) + " / " + str(player_node.max_health) + "\n"
	stats_text += "Can Yenileme: " + str(player_node.combat_comp.can_yenileme) + " sn\n"
	# Float -> float yapıldı ve combat_comp üzerinden çağrıldı
	stats_text += "Zırh: %" + str(float(player_node.combat_comp.hasar_azaltma) * 100.0) + "\n"
	stats_text += "Dikenli Deri: " + str(player_node.combat_comp.dikenli_deri) + "\n"
	stats_text += "Kaçış Şansı: %" + str(float(player_node.combat_comp.kacis_sansi) * 100.0) + "\n"
	stats_text += "İp Uzunluğu: " + str(player_node.ip_uzunlugu) + "\n"
	stats_text += "Atış Hızı: " + str(player_node.combat_comp.atis_hizi) + " / sn\n"
	stats_text += "Mermi Sayısı: " + str(player_node.combat_comp.mermi_sayisi) + "\n"
	stats_text += "Delip Geçme: " + str(player_node.combat_comp.delip_gecme) + "\n"
	stats_text += "Mermi Hasarı: " + str(player_node.combat_comp.mermi_hasari) + "\n"
	
	stats_label.text = stats_text # RichTextLabel ise kodların görünmesini engeller


func _ready_countdown() -> void:
	countdown_label = get_tree().current_scene.find_child("CountdownLabel", true, false) as Label

	base_time_limit += Global.extended_core_clock * 60.0 # +1 minute per upgrade
	remaining_time = base_time_limit

func update_balance_ui() -> void:
	if is_instance_valid(player_node) and is_instance_valid(balance_label):
		balance_label.text = str(int(player_node.get_node("EconomyComponent").gold))

func _on_return_market_pressed() -> void:
	if is_instance_valid(player_node) and player_node.has_node("EconomyComponent"):
		var eco = player_node.get_node("EconomyComponent")
		eco.convert_gold_to_global()

	Global.save_game()

	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ShopUI.tscn")

func _check_time_events() -> void:
	# Merchant at 2 minutes (120s)
	if arena_time >= 120.0 and not get_meta("merchant_spawned", false):
		set_meta("merchant_spawned", true)
		_spawn_merchant()

	# Horde at 3 minutes (180s)
	if arena_time >= 180.0 and not horde_triggered:
		horde_triggered = true
		is_horde_mode = true
		current_spawn_multiplier = 3
		spawn_timer.wait_time = spawn_timer.wait_time / 3.0
		_show_center_warning("SÜRÜ BASKINI!")


	# 4 minutes: Flappy Chase (DeathLine)
	if arena_time >= 240.0 and not get_meta("deathline_spawned", false):
		set_meta("deathline_spawned", true)
		var dl = load("res://DeathLine.gd").new()
		dl.global_position = player_node.global_position + Vector2(-3000, 0) # Start way behind
		add_child(dl)
		_show_center_warning("ÖLÜM ÇİZGİSİ YAKLAŞIYOR!")

	# 1 minute: Speed Merchant
	if arena_time >= 60.0 and not get_meta("speed_merchant_spawned", false):
		set_meta("speed_merchant_spawned", true)
		var sm = load("res://SpeedMerchant.gd").new()
		sm.global_position = player_node.global_position + Vector2(1000, 0)
		add_child(sm)
		_show_center_warning("HIZLI TÜCCARI YAKALA!")

	# Boss at 5 minutes (300s)
	if arena_time >= 300.0 and not boss_triggered:
		boss_triggered = true
		_spawn_boss()
		_show_center_warning("BOSS BELİRDİ!")

func _show_center_warning(msg: String) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.modulate = Color.RED
	lbl.add_theme_font_size_override("font_size", 48)
	get_tree().current_scene.find_child("CanvasLayer", true, false).add_child(lbl)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var tween = create_tween()
	tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(lbl.queue_free)

func _spawn_boss() -> void:
	var angle = randf() * 2.0 * PI
	var spawn_pos = player_node.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
	var boss = enemy_scene.instantiate()
	boss.global_position = spawn_pos
	boss.scale = Vector2(3.0, 3.0)
	boss.max_health = 1000.0 * pow(1.5, Global.successful_loops) # HUGE HP
	boss.move_speed = 100.0
	boss.base_mass = 5.0
	boss.is_boss = true
	# Note: Off-screen indicator would require a separate UI script,
	# but we keep it simple by just having a big enemy tracking us.
	add_child(boss)

func _spawn_merchant() -> void:
	var merchant = load("res://Merchant.gd").new()
	var angle = randf() * 2.0 * PI
	var dist = randf_range(1000.0, 2000.0)
	merchant.global_position = player_node.global_position + Vector2(cos(angle), sin(angle)) * dist
	add_child(merchant)
	_show_center_warning("TÜCCAR GELDİ!")

func _update_countdown_ui() -> void:
	if remaining_time > 0:
		var mins = int(remaining_time) / 60
		var secs = int(remaining_time) % 60
		countdown_label.text = "%02d:%02d" % [mins, secs]

		if remaining_time <= 60.0:
			countdown_label.add_theme_color_override("font_color", Color.RED)
	else:
		var overtime = abs(remaining_time)
		var secs = int(overtime) % 60
		countdown_label.text = "OVERTIME: %02d" % [secs]
		countdown_label.add_theme_color_override("font_color", Color.MAGENTA)

func _check_dynamic_difficulty() -> void:
	if remaining_time > 60.0:
		var current_minute = int(remaining_time) / 60
		if current_minute < last_minute_checked:
			last_minute_checked = current_minute
			_increase_difficulty()

	elif remaining_time > 0.0:
		var current_20s = int(remaining_time) / 20
		if current_20s < last_20s_checked:
			last_20s_checked = current_20s
			_increase_difficulty()
			_show_center_warning("ZORLUK ARTIYOR!")

func _increase_difficulty() -> void:
	difficulty_multiplier *= 1.15
	spawn_timer.wait_time = max(0.1, spawn_timer.wait_time / 1.15)
