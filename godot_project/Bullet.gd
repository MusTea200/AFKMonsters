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
	rotation = direction.angle() # Mermi Doguya bakiyor, direk vector acisi alinir
	_traveled_distance += move_vec.length()
	
	if _traveled_distance >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "WeakSpot" and area.get_parent() and area.get_parent().get_parent() and area.get_parent().get_parent().get_parent() is Enemy:
		# Traverse up from WeakSpot -> Polygon2D -> CollisionPolygon2D -> Boss (Enemy)
		var boss = area.get_parent().get_parent().get_parent()
		if boss.has_method("weak_spot_hit"):
			boss.weak_spot_hit(damage, direction)

			# Krit spark VFX
			var sparks = CPUParticles2D.new()
			sparks.emitting = false
			sparks.one_shot = true
			sparks.lifetime = 0.5
			sparks.spread = 180.0
			sparks.initial_velocity_min = 200.0
			sparks.initial_velocity_max = 400.0
			sparks.color = Color.RED
			get_tree().current_scene.add_child(sparks)
			sparks.global_position = global_position
			sparks.emitting = true

		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
	elif area is Enemy:
		area.take_damage(damage, direction)
		
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
