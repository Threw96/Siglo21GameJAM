extends Control

const MAIN_MENU_SCENE_PATH: String = "res://Scenes/Menu.tscn"

@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready() -> void:
	get_tree().paused = false
	back_button.grab_focus()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
