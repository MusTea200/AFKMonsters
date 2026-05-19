extends Control

var items = {
	"pets": [
		{"name": "Hızlandırıcı Kedi", "tier": 1},
		{"name": "Zamanla Can Basan Doktor Dron", "tier": 2},
		{"name": "Alev Püskürten Ejderha", "tier": 5}
	],
	"costumes": [
		{"name": "Maksimum Can Artırıcı", "tier": 1},
		{"name": "İtme Dalgası", "tier": 3},
		{"name": "Run Başı 1 Kez Dirilme", "tier": 5}
	],
	"weapons": [
		{"name": "Shotgun", "tier": 2},
		{"name": "Boomerang", "tier": 3},
		{"name": "Orbit Bullets", "tier": 4},
		{"name": "Wizard Staff", "tier": 5}
	]
}

var grid: GridContainer
var spin_btn: Button
var is_spinning: bool = false
var spin_time: float = 0.0
var spin_delay: float = 0.05
var current_index: int = 0
var target_index: int = 0
var roll_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Donma hissi icin pause=true altinda calis


	# Animasyon ve UI
	var panel = $PanelContainer
	var vbox = panel.get_node("VBoxContainer")
	var close_btn = vbox.get_node("CloseBtn")
	var tab = vbox.get_node("TabContainer")
	# Sekmeleri dinamik doldur
	_populate_tab(tab.get_node("Weapons"), "weapons")
	_populate_tab(tab.get_node("Pets"), "pets")
	_populate_tab(tab.get_node("Costumes"), "costumes")

	# Varsayilan olarak ilk sekme
	grid = tab.get_node("Weapons").get_node("GridContainer")

	tab.tab_changed.connect(func(tab_idx: int):
		if tab_idx == 0: grid = tab.get_node("Weapons").get_node("GridContainer")
		elif tab_idx == 1: grid = tab.get_node("Pets").get_node("GridContainer")
		elif tab_idx == 2: grid = tab.get_node("Costumes").get_node("GridContainer")
	)


func _on_spin() -> void:
	if is_spinning: return
	is_spinning = true

	# Sadece havuzda kalan (level < 20) esyalari bulalim
	var active_items = []
	for i in range(grid.get_child_count()):
		var p = grid.get_child(i)
		if p.get_meta("level") < 20:
			active_items.append(i)

	if active_items.size() == 0:
		is_spinning = false
		return # Bu sekmedeki her sey MAX!

	# Flattening ve Dinamik Ihtimal Dagitimi
	# Kalan esyalarin tierlarina gore temel agirliklari toplayalim
	var tier_weights = {1: 0.60, 2: 0.25, 3: 0.10, 4: 0.04, 5: 0.01}
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
	spin_time = 0.0
	spin_delay = 0.02 # Baslangicta inanilmaz hizli don!
	roll_count = 40 + target_index # 40 tam tur + hedefe varis

func _process(delta: float) -> void:
	if not is_spinning: return

	spin_time += delta
	if spin_time >= spin_delay:
		spin_time = 0.0

		# Reset old glow
		if current_index < grid.get_child_count():
			grid.get_child(current_index).modulate = Color.WHITE
			grid.get_child(current_index).scale = Vector2.ONE

		current_index = (current_index + 1) % grid.get_child_count()

		# Set new glow

		# Cyberpunk ses tınısı simülasyonu (Bip Bop)
		# AudioStreamPlayer eklenebilir


		# Profesyonel Near Miss Yavaslamasi
		roll_count -= 1

		if roll_count < 10:
			spin_delay += 0.08 # Sona yaklastikca katlanarak yavasla

			# Sondan 1 ve 2 onceki adimlari efsanevi esyalar mis gibi parlat
			if roll_count == 1 or roll_count == 2:
				grid.get_child(current_index).modulate = Color(1.0, 0.0, 1.0) # Sinsi neon mor!
		else:
			grid.get_child(current_index).modulate = Color(1.5, 1.5, 0.0) # Intense Yellow/Gold

		grid.get_child(current_index).scale = Vector2(1.1, 1.1)



func _award_item(idx: int) -> void:
	var p = grid.get_child(idx)
	var cat = p.get_meta("category")
	var item_idx = p.get_meta("item_index")
	var lvl = p.get_meta("level") + 1
	p.set_meta("level", lvl)

	var l = p.get_child(0) as Label
	l.text = items[cat][item_idx]["name"] + "\nTier " + str(items[cat][item_idx]["tier"]) + "\nLvl " + str(lvl) + "/20"

	# MAX Seviyeye ulastiysa karart
	if lvl >= 20:
		p.modulate = Color(0.3, 0.3, 0.3)
		l.text += "\n(MAXED)"

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
	tw.tween_property(p, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(p, "scale", Vector2.ONE, 0.3)
	p.modulate = Color.GREEN # Gecici Yesil
