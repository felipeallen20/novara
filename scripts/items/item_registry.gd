class_name ItemRegistry
extends Resource

## Asocia identificadores de item con su definición, para poder referenciarlos
## por id, como en los datos de las recetas. Se construye una vez y no se
## modifica, igual que BlockRegistry y MineralRegistry.

var _items: Dictionary = {}


static func with_default_items() -> ItemRegistry:
	var registry := ItemRegistry.new()
	registry.register(SanditeItem.new())
	registry.register(FerriteItem.new())
	registry.register(OxyfernItem.new())
	registry.register(OxygenTankItem.new())
	return registry


func register(item: Item) -> void:
	_items[item.id] = item


func get_item(id: int) -> Item:
	var item: Item = _items.get(id)
	return item


func has_item(id: int) -> bool:
	return _items.has(id)


func items() -> Array[Item]:
	var result: Array[Item] = []
	result.assign(_items.values())
	return result
