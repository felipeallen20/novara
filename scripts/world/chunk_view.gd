class_name ChunkView
extends Node3D

## Representación y colisión de un chunk. Recibe geometría ya calculada y la aplica en el
## hilo principal.

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D


func _ready() -> void:
	_mesh_instance.material_override = _create_material()


func apply(mesh_data: ChunkMeshData) -> void:
	if mesh_data.is_empty():
		_mesh_instance.mesh = null
		_collision_shape.shape = null
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mesh_data.vertices
	arrays[Mesh.ARRAY_NORMAL] = mesh_data.normals
	arrays[Mesh.ARRAY_COLOR] = mesh_data.colors
	arrays[Mesh.ARRAY_INDEX] = mesh_data.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_instance.mesh = mesh
	# La colisión se construye a partir del mismo mesh: deforma si cambia el terreno.
	_collision_shape.shape = mesh.create_trimesh_shape()


func _create_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	return material
