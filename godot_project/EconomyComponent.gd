extends Node
class_name EconomyComponent

var player: RigidBody2D
var exp: float = 0.0
var level: int = 1
var gold: float = 0.0
var next_level_exp: float = 100.0

var exp_bar: ProgressBar
var level_up_ui

func initialize(_player: RigidBody2D, _exp_bar: ProgressBar, _level_up_ui) -> void:
	player = _player
	exp_bar = _exp_bar
	level_up_ui = _level_up_ui

	if is_instance_valid(exp_bar):
		exp_bar.max_value = next_level_exp
		exp_bar.value = exp

func add_exp(amount: float) -> void:
	exp += amount
	if is_instance_valid(exp_bar):
		exp_bar.value = exp
	while exp >= next_level_exp:
		_level_up()

func add_gold(amount: float) -> void:
	gold += amount
	var arena = get_tree().current_scene
	if arena.has_method("update_balance_ui"):
		arena.update_balance_ui()

func _level_up() -> void:
	exp -= next_level_exp
	level += 1
	next_level_exp *= 1.5

	if is_instance_valid(exp_bar):
		exp_bar.max_value = next_level_exp
		exp_bar.value = exp

	if is_instance_valid(level_up_ui):
		level_up_ui.show_upgrades()

func apply_upgrade(type: String) -> void:
	match type:
		"max_health":
			player.max_health += 20.0
			player.current_health += 20.0
			if is_instance_valid(player.health_bar):
				player.health_bar.max_value = player.max_health
				player.health_bar.value = player.current_health
		"regen":
			if player.has_node("CombatComponent"):
				player.get_node("CombatComponent").can_yenileme += 0.5
		"armor":
			if player.has_node("CombatComponent"):
				var comp = player.get_node("CombatComponent")
				comp.hasar_azaltma = min(comp.hasar_azaltma + 0.05, 0.8) # Max 80%
		"thorns":
			if player.has_node("CombatComponent"):
				player.get_node("CombatComponent").dikenli_deri += 5.0
		"dodge":
			if player.has_node("CombatComponent"):
				var comp = player.get_node("CombatComponent")
				comp.kacis_sansi = min(comp.kacis_sansi + 0.05, 0.6) # Max 60%
		"rope_len":
			player.ip_uzunlugu += 100.0
		"fire_rate":
			if player.has_node("CombatComponent"):
				var comp = player.get_node("CombatComponent")
				comp.atis_hizi += 0.5
				comp.update_fire_rate()
		"bullet_count":
			if player.has_node("CombatComponent"):
				player.get_node("CombatComponent").mermi_sayisi += 1
		"piercing":
			if player.has_node("CombatComponent"):
				player.get_node("CombatComponent").delip_gecme += 1
		"damage":
			if player.has_node("CombatComponent"):
				player.get_node("CombatComponent").mermi_hasari += 10.0
		"mass":
			player.mass_multiplier += 0.5
			player.mass = 1.0 * player.mass_multiplier
		"stiffness":
			player.stiffness_multiplier += 0.5
# EconomyComponent.gd dosyasının en altına ekle:

func finalize_run() -> void:
	var arena = get_tree().current_scene
	if is_instance_valid(arena) and "remaining_time" in arena:
		var rt = arena.remaining_time
		if rt < 0:
			var overtime = abs(rt)
			var base_time_mins = arena.base_time_limit / 60.0
			# S_0 = 30 * 3^((T_base - 10)/5)
			var s_0 = 30.0 * pow(3.0, (base_time_mins - 10.0) / 5.0)

			# Exponential growth: s_0 * 2^(overtime)
			var inflation_reward = int(s_0 * pow(2.0, overtime))

			print("OVERTIME REWARD: ", inflation_reward)
			Global.dongu_parcaciklari += inflation_reward

	Global.end_run()

func convert_gold_to_global() -> void:
	if gold > 0:
		Global.dongu_parcaciklari += int(gold)
		gold = 0 # Prevent double counting
