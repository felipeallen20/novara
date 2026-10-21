class_name SanditeItem
extends Item

## Arenita (Sandite): objeto que se obtiene al minar el mineral homónimo.

const ID := 1

const ICON := preload("res://assets/items/icons/minerals/sandite-item.png")


func _init() -> void:
	id = ID
	display_name = "Arenita (Sandite)"
	icon = ICON
