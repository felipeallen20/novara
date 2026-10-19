class_name BlockRegistry
extends Resource

## Asocia identificadores de bloque con su definición. Se construye una vez y se comparte
## sin modificarse, por lo que es seguro de usar desde varios hilos.

var _blocks: Dictionary = {}

# Opacidad por id, para la consulta rápida del mesher.
var _opaque: Array[bool] = []


static func with_default_blocks() -> BlockRegistry:
	var registry := BlockRegistry.new()
	registry.register(SoftGround.new())
	registry.register(LavenderStone.new())
	return registry


func register(block: Block) -> void:
	_blocks[block.id] = block
	if block.id >= _opaque.size():
		_opaque.resize(block.id + 1)
	_opaque[block.id] = block.opaque


func get_block(id: int) -> Block:
	var block: Block = _blocks.get(id)
	return block


func has_block(id: int) -> bool:
	return _blocks.has(id)


func is_opaque(id: int) -> bool:
	if id < 0 or id >= _opaque.size():
		return false
	return _opaque[id]
