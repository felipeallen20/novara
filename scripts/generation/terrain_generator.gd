class_name TerrainGenerator
extends RefCounted

## Genera el terreno de un chunk de forma determinista a partir de la semilla y la
## coordenada. Función pura: no tiene estado mutable, por lo que es seguro usar una
## instancia compartida desde varios hilos.

const BASE_HEIGHT := 8
const HEIGHT_AMPLITUDE := 6.0
const DEFAULT_FREQUENCY := 0.02

var _chunk_size: int
var _world_seed: int
var _frequency: float


func _init(world_seed: int, chunk_size: int, frequency: float = DEFAULT_FREQUENCY) -> void:
	_world_seed = world_seed
	_chunk_size = chunk_size
	_frequency = frequency


func generate(chunk_coord: Vector3i) -> ChunkData:
	var noise := _create_noise()
	var data := ChunkData.new()
	data.configure(_chunk_size)
	var origin := chunk_coord * _chunk_size
	for z in _chunk_size:
		for x in _chunk_size:
			# Una muestra de ruido por columna, no una por vóxel.
			var local_top := surface_height(noise, origin.x + x, origin.z + z) - origin.y
			data.fill_column(x, z, local_top, SoftGround.ID)
	return data


func surface_height(noise: FastNoiseLite, world_x: int, world_z: int) -> int:
	return BASE_HEIGHT + roundi(noise.get_noise_2d(world_x, world_z) * HEIGHT_AMPLITUDE)


func _create_noise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = _world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = _frequency
	return noise
