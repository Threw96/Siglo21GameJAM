extends Node


var Player: Player = null
var debug_enabled: bool = false
var env_values: Dictionary[String, String] = {}
var survived_time: float = 0.0
var enemies_killed: int = 0
var is_run_active: bool = false

signal survived_time_changed(time_seconds: float)
signal enemies_killed_changed(kill_count: int)

func _ready() -> void:
	env_values = _read_env_file()
	debug_enabled = _read_debug_enabled()

func _process(delta: float) -> void:
	if not is_run_active:
		return
	survived_time += delta
	survived_time_changed.emit(survived_time)

func start_run() -> void:
	survived_time = 0.0
	enemies_killed = 0
	is_run_active = true
	survived_time_changed.emit(survived_time)
	enemies_killed_changed.emit(enemies_killed)

func stop_run() -> void:
	is_run_active = false

func register_enemy_kill() -> void:
	enemies_killed += 1
	enemies_killed_changed.emit(enemies_killed)

func debug_log(message: String) -> void:
	if debug_enabled:
		print(message)

func _read_debug_enabled() -> bool:
	var raw_value: String = _get_env_value("SIGLO21_DEBUG").to_lower()
	return raw_value == "1" or raw_value == "true" or raw_value == "yes" or raw_value == "on"

func _get_env_value(key: String) -> String:
	if env_values.has(key):
		return env_values[key]
	return OS.get_environment(key)

func _read_env_file() -> Dictionary[String, String]:
	var values: Dictionary[String, String] = {}
	if not FileAccess.file_exists("res://.env"):
		return values
	var file: FileAccess = FileAccess.open("res://.env", FileAccess.READ)
	if file == null:
		return values
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		_parse_env_line(line, values)
	return values

func _parse_env_line(line: String, values: Dictionary[String, String]) -> void:
	if line.begins_with("$env:"):
		line = line.substr(5)
	var separator_index: int = line.find("=")
	if separator_index == -1:
		return
	var key: String = line.substr(0, separator_index).strip_edges()
	var value: String = line.substr(separator_index + 1).strip_edges()
	value = _strip_env_quotes(value)
	if not key.is_empty():
		values[key] = value

func _strip_env_quotes(value: String) -> String:
	if value.length() >= 2:
		var first_char: String = value.substr(0, 1)
		var last_char: String = value.substr(value.length() - 1, 1)
		if (first_char == "\"" and last_char == "\"") or (first_char == "'" and last_char == "'"):
			return value.substr(1, value.length() - 2)
	return value
