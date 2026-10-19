class_name ChunkMesher
extends RefCounted

## Convierte los vóxeles de un chunk en arrays de geometría. Sin nodos ni render.
## NEIGHBOR_OFFSETS fija el orden de las caras y el de los vecinos al meshear.

const NEIGHBOR_OFFSETS := [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]

# Tangentes por cara, en el mismo orden que NEIGHBOR_OFFSETS. Permiten muestrear el AO
# en los tres vóxeles que rodean cada esquina de la cara.
const _FACE_TANGENTS := [
	[Vector3i(0, 1, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, 1, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, 0, 1), Vector3i(1, 0, 0)],
	[Vector3i(0, 0, 1), Vector3i(1, 0, 0)],
	[Vector3i(1, 0, 0), Vector3i(0, 1, 0)],
	[Vector3i(1, 0, 0), Vector3i(0, 1, 0)],
]

# Esquinas de cada cara, en el mismo orden que NEIGHBOR_OFFSETS.
#
# Godot considera cara frontal la que, vista desde fuera, recorre sus vértices en
# sentido horario: para (p0, p1, p2) el frente es (p0 - p2) x (p0 - p1). Con este orden
# ese producto apunta en la dirección de la normal de la cara, así que el culling
# normal y la normal de colisión del trimesh coinciden con la cara exterior.
const _FACE_CORNERS := [
	[Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	[Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0)],
]

const _AO_BRIGHTNESS := [0.35, 0.6, 0.82, 1.0]


func build(chunk: ChunkData, registry: BlockRegistry, neighbors: Array = []) -> ChunkMeshData:
	var mesh_data := ChunkMeshData.new()
	for y in chunk.size:
		for z in chunk.size:
			for x in chunk.size:
				var local := Vector3i(x, y, z)
				var block_id := chunk.get_block(local)
				if block_id == ChunkData.AIR:
					continue
				var block := registry.get_block(block_id)
				if block == null:
					continue
				_append_visible_faces(mesh_data, chunk, registry, neighbors, local, block)
	return mesh_data


func _append_visible_faces(
	mesh_data: ChunkMeshData,
	chunk: ChunkData,
	registry: BlockRegistry,
	neighbors: Array,
	local: Vector3i,
	block: Block
) -> void:
	for face_index in NEIGHBOR_OFFSETS.size():
		var normal: Vector3i = NEIGHBOR_OFFSETS[face_index]
		if registry.is_opaque(_block_id_at_offset(chunk, neighbors, local, normal)):
			continue
		_append_quad(mesh_data, chunk, registry, neighbors, local, block, face_index)


func _append_quad(
	mesh_data: ChunkMeshData,
	chunk: ChunkData,
	registry: BlockRegistry,
	neighbors: Array,
	local: Vector3i,
	block: Block,
	face_index: int
) -> void:
	var normal: Vector3i = NEIGHBOR_OFFSETS[face_index]
	var tangents: Array = _FACE_TANGENTS[face_index]
	var corners: Array = _FACE_CORNERS[face_index]
	var tangent1_axis: Vector3i = tangents[0]
	var tangent2_axis: Vector3i = tangents[1]
	var light_offset := normal
	var ao_levels := []

	for corner in corners:
		var corner_vector: Vector3 = corner
		var tangent1 := tangent1_axis * (1 if corner_vector.dot(Vector3(tangent1_axis)) > 0.5 else -1)
		var tangent2 := tangent2_axis * (1 if corner_vector.dot(Vector3(tangent2_axis)) > 0.5 else -1)
		var side1 := registry.is_opaque(_block_id_at_offset(chunk, neighbors, local, light_offset + tangent1))
		var side2 := registry.is_opaque(_block_id_at_offset(chunk, neighbors, local, light_offset + tangent2))
		var corner_blocked := registry.is_opaque(
			_block_id_at_offset(chunk, neighbors, local, light_offset + tangent1 + tangent2)
		)
		ao_levels.append(_vertex_ao(side1, side2, corner_blocked))

	var base := mesh_data.vertices.size()
	for corner_index in corners.size():
		mesh_data.vertices.append(Vector3(local) + corners[corner_index])
		mesh_data.normals.append(Vector3(normal))
		mesh_data.colors.append(_lit_color(block.color, _AO_BRIGHTNESS[ao_levels[corner_index]]))
	_append_quad_indices(mesh_data, base, ao_levels)


func _append_quad_indices(mesh_data: ChunkMeshData, base: int, ao_levels: Array) -> void:
	# La diagonal se elige entre las dos esquinas con más luz para evitar bandas.
	if ao_levels[1] + ao_levels[3] > ao_levels[0] + ao_levels[2]:
		mesh_data.indices.append(base + 1)
		mesh_data.indices.append(base + 2)
		mesh_data.indices.append(base + 3)
		mesh_data.indices.append(base + 1)
		mesh_data.indices.append(base + 3)
		mesh_data.indices.append(base)
	else:
		mesh_data.indices.append(base)
		mesh_data.indices.append(base + 1)
		mesh_data.indices.append(base + 2)
		mesh_data.indices.append(base)
		mesh_data.indices.append(base + 2)
		mesh_data.indices.append(base + 3)


func _vertex_ao(side1: bool, side2: bool, corner_blocked: bool) -> int:
	if side1 and side2:
		return 0
	return 3 - (int(side1) + int(side2) + int(corner_blocked))


func _lit_color(color: Color, brightness: float) -> Color:
	# Solo el albedo se atenúa; el canal alfa se conserva.
	return Color(color.r * brightness, color.g * brightness, color.b * brightness, color.a)


func _block_id_at_offset(chunk: ChunkData, neighbors: Array, local: Vector3i, offset: Vector3i) -> int:
	var target := local + offset
	if chunk.is_inside(target):
		return chunk.get_block(target)
	var neighbor: ChunkData = _neighbor_in_slot(neighbors, _out_of_range_slot(target, chunk.size))
	if neighbor == null:
		return ChunkData.AIR
	return neighbor.get_block(ChunkCoord.block_to_local(target, chunk.size))


## Casilla del vecino según el eje por el que el objetivo se sale del chunk. El objetivo
## solo puede salirse por un eje a la vez porque los offsets son como máximo de 1.
func _out_of_range_slot(target: Vector3i, chunk_size: int) -> int:
	if target.x < 0:
		return 1
	if target.x >= chunk_size:
		return 0
	if target.y < 0:
		return 3
	if target.y >= chunk_size:
		return 2
	if target.z < 0:
		return 5
	return 4


func _neighbor_in_slot(neighbors: Array, slot: int) -> ChunkData:
	if slot < 0 or slot >= neighbors.size():
		return null
	var neighbor: ChunkData = neighbors[slot]
	return neighbor
