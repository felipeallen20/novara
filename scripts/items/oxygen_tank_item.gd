class_name OxygenTankItem
extends Item

## Tanque de oxígeno: consumible que se fabrica en la estación de fabricación.

const ID := 4

const ICON := preload("res://assets/items/icons/consumables/oxygen_tank.png")


func _init() -> void:
	id = ID
	display_name = "Tanque de Oxígeno"
	icon = ICON
