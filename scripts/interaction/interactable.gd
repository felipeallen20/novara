class_name Interactable
extends Node3D

## Objeto del mundo con el que el jugador puede interactuar: una planta que se
## recoge, una estación de fabricación, etc. El jugador apunta con su raycast y
## el objeto al que pertenece lo colisionado es el que entra en el foco.
##
## Cada objeto decide el texto del aviso (get_interaction_text), hasta dónde se
## puede interactuar (get_interaction_distance) y qué ocurre al interactuar
## (interact).

## Interfaz que se abre al interactuar con este objeto. La escena tiene que
## mostrarse al entrar en el árbol y liberarse al cerrarse.
@export var interaction_ui: PackedScene

## Distancia máxima por defecto, en bloques, a la que se puede interactuar.
const DEFAULT_INTERACTION_DISTANCE := 2.5


## Texto de la acción que muestra el aviso de interacción.
func get_interaction_text() -> String:
	return "Interactuar"


## Distancia máxima, en bloques, a la que se puede interactuar.
func get_interaction_distance() -> float:
	return DEFAULT_INTERACTION_DISTANCE


## Ejecuta la interacción con el jugador.
func interact(_player: PlayerController) -> void:
	pass
