extends Area2D
class_name Bullet

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0
var damage: float = 10.0
var pierce_count: int = 0
var max_distance: float = 2000.0

var _traveled_distance: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _process(delta: float) -> void:
	var move_vec = direction * speed * delta
	global_position += move_vec
	_traveled_distance += move_vec.length()
	
	if _traveled_distance >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		area._take_damage(damage) # Or call a public method if available
		
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
