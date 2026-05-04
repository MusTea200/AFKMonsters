extends Node2D
class_name OrbitalPivot

@export var rotation_speed: float = 3.0
@export var damage: float = 50.0

@onready var area: Area2D = $OrbitalArea

func _ready() -> void:
	area.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	# Rotate the pivot to make the offset Area2D orbit the player
	rotation += rotation_speed * delta

func _on_area_entered(other_area: Area2D) -> void:
	if other_area is Enemy:
		other_area.take_orbital_damage(damage)
