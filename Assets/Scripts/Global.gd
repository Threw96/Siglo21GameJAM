extends Node


var Player: Player = null
var debug_enabled: bool = false

func _ready() -> void:
	debug_enabled = _read_debug_enabled()

func debug_log(message: String) -> void:
	if debug_enabled:
		print(message)

func _read_debug_enabled() -> bool:
	var raw_value: String = OS.get_environment("SIGLO21_DEBUG").to_lower()
	return raw_value == "1" or raw_value == "true" or raw_value == "yes" or raw_value == "on"
