class_name LavenderStone
extends Block

## Bloque de superficie: piedra de tono lavanda, algo más clara que el resto de la paleta
## mineral. Alterna con SoftGround para dar variedad al terreno.

const ID := 2


func _init() -> void:
	id = ID
	display_name = "LavenderStone"
	color = Color(0.78, 0.74, 0.92)
	opaque = true
	solid = true
