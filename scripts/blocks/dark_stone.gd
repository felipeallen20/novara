class_name DarkStone
extends Block

## Piedra de tono morado oscuro, la más oscura de la paleta mineral. Aparece en
## franjas del terreno junto a SoftGround y LavenderStone según el ruido de material.

const ID := 3


func _init() -> void:
	id = ID
	display_name = "DarkStone"
	color = Color(0.3, 0.19, 0.42)
	opaque = true
	solid = true
