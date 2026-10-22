class_name PlayerController
extends CharacterBody3D

## Controlador en primera persona para probar el mundo. Usa teclas físicas directas
## (WASD, Espacio) para no añadir acciones al mapa de entrada del proyecto.
## Posee las estadísticas vitales (stats); otros sistemas como el HUD se conectan
## a sus señales en lugar de consultarlas cada frame.

## Se emite cuando cambia el objeto con el que el jugador puede interactuar:
## la planta apuntada, la estación de fabricación, o null si ya no apunta a ninguno.
signal interaction_focus_changed(target: Interactable)

## Se emite cuando el jugador interactúa con un objeto.
signal interaction_performed(target: Interactable)

const WALK_SPEED := 6.0
const JUMP_VELOCITY := 7.5
const GRAVITY := 24.0
const MOUSE_SENSITIVITY := 0.0025
const MAX_PITCH := 1.5

@onready var _camera: Camera3D = $Camera3D
@onready var _ray_cast: RayCast3D = $Camera3D/RayCast3D
@onready var _highlight: HighlightController = $HighlightController
@onready var _mining_pistol: MiningPistol = $MiningPistol

var _pitch := 0.0
var _safe_zone: SafeZone
var _was_in_safe_zone := false
## Objeto del mundo con el que el jugador puede interactuar, si lo hay.
var _focused_target: Interactable = null

## Estadísticas vitales del jugador. Se crean en el propio script (no como .tres)
## para que estén disponibles antes de que cualquier _ready acceda a ellas.
var stats := PlayerStats.new()

## Objetos recogidos por el jugador (minería y otras actividades).
var inventory := InventoryData.new()


func set_safe_zone(safe_zone: SafeZone) -> void:
	_safe_zone = safe_zone


## Cámara de la vista del jugador, para proyectar avisos en pantalla.
func get_view_camera() -> Camera3D:
	return _camera


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# La pistola mina al mundo; el inventario del jugador recoge lo que suelta.
	_mining_pistol.inventory = inventory


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event.is_action_pressed("interaction"):
		_interact()
		return
	var motion := event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
	_pitch = clampf(_pitch - motion.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH)
	_camera.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var in_safe_zone := _safe_zone != null and _safe_zone.contains_position(global_position)
	stats.tick(delta, in_safe_zone)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_direction := Vector2(
		_key_axis(KEY_D, KEY_A),
		_key_axis(KEY_S, KEY_W)
	)
	var direction := (transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	if direction.is_zero_approx():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	move_and_slide()
	_report_safe_zone(not direction.is_zero_approx(), in_safe_zone)
	_update_highlight()
	_update_focus()


## Interactúa con el objeto apuntado: recoge la planta, abre la estación de
## fabricación, etc.
func _interact() -> void:
	var target := _aimed_interactable()
	if target == null:
		return
	# El objeto puede desaparecer al interactuar (una planta se recoge), así que
	# el aviso se retira antes de la acción.
	_focused_target = null
	interaction_focus_changed.emit(null)
	interaction_performed.emit(target)
	target.interact(self)


## Objeto con el que el jugador puede interactuar. Solo cuenta si está lo
## bastante cerca, según la distancia que permita el propio objeto.
func _aimed_interactable() -> Interactable:
	if not _ray_cast.is_colliding():
		return null
	var collider := _ray_cast.get_collider() as Node
	if collider == null:
		return null
	var target := _find_interactable(collider)
	if target == null:
		return null
	if target.global_position.distance_to(global_position) > target.get_interaction_distance():
		return null
	return target


## Objeto interactable al que pertenece el nodo colisionado, subiendo por sus
## padres: el Area3D de una planta, el StaticBody3D de una estación.
func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current != null:
		if current is Interactable:
			return current
		current = current.get_parent()
	return null


## Actualiza el objeto enfocado y avisa de los cambios de foco para que el HUD
## muestre u oculte el aviso de la tecla.
func _update_focus() -> void:
	var target := _aimed_interactable()
	if target == _focused_target:
		return
	_focused_target = target
	interaction_focus_changed.emit(target)


## Resalta el objeto apuntado por el raycast de la cámara. Se ejecuta tras mover
## al jugador para que el rayo use la posición y el giro actuales.
func _update_highlight() -> void:
	if not _ray_cast.is_colliding():
		_highlight.clear()
		return
	var collider := _ray_cast.get_collider()
	var point := _ray_cast.get_collision_point()
	var normal := _ray_cast.get_collision_normal()
	_highlight.highlight(collider, point, normal)


## Imprime el estado de la safe zone solo cuando cambia y el jugador está caminando,
## para no llenar la consola repitiendo el mismo mensaje cada frame.
func _report_safe_zone(is_walking: bool, inside: bool) -> void:
	if _safe_zone == null or not is_walking:
		return
	if inside == _was_in_safe_zone:
		return
	_was_in_safe_zone = inside
	if inside:
		print("Safe Zone")
	else:
		print("Fuera de Safe Zone")


func _key_axis(positive: Key, negative: Key) -> float:
	var pressed := int(Input.is_physical_key_pressed(positive)) - int(Input.is_physical_key_pressed(negative))
	return float(pressed)
