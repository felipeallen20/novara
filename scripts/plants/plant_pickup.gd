class_name PlantPickup
extends Interactable

## Planta que se puede recoger: al apuntarla y pulsar la tecla de interacción, el
## jugador se lleva el item y la planta desaparece del mundo.
##
## La escena lleva un Area3D para que el rayo de puntería la alcance. El aviso
## con la tecla que hay que pulsar lo muestra el HUD, como elemento de interfaz.

## Item que deja al recogerla.
@export var item: Item
## Distancia máxima, en bloques, a la que se puede recoger.
@export var pick_up_distance: float = 2.5


## Texto del aviso: qué se recoge y cómo se llama.
func get_interaction_text() -> String:
	if item == null:
		return "Recoger"
	return "Recoger %s" % item.display_name


## Distancia máxima, en bloques, a la que se puede recoger la planta.
func get_interaction_distance() -> float:
	return pick_up_distance


## Recoge la planta y guarda el item en el inventario del jugador.
func interact(player: PlayerController) -> void:
	var collected := pick_up()
	if collected != null:
		player.inventory.add(collected)


## Recoge la planta y devuelve el item que deja. La planta desaparece del mundo.
func pick_up() -> Item:
	var collected := item
	queue_free()
	return collected
