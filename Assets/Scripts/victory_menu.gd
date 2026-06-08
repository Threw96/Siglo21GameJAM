extends Control

const CHARACTER_SELECT_SCENE_PATH: String = "res://Scenes/CharacterSelectMenu.tscn"

@onready var replay_button: Button = $CenterContainer/VBoxContainer/ReplayButton

func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_game_start()
	replay_button.grab_focus()

func _on_replay_button_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)
