class_name MiningLandsBiome
extends Biome

## Primer bioma de NOVARA: "Mining Lands". Planeta extraterrestre de llanuras
## extensas, colinas erosionadas, macizos rocosos y cuencas, con los tres bloques
## del proyecto agrupados según la forma del terreno.
##
## El relieve se organiza con una única nota de muy baja frecuencia (la "geografía"):
## sus valores altos marcan los macizos y sus valores bajos las cuencas, y en medio
## quedan las llanuras. Sobre esa base se suman colinas suaves y crestas angulosas,
## de modo que las elevaciones quedan conectadas por pendientes y nunca aparecen
## montículos aislados.
##
## Porcentajes orientativos de reparto: ~55 % llanuras, ~25 % colinas, ~15 % regiones
## rocosas y ~5 % cuencas. Los umbrales de zona están exportados para poder ajustarlos
## sin tocar el algoritmo.

# --- Geografía: zonas amplias --------------------------------------------------
## Frecuencia de las grandes zonas (macizos y cuencas). Muy baja para que cada zona
## ocupe cientos de columnas y se reconozca como una región del planeta.
@export var zone_frequency: float = 0.003
## Valor de la zona a partir del cual empieza la transición hacia macizo rocoso.
@export var zone_massif_start: float = 0.3
## Valor de la zona a partir del cual el macizo ya es rocoso consolidado.
@export var zone_massif_full: float = 0.5
## Valor de la zona a partir del cual empieza la depresión de la cuenca.
@export var zone_basin_start: float = -0.48
## Valor de la zona del fondo de la cuenca, ya hundida del todo.
@export var zone_basin_full: float = -0.72

# --- Colinas suaves ------------------------------------------------------------
## Frecuencia de los parches de colina. Por debajo de la de macizos: estructuras
## amplias pero menores que las regiones geológicas.
@export var hill_frequency: float = 0.008
## Ruido de colina a partir del cual empieza el relieve de colina.
@export var hill_start: float = 0.15
## Ruido de colina a partir del cual la colina alcanza su altura máxima.
@export var hill_full: float = 0.55
## Altura máxima de las colinas suaves, en bloques.
@export var hill_amplitude: float = 4.5
## Peso de las pendientes que conectan las colinas con los macizos cercanos, para
## que las elevaciones nazcan unidas a la zona rocosa y no como montículos sueltos.
@export var hill_flank_strength: float = 0.9

# --- Macizos y cuencas ---------------------------------------------------------
## Frecuencia de las crestas del macizo. Da el trazo angular de las formaciones.
@export var crest_frequency: float = 0.014
## Altura máxima de un macizo consolidado, en bloques.
@export var massif_amplitude: float = 13.0
## Profundidad máxima de las cuencas, en bloques.
@export var basin_depth: float = 3.5
## Perfil mínimo del macizo (0 a 1). Multiplicado por massif_amplitude evita que
## los valles del macizo se hundan demasiado y mantiene el relieve anguloso.
@export var crest_min_shape: float = 0.55

# --- Materiales ----------------------------------------------------------------
## Elevación rocosa (máscara de macizo por la amplitud y el perfil de cresta) a
## partir de la cual la superficie es DarkStone: crestas y corazón del macizo.
@export var dark_lift_threshold: float = 9.0
## Máscara de macizo a partir de la cual la superficie es LavenderStone: laderas,
## bordes erosionados y transiciones hacia la zona rocosa.
@export var lavender_rock_threshold: float = 0.18
## Ruido que agita la frontera del macizo, para que no se dibuje como un anillo de
## contorno perfecto. El material sigue agrupado, solo se vuelve irregular el borde.
@export var edge_jitter: float = 0.1
## Pendiente, en bloques por columna, a partir de la cual se expone roca lila en
## colinas erosionadas y bordes marcados fuera del macizo.
@export var rocky_slope: float = 0.12
## Distancia geográfica mínima a un macizo (valor de la zona) para que aparezcan
## vetas de afloramiento de DarkStone, así no se esparce roca oscura por la llanura.
@export var outcrop_zone_min: float = 0.15
## Anchura de la veta de afloramiento: el tramo en el que la cresta permanece cerca
## de su cero. Más pequeño, vetas más finas y raras.
@export var outcrop_width: float = 0.02

## Frecuencia del ruido que agita las fronteras del macizo.
@export var detail_frequency: float = 0.02

# --- Semillas de los ruidos propios del bioma -----------------------------------
const ZONE_SEED_OFFSET := 104729
const HILL_SEED_OFFSET := 130363
const CREST_SEED_OFFSET := 155921
const DETAIL_SEED_OFFSET := 181081

var _zone_noise: FastNoiseLite
var _hill_noise: FastNoiseLite
var _crest_noise: FastNoiseLite
var _detail_noise: FastNoiseLite


func _init() -> void:
	# Parámetros base heredados, afinados para que las llanuras sean extensas y
	# casi planas en lugar del relieve genérico de la plantilla.
	height_amplitude = 1.6
	relief_frequency = 0.006


func setup(world_seed: int) -> void:
	super.setup(world_seed)
	_zone_noise = _create_noise(world_seed + ZONE_SEED_OFFSET, zone_frequency)
	_hill_noise = _create_noise(world_seed + HILL_SEED_OFFSET, hill_frequency)
	_crest_noise = _create_noise(world_seed + CREST_SEED_OFFSET, crest_frequency)
	_detail_noise = _create_noise(world_seed + DETAIL_SEED_OFFSET, detail_frequency)


func sample_height(world_x: int, world_z: int) -> float:
	var zone := _zone_noise.get_noise_2d(world_x, world_z)
	var massif := smoothstep(zone_massif_start, zone_massif_full, zone)
	# Llanura de partida: base heredada con suaves ondulaciones.
	var height := super.sample_height(world_x, world_z)
	height += hill_mask(world_x, world_z, zone) * hill_amplitude
	if massif > 0.01:
		height += massif * massif_amplitude * crest_shape(world_x, world_z)
	# Bordes decrecientes: 0 en el borde de la cuenca, 1 en su fondo. La cuenca se
	# hunde sobre el terreno que ya tiene y nunca sobre un macizo.
	height -= smoothstep(zone_basin_start, zone_basin_full, zone) * (1.0 - massif) * basin_depth
	return height


func sample_surface_block(world_x: int, world_z: int) -> int:
	var zone := _zone_noise.get_noise_2d(world_x, world_z)
	var massif := smoothstep(zone_massif_start, zone_massif_full, zone)
	var rock := clampf(
		massif + _detail_noise.get_noise_2d(world_x, world_z) * edge_jitter, 0.0, 1.0
	)
	if rock > 0.01:
		var lift := rock * massif_amplitude * crest_shape(world_x, world_z)
		if lift >= dark_lift_threshold:
			return DarkStone.ID
		if rock >= lavender_rock_threshold:
			return LavenderStone.ID
	# Vetas de afloramiento: bandas finas donde la cresta cruza su cero, solo cerca
	# de las zonas rocosas, para orientarse sin esparcir DarkStone por la llanura.
	if (
		zone >= outcrop_zone_min
		and absf(_crest_noise.get_noise_2d(world_x, world_z)) <= outcrop_width
	):
		return DarkStone.ID
	# Colinas erosionadas y bordes marcados: pendiente suficiente para exponer roca.
	if hill_mask(world_x, world_z, zone) > 0.0 and _slope_at(world_x, world_z) >= rocky_slope:
		return LavenderStone.ID
	return SoftGround.ID


## Probabilidad de relieve de colina en la columna: parches amplios de colinas
## suaves que, en las laderas, se unen a los macizos cercanos.
func hill_mask(world_x: int, world_z: int, zone: float) -> float:
	var hills := smoothstep(hill_start, hill_full, _hill_noise.get_noise_2d(world_x, world_z))
	var flank := smoothstep(0.0, zone_massif_start, zone) * hill_flank_strength
	return maxf(hills, flank)


## Perfil del macizo: crestas angulosas (ruido en valor absoluto invertido) en vez
## de cúpulas redondeadas. Devuelve crest_min_shape..1 como fracción de la amplitud.
func crest_shape(world_x: int, world_z: int) -> float:
	var ridge := 1.0 - absf(_crest_noise.get_noise_2d(world_x, world_z))
	return crest_min_shape + (1.0 - crest_min_shape) * ridge


## Pendiente aproximada de la columna, en bloques por columna. Las columnas vecinas
## se muestrean en coordenadas del mundo, así que no hay costuras entre chunks.
func _slope_at(world_x: int, world_z: int) -> float:
	var height := sample_height(world_x, world_z)
	var step_x := absf(sample_height(world_x + 1, world_z) - height)
	var step_z := absf(sample_height(world_x, world_z + 1) - height)
	return maxf(step_x, step_z)
