extends StaticBody2D
class_name GrappleNode

enum NodeType { NORMAL, QUANTUM, PRISM, STASIS, RIGID, VORTEX, EXPLOSIVE }

@export var node_type: NodeType = NodeType.NORMAL

var stiffness: float = 20.0
var max_rope_length: float = 400.0
var type_activated: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Hangi düğümün doğacağına rastgele karar ver
	if node_type == NodeType.NORMAL:
		var rand_val = randf()
		if rand_val > 0.95: node_type = NodeType.EXPLOSIVE
		elif rand_val > 0.85: node_type = NodeType.STASIS
		elif rand_val > 0.75: node_type = NodeType.PRISM
		elif rand_val > 0.65: node_type = NodeType.QUANTUM
		elif rand_val > 0.55: node_type = NodeType.RIGID
		elif rand_val > 0.45: node_type = NodeType.VORTEX

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
		NodeType.RIGID: # Pervane Çubuğu
			modulate = Color.ORANGE
			stiffness = 10000.0 # Esneme sıfır!
			max_rope_length = 350.0
		NodeType.VORTEX: # Hızlı Çekim
			modulate = Color.RED
			stiffness = 50.0
			max_rope_length = 800.0
		NodeType.EXPLOSIVE: # Düşman Temizleyici
			modulate = Color.CRIMSON
			stiffness = 20.0
			max_rope_length = 400.0

func _on_mouse_entered() -> void:
	if get_tree().paused: return
	scale = Vector2(1.4, 1.4)
	modulate.v = 1.3

func _on_mouse_exited() -> void:
	scale = Vector2(1.0, 1.0)
	modulate.v = 1.0

# KANCA TAKILDIĞINDA ÇALIŞACAK OLAN ÖZEL GÜÇLER
func trigger_effect(player: Node2D) -> void:
	if type_activated: return # Her düğüm gücünü sadece 1 kez kullanır (Sürekli patlamasın diye)
	type_activated = true
	
	match node_type:
		NodeType.QUANTUM:
			var pull_dir = player.global_position.direction_to(global_position)
			if player.has_method("apply_central_impulse"):
				player.apply_central_impulse(pull_dir * 3000.0)
				
		NodeType.PRISM:
			if "bullet_scene" in player and player.get("bullet_scene"):
				for i in range(8):
					var angle = (PI * 2.0 / 8.0) * i
					var bullet = player.get("bullet_scene").instantiate()
					bullet.global_position = global_position
					bullet.direction = Vector2(cos(angle), sin(angle))
					bullet.damage = player.get("mermi_hasari") * 0.5
					bullet.pierce_count = 1
					get_tree().current_scene.add_child(bullet)
					
		NodeType.STASIS:
			if "hasar_azaltma" in player:
				player.set("hasar_azaltma", min(player.get("hasar_azaltma") + 0.1, 0.9))
				
		NodeType.VORTEX:
			# Quantum'dan çok daha vahşi ve anlık bir kuvvet uygular
			var pull_dir = player.global_position.direction_to(global_position)
			if player.has_method("apply_central_impulse"):
				player.apply_central_impulse(pull_dir * 12000.0) 
				
		NodeType.EXPLOSIVE:
			# Arenadaki düşmanları bul ve bu düğüme yakın olanları yut!
			var arena_nodes = get_tree().current_scene.get_children()
			for child in arena_nodes:
				if "Enemy" in child.name:
					if global_position.distance_to(child.global_position) < 400.0:
						child.queue_free() # Düşmanı anında sil
