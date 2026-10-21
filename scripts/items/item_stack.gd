class_name ItemStack
extends RefCounted

## Unidades de un mismo objeto apiladas en una casilla del inventario.

var item: Item
var amount: int


func _init(p_item: Item, p_amount: int = 1) -> void:
	item = p_item
	amount = p_amount
