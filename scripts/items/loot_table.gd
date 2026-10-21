class_name LootTable
extends Resource

## Tabla de loot: qué suelta un depósito y en qué cantidad. Cada entrada se tira
## por separado y el resultado son unidades de item listas para el inventario.

@export var entries: Array[LootEntry] = []


func _init(p_entries: Array[LootEntry] = []) -> void:
	entries = p_entries


## Objetos sueltos en una sola extracción.
func roll() -> Array[Item]:
	var drops: Array[Item] = []
	for entry in entries:
		for count in entry.roll_amount():
			drops.append(entry.item)
	return drops
