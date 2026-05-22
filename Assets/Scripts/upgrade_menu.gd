extends CanvasLayer

var player: Player
var choices: Array[StatBuff] = []
var buttons: Array[Button] = []
var selected_index: int = 0

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var option_buttons: VBoxContainer = $Panel/VBoxContainer/OptionButtons

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	buttons = [
		$Panel/VBoxContainer/OptionButtons/OptionButton1,
		$Panel/VBoxContainer/OptionButtons/OptionButton2,
		$Panel/VBoxContainer/OptionButtons/OptionButton3,
	]
	for index in range(buttons.size()):
		buttons[index].pressed.connect(_on_option_pressed.bind(index))
		buttons[index].mouse_entered.connect(_select_option.bind(index))
		buttons[index].process_mode = Node.PROCESS_MODE_ALWAYS
	_update_buttons()
	_select_option(0)

func setup(_player: Player, _choices: Array[StatBuff], level: int) -> void:
	player = _player
	choices = _choices
	if is_node_ready():
		title_label.text = "Nivel %s" % level
		_update_buttons()
		_select_option(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_select_option(wrapi(selected_index - 1, 0, buttons.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_select_option(wrapi(selected_index + 1, 0, buttons.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or _is_confirm_key(event):
		_choose_selected_option()
		get_viewport().set_input_as_handled()

func _is_confirm_key(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false
	var key_event: InputEventKey = event as InputEventKey
	return key_event.pressed and not key_event.echo and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE)

func _update_buttons() -> void:
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		button.disabled = index >= choices.size()
		if index < choices.size():
			button.text = _get_choice_text(choices[index])
		else:
			button.text = "-"

func _select_option(index: int) -> void:
	selected_index = clampi(index, 0, buttons.size() - 1)
	buttons[selected_index].grab_focus()

func _choose_selected_option() -> void:
	_on_option_pressed(selected_index)

func _on_option_pressed(index: int) -> void:
	if player == null or index < 0 or index >= choices.size():
		return
	player.choose_upgrade(index)
	get_tree().paused = false
	queue_free()

func _get_choice_text(choice: StatBuff) -> String:
	var stat_name: String = String(Stats.BuffableStats.keys()[choice.stat]).capitalize().replace("_", " ")
	match choice.buff_type:
		StatBuff.BuffType.ADD:
			return "+%.0f %s" % [choice.buff_amount, stat_name]
		StatBuff.BuffType.MULTIPLY:
			return "+%d%% %s" % [roundi(choice.buff_amount * 100.0), stat_name]
	return stat_name
