extends Control

var items = {
	"pets": [
		{"name": "Hızlandırıcı Kedi", "tier": 1},
		{"name": "Zamanla Can Basan Doktor Dron", "tier": 2},
		{"name": "Ruh Emici", "tier": 3},
		{"name": "Kalkan Dronu", "tier": 4},
		{"name": "Alev Püskürten Ejderha", "tier": 5},
		{"name": "Şifacı Peri", "tier": 5}
	],
	"costumes": [
		{"name": "Maksimum Can Artırıcı", "tier": 1},
		{"name": "İtme Dalgası", "tier": 3},
		{"name": "Gölge Koşucu", "tier": 3},
		{"name": "Mıknatıs Zırhı", "tier": 4},
		{"name": "Reflektör", "tier": 5},
		{"name": "Run Başı 1 Kez Dirilme", "tier": 5}
	],
	"weapons": [
		{"name": "Shotgun", "tier": 2},
		{"name": "Boomerang", "tier": 3},
		{"name": "Homing Missile", "tier": 3},
		{"name": "Orbit Bullets", "tier": 4},
		{"name": "Chain Lightning", "tier": 4},
		{"name": "Wizard Staff", "tier": 5},
		{"name": "Black Hole", "tier": 5}
	]
}

var grid: GridContainer
var spin_btn: Button
var is_spinning: bool = false
var spin_time_elapsed: float = 0.0
var spin_delay: float = 0.05
var spin_step_timer: float = 0.0
var current_index: int = 0
var target_index: int = 0
var roll_count: int = 0
var locked_grid: GridContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Donma hissi icin pause=true altinda calis


	# Animasyon ve UI
	var panel = $PanelContainer
	var vbox = panel.get_node("VBoxContainer")
	var close_btn = vbox.get_node("CloseBtn")
	var tab = vbox.get_node("TabContainer")
	spin_btn = vbox.get_node("SpinBtn")
	spin_btn.pressed.connect(_on_spin)
	# Sekmeleri dinamik doldur
	_populate_tab(tab.get_node("Weapons"), "weapons")
	_populate_tab(tab.get_node("Pets"), "pets")
	_populate_tab(tab.get_node("Costumes"), "costumes")

	# Varsayilan olarak ilk sekme
	grid = tab.get_node("Weapons").get_node("GridContainer")

	close_btn.pressed.connect(func():
		if is_spinning:
			is_spinning = false
			_award_item(target_index)
		get_tree().paused = false
		queue_free()
	)

	tab.tab_changed.connect(func(tab_idx: int):
		if tab_idx == 0: grid = tab.get_node("Weapons").get_node("GridContainer")
		elif tab_idx == 1: grid = tab.get_node("Pets").get_node("GridContainer")
		elif tab_idx == 2: grid = tab.get_node("Costumes").get_node("GridContainer")
	)


func _on_spin() -> void:
	if is_spinning: return
	is_spinning = true
	locked_grid = grid

	# Sadece havuzda kalan (level < 20) esyalari bulalim
	var active_items = []
	for i in range(locked_grid.get_child_count()):
		var p = locked_grid.get_child(i)
		if p.get_meta("level") < 20:
			active_items.append(i)

	if active_items.size() == 0:
		is_spinning = false
		return # Bu sekmedeki her sey MAX!

	# Flattening ve Dinamik Ihtimal Dagitimi
	# Kalan esyalarin tierlarina gore temel agirliklari toplayalim
	var tier_weights = {1: 0.60, 2: 0.25, 3: 0.10, 4: 0.04, 5: 0.05}
	var available_weights = 0.0
	for i in active_items:
		var p = grid.get_child(i)
		var cat = p.get_meta("category")
		var idx = p.get_meta("item_index")
		var t = items[cat][idx]["tier"]
		available_weights += tier_weights[t]

	# Yeni dagilimli rastgelelik
	var rand = randf() * available_weights
	var current_weight = 0.0
	target_index = active_items[0] # Fallback

	for i in active_items:
		var p = grid.get_child(i)
		var cat = p.get_meta("category")
		var idx = p.get_meta("item_index")
		var t = items[cat][idx]["tier"]
		current_weight += tier_weights[t]
		if rand <= current_weight:
			target_index = i
			break

	# Sinsi hile (Dopamin Gacha): Profesyonel Near Miss Animasyonu.
	# Hile: hedef_index'i onceden seciyoruz fakat gorsel carkı hedef index'in 2 gerisinde (efsanevi uzerinde) saniye boyunca yavaslatip
	# hedefte durduracagiz. Animasyonun icinde _process te halledecegiz.

	# Hedef indeks bulundu. Donusu baslat:
	spin_time_elapsed = 0.0
	spin_step_timer = 0.0
	spin_delay = 0.02

func _process(delta: float) -> void:
	if not is_spinning: return

	spin_time_elapsed += delta
	spin_step_timer += delta

	# Ussel yavaslama
	var t = min(spin_time_elapsed / 5.0, 1.0)
	spin_delay = lerp(0.02, 0.4, pow(t, 3.0))

	if spin_step_timer >= spin_delay:
		spin_step_timer = 0.0

		if current_index < locked_grid.get_child_count():
			locked_grid.get_child(current_index).modulate = Color.WHITE
			locked_grid.get_child(current_index).scale = Vector2.ONE

		current_index = (current_index + 1) % locked_grid.get_child_count()

		if t > 0.8:
			locked_grid.get_child(current_index).modulate = Color(1.0, 0.0, 1.0) # Sinsi neon mor!
		else:
			locked_grid.get_child(current_index).modulate = Color(1.5, 1.5, 0.0) # Intense Yellow/Gold

		locked_grid.get_child(current_index).scale = Vector2(1.1, 1.1)

	if spin_time_elapsed >= 5.0:
		is_spinning = false

		# Gorseli hedefe kilitle
		if current_index < locked_grid.get_child_count():
			locked_grid.get_child(current_index).modulate = Color.WHITE
			locked_grid.get_child(current_index).scale = Vector2.ONE

		current_index = target_index

		_award_item(target_index)
func _award_item(idx: int) -> void:
	var p = locked_grid.get_child(idx)
	var cat = p.get_meta("category")
	var item_idx = p.get_meta("item_index")

	var item_name = items[cat][item_idx]["name"]
	var lvl = Global.gacha_levels[item_name] + 1
	Global.gacha_levels[item_name] = lvl
	Global.save_game()

	p.set_meta("level", lvl)

	var l = p.get_child(0) as Label
	l.text = item_name + "
Tier " + str(items[cat][item_idx]["tier"]) + "
Lvl " + str(lvl) + "/20"

	# MAX Seviyeye ulastiysa karart
	if lvl >= 20:
		p.modulate = Color(0.3, 0.3, 0.3)
		l.text += "
(MAXED)"

	# Global Pasif Enjeksiyonlari (10. ve 20. seviyelerde)
	if lvl == 10:
		Global.perm_max_health += 10.0
		Global.base_speed += 20.0
	elif lvl == 20:
		Global.perm_max_health += 50.0
		Global.base_speed += 50.0
		Global.perm_starting_damage += 15.0

	# Kazanilan gorsel soku
	var tw = create_tween()
	tw.tween_property(p, "scale", Vector2(2.0, 2.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3)
	p.modulate = Color.GREEN # Gecici Yesil

	# Siber Particle
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.color = Color("00ff33")
	particles.position = p.size / 2.0
	p.add_child(particles)

func _populate_tab(tab_node: Node, category: String) -> void:
	var grid_container = tab_node.get_node("GridContainer")
	for child in grid_container.get_children():
		child.queue_free()

	var cat_items = items[category]
	for i in range(cat_items.size()):
		var item = cat_items[i]
		var item_name = item["name"]
		if not Global.gacha_levels.has(item_name):
			Global.gacha_levels[item_name] = 0
		var current_lvl = Global.gacha_levels[item_name]

		var panel_container = PanelContainer.new()
		panel_container.custom_minimum_size = Vector2(180, 120)
		panel_container.set_meta("category", category)
		panel_container.set_meta("item_index", i)
		panel_container.set_meta("level", current_lvl)

		var label = Label.new()
		label.text = item_name + "
Tier " + str(item["tier"]) + "
Lvl " + str(current_lvl) + "/20"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel_container.add_child(label)

		if current_lvl >= 20:
			panel_container.modulate = Color(0.3, 0.3, 0.3)
			label.text += "
(MAXED)"

		grid_container.add_child(panel_container)