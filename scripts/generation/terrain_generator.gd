class_name TerrainGenerator
extends RefCounted

## Genera el terreno de un chunk de forma determinista a partir de la semilla y la
## coordenada. Función pura: no tiene estado mutable, por lo que es seguro usar una
## instancia compartida desde varios hilos.

const BASE_HEIGHT := 8
const HEIGHT_AMPLITUDE := 6.0
const DEFAULT_FREQUENCY := 0.02

## Frecuencia del ruido que elige el material de cada columna. Algo mayor que la del
## relieve, para que las vetas sean menores que las colinas.
const MATERIAL_FREQUENCY := 0.035

## Semilla propia del ruido de material, para que no coincida con la del relieve.
const MATERIAL_SEED_OFFSET := 7919

## Umbral sobre el ruido de material. En 0.0 el ruido queda repartido mitad y mitad, así
## que LavenderStone y SoftGround cubren una superficie equivalente.
const LAVENDER_STONE_THRESHOLD := 0.0

var _chunk_size: int
var _world_seed: int
var _frequency: float


func _init(world_seed: int, chunk_size: int, frequency: float = DEFAULT_FREQUENCY) -> void:
	_world_seed = world_seed
	_chunk_size = chunk_size
	_frequency = frequency


func generate(chunk_coord: Vector3i) -> ChunkData:
	var height_noise := _create_height_noise()
	var material_noise := _create_material_noise()
	var data := ChunkData.new()
	data.configure(_chunk_size)
	var origin := chunk_coord * _chunk_size
	for z in _chunk_size:
		for x in _chunk_size:
			var world_x := origin.x + x
			var world_z := origin.z + z
			# Una muestra de ruido por columna y material, no una por vóxel.
			var local_top := surface_height(height_noise, world_x, world_z) - origin.y
			data.fill_column(x, z, local_top, surface_block(material_noise, world_x, world_z))
	return data


func surface_height(noise: FastNoiseLite, world_x: int, world_z: int) -> int:
	return BASE_HEIGHT + roundi(noise.get_noise_2d(world_x, world_z) * HEIGHT_AMPLITUDE)


## Bloque de superficie de una columna. El umbral divide el ruido en dos mitades, así que
## ambos bloques ocupan el terreno a partes aproximadamente iguales.
func surface_block(material_noise: FastNoiseLite, world_x: int, world_z: int) -> int:
	if material_noise.get_noise_2d(world_x, world_z) >= LAVENDER_STONE_THRESHOLD:
		return LavenderStone.ID
	return SoftGround.ID


func _create_height_noise() -> FastNoiseLite:
	return _create_noise(_world_seed, _frequency)


func _create_material_noise() -> FastNoiseLite:
	return _create_noise(_world_seed + MATERIAL_SEED_OFFSET, MATERIAL_FREQUENCY)


static func _create_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	return noise
