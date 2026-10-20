class_name MineralSpawner
extends RefCounted

## Decide qué depósitos de minerales nacen sobre la superficie de una columna. Cada
## mineral usa dos ruidos derivados de la semilla del mundo y de su id: uno de
## parche, que marca los yacimientos, y otro de dispersión, que suelta los cristales
## dentro de cada parche. Así dos minerales no comparten emplazamientos, no hace
## falta guardar nada y el mismo mundo produce siempre los mismos depósitos.
##
## Ciclo de vida: se crea, se ajustan los parámetros y se llama a `setup`. Después
## solo se lee, con el mismo contrato que Biome, por lo que es seguro de usar desde
## los hilos de generación.

## Frecuencia del ruido de parche: a menor frecuencia, yacimientos más amplios.
@export var patch_frequency: float = 0.08
## Valor del ruido de parche a partir del cual la columna cae dentro de un yacimiento.
## Con este valor los yacimientos cubren algo más del 10 % del terreno, en parches.
@export var patch_threshold: float = 0.42
## Frecuencia del ruido de dispersión. Muy mayor que la del parche, para que los
## cristales sueltos sean columnas individuales y no bloques macizos.
@export var scatter_frequency: float = 0.45
## Valor del ruido de dispersión a partir del cual la columna concreta tiene cristal.
## Combinado con el de parche deja cristales sueltos dentro de cada yacimiento.
@export var scatter_threshold: float = 0.35

## Semillas propias de los ruidos, para que no coincidan con las del bioma.
const PATCH_SEED_OFFSET := 499
const SCATTER_SEED_OFFSET := 997

## Margen del centro del cristal respecto al borde de la columna, para que el
## depósito no quede clavado en el centro del bloque.
const POSITION_MARGIN := 0.2
## Rango de escala de los depósitos y giro máximo alrededor de X y Z, en radianes.
const SCALE_RANGE := Vector2(0.8, 1.35)
const MAX_TILT_RADIANS := 0.21

var _minerals: Array[Mineral] = []
var _world_seed := 0
var _patch_noises: Dictionary = {}
var _scatter_noises: Dictionary = {}
var _configured := false


func _init(minerals: Array[Mineral], world_seed: int) -> void:
	_minerals = minerals
	_world_seed = world_seed


## Prepara los ruidos de cada mineral. Se llama una sola vez, desde el hilo
## principal, antes de generar ningún chunk.
func setup() -> void:
	for mineral in _minerals:
		_patch_noises[mineral.id] = _create_noise(
			_world_seed + mineral.id * PATCH_SEED_OFFSET, patch_frequency
		)
		_scatter_noises[mineral.id] = _create_noise(
			_world_seed + mineral.id * SCATTER_SEED_OFFSET, scatter_frequency
		)
	_configured = true


func is_configured() -> bool:
	return _configured


## Depósitos que nacen en la columna (world_x, world_z) cuando su superficie es
## `surface_block_id`. `local_column` lleva (x, y del bloque de superficie, z) en
## coordenadas locales del chunk.
func sample(
	world_x: int, world_z: int, surface_block_id: int, local_column: Vector3i
) -> Array[MineralSpawn]:
	var spawns: Array[MineralSpawn] = []
	for mineral in _minerals:
		if mineral.host_block_id != surface_block_id:
			continue
		var patch_noise: FastNoiseLite = _patch_noises[mineral.id]
		if patch_noise.get_noise_2d(world_x, world_z) <= patch_threshold:
			continue
		var scatter_noise: FastNoiseLite = _scatter_noises[mineral.id]
		if scatter_noise.get_noise_2d(world_x, world_z) <= scatter_threshold:
			continue
		spawns.append(_make_spawn(mineral, world_x, world_z, local_column))
	return spawns


func _make_spawn(
	mineral: Mineral, world_x: int, world_z: int, local_column: Vector3i
) -> MineralSpawn:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(world_x, 0, world_z))
	var spawn := MineralSpawn.new()
	spawn.mineral_id = mineral.id
	spawn.local_position = Vector3(
		local_column.x + rng.randf_range(POSITION_MARGIN, 1.0 - POSITION_MARGIN),
		local_column.y + 1.0,
		local_column.z + rng.randf_range(POSITION_MARGIN, 1.0 - POSITION_MARGIN)
	)
	spawn.rotation = Vector3(
		rng.randf_range(-MAX_TILT_RADIANS, MAX_TILT_RADIANS),
		rng.randf_range(0.0, TAU),
		rng.randf_range(-MAX_TILT_RADIANS, MAX_TILT_RADIANS)
	)
	spawn.scale = rng.randf_range(SCALE_RANGE.x, SCALE_RANGE.y)
	spawn.variation_seed = rng.randi()
	return spawn


static func _create_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	return noise
