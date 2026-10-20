class_name Biome
extends Resource

## Plantilla base de bioma: reúne los parámetros comunes de cualquier bioma y el
## contrato que TerrainGenerator usa para dar altura y material a cada columna.
##
## Ciclo de vida: se crea, se ajustan los parámetros y se llama a `setup` con la
## semilla del mundo. Después solo se lee: la generación corre en los hilos de
## WorkerThreadPool y muestrear FastNoiseLite no muta estado, así que una instancia
## compartida es segura mientras nadie la modifique.

## Altura media de la superficie, en bloques. La zona segura de aparición queda
## plana a esta altura.
@export var base_height: int = 8

## Amplitud del relieve principal, en bloques.
@export var height_amplitude: float = 6.0

## Frecuencia del ruido de relieve. A menor frecuencia, estructuras más amplias.
@export var relief_frequency: float = 0.02

## Frecuencia del ruido que reparte el material de superficie por defecto. Algo
## mayor que la del relieve, para que las vetas sean menores que las colinas.
@export var material_frequency: float = 0.035

## Umbrales del material de superficie por defecto. El ruido simplex se reparte de
## forma aproximadamente simétrica en [-1, 1], así que dos umbrales en tercios
## dividen el terreno en tres bandas de superficie comparable.
@export var dark_stone_threshold: float = -0.33
@export var lavender_stone_threshold: float = 0.33

## Semilla propia del ruido de material, para que no coincida con la del relieve.
const MATERIAL_SEED_OFFSET := 7919

var _relief_noise: FastNoiseLite
var _material_noise: FastNoiseLite


## Prepara los ruidos del bioma. Se llama una sola vez, desde el hilo principal,
## después de fijar los parámetros y antes de generar ningún chunk.
func setup(world_seed: int) -> void:
	_relief_noise = _create_noise(world_seed, relief_frequency)
	_material_noise = _create_noise(world_seed + MATERIAL_SEED_OFFSET, material_frequency)


func is_configured() -> bool:
	return _relief_noise != null


## Altura de la superficie en la columna (world_x, world_z), sin redondear. Las
## pendientes se calculan sobre este valor continuo.
func sample_height(world_x: int, world_z: int) -> float:
	return float(base_height) + _relief_noise.get_noise_2d(world_x, world_z) * height_amplitude


## Material de superficie de la columna. Por defecto: bandas de material según un
## ruido independiente del relieve.
func sample_surface_block(world_x: int, world_z: int) -> int:
	var material := _material_noise.get_noise_2d(world_x, world_z)
	if material >= lavender_stone_threshold:
		return LavenderStone.ID
	if material >= dark_stone_threshold:
		return SoftGround.ID
	return DarkStone.ID


## Material de superficie en las columnas que el bioma mantiene planas (zona segura).
func flat_surface_block() -> int:
	return SoftGround.ID


static func _create_noise(noise_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	return noise
