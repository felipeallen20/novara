class_name InteractionPrompt
extends Control

## Aviso de interacción del HUD: la tecla que hay que pulsar y la acción que
## hace, colocados junto al objeto apuntado. Es un elemento de interfaz y no un
## objeto del mundo, para que se lea siempre con nitidez y no se confunda con la
## geometría de la escena.

## Altura sobre el objeto apuntado donde se ancla el aviso, en bloques.
const TARGET_HEIGHT := 0.5
## Separación del aviso respecto al objeto apuntado, en píxeles.
const SCREEN_OFFSET := Vector2(0.0, -48.0)
## Margen respecto a los bordes de la pantalla, en píxeles.
const SCREEN_MARGIN := 8.0

@onready var _action_label: Label = $Row/ActionLabel

var _target: Node3D
var _camera: Camera3D


## Muestra el aviso junto al objeto indicado.
func show_for(target: Node3D, camera: Camera3D, action_text: String) -> void:
	_target = target
	_camera = camera
	_action_label.text = action_text
	visible = true
	_update_position()


## Oculta el aviso.
func hide_prompt() -> void:
	_target = null
	visible = false


func _process(_delta: float) -> void:
	if visible:
		_update_position()


## Coloca el aviso sobre el objeto apuntado, sin salirse de la pantalla.
func _update_position() -> void:
	if not is_instance_valid(_target) or not is_instance_valid(_camera):
		hide_prompt()
		return
	var anchor := _target.global_position + Vector3.UP * TARGET_HEIGHT
	var screen := _camera.unproject_position(anchor) + SCREEN_OFFSET
	# El aviso se dibuja en el canvas, no en un contenedor: su tamaño lo fija
	# el contenido, y hay que asegurarlo para que no salga recortado.
	var prompt_size := get_combined_minimum_size()
	size = prompt_size
	var view_size := get_viewport_rect().size
	screen.x = clampf(screen.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, view_size.x - prompt_size.x - SCREEN_MARGIN))
	screen.y = clampf(screen.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, view_size.y - prompt_size.y - SCREEN_MARGIN))
	position = screen
