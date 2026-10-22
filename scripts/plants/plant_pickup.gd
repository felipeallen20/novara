class_name PlantPickup
extends Node3D

## Planta que se puede recoger: al apuntarla y pulsar la tecla de interacción, el
## jugador se lleva el item y la planta desaparece del mundo.
##
## La escena lleva un Area3D para que el rayo de puntería la alcance. El aviso
## con la tecla que hay que pulsar lo muestra el HUD, como elemento de interfaz.

## Item que deja al recogerla.
@export var item: Item
## Distancia máxima, en bloques, a la que se puede recoger.
@export var pick_up_distance: float = 2.5


## True si el jugador está lo bastante cerca para recogerla.
func can_pick_up(from_position: Vector3) -> bool:
	return global_position.distance_to(from_position) <= pick_up_distance


## Recoge la planta y devuelve el item que deja. La planta desaparece del mundo.
func pick_up() -> Item:
	var collected := item
	queue_free()
	return collected
