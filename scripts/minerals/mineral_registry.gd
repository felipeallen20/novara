class_name MineralRegistry
extends Resource

## Asocia identificadores de mineral con su definición. Se construye una vez y se
## comparte sin modificarse, igual que BlockRegistry, así que es seguro de usar
## desde los hilos de generación.

var _minerals: Dictionary = {}


static func with_default_minerals() -> MineralRegistry:
	var registry := MineralRegistry.new()
	registry.register(Sandite.new())
	return registry


func register(mineral: Mineral) -> void:
	_minerals[mineral.id] = mineral


func get_mineral(id: int) -> Mineral:
	var mineral: Mineral = _minerals.get(id)
	return mineral


func has_mineral(id: int) -> bool:
	return _minerals.has(id)


func minerals() -> Array[Mineral]:
	var result: Array[Mineral] = []
	result.assign(_minerals.values())
	return result
