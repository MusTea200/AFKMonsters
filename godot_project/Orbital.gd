extends Node2D
class_name OrbitalPivot

@export var rotation_speed: float = 3.0
@export var damage: float = 50.0

var area: Area2D

func _ready() -> void:
	# Safely find the Area2D child dynamically without hardcoding paths that could break if user changes the scene
	for child in get_children():
		if child is Area2D:
			area = child
			break

	if area:
		area.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	rotation += rotation_speed * delta

func _on_area_entered(other_area: Area2D) -> void:
	if other_area is Enemy:
		other_area.take_orbital_damage(damage)
