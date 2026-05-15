extends Node

var save_path = "user://savegame.cfg"

# Kalıcı veriler
var dongu_parcaciklari: int = 0
var perm_max_health: float = 100.0
var perm_starting_damage: float = 25.0
var base_speed: float = 1200.0
var shield_capacity: int = 0
var orbital_count: int = 0
var extended_core_clock: int = 0
var successful_loops: int = 0
var roulette_universe_unlocked: bool = false

# Geçici run verileri
var current_run_kills: int = 0
var current_run_start_time: float = 0.0

# Global.gd içine eklenecekler:
var upgrade_levels = {
	"health": 0,
	"damage": 0,
	"magnet": 0,
	"speed": 0,
	"shield": 0,
	"orbital": 0,
	"clock": 0
}

func get_upgrade_cost(type: String) -> int:
	var base_costs = {"health": 100, "damage": 150, "magnet": 200, "speed": 120, "shield": 500, "orbital": 300, "clock": 1000}
	return int(base_costs[type] * pow(1.5, upgrade_levels[type]))

func _ready() -> void:
	load_game()

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Stats", "dongu_parcaciklari", dongu_parcaciklari)
	config.set_value("Stats", "perm_max_health", perm_max_health)
	config.set_value("Stats", "perm_starting_damage", perm_starting_damage)
	config.set_value("Stats", "base_speed", base_speed)
	config.set_value("Stats", "shield_capacity", shield_capacity)
	config.set_value("Stats", "orbital_count", orbital_count)
	config.set_value("Stats", "extended_core_clock", extended_core_clock)
	config.set_value("Stats", "successful_loops", successful_loops)
	config.set_value("Stats", "roulette_universe_unlocked", roulette_universe_unlocked)
	config.set_value("Stats", "upgrade_levels", upgrade_levels)
	config.save(save_path)

func load_game() -> void:
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		dongu_parcaciklari = config.get_value("Stats", "dongu_parcaciklari", 0)
		perm_max_health = config.get_value("Stats", "perm_max_health", 100.0)
		perm_starting_damage = config.get_value("Stats", "perm_starting_damage", 25.0)
		base_speed = config.get_value("Stats", "base_speed", 1200.0)
		shield_capacity = config.get_value("Stats", "shield_capacity", 0)
		orbital_count = config.get_value("Stats", "orbital_count", 0)
		extended_core_clock = config.get_value("Stats", "extended_core_clock", 0)
		successful_loops = config.get_value("Stats", "successful_loops", 0)
		roulette_universe_unlocked = config.get_value("Stats", "roulette_universe_unlocked", false)
		upgrade_levels = config.get_value("Stats", "upgrade_levels", {"health": 0, "damage": 0, "magnet": 0, "speed": 0, "shield": 0, "orbital": 0, "clock": 0})

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
	get_tree().change_scene_to_file("res://ShopUI.tscn")
