class_name HighlightController
extends Node3D

## Resalta el objeto del mundo al que apunta el jugador. Es el punto unico donde
## se decide que se resalta y de que color, para poder anadir nuevos tipos
## (bloques, minerales, futuras entidades) sin tocar el controlador del jugador.
##
## El raycast vive en el jugador; este nodo solo recibe el resultado ya resuelto
## con `highlight(collider, point, normal)` o lo oculta con `clear()`.

## Color del contorno de un bloque. Gris oscuro, más modesto que el negro puro.
const BLOCK_COLOR := Color(0.22, 0.22, 0.24, 0.85)
## Color del contorno de un mineral.
const MINERAL_COLOR := Color(0.95, 0.15, 0.15, 1.0)
## Margen del contorno alrededor del objeto, en metros.
const OUTLINE_MARGIN := 0.002

## Grupo que marca los nodos colisionables del terreno (bloques de un chunk).
const TERRAIN_GROUP := &"terrain"
## Grupo que marca los depósitos de mineral.
const MINERAL_GROUP := &"mineral"

@onready var _box: HighlightBox = $Box


func _ready() -> void:
	# El contorno vive en el mundo: no debe heredar el giro del jugador, solo se
	# coloca sobre el objeto apuntado.
	_box.top_level = true


## Resalta lo golpeado por el raycast. Devuelve true si encontró algo que resaltar.
func highlight(collider: Object, point: Vector3, normal: Vector3) -> bool:
	var node := collider as Node3D
	if node == null:
		clear()
		return false
	if node.is_in_group(MINERAL_GROUP):
		# El collider es el Area3D del depósito; su padre es el nodo con la malla.
		_highlight_mineral(_visual_root(node))
		return true
	if node.is_in_group(TERRAIN_GROUP):
		_highlight_block(node, point, normal)
		return true
	clear()
	return false


## Nodo que contiene la malla visible de un objeto colisionable.
func _visual_root(node: Node3D) -> Node3D:
	var parent := node.get_parent()
	var as_node3d := parent as Node3D
	return as_node3d if as_node3d != null else node


func clear() -> void:
	_box.visible = false


## Contorno ajustado al AABB del depósito de mineral.
func _highlight_mineral(deposit: Node3D) -> void:
	var box := _local_visual_box(deposit)
	if box.size == Vector3.ZERO:
		clear()
		return
	var world_box := _to_world_box(deposit, box)
	world_box = world_box.grow(OUTLINE_MARGIN)
	_box.set_box(world_box, MINERAL_COLOR)
	_box.visible = true


## Contorno de un voxel: el bloque que queda justo debajo de la cara golpeada.
func _highlight_block(body: Node3D, point: Vector3, normal: Vector3) -> void:
	# El punto de impacto está sobre la cara; retroceder media celda entra en el bloque.
	var center := point - normal * 0.5
	var voxel := Vector3(floorf(center.x), floorf(center.y), floorf(center.z)) + Vector3(0.5, 0.5, 0.5)
	var box := AABB(voxel - Vector3(0.5, 0.5, 0.5), Vector3.ONE)
	box = box.grow(OUTLINE_MARGIN)
	_box.set_box(box, BLOCK_COLOR)
	_box.visible = true


## AABB en coordenadas locales del nodo, sumando las mallas visibles de sus hijos.
func _local_visual_box(node: Node) -> AABB:
	var box := AABB()
	var has_mesh := false
	for child in node.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var child_box := mesh_instance.get_aabb()
		if not has_mesh:
			box = child_box
			has_mesh = true
		else:
			box = box.merge(child_box)
	if not has_mesh:
		return AABB()
	return box


## Convierte un AABB local en un AABB en coordenadas globales.
func _to_world_box(node: Node3D, local_box: AABB) -> AABB:
	var base := node.global_transform
	var world_box := AABB(base * local_box.position, Vector3.ZERO)
	for corner in 8:
		var local_corner := local_box.position + Vector3(
			local_box.size.x * float(corner & 1),
			local_box.size.y * float((corner >> 1) & 1),
			local_box.size.z * float((corner >> 2) & 1)
		)
		world_box = world_box.expand(base * local_corner)
	return world_box
