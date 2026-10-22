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


## Cuántas unidades del item hay guardadas.
func count(item: Item) -> int:
	var total := 0
	for stack in _slots:
		if stack.item.id == item.id:
			total += stack.amount
	return total


## Gasta unidades de un item, quitando la casilla si se queda vacía. Devuelve
## false si no hay unidades suficientes.
func remove(item: Item, amount: int) -> bool:
	if count(item) < amount:
		return false
	var left := amount
	var index := 0
	while index < _slots.size() and left > 0:
		var stack := _slots[index]
		if stack.item.id != item.id:
			index += 1
			continue
		var taken := mini(stack.amount, left)
		stack.amount -= taken
		left -= taken
		if stack.amount > 0:
			index += 1
			continue
		_slots.remove_at(index)
	changed.emit()
	return true
