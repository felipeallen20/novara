class_name SafeZone
extends RefCounted

## Zona segura alrededor del punto de aparición del jugador: un área cuadrada de
## SIZE x SIZE columnas que el generador mantiene plana a `flat_height`.
## Inmutable tras construirse, así que es seguro leerla desde los hilos de generación.

const SIZE := 32

var center := Vector2i.ZERO
var flat_height := 0


func _init(spawn_position: Vector3, p_flat_height: int) -> void:
	center = Vector2i(floori(spawn_position.x), floori(spawn_position.z))
	flat_height = p_flat_height


func min_corner() -> Vector2i:
	return center - Vector2i.ONE * (SIZE / 2)


func contains_xz(world_x: int, world_z: int) -> bool:
	var corner := min_corner()
	return (
		world_x >= corner.x and world_x < corner.x + SIZE
		and world_z >= corner.y and world_z < corner.y + SIZE
	)


func contains_position(world_position: Vector3) -> bool:
	return contains_xz(floori(world_position.x), floori(world_position.z))
