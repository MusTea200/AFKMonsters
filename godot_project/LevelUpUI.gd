extends CanvasLayer
class_name LevelUpUI

signal upgrade_selected(upgrade_type)

@onready var panel = $Panel
@onready var vbox = $Panel/VBoxContainer

# Geliştirme Havuzu (Dictionary: Ağırlık/Nadirlik vb eklenebilir, şimdilik isimler)
var upgrade_pool = [
	{"id": "max_health", "text": "Max Can +20", "weight": 10},
	{"id": "regen", "text": "Can Yenileme +0.5", "weight": 8},
	{"id": "armor", "text": "Hasar Azaltma +5%", "weight": 5},
	{"id": "thorns", "text": "Dikenli Deri +5", "weight": 7},
	{"id": "dodge", "text": "Kaçış Şansı +5%", "weight": 5},
	{"id": "rope_len", "text": "İp Uzunluğu +100", "weight": 8},
	{"id": "fire_rate", "text": "Atış Hızı +0.5", "weight": 10},
	{"id": "bullet_count", "text": "Mermi Sayısı +1", "weight": 3},
	{"id": "piercing", "text": "Delip Geçme +1", "weight": 4},
	{"id": "damage", "text": "Mermi Hasarı +10", "weight": 9}
]

var buttons: Array[Button] = []
@onready var reroll_btn = $Panel/RerollButton
var reroll_cost: float = 10.0
var player_node: Player

func _ready() -> void:
	panel.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # UI runs even when paused
	# Try to find RerollButton, we assume user added it
	reroll_btn = panel.find_child("RerollButton", true, false)
	if reroll_btn:
		reroll_btn.pressed.connect(_on_reroll_pressed)
		
	# Find player
	var scene_nodes = get_tree().current_scene.get_children()
	for n in scene_nodes:
		if n is Player:
			player_node = n
			break


	# Clear existing static buttons
	for child in vbox.get_children():
		child.queue_free()
		
	# Create 3 dynamic buttons
	for i in range(3):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 50)
		btn.pressed.connect(_on_button_pressed.bind(btn))
		vbox.add_child(btn)
		buttons.append(btn)

func show_upgrades() -> void:
	get_tree().paused = true
	Engine.time_scale = 0.0
	
	_roll_upgrades()
	panel.show()

func _roll_upgrades() -> void:
	# Gacha sistemi: Ağırlıklara göre 3 rastgele benzersiz seçenek seç
	var available_upgrades = upgrade_pool.duplicate(true)
	
	for btn in buttons:
		if available_upgrades.is_empty():
			btn.hide()
			continue
			
		btn.show()
		var total_weight = 0
		for upg in available_upgrades:
			total_weight += upg["weight"]
			
		var roll = randi() % total_weight
		var current_weight = 0
		var selected_index = -1
		
		for i in range(available_upgrades.size()):
			current_weight += available_upgrades[i]["weight"]
			if roll < current_weight:
				selected_index = i
				break
				
		var selected_upgrade = available_upgrades[selected_index]
		btn.text = selected_upgrade["text"]
		# Store the ID in metadata so we know what was clicked
		btn.set_meta("upgrade_id", selected_upgrade["id"])
		
		available_upgrades.remove_at(selected_index)

func _on_button_pressed(btn: Button) -> void:
	var upgrade_id = btn.get_meta("upgrade_id")
	_resume_and_emit(upgrade_id)

func _resume_and_emit(type: String) -> void:
	panel.hide()
	Engine.time_scale = 1.0
	get_tree().paused = false
	upgrade_selected.emit(type)

func _on_reroll_pressed() -> void:
	if is_instance_valid(player_node) and player_node.gold >= reroll_cost:
		player_node.add_gold(-reroll_cost)
		_roll_upgrades()
