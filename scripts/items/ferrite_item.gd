class_name FerriteItem
extends Item

## Ferrita (Ferrite): objeto que se obtiene al minar el mineral homónimo.

const ID := 2

const ICON := preload("res://assets/items/icons/minerals/ferrite-item.png")


func _init() -> void:
	id = ID
	display_name = "Ferrita (Ferrite)"
	icon = ICON
