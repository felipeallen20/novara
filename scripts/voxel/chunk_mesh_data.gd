class_name ChunkMeshData
extends RefCounted

## Geometría calculada de un chunk, lista para convertirse en ArrayMesh en el hilo principal.

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


func is_empty() -> bool:
	return indices.is_empty()
