class_name PlantSpawner
extends RefCounted

## Decide qué plantas nacen en cada columna. Cada planta lleva sus propias reglas
## (superficie, desnivel, frecuencia y separación), así que el generador no
## cambia al añadir plantas nuevas.
##
## Ciclo de vida: se crea con la lista de plantas y el bioma, y solo se lee. Es
## seguro de usar desde los hilos de generación.

## Margen del centro de la planta respecto al centro del bloque, para que no caiga
## siempre en el mismo punto.
const POSITION_MARGIN := 0.35
## Inclinación máxima de la planta, en radianes.
const MAX_TILT := 0.12
## Radio de búsqueda del desnivel, en bloques.
const CLIFF_RADIUS := 8
## Direcciones en las que se busca el desnivel.
const CLIFF_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
]

var _plants: Array[Plant] = []
var _biome: Biome


func _init(plants: Array[Plant], biome: Biome) -> void:
	_plants = plants
	_biome = biome


## Plantas que nacen en la columna (world_x, world_z) cuando su superficie es
## `surface_block_id`. `local_column` lleva (x, y del bloque de superficie, z) en
## coordenadas locales del chunk.
func sample(
	world_x: int, world_z: int, surface_block_id: int, local_column: Vector3i
) -> Array[PlantSpawn]:
	var spawns: Array[PlantSpawn] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(world_x, 0, world_z))
	for plant in _plants:
		if not plant.can_grow(surface_block_id):
			continue
		if not _is_anchor(world_x, world_z, plant):
			continue
		if rng.randf() > plant.density:
			continue
		if not _has_cliff(world_x, world_z, plant):
			continue
		spawns.append(_make_spawn(plant, local_column, rng))
	return spawns


## True si la columna es el anclaje de su celda. Solo el anclaje puede tener
## planta, así que dentro de una celda no se acumulan.
func _is_anchor(world_x: int, world_z: int, plant: Plant) -> bool:
	var size := maxi(1, plant.spacing)
	var cell := Vector2i(floori(float(world_x) / size), floori(float(world_z) / size))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell)
	var anchor := Vector2i(
		cell.x * size + rng.randi_range(0, size - 1),
		cell.y * size + rng.randi_range(0, size - 1)
	)
	return anchor == Vector2i(world_x, world_z)


## True si alrededor de la columna hay roca que la supere por al menos la altura
## mínima que pide la planta. Así solo crecen al pie de un desnivel de verdad.
func _has_cliff(world_x: int, world_z: int, plant: Plant) -> bool:
	var base := _biome.sample_height(world_x, world_z)
	for direction in CLIFF_DIRECTIONS:
		var x := world_x + direction.x * CLIFF_RADIUS
		var z := world_z + direction.y * CLIFF_RADIUS
		if not plant.cliff_block_ids.has(_biome.sample_surface_block(x, z)):
			continue
		if _biome.sample_height(x, z) - base >= plant.min_cliff_height:
			return true
	return false


func _make_spawn(
	plant: Plant, local_column: Vector3i, rng: RandomNumberGenerator
) -> PlantSpawn:
	var spawn := PlantSpawn.new()
	spawn.plant_id = plant.id
	spawn.local_position = Vector3(
		local_column.x + rng.randf_range(POSITION_MARGIN, 1.0 - POSITION_MARGIN),
		local_column.y + 1.0,
		local_column.z + rng.randf_range(POSITION_MARGIN, 1.0 - POSITION_MARGIN)
	)
	spawn.rotation = Vector3(
		rng.randf_range(-MAX_TILT, MAX_TILT),
		rng.randf_range(0.0, TAU),
		rng.randf_range(-MAX_TILT, MAX_TILT)
	)
	spawn.scale = rng.randf_range(plant.scale_range.x, plant.scale_range.y)
	return spawn
