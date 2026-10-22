class_name OxyfernItem
extends Item

## Oxyfern: objeto que se obtiene al recoger la planta homónima.

const ID := 3

const ICON := preload("res://assets/items/icons/plants/oxyfern.png")


func _init() -> void:
	id = ID
	display_name = "Oxyfern"
	icon = ICON
