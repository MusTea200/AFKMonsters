extends StaticBody2D
class_name GrappleNode

enum Rarity { WHITE, BLUE, PURPLE }

@export var rarity: Rarity = Rarity.WHITE

# Defaults
var stiffness: float = 20.0
var max_rope_length: float = 400.0

func _ready() -> void:
	match rarity:
		Rarity.WHITE:
			stiffness = 15.0
			max_rope_length = 300.0
		Rarity.BLUE:
			stiffness = 30.0
			max_rope_length = 500.0
		Rarity.PURPLE:
			stiffness = 60.0
			max_rope_length = 800.0
