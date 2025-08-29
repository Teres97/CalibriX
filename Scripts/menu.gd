extends Node2D

@onready var resume_button: Button = $Resume
@onready var exit_button: Button = $Exit

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_exit_pressed() -> void:
	get_tree().quit()
