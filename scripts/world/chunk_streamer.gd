class_name ChunkStreamer
extends Node3D

## Decide qué chunks existen según la posición del visor, encola su generación y su
## meshing en WorkerThreadPool y aplica los resultados en el hilo principal con
## presupuesto por frame. El número de tareas en vuelo está acotado para no saturar el
## pool ni competir con el hilo principal.
##
## Las tareas no tocan el árbol de escena: solo publican resultados en una lista
## protegida por Mutex. Los estados y los datos se leen y escriben solo en el hilo
## principal.
##
## Invariante: un chunk en estado GENERATED siempre tiene su ChunkData guardado, porque
## el estado se marca al guardar los datos y no al terminar la tarea.

enum State { GENERATING, GENERATED, MESHING, READY }

const CHUNK_SIZE := 32

const MAX_TASKS_IN_FLIGHT := 4
const MAX_RESULTS_PER_FRAME := 2

const _KIND_DATA := 0
const _KIND_MESH := 1

const _CHUNK_VIEW_SCENE := preload("res://scenes/chunk_view.tscn")

var _load_distance: int
var _unload_distance: int
var _chunk_y_range: Vector2i
var _generator: TerrainGenerator
var _mesher: ChunkMesher
var _registry: BlockRegistry
var _mineral_registry: MineralRegistry
var _plants: Array[Plant] = []
var _atlas: BlockAtlas
var _terrain_material: ShaderMaterial
var _viewer: Node3D

## Sombreado estilizado del terreno. Configurable desde el editor o por código.
@export var terrain_style: StylizedMaterial = preload("res://resources/materials/terrain_style.tres")

var _viewer_chunk := Vector3i.ZERO
var _viewer_initialized := false
var _desired := {}
var _desired_sorted := []
var _states := {}
var _chunk_data := {}
var _views := {}
var _generation_tasks := {}
var _mesh_tasks := {}

var _mutex := Mutex.new()
var _completed: Array = []


func configure(
	load_distance: int,
	unload_distance: int,
	chunk_y_range: Vector2i,
	generator: TerrainGenerator,
	mesher: ChunkMesher,
	registry: BlockRegistry,
	mineral_registry: MineralRegistry,
	plants: Array[Plant] = []
) -> void:
	_load_distance = load_distance
	_unload_distance = unload_distance
	_chunk_y_range = chunk_y_range
	_generator = generator
	_mesher = mesher
	_registry = registry
	_mineral_registry = mineral_registry
	_plants = plants
	# El atlas se construye una vez aquí, en el hilo principal, y se comparte de solo
	# lectura con las tareas de meshing.
	_atlas = BlockAtlas.new()
	_atlas.build(registry)
	_terrain_material = _create_terrain_material()


func set_viewer(viewer: Node3D) -> void:
	_viewer = viewer


func _exit_tree() -> void:
	# Las tareas en vuelo referencian este nodo: hay que esperarlas antes de que exista.
	for task_id in _generation_tasks.values():
		WorkerThreadPool.wait_for_task_completion(task_id)
	for task_id in _mesh_tasks.values():
		WorkerThreadPool.wait_for_task_completion(task_id)
	_generation_tasks.clear()
	_mesh_tasks.clear()


func _process(_delta: float) -> void:
	if _viewer == null or _load_distance <= 0:
		return
	_apply_completed()
	_reap_finished_tasks()
	var viewer_chunk := ChunkCoord.world_to_chunk(_viewer.global_position, CHUNK_SIZE)
	var viewer_moved := not _viewer_initialized or viewer_chunk != _viewer_chunk
	if viewer_moved:
		_viewer_chunk = viewer_chunk
		_desired = _desired_coords(_viewer_chunk)
		_desired_sorted = _sorted_by_distance(_desired)
		_viewer_initialized = true
	_start_tasks()
	if viewer_moved:
		_unload_outside()


## Cilindro: radio horizontal completo y banda vertical absoluta, no esfera 3D.
func _desired_coords(viewer_chunk: Vector3i) -> Dictionary:
	var desired := {}
	var radius_squared := _load_distance * _load_distance
	for y in range(_chunk_y_range.x, _chunk_y_range.y + 1):
		for z in range(-_load_distance, _load_distance + 1):
			for x in range(-_load_distance, _load_distance + 1):
				if x * x + z * z > radius_squared:
					continue
				desired[viewer_chunk + Vector3i(x, y - viewer_chunk.y, z)] = true
	return desired


func _start_tasks() -> void:
	for coord: Vector3i in _desired_sorted:
		if _in_flight_count() >= MAX_TASKS_IN_FLIGHT:
			return
		if not _states.has(coord):
			_start_generation(coord)
		elif _states[coord] == State.GENERATED and _neighbors_ready(coord, _desired):
			_start_meshing(coord)


func _in_flight_count() -> int:
	return _generation_tasks.size() + _mesh_tasks.size()


func _sorted_by_distance(desired: Dictionary) -> Array:
	var coords := desired.keys()
	coords.sort_custom(func(a, b): return _distance_squared(a) < _distance_squared(b))
	return coords


func _distance_squared(coord: Vector3i) -> int:
	var delta := coord - _viewer_chunk
	return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z


## Solo se espera a los vecinos que van a existir; los demás se tratarán como aire.
func _neighbors_ready(coord: Vector3i, desired: Dictionary) -> bool:
	for offset: Vector3i in ChunkMesher.NEIGHBOR_OFFSETS:
		var neighbor := coord + offset
		if desired.has(neighbor) and not _chunk_data.has(neighbor):
			return false
	return true


func _start_generation(coord: Vector3i) -> void:
	_states[coord] = State.GENERATING
	var task_id := WorkerThreadPool.add_task(
		_generate_task.bind(coord), false, "Generar chunk %s" % coord
	)
	_generation_tasks[coord] = task_id


func _generate_task(coord: Vector3i) -> void:
	var data := _generator.generate(coord)
	_mutex.lock()
	_completed.append([_KIND_DATA, coord, data])
	_mutex.unlock()


func _start_meshing(coord: Vector3i) -> void:
	_states[coord] = State.MESHING
	var neighbors := []
	for offset: Vector3i in ChunkMesher.NEIGHBOR_OFFSETS:
		neighbors.append(_chunk_data.get(coord + offset))
	var task_id := WorkerThreadPool.add_task(
		_mesh_task.bind(coord, _chunk_data[coord], neighbors), false, "Mallar chunk %s" % coord
	)
	_mesh_tasks[coord] = task_id


func _mesh_task(coord: Vector3i, chunk: ChunkData, neighbors: Array) -> void:
	var mesh_data := _mesher.build(chunk, _registry, _atlas, neighbors, coord)
	_mutex.lock()
	_completed.append([_KIND_MESH, coord, mesh_data])
	_mutex.unlock()


func _reap_finished_tasks() -> void:
	for coord in _generation_tasks.keys():
		if not WorkerThreadPool.is_task_completed(_generation_tasks[coord]):
			continue
		WorkerThreadPool.wait_for_task_completion(_generation_tasks[coord])
		_generation_tasks.erase(coord)
	for coord in _mesh_tasks.keys():
		if not WorkerThreadPool.is_task_completed(_mesh_tasks[coord]):
			continue
		WorkerThreadPool.wait_for_task_completion(_mesh_tasks[coord])
		_mesh_tasks.erase(coord)


func _apply_completed() -> void:
	var pending := _take_completed()
	var mesh_results := []
	for entry in pending:
		var coord: Vector3i = entry[1]
		if not _states.has(coord):
			continue
		if entry[0] == _KIND_DATA:
			# GENERATED se marca aquí, con los datos ya en la mano, no al terminar la tarea.
			_chunk_data[coord] = entry[2]
			_states[coord] = State.GENERATED
		elif entry[0] == _KIND_MESH:
			mesh_results.append(entry)
	_apply_mesh_results(mesh_results)


func _apply_mesh_results(mesh_results: Array) -> void:
	var applied := 0
	for entry in mesh_results:
		var coord: Vector3i = entry[1]
		if not _states.has(coord) or _states[coord] != State.MESHING:
			continue
		if applied >= MAX_RESULTS_PER_FRAME:
			_requeue(entry)
			continue
		_spawn_view(coord, entry[2])
		_states[coord] = State.READY
		applied += 1


func _take_completed() -> Array:
	_mutex.lock()
	var pending: Array = _completed
	_completed = []
	_mutex.unlock()
	return pending


func _requeue(entry: Array) -> void:
	_mutex.lock()
	_completed.append(entry)
	_mutex.unlock()


func _spawn_view(coord: Vector3i, mesh_data: ChunkMeshData) -> void:
	var view := _CHUNK_VIEW_SCENE.instantiate() as ChunkView
	add_child(view)
	view.position = ChunkCoord.chunk_to_world(coord, CHUNK_SIZE)
	view.set_terrain_material(_terrain_material)
	view.apply(mesh_data)
	_spawn_mineral_deposits(view, coord)
	_spawn_plants(view, coord)
	_views[coord] = view


## Material único del terreno: muestrea el atlas por cara con las UV y el color de
## vértice horneados en el mesher, bajo el sombreado estilizado. Si ningún bloque
## tiene texturas, el terreno se dibuja con su color plano.
func _create_terrain_material() -> ShaderMaterial:
	if _atlas.atlas_texture == null:
		return terrain_style.create_material(false)
	return terrain_style.create_material(true, _atlas.atlas_texture, _atlas.tile_uv)


## Instancia los depósitos de minerales del chunk dentro de su vista. Al colgar del
## ChunkView se descargan con él, sin llevar una cuenta aparte.
func _spawn_mineral_deposits(view: Node3D, coord: Vector3i) -> void:
	var data: ChunkData = _chunk_data[coord]
	for spawn: MineralSpawn in data.mineral_spawns:
		var mineral := _mineral_registry.get_mineral(spawn.mineral_id)
		if mineral == null or mineral.model == null:
			continue
		var deposit := mineral.model.instantiate() as Node3D
		view.add_child(deposit)
		deposit.position = spawn.local_position
		deposit.rotation = spawn.rotation
		deposit.scale = Vector3.ONE * spawn.scale
		if deposit is MineralDeposit:
			(deposit as MineralDeposit).apply(mineral, spawn.variation_seed)


## Instancia las plantas del chunk dentro de su vista, igual que los depósitos.
func _spawn_plants(view: Node3D, coord: Vector3i) -> void:
	var data: ChunkData = _chunk_data[coord]
	for spawn: PlantSpawn in data.plant_spawns:
		var plant := _get_plant(spawn.plant_id)
		if plant == null or plant.model == null:
			continue
		var node := plant.model.instantiate() as Node3D
		view.add_child(node)
		node.position = spawn.local_position
		node.rotation = spawn.rotation
		node.scale = Vector3.ONE * spawn.scale


## Planta con esa id. La lista es corta, así que basta con recorrerla.
func _get_plant(plant_id: int) -> Plant:
	for plant in _plants:
		if plant.id == plant_id:
			return plant
	return null


## Descarga con histéresis: se conserva hasta _unload_distance para no recargar lo que se
## acaba de soltar. Un chunk con una tarea en vuelo se pospone hasta que la tarea termina.
func _unload_outside() -> void:
	for coord: Vector3i in _states.keys():
		if _is_within(coord, _unload_distance):
			continue
		if _generation_tasks.has(coord) or _mesh_tasks.has(coord):
			continue
		_discard_chunk(coord)


func _is_within(coord: Vector3i, distance: int) -> bool:
	if coord.y < _chunk_y_range.x or coord.y > _chunk_y_range.y:
		return false
	var delta := coord - _viewer_chunk
	return delta.x * delta.x + delta.z * delta.z <= distance * distance


func _discard_chunk(coord: Vector3i) -> void:
	if _views.has(coord):
		_views[coord].queue_free()
		_views.erase(coord)
	_chunk_data.erase(coord)
	_states.erase(coord)
