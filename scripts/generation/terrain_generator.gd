class_name TerrainGenerator
extends RefCounted

## Genera el terreno de un chunk de forma determinista a partir de la coordenada y
## del bioma. El bioma decide el relieve y el material de cada columna; el generador
## aplica la zona segura, redondea las alturas a bloques y pide los depósitos de
## minerales que nacen sobre la superficie. Sin estado mutable, por lo que es seguro
## usar una instancia compartida desde varios hilos.

var _chunk_size: int
var _biome: Biome
var _safe_zone: SafeZone
var _mineral_spawner: MineralSpawner


func _init(
	biome: Biome,
	chunk_size: int,
	safe_zone: SafeZone = null,
	mineral_spawner: MineralSpawner = null
) -> void:
	assert(
		biome != null and biome.is_configured(),
		"TerrainGenerator necesita un bioma con setup(semilla_del_mundo) ya llamado."
	)
	assert(
		mineral_spawner == null or mineral_spawner.is_configured(),
		"TerrainGenerator necesita un MineralSpawner con setup() ya llamado."
	)
	_chunk_size = chunk_size
	_biome = biome
	_safe_zone = safe_zone
	_mineral_spawner = mineral_spawner


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
			var surface_id := surface_block(world_x, world_z)
			data.fill_column(x, z, local_top, surface_id)
			_append_mineral_spawns(data, world_x, world_z, Vector3i(x, local_top, z), surface_id)
	return data


## Depósitos de minerales de la columna, solo fuera de la zona segura: allí el suelo
## se mantiene limpio y plano para la aparición del jugador.
func _append_mineral_spawns(
	data: ChunkData, world_x: int, world_z: int, local_column: Vector3i, surface_id: int
) -> void:
	if _mineral_spawner == null:
		return
	if _safe_zone != null and _safe_zone.contains_xz(world_x, world_z):
		return
	for spawn: MineralSpawn in _mineral_spawner.sample(world_x, world_z, surface_id, local_column):
		data.mineral_spawns.append(spawn)


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
