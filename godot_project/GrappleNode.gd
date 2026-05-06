extends StaticBody2D
class_name GrappleNode

enum NodeType { NORMAL, QUANTUM, PRISM, STASIS }

@export var node_type: NodeType = NodeType.NORMAL

# Defaults
var stiffness: float = 20.0
var max_rope_length: float = 400.0
var type_activated: bool = false

func _ready() -> void:
	# Randomize if not explicitly set
	if node_type == NodeType.NORMAL:
		var rand_val = randf()
		if rand_val > 0.95:
			node_type = NodeType.STASIS
		elif rand_val > 0.85:
			node_type = NodeType.PRISM
		elif rand_val > 0.75:
			node_type = NodeType.QUANTUM
			
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

func trigger_effect(player: Player) -> void:
	if type_activated:
		return
	type_activated = true
	
	match node_type:
		NodeType.QUANTUM:
			# Extra speed burst
			var pull_dir = player.global_position.direction_to(global_position)
			player.apply_central_impulse(pull_dir * 3000.0)
		NodeType.PRISM:
			# Shoot extra random bullets
			if player.bullet_scene:
				for i in range(8):
					var angle = (PI * 2.0 / 8.0) * i
					var bullet = player.bullet_scene.instantiate() as Bullet
					bullet.global_position = global_position
					bullet.direction = Vector2(cos(angle), sin(angle))
					bullet.damage = player.mermi_hasari * 0.5
					bullet.pierce_count = 1
					get_tree().current_scene.add_child(bullet)
		NodeType.STASIS:
			# Freeze nearby enemies momentarily (or just give big armor to player)
			player.hasar_azaltma = min(player.hasar_azaltma + 0.5, 0.9)
			# We'll just let it wear off when they take damage next time, or just keep it as a permanent micro-buff for now
			# A more complex stasis would need a timer on Player, but we stick to simplicity.
