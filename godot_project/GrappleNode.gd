extends StaticBody2D
class_name GrappleNode

enum NodeType { NORMAL, QUANTUM, PRISM, STASIS }

@export var node_type: NodeType = NodeType.NORMAL

# Orijinal renk hafızasına artık gerek yok, kodları sildim.
var stiffness: float = 20.0
var max_rope_length: float = 400.0
var type_activated: bool = false

func _ready() -> void:
	# Oyun durduğunda bu düğümler etkileşime girmemeli (ESC için)
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Rastgele düğüm türünü belirle
	if node_type == NodeType.NORMAL:
		var rand_val = randf()
		if rand_val > 0.95:
			node_type = NodeType.STASIS
		elif rand_val > 0.85:
			node_type = NodeType.PRISM
		elif rand_val > 0.75:
			node_type = NodeType.QUANTUM
			
	# Türüne göre kalıcı rengini ve özelliklerini belirle
	match node_type:
		NodeType.NORMAL:
			modulate = Color.YELLOW
			stiffness = 20.0
			max_rope_length = 400.0
		NodeType.QUANTUM:
			modulate = Color.PURPLE
			stiffness = 30.0
			max_rope_length = 600.0
		NodeType.PRISM:
			modulate = Color.CYAN
			stiffness = 15.0
			max_rope_length = 500.0
		NodeType.STASIS:
			modulate = Color.WHITE
			stiffness = 100.0
			max_rope_length = 200.0

# --- FARE ETKİLEŞİMLERİ (TASARIM GÜNCELLEMESİ) ---

func _on_mouse_entered() -> void:
	if get_tree().paused: return # Oyun durduysa büyüme!
	
	# TASARIM ÇÖZÜMÜ: Rengi sarıya döndürmüyoruz, KENDİ renginde bırakıyoruz.
	# Ancak düğümü belirgin şekilde büyütüyoruz ve biraz parlatıyoruz.
	
	# Orijinal boyutu Vector2(1.0, 1.0) idi, %40 büyüterek Vector2(1.4, 1.4) yapalım.
	# Bu çok hissedilir ve havalı durur.
	scale = Vector2(1.4, 1.4)
	
	# Düğümün kendi rengini (modulate) daha parlak hale getirip "seçili" hissi verelim
	modulate.v = 1.3 # Parlaklık değerini (value) artırır

func _on_mouse_exited() -> void:
	# Fare çıkınca eski boyutuna ve eski parlaklığına döndür
	scale = Vector2(1.0, 1.0)
	modulate.v = 1.0 # Parlaklığı normale döndür
