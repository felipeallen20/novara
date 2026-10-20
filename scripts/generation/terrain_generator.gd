class_name TerrainGenerator
extends RefCounted

## Genera el terreno de un chunk de forma determinista a partir de la coordenada y
## del bioma. El bioma decide el relieve y el material de cada columna; el generador
## aplica la zona segura y redondea las alturas a bloques. Sin estado mutable, por lo
## que es seguro usar una instancia compartida desde varios hilos.

var _chunk_size: int
var _biome: Biome
var _safe_zone: SafeZone


func _init(biome: Biome, chunk_size: int, safe_zone: SafeZone = null) -> void:
	assert(
		biome != null and biome.is_configured(),
		"TerrainGenerator necesita un bioma con setup(semilla_del_mundo) ya llamado."
	)
	_chunk_size = chunk_size
	_biome = biome
	_safe_zone = safe_zone


func generate(chunk_coord: Vector3i) -> ChunkData:
	var data := ChunkData.new()
	data.configure(_chunk_size)
	var origin := chunk_coord * _chunk_size
	for z in _chunk_size:
		for x in _chunk_size:
			var world_x := origin.x + x
			var world_z := origin.z + z
			# Una muestra de altura y material por columna, no una por vóxel.
			var local_top := surface_height(world_x, world_z) - origin.y
			data.fill_column(x, z, local_top, surface_block(world_x, world_z))
	return data


## Altura entera de la superficie; plana dentro de la zona segura de aparición.
func surface_height(world_x: int, world_z: int) -> int:
	if _safe_zone != null and _safe_zone.contains_xz(world_x, world_z):
		return _safe_zone.flat_height
	return roundi(_biome.sample_height(world_x, world_z))


## Bloque de superficie de la columna; la zona segura usa el material llano del bioma.
func surface_block(world_x: int, world_z: int) -> int:
	if _safe_zone != null and _safe_zone.contains_xz(world_x, world_z):
		return _biome.flat_surface_block()
	return _biome.sample_surface_block(world_x, world_z)
