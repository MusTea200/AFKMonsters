extends Area2D
class_name Redzone

var player: Node2D
var inside_time: float = 0.0
var debuff_active: bool = false
var debuff_timer: float = 0.0

var original_speed: float = 0.0
var original_regen: float = 0.0

var visual: Sprite2D

func _ready() -> void:
	visual = Sprite2D.new()
	visual.texture = load("res://icon.svg")
	visual.modulate = Color(1.0, 0.0, 0.0, 0.3)
	visual.scale = Vector2(10.0, 10.0) # Large area
	add_child(visual)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 300.0
	col.shape = shape
	add_child(col)

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		inside_time += delta

		# Anında debuff uygula
		if not debuff_active:
			_apply_debuff()

		visual.modulate.a = min(0.5, 0.3 + (inside_time * 0.1))
	else:
		if debuff_active:
			debuff_timer -= delta
			if debuff_timer <= 0:
				_remove_debuff()

		visual.modulate.a = max(0.3, visual.modulate.a - delta * 0.2)
		inside_time = max(0.0, inside_time - delta * 2.0)

func _on_area_entered(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		player = area if area.name == "Player" else area.get_parent()

func _on_area_exited(area: Area2D) -> void:
	if area is Enemy: return
	if area.name == "Player" or area.get_parent().name == "Player":
		player = null
		# Çıkınca sürenin 1/3'ü kadar debuff devam eder
		debuff_timer = inside_time / 3.0

func _apply_debuff() -> void:
	debuff_active = true
	var p = player if is_instance_valid(player) else get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p):
		original_speed = p.max_speed
		original_regen = p.combat_comp.can_yenileme

		p.max_speed = original_speed * 0.5
		p.combat_comp.can_yenileme = 0.0
		p.modulate = Color.GREEN_YELLOW

func _remove_debuff() -> void:
	debuff_active = false
	var p = get_tree().current_scene.find_child("Player", true, false)
	if is_instance_valid(p) and original_speed > 0:
		p.max_speed = original_speed
		p.combat_comp.can_yenileme = original_regen
		p.modulate = Color.WHITE

		original_speed = 0.0
