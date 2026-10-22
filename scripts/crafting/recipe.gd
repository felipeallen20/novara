class_name Recipe
extends RefCounted

## Receta de fabricación: el item que produce y los materiales que consume.
## Los materiales son pilas: el item y cuántas unidades hacen falta.

var id: StringName = &""
var result: Item
var ingredients: Array[ItemStack] = []


## True si el inventario tiene todos los materiales de la receta.
func can_craft(inventory: InventoryData) -> bool:
	for ingredient in ingredients:
		if inventory.count(ingredient.item) < ingredient.amount:
			return false
	return true
