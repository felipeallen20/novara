class_name CraftingUi
extends CanvasLayer

## Interfaz de fabricación de la estación de fabricación. Se abre al
## interactuar con la estación. Todavía no hay recetas: el panel está vacío y
## solo sirve para cerrarse.
##
## La escena se muestra al entrar en el árbol y se libera al cerrarse, así que
## el HUD solo tiene que instanciarla.

@onready var _close_button: Button = $Root/Backdrop/CloseButton

var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _is_open := false


func _ready() -> void:
	_close_button.pressed.connect(close)
	open()


## Abre la interfaz y libera el ratón para poder usarla.
func open() -> void:
	visible = true
	_is_open = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Cierra la interfaz y devuelve el ratón al juego.
func close() -> void:
	visible = false
	_is_open = false
	Input.mouse_mode = _previous_mouse_mode
	queue_free()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	# La misma tecla que abre la interfaz la cierra, sin llegar a interactuar
	# con el mundo por debajo.
	if event.is_action_pressed("interaction"):
		get_viewport().set_input_as_handled()
		close()
