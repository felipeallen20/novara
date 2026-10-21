class_name ChunkMeshData
extends RefCounted

## Geometría calculada de un chunk, lista para convertirse en ArrayMesh en el hilo principal.

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
## UV local [0,1] dentro de la celda del atlas de cada cara.
var uvs := PackedVector2Array()
## Desplazamiento UV de la celda del atlas del bloque y cara de cada vértice.
var atlas_offsets := PackedVector2Array()
var indices := PackedInt32Array()


func is_empty() -> bool:
	return indices.is_empty()
