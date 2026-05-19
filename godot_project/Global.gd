extends Node

var save_path = "user://savegame.cfg"

# Kalıcı veriler
enum InputType { KEYBOARD, JOYPAD, TOUCH }
enum ControlMode { AUTO, FORCE_KEYBOARD, FORCE_JOYPAD, FORCE_TOUCH }
enum MapType { CYBER_GRID, NEON_HELL, QUANTUM_VOID }
var current_selected_map: MapType = MapType.CYBER_GRID

var current_input_type: InputType = InputType.KEYBOARD
var settings_control_mode: ControlMode = ControlMode.AUTO
var use_manual_aim_joystick: bool = true
var grapple_hold_mode: bool = true
var settings_sensitivity: float = 1.0
var settings_vsync: bool = true
var settings_volume: float = 1.0
var settings_resolution: Vector2 = Vector2(1920, 1080)


func _unhandled_input(event: InputEvent) -> void:
	if settings_control_mode != ControlMode.AUTO: return

	if event is InputEventKey or event is InputEventMouse:
		current_input_type = InputType.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Ignore small deadzone stick twitches
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.2: return
		current_input_type = InputType.JOYPAD
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		current_input_type = InputType.TOUCH

var dongu_parcaciklari: int = 0
var otomat_parasi: int = 0
var perm_max_health: float = 100.0
var perm_starting_damage: float = 25.0
var base_speed: float = 1200.0
var shield_capacity: int = 0
var orbital_count: int = 0
var extended_core_clock: int = 0
var successful_loops: int = 0
var roulette_universe_unlocked: bool = false
var particle_drop_chance_level: int = 0 # Max 8
var particle_drop_amount_level: int = 0 # Max 9
var turret_unlocked: bool = false
var portable_magnet_unlocked: bool = false
var poison_flask_unlocked: bool = false

# UI Referansları
var left_joystick: VirtualJoystick = null
var right_joystick: VirtualJoystick = null

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
	"clock": 0,
	"particle_chance": 0,
	"particle_amount": 0
,
	"turret_unlock": 0,
	"portable_magnet_unlock": 0,
	"poison_flask_unlock": 0
}

var gacha_levels = {}


func get_upgrade_cost(type: String) -> int:
	var base_costs = {"health": 100, "damage": 150, "magnet": 200, "speed": 120, "shield": 500, "orbital": 300, "clock": 1000, "particle_chance": 300, "particle_amount": 500, "turret_unlock": 2500, "portable_magnet_unlock": 3000, "poison_flask_unlock": 3500}
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
	config.set_value("Stats", "particle_drop_chance_level", particle_drop_chance_level)
	config.set_value("Stats", "particle_drop_amount_level", particle_drop_amount_level)
	config.set_value("Stats", "turret_unlocked", turret_unlocked)
	config.set_value("Stats", "portable_magnet_unlocked", portable_magnet_unlocked)
	config.set_value("Stats", "poison_flask_unlocked", poison_flask_unlocked)
	config.set_value("Stats", "upgrade_levels", upgrade_levels)
	config.set_value("Stats", "gacha_levels", gacha_levels)
	config.set_value("Settings", "control_mode", settings_control_mode)
	config.set_value("Settings", "use_manual_aim_joystick", use_manual_aim_joystick)
	config.set_value("Settings", "grapple_hold_mode", grapple_hold_mode)
	config.set_value("Settings", "current_selected_map", current_selected_map)
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
		particle_drop_chance_level = config.get_value("Stats", "particle_drop_chance_level", 0)
		particle_drop_amount_level = config.get_value("Stats", "particle_drop_amount_level", 0)
		turret_unlocked = config.get_value("Stats", "turret_unlocked", false)
		portable_magnet_unlocked = config.get_value("Stats", "portable_magnet_unlocked", false)
		poison_flask_unlocked = config.get_value("Stats", "poison_flask_unlocked", false)
		upgrade_levels = config.get_value("Stats", "upgrade_levels", {"health": 0, "damage": 0, "magnet": 0, "speed": 0, "shield": 0, "orbital": 0, "clock": 0})
		gacha_levels = config.get_value("Stats", "gacha_levels", {})
		settings_control_mode = config.get_value("Settings", "control_mode", ControlMode.AUTO)
		use_manual_aim_joystick = config.get_value("Settings", "use_manual_aim_joystick", true)
		grapple_hold_mode = config.get_value("Settings", "grapple_hold_mode", true)
		current_selected_map = config.get_value("Settings", "current_selected_map", MapType.CYBER_GRID)

func start_run() -> void:
	roulette_universe_unlocked = false # Her run basinda kapali gelsin
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
