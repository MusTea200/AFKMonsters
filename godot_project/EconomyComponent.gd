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
	# 1. Turda toplanan altınları kalıcı bakiyeye (dongu_parcaciklari) aktar 
	# Subway Surfers mantığında her altın 1 birim değerindedir
	Global.dongu_parcaciklari += int(gold) 
	
	# 2. Global üzerinden öldürme bonuslarını hesapla ve verileri kaydet 
	Global.end_run()
