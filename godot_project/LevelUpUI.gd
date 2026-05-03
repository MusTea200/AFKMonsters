extends CanvasLayer
class_name LevelUpUI

signal upgrade_selected(upgrade_type)

@onready var panel = $Panel
@onready var btn_mass = $Panel/VBoxContainer/BtnMass
@onready var btn_stiffness = $Panel/VBoxContainer/BtnStiffness
@onready var btn_orbital = $Panel/VBoxContainer/BtnOrbital

func _ready() -> void:
	panel.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # UI runs even when paused

	btn_mass.pressed.connect(_on_mass_pressed)
	btn_stiffness.pressed.connect(_on_stiffness_pressed)
	btn_orbital.pressed.connect(_on_orbital_pressed)

func show_upgrades() -> void:
	get_tree().paused = true # Pauses physics and standard process
	# The prompt asked for Engine.time_scale = 0, we can do both or just timescale.
	# get_tree().paused is usually cleaner for UI interactions in Godot.
	Engine.time_scale = 0.0
	panel.show()

func _on_mass_pressed() -> void:
	_resume_and_emit("mass")

func _on_stiffness_pressed() -> void:
	_resume_and_emit("stiffness")

func _on_orbital_pressed() -> void:
	_resume_and_emit("orbital")

func _resume_and_emit(type: String) -> void:
	panel.hide()
	Engine.time_scale = 1.0
	get_tree().paused = false
	upgrade_selected.emit(type)
