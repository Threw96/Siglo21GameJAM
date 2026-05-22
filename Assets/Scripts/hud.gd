extends CanvasLayer

var stats: Stats

@onready var xp_bar: ProgressBar = $TopBar/XpBar
@onready var xp_label: Label = $TopBar/XpBar/XpLabel
@onready var level_label: Label = $LevelLabel

func setup(_stats: Stats) -> void:
	stats = _stats
	if stats == null:
		return
	if not stats.experience_changed.is_connected(_on_experience_changed):
		stats.experience_changed.connect(_on_experience_changed)
	if not stats.leveled_up.is_connected(_on_leveled_up):
		stats.leveled_up.connect(_on_leveled_up)
	if is_node_ready():
		_update_hud()

func _ready() -> void:
	xp_label.visible = Global.debug_enabled
	if stats != null:
		_update_hud()

func _on_experience_changed(_experience: float, _level: int) -> void:
	_update_hud()

func _on_leveled_up(_new_level: int, _old_level: int) -> void:
	_update_hud()

func _update_hud() -> void:
	if stats == null:
		return
	var current_xp: float = stats.get_current_level_experience()
	var required_xp: float = stats.get_next_level_required_experience()
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp
	xp_label.visible = Global.debug_enabled
	xp_label.text = "%d / %d XP" % [roundi(current_xp), roundi(required_xp)]
	level_label.text = "Nivel %s" % stats.level
