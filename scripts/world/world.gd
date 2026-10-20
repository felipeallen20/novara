extends Node3D

## Punto de entrada del mundo. Configura el streamer de chunks y le indica al jugador
## como visor.

const LOAD_DISTANCE_CHUNKS := 6
const UNLOAD_DISTANCE_CHUNKS := 8
const WORLD_SEED := 12345

## Banda vertical absoluta de chunks. El terreno de prueba solo existe en y = 0.
const CHUNK_Y_RANGE := Vector2i(0, 0)

@onready var _chunk_streamer: ChunkStreamer = $ChunkStreamer
@onready var _player: CharacterBody3D = $Player


func _ready() -> void:
	var registry := BlockRegistry.with_default_blocks()
	var mineral_registry := MineralRegistry.with_default_minerals()
	var biome := MiningLandsBiome.new()
	biome.setup(WORLD_SEED)
	var safe_zone := SafeZone.new(_player.global_position, biome.base_height)
	var mineral_spawner := MineralSpawner.new(mineral_registry.minerals(), WORLD_SEED)
	mineral_spawner.setup()
	var generator := TerrainGenerator.new(
		biome, ChunkStreamer.CHUNK_SIZE, safe_zone, mineral_spawner
	)
	_chunk_streamer.configure(
		LOAD_DISTANCE_CHUNKS,
		UNLOAD_DISTANCE_CHUNKS,
		CHUNK_Y_RANGE,
		generator,
		ChunkMesher.new(),
		registry,
		mineral_registry
	)
	_chunk_streamer.set_viewer(_player)
	_player.set_safe_zone(safe_zone)
