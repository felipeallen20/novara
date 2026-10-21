extends CanvasLayer

## Abre y cierra la interfaz de inventario con la accion "open_inventory".
## El panel es un holograma 3D que se proyecta frente a la camara del jugador:
## se instancia como hijo de Camera3D para que quede suspendido en el espacio con
## perspectiva real, y aparece con una breve animacion de proyeccion.
##
## Con el panel abierto el raton queda libre para navegar la interfaz. Mantener
## el click derecho captura el raton temporalmente para mirar alrededor; al
## soltarlo se vuelve a liberar para seguir usando la interfaz.

const INVENTORY_SCENE := preload("res://scenes/ui/inventory/inventory.tscn")

## Distancia a la que se proyecta el panel frente a la camara, en metros.
const PANEL_DISTANCE := 1.5
## Segundos que dura la animacion de aparicion.
const APPEAR_DURATION := 0.18
## Inclinacion base del panel en grados: la parte superior mira ligeramente hacia
## abajo (se aleja del jugador), como una pantalla suspendida vista desde abajo.
const PANEL_PITCH_DEGREES := 8.0
## Rigidez con la que el panel vuelve a su transform de reposo (mayor = mas centrado).
const PARALLAX_FOLLOW := 8.0
## Cuanto rota el panel ante el giro de la camara. Muy bajo para que sea un
## efecto sutil: solo un pequeno cabeceo/ladeo, nunca un movimiento amplio.
const PARALLAX_ROTATION := 4.0
## Rapidez con la que el cabeceo sigue (y suelta) el giro de la camara.
const PARALLAX_DAMPING := 6.0
## Limite del cabeceo inducido, en grados, para que un giro rapido no lo exagere.
const MAX_SWAY_DEGREES := 3.5
## Amplitud de la flotacion continua del panel, en metros.
const FLOAT_AMPLITUDE := 0.004
## Velocidad de la flotacion continua.
const FLOAT_SPEED := 1.0

@export var player: PlayerController

var _panel: Node3D
var _appear := 0.0
## Escala actual del panel, gobernada por la animacion de aparicion.
var _appear_scale := 1.0
var _open := false
## True mientras el click derecho se mantiene para mirar alrededor.
var _looking := false
## Posicion y rotacion de reposo del panel respecto a la camara (incluye la
## inclinacion base).
var _rest_basis := Basis.IDENTITY
## Rotacion inducida por el giro de la camara, que vuelve a cero sola. Se mantiene
## pequena para que el panel no se desvie y siga sintiendose centrado.
var _sway := Vector2.ZERO
## Rotacion global de la camara en el frame anterior, para medir su velocidad angular.
var _prev_camera_rotation := Vector3.ZERO
var _float_time := 0.0


func _ready() -> void:
	if player == null:
		# El HUD conoce al jugador; el panel lo hereda para no duplicar la ruta.
		player = get_parent().get("player") as PlayerController
	if player == null:
		push_error("InventoryUi: falta la referencia al jugador.")
		return
	var camera := _camera()
	if camera == null:
		push_error("InventoryUi: el jugador no tiene un Camera3D; el panel no puede proyectarse.")
		return
	_panel = INVENTORY_SCENE.instantiate()
	camera.add_child(_panel)
	_panel.visible = false
	_rest_basis = Basis(Vector3.RIGHT, deg_to_rad(PANEL_PITCH_DEGREES))
	_prev_camera_rotation = camera.global_rotation


func _process(delta: float) -> void:
	if _panel == null:
		return
	_update_appear(delta)
	if _open:
		_update_floating(delta)


func _update_appear(delta: float) -> void:
	if _appear <= 0.0:
		return
	_appear = maxf(_appear - delta / APPEAR_DURATION, 0.0)
	# Escala con rebote leve para simular el encendido del proyector.
	_appear_scale = (1.0 - _appear) * (1.0 + 0.08 * sin(_appear * PI))
	_panel.scale = Vector3.ONE * _appear_scale


## Mantiene el panel casi centrado: apenas flota una fraccion de milimetro y, al
## girar la camara, rota de forma sutil (no se desplaza). La rotacion inducida
## decae sola hacia la inclinacion base. No toca la escala: esa la gobierna la
## animacion de aparicion.
func _update_floating(delta: float) -> void:
	_float_time += delta
	var camera := _camera()
	if camera != null:
		var rotation := camera.global_rotation
		var yaw_delta := wrapf(rotation.y - _prev_camera_rotation.y, -PI, PI)
		var pitch_delta := rotation.x - _prev_camera_rotation.x
		_prev_camera_rotation = rotation
		# La rotacion sigue la velocidad de giro instantanea: al dejar de girar,
		# vuelve sola a cero. No se acumula, asi el panel nunca se desvia.
		var speed := Vector2(yaw_delta, pitch_delta) / maxf(delta, 0.0001)
		var target_sway := speed * deg_to_rad(PARALLAX_ROTATION)
		target_sway = target_sway.limit_length(deg_to_rad(MAX_SWAY_DEGREES))
		_sway = _sway.lerp(target_sway, clampf(PARALLAX_DAMPING * delta, 0.0, 1.0))
	else:
		_sway = _sway.lerp(Vector2.ZERO, clampf(PARALLAX_DAMPING * delta, 0.0, 1.0))

	# Rotacion objetivo: inclinacion base + cabeceo sutil alrededor de X e Y.
	var target := Basis(Vector3.RIGHT, deg_to_rad(PANEL_PITCH_DEGREES) + _sway.y)
	target = target.rotated(Vector3.UP, _sway.x)

	var bob := Vector3(
		sin(_float_time * FLOAT_SPEED) * FLOAT_AMPLITUDE,
		cos(_float_time * FLOAT_SPEED * 0.7) * FLOAT_AMPLITUDE,
		0.0
	)
	var weight := clampf(PARALLAX_FOLLOW * delta, 0.0, 1.0)
	var target_origin := Vector3(0.0, 0.0, -PANEL_DISTANCE) + bob
	_panel.position = _panel.position.lerp(target_origin, weight)
	_panel.basis = _panel.basis.orthonormalized().slerp(target.orthonormalized(), weight)
	_panel.scale = Vector3.ONE * _appear_scale


## Usa _input en lugar de _unhandled_input para capturar el click derecho aunque
## un Control del panel consuma el evento.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		get_viewport().set_input_as_handled()
		set_open(not _open)
		return
	if not _open:
		return
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_RIGHT:
		return
	_looking = button.pressed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _looking else Input.MOUSE_MODE_VISIBLE
	# Evita que el click derecho active menus contextuales de los controles.
	get_viewport().set_input_as_handled()


func set_open(open: bool) -> void:
	if _panel == null:
		return
	_open = open
	_panel.visible = open
	if open:
		_appear = 1.0
		# Arranca en reposo (inclinado) para no arrastrar el sway anterior.
		_panel.transform = Transform3D(_rest_basis, Vector3(0.0, 0.0, -PANEL_DISTANCE))
		_panel.scale = Vector3.ZERO
		_sway = Vector2.ZERO
		var camera := _camera()
		if camera != null:
			_prev_camera_rotation = camera.global_rotation
	_looking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func _camera() -> Camera3D:
	if player == null:
		return null
	return player.get_node_or_null("Camera3D") as Camera3D
