extends Node

var save_path = "user://savegame.cfg"

# Kalıcı veriler
var dongu_parcaciklari: int = 0
var perm_max_health: float = 100.0
var perm_starting_damage: float = 25.0
var successful_loops: int = 0

# Geçici run verileri
var current_run_kills: int = 0
var current_run_start_time: float = 0.0

func _ready() -> void:
	load_game()

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Stats", "dongu_parcaciklari", dongu_parcaciklari)
	config.set_value("Stats", "perm_max_health", perm_max_health)
	config.set_value("Stats", "perm_starting_damage", perm_starting_damage)
	config.set_value("Stats", "successful_loops", successful_loops)
	config.save(save_path)

func load_game() -> void:
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		dongu_parcaciklari = config.get_value("Stats", "dongu_parcaciklari", 0)
		perm_max_health = config.get_value("Stats", "perm_max_health", 100.0)
		perm_starting_damage = config.get_value("Stats", "perm_starting_damage", 25.0)
		successful_loops = config.get_value("Stats", "successful_loops", 0)

func start_run() -> void:
	current_run_kills = 0
	current_run_start_time = Time.get_ticks_msec() / 1000.0

func end_run() -> void:
	var survival_time = (Time.get_ticks_msec() / 1000.0) - current_run_start_time

	if survival_time >= 600.0: # 10 dakika hayatta kaldıysa
		successful_loops += 1

	var kazanilan_parcacik = int(current_run_kills * 0.1)
	dongu_parcaciklari += kazanilan_parcacik

	save_game()

	# Restart
	get_tree().reload_current_scene()
