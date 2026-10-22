class_name Oxyfern
extends Plant

## Oxyfern: helecho que crece al pie de las montañas, en el suelo blando que
## queda bajo los bordes de roca. Solo aparece donde el desnivel tiene 4 o más
## bloques de altura, y de forma separada: hay que buscarlas un poco.

const ID := 1

const MODEL := preload("res://scenes/plants/oxyfern.tscn")


func _init() -> void:
	id = ID
	display_name = "Oxyfern"
	model = MODEL
	host_block_id = SoftGround.ID
	cliff_block_ids = [DarkStone.ID, LavenderStone.ID]
	min_cliff_height = 4
	density = 0.105
	spacing = 4
	scale_range = Vector2(0.85, 1.15)
