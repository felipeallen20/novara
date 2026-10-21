class_name LootEntry
extends Resource

## Una entrada de una tabla de loot: el objeto que suelta y el rango de cantidades.

@export var item: Item
@export var min_amount: int = 1
@export var max_amount: int = 1


func _init(p_item: Item = null, p_min_amount: int = 1, p_max_amount: int = 1) -> void:
	item = p_item
	min_amount = p_min_amount
	max_amount = p_max_amount


## Cantidad que toca a esta entrada en una extracción.
func roll_amount() -> int:
	return randi_range(min_amount, max_amount)
