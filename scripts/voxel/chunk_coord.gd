class_name ChunkCoord
extends RefCounted

## Conversiones entre posición de mundo, coordenada de chunk y posición local.
## Única fuente de verdad de esta matemática.

static func world_to_chunk(world_position: Vector3, chunk_size: int) -> Vector3i:
	return Vector3i(
		floori(world_position.x / chunk_size),
		floori(world_position.y / chunk_size),
		floori(world_position.z / chunk_size)
	)

static func chunk_to_world(chunk_position: Vector3i, chunk_size: int) -> Vector3:
	return Vector3(chunk_position) * chunk_size

static func block_to_local(block_position: Vector3i, chunk_size: int) -> Vector3i:
	# posmod global: Vector3i no expone un método posmod.
	return Vector3i(
		posmod(block_position.x, chunk_size),
		posmod(block_position.y, chunk_size),
		posmod(block_position.z, chunk_size)
	)

static func local_to_index(local: Vector3i, chunk_size: int) -> int:
	# Layout: x más rápido, luego z, luego y.
	return local.x + local.z * chunk_size + local.y * chunk_size * chunk_size
