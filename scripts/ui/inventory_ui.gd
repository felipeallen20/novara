extends CanvasLayer

## Abre y cierra la interfaz de inventario con la accion "open_inventory".
## La interfaz es una UI 2D clasica (CanvasLayer + Control) con una cuadricula
## de 32 celdas (8 columnas x 4 filas), definida en inventory.tscn.
##
## Con el inventario abierto el raton queda libre para navegar la interfaz.
## Mantener el click derecho captura el raton temporalmente para mirar
## alrededor; al soltarlo se vuelve a liberar para seguir usando la interfaz.

const INVENTORY_SCENE := preload("res://scenes/ui/inventory/inventory.tscn")

@export var player: PlayerController

var _inventory: CanvasLayer
var _open := false
## True mientras el click derecho se mantiene para mirar alrededor.
var _looking := false


func _ready() -> void:
	if player == null:
		# El HUD conoce al jugador; el inventario lo hereda para no duplicar la ruta.
		player = get_parent().get("player") as PlayerController
	if player == null:
		push_error("InventoryUi: falta la referencia al jugador.")
	_inventory = INVENTORY_SCENE.instantiate()
	add_child(_inventory)
	_inventory.visible = false
	if player != null:
		_inventory.bind(player.inventory)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		get_viewport().set_input_as_handled()
		set_open(not _open)
		return
	if not _open:
		return
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_RIGHT:
		return
	_looking = button.pressed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _looking else Input.MOUSE_MODE_VISIBLE
	# Evita que el click derecho active menus contextuales de los controles.
	get_viewport().set_input_as_handled()


func set_open(open: bool) -> void:
	_open = open
	_inventory.visible = open
	_looking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
