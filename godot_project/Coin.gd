extends Area2D
class_name Coin

@export var value: float = 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_gold(value)
		queue_free()
