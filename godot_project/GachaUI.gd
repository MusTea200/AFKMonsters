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
	var scroll = tab.get_node("Weapons")
	grid = scroll.get_node("GridContainer")
	spin_btn = vbox.get_node("SpinBtn")

	close_btn.pressed.connect(func():
		get_tree().paused = false
		queue_free()
	)
	spin_btn.pressed.connect(_on_spin)

	for w in items["weapons"]:
		var p = Panel.new()
		p.custom_minimum_size = Vector2(150, 150)
		var l = Label.new()
		l.text = w["name"] + "\nTier " + str(w["tier"])
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		p.add_child(l)
		grid.add_child(p)

func _on_spin() -> void:
	if is_spinning: return
	is_spinning = true

	# Temel Olasilik & Near-Miss algoritmasi
	var rand = randf()
	var tier = 1
	if rand > 0.95: tier = 5
	elif rand > 0.91: tier = 4
	elif rand > 0.81: tier = 3
	elif rand > 0.60: tier = 2

	# Cikan tier'a uygun bir hedef bul
	var possible_targets = []
	for i in range(grid.get_child_count()):
		if items["weapons"][i]["tier"] == tier:
			possible_targets.append(i)

	if possible_targets.size() > 0:
		target_index = possible_targets[randi() % possible_targets.size()]
	else:
		target_index = 0

	# Sinsi hile: Hedefin 1-2 adim gerisinde Tier 4/5 varmis gibi goster (Dopamin gacha)
	# Eğer hedef Tier 1-3 ise, onu çevreleyen slotlardan (görsel olarak) birini zorla Tier 5 yapalım ki göz yanılsaması olsun.
	# Bu sadece görsel bir hiledir, the target is already selected.
	if tier <= 3:
		var bait_idx = (target_index - 1) % grid.get_child_count()
		if bait_idx < 0: bait_idx += grid.get_child_count()
		var p = grid.get_child(bait_idx)
		if p and p.get_child_count() > 0:
			var l = p.get_child(0) as Label
			if l: l.text = ">> LEGENDARY BAIT <<\nTier 5"
	# Burada basitce spin suresini ve animasyonunu baslatiyoruz
	spin_time = 0.0
	spin_delay = 0.05
	roll_count = 30 + target_index # En az 30 tur don

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
		grid.get_child(current_index).modulate = Color(1.5, 1.5, 0.0) # Intense Yellow/Gold
		grid.get_child(current_index).scale = Vector2(1.1, 1.1)

		# Cyberpunk ses tınısı simülasyonu (Bip Bop)
		# AudioStreamPlayer eklenebilir

		roll_count -= 1

		# Yavaslat (Sona dogru)
		if roll_count < 10:
			spin_delay += 0.05

		if roll_count <= 0:
			is_spinning = false
			# Odul kazandirma logic'i buraya gelecek
