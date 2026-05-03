extends Area2D
class_name Drop

enum DropType { EXP, GOLD }

@export var drop_type: DropType = DropType.EXP
@export var value: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if drop_type == DropType.EXP:
			body.add_exp(value)
		else:
			body.add_gold(value)
		queue_free()
