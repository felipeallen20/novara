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


func _ready() -> void:
	if player == null:
		push_error("HUD: falta asignar 'Player' en el Inspector del nodo HUD (escena res://scenes/hud.tscn).")
		return
	player.stats.stat_changed.connect(_on_stat_changed)
	player.interaction_focus_changed.connect(_on_interaction_focus_changed)
	_update_stat(PlayerStats.STAT_INTEGRITY, player.stats.integrity, player.stats.max_integrity)
	_update_stat(PlayerStats.STAT_OXYGEN, player.stats.oxygen, player.stats.max_oxygen)


func _on_stat_changed(stat: StringName, current: float, maximum: float) -> void:
	_update_stat(stat, current, maximum)


## Muestra el aviso de interacción junto a la planta apuntada, o lo oculta
## cuando el jugador deja de apuntarla.
func _on_interaction_focus_changed(plant: PlantPickup) -> void:
	if plant == null:
		_prompt.hide_prompt()
		return
	_prompt.show_for(plant, player.get_view_camera(), _interaction_text(plant))


## Texto de la acción que hace el aviso, con el nombre del item que deja.
func _interaction_text(plant: PlantPickup) -> String:
	if plant.item == null:
		return "Recoger"
	return "Recoger %s" % plant.item.display_name


func _update_stat(stat: StringName, current: float, maximum: float) -> void:
	var percent := int(roundf(current / maximum * 100.0))
	match stat:
		PlayerStats.STAT_INTEGRITY:
			_integrity_value.text = "%d %%" % percent
		PlayerStats.STAT_OXYGEN:
			_oxygen_value.text = "%d %%" % percent
