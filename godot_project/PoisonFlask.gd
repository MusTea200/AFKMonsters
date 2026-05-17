extends Node2D

var target_pos: Vector2
var speed: float = 800.0
var poison_pool_scene = preload("res://PoisonPool.tscn")

func _ready() -> void:
	var visual = Sprite2D.new()
	visual.texture = load("res://icon.svg")
	visual.modulate = Color(0.2, 1.0, 0.2)
	visual.scale = Vector2(0.2, 0.2)
	add_child(visual)

func _process(delta: float) -> void:
	var dir = global_position.direction_to(target_pos)
	var dist = global_position.distance_to(target_pos)

	if dist < speed * delta:
		_explode()
	else:
		global_position += dir * speed * delta
		rotation += 10.0 * delta

func _explode() -> void:
	if poison_pool_scene:
		var pool = poison_pool_scene.instantiate()
		pool.global_position = global_position
		pool.scale = Vector2(1.5, 1.5) # Player's poison pool is bigger
		get_tree().current_scene.add_child(pool)
	queue_free()
