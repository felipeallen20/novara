class_name Sandite
extends Mineral

## Arenita (Sandite): mineral común de tono gris/café opaco. Aparece en yacimientos
## de cristales sobre las columnas de SoftGround, fuera de la zona segura.

const ID := 1

const MODEL := preload("res://scenes/minerals/sandite.tscn")


func _init() -> void:
	id = ID
	display_name = "Arenita (Sandite)"
	rarity = Rarity.COMMON
	durability = 1.5
	yield_amount = 1
	color = Color(0.47, 0.41, 0.34)
	host_block_id = SoftGround.ID
	loot = LootTable.new([LootEntry.new(SanditeItem.new(), 1, 2)])
	model = MODEL
