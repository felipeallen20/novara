class_name Fabricator
extends Interactable

## Estación de fabricación: objeto fijo del mundo. El modelo importado no trae
## normales, así que al entrar en el árbol se le generan y se le aplica el
## sombreado estilizado del juego, con el color del metal en los vértices.
##
## Al apuntarla y pulsar la tecla de interacción se abre su interfaz de
## fabricación.

## Sombreado estilizado de la estación. Configurable desde el editor o por código.
@export var style: StylizedMaterial = preload("res://resources/materials/workspace_style.tres")

## Color base del metal. Los vértices reciben un degradado vertical suave.
@export var base_color: Color = Color(0.42, 0.43, 0.47)

## Rango del degradado vertical del color, del punto más bajo al más alto.
@export var shade_range: Vector2 = Vector2(0.72, 1.12)

@onready var _mesh_instance: MeshInstance3D = _find_mesh(self)

var _min_height := 0.0
var _max_height := 1.0


## Texto del aviso: la estación abre la interfaz de fabricación.
func get_interaction_text() -> String:
	return "Fabricar"


func _ready() -> void:
	if _mesh_instance == null or _mesh_instance.mesh == null:
		return
	var aabb := _mesh_instance.mesh.get_aabb()
	_min_height = aabb.position.y
	_max_height = aabb.position.y + aabb.size.y
	_mesh_instance.mesh = _with_normals(_mesh_instance.mesh)
	_mesh_instance.material_override = style.create_material(false)


## Devuelve la malla con normales. El modelo importado viene sin ellas y sin
## normales no hay luz difusa, así que el objeto saldría negro. Si ya las
## tiene, se devuelve tal cual.
func _with_normals(mesh: ArrayMesh) -> ArrayMesh:
	if mesh.get_surface_count() == 0:
		return mesh
	var arrays := mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_NORMAL] != null:
		return mesh
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var normals := _face_normals(vertices, indices)
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	for i in vertices.size():
		colors[i] = _vertex_color(vertices[i])
	var new_arrays := []
	new_arrays.resize(Mesh.ARRAY_MAX)
	new_arrays[Mesh.ARRAY_VERTEX] = vertices
	new_arrays[Mesh.ARRAY_NORMAL] = normals
	new_arrays[Mesh.ARRAY_COLOR] = colors
	new_arrays[Mesh.ARRAY_INDEX] = indices
	var new_mesh := ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arrays)
	return new_mesh


## Normales suavizadas por vértice. La orientación de cada cara se decide
## mirando hacia fuera desde el centro de la malla, para no depender del
## sentido de los triángulos del modelo importado.
func _face_normals(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var center := Vector3.ZERO
	for vertex in vertices:
		center += vertex
	if vertices.size() > 0:
		center /= float(vertices.size())
	var accumulated := PackedVector3Array()
	accumulated.resize(vertices.size())
	for i in range(0, indices.size() - 2, 3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i + 1]]
		var c := vertices[indices[i + 2]]
		var normal := (b - a).cross(c - a)
		if normal.length_squared() < 0.0000001:
			continue
		normal = normal.normalized()
		# La normal debe apuntar hacia fuera de la malla.
		if normal.dot((a + b + c) / 3.0 - center) < 0.0:
			normal = -normal
		for j in 3:
			accumulated[indices[i + j]] += normal
	for i in accumulated.size():
		if accumulated[i].length_squared() > 0.0000001:
			accumulated[i] = accumulated[i].normalized()
		else:
			accumulated[i] = Vector3.UP
	return accumulated


## Color de un vértice: el base con un degradado vertical suave.
func _vertex_color(vertex: Vector3) -> Color:
	var height_ratio := inverse_lerp(_min_height, _max_height, vertex.y)
	return base_color * lerpf(shade_range.x, shade_range.y, height_ratio)


## Primer MeshInstance3D de la jerarquía: el modelo importado lo trae anidado.
func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null
