extends Node

func hitstop(duration: float = 0.05, slow_scale: float = 0.1) -> void:
	Engine.time_scale = slow_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
