extends Area2D

var player: Node2D
var dot_timer: float = 0.0
var damage_per_tick: float = 5.0
var visual: Polygon2D

func _ready() -> void:
	# Siber Neon Yeşili Polygon2D Görseli
	visual = Polygon2D.new()
	var points = PackedVector2Array()
	var radius = 40.0
	for i in range(32):
		var angle = (i / 32.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points
	visual.color = Color(0.2, 1.0, 0.2, 0.6) # Neon green
	add_child(visual)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 3 Saniyelik Ömür (Fade Out & Die)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 3.0)
	tween.tween_callback(self.queue_free)

func _process(delta: float) -> void:
	if is_instance_valid(player):
		dot_timer += delta
		if dot_timer >= 1.0: # Her 1 saniyede bir vur
			dot_timer = 0.0
			if player.has_method("take_damage"):
				player.take_damage(damage_per_tick)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		# Girdiği gibi ilk hasarı vuralım, beklemesin
		if player.has_method("take_damage"):
			player.take_damage(damage_per_tick)
		dot_timer = 0.0

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
