extends CanvasLayer

## HUD que muestra la integridad y el oxígeno del jugador en porcentaje, y el
## aviso de interacción (tecla y acción) del objeto que el jugador tiene
## apuntado. Se actualiza solo cuando PlayerStats emite stat_changed; no
## consulta los valores cada frame.

@export var player: PlayerController

#@onready var _integrity_bar: ProgressBar = $VBoxContainer/IntegrityRow/IntegrityBar
@onready var _integrity_value: Label = $VBoxContainer/IntegrityRow/IntegrityValue
#@onready var _oxygen_bar: ProgressBar = $VBoxContainer/OxygenRow/OxygenBar
@onready var _oxygen_value: Label = $VBoxContainer/OxygenRow/OxygenValue
@onready var _prompt: InteractionPrompt = $InteractionPrompt

## Interfaz de interacción abierta (la de fabricación, por ahora).
var _interaction_ui: Node = null


func _ready() -> void:
	if player == null:
		push_error("HUD: falta asignar 'Player' en el Inspector del nodo HUD (escena res://scenes/hud.tscn).")
		return
	player.stats.stat_changed.connect(_on_stat_changed)
	player.interaction_focus_changed.connect(_on_interaction_focus_changed)
	player.interaction_performed.connect(_on_interaction_performed)
	_update_stat(PlayerStats.STAT_INTEGRITY, player.stats.integrity, player.stats.max_integrity)
	_update_stat(PlayerStats.STAT_OXYGEN, player.stats.oxygen, player.stats.max_oxygen)


func _on_stat_changed(stat: StringName, current: float, maximum: float) -> void:
	_update_stat(stat, current, maximum)


## Muestra el aviso de interacción junto al objeto apuntado, o lo oculta
## cuando el jugador deja de apuntarlo.
func _on_interaction_focus_changed(target: Interactable) -> void:
	if target == null:
		_prompt.hide_prompt()
		return
	_prompt.show_for(target, player.get_view_camera(), target.get_interaction_text())


## Abre la interfaz del objeto con el que se ha interactuado, si tiene una.
func _on_interaction_performed(target: Interactable) -> void:
	if target.interaction_ui == null:
		return
	_open_interaction_ui(target.interaction_ui)


## Instancia la interfaz de interacción y la muestra. La interfaz se libera
## sola cuando se cierra.
func _open_interaction_ui(ui_scene: PackedScene) -> void:
	if _interaction_ui != null and is_instance_valid(_interaction_ui):
		_interaction_ui.queue_free()
	_interaction_ui = ui_scene.instantiate()
	add_child(_interaction_ui)


func _update_stat(stat: StringName, current: float, maximum: float) -> void:
	var percent := int(roundf(current / maximum * 100.0))
	match stat:
		PlayerStats.STAT_INTEGRITY:
			_integrity_value.text = "%d %%" % percent
		PlayerStats.STAT_OXYGEN:
			_oxygen_value.text = "%d %%" % percent
