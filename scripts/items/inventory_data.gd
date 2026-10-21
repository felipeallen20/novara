class_name InventoryData
extends RefCounted

## Contenido del inventario: casillas con pilas de items apiladas por id. Emite
## `changed` para que la interfaz se refresque solo cuando entra o sale algo.

signal changed

## Casillas visibles en la interfaz (8 columnas x 4 filas).
const SLOT_COUNT := 32

var _slots: Array[ItemStack] = []


## Añade `amount` unidades, apilándolas sobre una pila existente del mismo id.
func add(item: Item, amount: int = 1) -> void:
	for stack in _slots:
		if stack.item.id == item.id:
			stack.amount += amount
			changed.emit()
			return
	_slots.append(ItemStack.new(item, amount))
	changed.emit()


## Pila de la casilla `index`, o null si esa casilla está vacía.
func get_slot(index: int) -> ItemStack:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]


## Cantidad de casillas ocupadas.
func occupied_slots() -> int:
	return _slots.size()
