class_name SoftGround
extends Block

## Bloque base de superficie: terreno blando de tono beige/amarillo.

const ID := 1


func _init() -> void:
	id = ID
	display_name = "SoftGround"
	color = Color(0.87, 0.79, 0.55)
	opaque = true
	solid = true
