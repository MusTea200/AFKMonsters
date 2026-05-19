extends Node2D
class_name DeathLine

var move_speed: float = 300.0
var line_visual: ColorRect
var player: Node2D
var damage_amount: float = 9999.0

func _ready() -> void:
	line_visual = ColorRect.new()
	line_visual.color = Color(1.0, 0.0, 0.0, 0.5)
	line_visual.custom_minimum_size = Vector2(10000, 2000)
	line_visual.position = Vector2(-5000, -2000)
	add_child(line_visual)

	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10000, 2000)
	col.shape = shape
	col.position = Vector2(0, -1000) # Center of visual
	area.add_child(col)
	add_child(area)

	area.area_entered.connect(_on_area_entered)
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position.x += move_speed * delta

func _on_area_entered(area: Area2D) -> void:
	_check_kill(area)

func _on_body_entered(body: Node2D) -> void:
	_check_kill(body)

func _check_kill(node: Node) -> void:
	if node is Player or node.name == "Player":
		node.current_health = 0
		node.take_damage(damage_amount)
	elif node is Enemy:
		node.current_health = 0
		node._take_damage(damage_amount)
