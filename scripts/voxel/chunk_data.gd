class_name ChunkData
extends RefCounted

## Vóxeles de un chunk y los depósitos de minerales que nacen sobre su superficie.
## Sin nodos ni render: la representación de los depósitos la crea el streamer en el
## hilo principal.

const AIR := 0

var size: int = 0

## Depósitos de minerales en coordenadas locales. Los decide la generación junto a
## los vóxeles, así llegan con el mismo ChunkData.
var mineral_spawns: Array[MineralSpawn] = []

var _blocks: PackedByteArray


func configure(chunk_size: int) -> void:
	size = chunk_size
	mineral_spawns = []
	_blocks = PackedByteArray()
	_blocks.resize(chunk_size * chunk_size * chunk_size)
	_blocks.fill(AIR)


func is_inside(local: Vector3i) -> bool:
	return (
		local.x >= 0 and local.x < size
		and local.y >= 0 and local.y < size
		and local.z >= 0 and local.z < size
	)


func get_block(local: Vector3i) -> int:
	if not is_inside(local):
		return AIR
	return _blocks[ChunkCoord.local_to_index(local, size)]


func set_block(local: Vector3i, block_id: int) -> void:
	if not is_inside(local):
		return
	_blocks[ChunkCoord.local_to_index(local, size)] = block_id


## Rellena con `block_id` la columna (x, z) desde y = 0 hasta `top_y` (incluido).
## Evita una llamada por vóxel en la generación.
func fill_column(x: int, z: int, top_y: int, block_id: int) -> void:
	var clamped_top := mini(top_y, size - 1)
	if clamped_top < 0:
		return
	var index := x + z * size
	var step := size * size
	for _y in clamped_top + 1:
		_blocks[index] = block_id
		index += step
