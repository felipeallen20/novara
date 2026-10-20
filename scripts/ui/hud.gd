extends CanvasLayer

## HUD que muestra la integridad y el oxígeno del jugador en porcentaje.
## Se actualiza solo cuando PlayerStats emite stat_changed; no consulta los
## valores cada frame.

@export var player: PlayerController

@onready var _integrity_bar: ProgressBar = $VBoxContainer/IntegrityRow/IntegrityBar
@onready var _integrity_value: Label = $VBoxContainer/IntegrityRow/IntegrityValue
@onready var _oxygen_bar: ProgressBar = $VBoxContainer/OxygenRow/OxygenBar
@onready var _oxygen_value: Label = $VBoxContainer/OxygenRow/OxygenValue


func _ready() -> void:
	if player == null:
		push_error("HUD: falta asignar 'Player' en el Inspector del nodo HUD (escena res://scenes/hud.tscn).")
		return
	player.stats.stat_changed.connect(_on_stat_changed)
	_update_stat(PlayerStats.STAT_INTEGRITY, player.stats.integrity, player.stats.max_integrity)
	_update_stat(PlayerStats.STAT_OXYGEN, player.stats.oxygen, player.stats.max_oxygen)


func _on_stat_changed(stat: StringName, current: float, maximum: float) -> void:
	_update_stat(stat, current, maximum)


func _update_stat(stat: StringName, current: float, maximum: float) -> void:
	var percent := int(roundf(current / maximum * 100.0))
	match stat:
		PlayerStats.STAT_INTEGRITY:
			_integrity_bar.max_value = maximum
			_integrity_bar.value = current
			_integrity_value.text = "%d %%" % percent
		PlayerStats.STAT_OXYGEN:
			_oxygen_bar.max_value = maximum
			_oxygen_bar.value = current
			_oxygen_value.text = "%d %%" % percent
