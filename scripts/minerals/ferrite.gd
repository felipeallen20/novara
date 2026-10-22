class_name Ferrite
extends Mineral

## Ferrita (Ferrite): mineral muy común de tono gris metálico. Aparece en
## yacimientos sobre las columnas de DarkStone, fuera de la zona segura.

const ID := 2

const MODEL := preload("res://scenes/minerals/ferrite.tscn")


func _init() -> void:
	id = ID
	display_name = "Ferrita (Ferrite)"
	rarity = Rarity.COMMON
	durability = 1.2
	yield_amount = 1
	color = Color(0.45, 0.44, 0.46)
	host_block_id = DarkStone.ID
	# Yacimientos muy abundantes: parches anchos y cristales en casi todas las
	# columnas del yacimiento.
	patch_threshold = -0.1
	scatter_threshold = 0.12
	loot = LootTable.new([LootEntry.new(FerriteItem.new(), 1, 3)])
	model = MODEL
