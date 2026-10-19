extends CharacterBody3D

## Controlador en primera persona para probar el mundo. Usa teclas físicas directas
## (WASD, Espacio) para no añadir acciones al mapa de entrada del proyecto.

const WALK_SPEED := 6.0
const JUMP_VELOCITY := 7.5
const GRAVITY := 24.0
const MOUSE_SENSITIVITY := 0.0025
const MAX_PITCH := 1.5

@onready var _camera: Camera3D = $Camera3D

var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	var motion := event as InputEventMouseMotion
	if motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
	_pitch = clampf(_pitch - motion.relative.y * MOUSE_SENSITIVITY, -MAX_PITCH, MAX_PITCH)
	_camera.rotation.x = _pitch


func _physics_process(delta: float) -> void:
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


func _key_axis(positive: Key, negative: Key) -> float:
	var pressed := int(Input.is_physical_key_pressed(positive)) - int(Input.is_physical_key_pressed(negative))
	return float(pressed)
