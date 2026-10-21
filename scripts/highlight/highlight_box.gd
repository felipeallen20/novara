class_name HighlightBox
extends Node3D

## Contorno de aristas para resaltar un objeto del mundo (bloque, mineral, etc.).
## Dibuja las 12 aristas de una caja unitaria con un material unshaded, sin
## escribir profundidad, para que el contorno se lea sobre la superficie.
##
## Uso: se ajusta con `set_box(size, color)` y se mueve con `global_position`.
## Un solo nodo sirve para cualquier objetivo; cambiar el color permite resaltar
## objetos de distinto tipo (bloques, minerales, futuras entidades).

const _EDGES := [
	# Aristas inferiores y superiores (eje X y Z).
	[Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5)],
	[Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5)],
	[Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)],
	[Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, -0.5, -0.5)],
	[Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
	[Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)],
	[Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
	[Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)],
	# Aristas verticales (eje Y).
	[Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5)],
	[Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
	[Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5)],
	[Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
]

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	# Solo contorno: no escribe profundidad para no recortar el objeto resaltado.
	_material.no_depth_test = true
	_mesh_instance.material_override = _material
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_unit_box()


## Encaja el contorno sobre una caja en coordenadas globales y le da color.
func set_box(box: AABB, color: Color) -> void:
	global_position = box.get_center()
	scale = box.size
	if _material != null:
		_material.albedo_color = color


## Genera las 12 aristas de una caja unitaria centrada en el origen.
func _build_unit_box() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for edge in _EDGES:
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(edge[0])
		mesh.surface_add_vertex(edge[1])
	mesh.surface_end()
	_mesh_instance.mesh = mesh
