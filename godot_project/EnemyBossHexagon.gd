extends Enemy

func _ready() -> void:
	super._ready()
	is_boss = true

	# Ana gövde (Area2D olan kendisi) hasarı yok saysın
	# Mermiler body_entered veya _take_damage çağırınca bunu ezeceğiz
	# Zayıf nokta ise WeakSpot isimli alt düğümde

func take_damage(amount: float, knock_dir: Vector2 = Vector2.ZERO) -> void:
	pass # Ana gövde hasar almaz!
	# Mermiler buraya çarptığında sadece silinir. (Bullet.gd take_damage'i çağırır)

func weak_spot_hit(amount: float, knock_dir: Vector2 = Vector2.ZERO) -> void:
	# Gerçek hasar zayıf noktadan alınır
	super.take_damage(amount, knock_dir)

	# Zayıf nokta vurulduğunda spesifik Boss sarsıntısı ve parlaması
	var tween = create_tween()
	modulate = Color.RED
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
