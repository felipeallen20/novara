class_name MiningPistol
extends Node3D

## Vista de la pistola de minado en la mano del jugador.
##
## La escena debe colgar del punto de la mano (`RightHand`), que a su vez cuelga de
## la Camera3D. Así la pistola hereda el giro horizontal y la inclinación de la
## cámara, y se queda fija en la mano sin cálculos por fotograma.
##
## En `_ready` este script recoloca la pistola en la mano derecha de la cámara si
## no está ya ahí, para no depender de la jerarquía montada a mano en el editor.

## Nodo con la instancia del modelo (.glb). Si se deja vacío se busca un hijo
## llamado `Model`, `Model2` o `Model3`.
@export var model: Node3D

## Visibilidad del modelo de la pistola.
@export var model_visible: bool = true:
	set(value):
		model_visible = value
		_apply_model_visibility()

## Nodo de la cámara del jugador desde el que se calcula la mano. Si se deja vacío
## se busca una Camera3D subiendo por los ancestros.
@export var camera: Camera3D

## Nombre del nodo que hace de mano derecha. Se busca como hijo de la cámara.
@export var hand_node_name: StringName = &"RightHand"

## Posición de la mano en coordenadas de la cámara: algo a la derecha, algo abajo
## y delante del encuadre.
@export var hand_position := Vector3(0.45, -0.32, -0.64)

## Rotación de la mano en grados, en coordenadas de la cámara. Orienta el arma:
## -90 en Y deja el cañón apuntando al frente de la vista (el .glb tiene la boca
## del cañón en el extremo negativo del eje X).
@export var hand_rotation_degrees := Vector3(0.0, -90.0, 0.0)

## Si está activo, ancla la pistola a la mano derecha al iniciar.
@export var anchor_to_hand := true

## Efectividad del láser: durabilidad que le resta al mineral por segundo de
## disparo continuo. La Sandite tiene 1.5 de durabilidad.
@export var mining_power: float = 1.0

## Destino de los objetos minados. Lo asigna el jugador al iniciar.
var inventory: InventoryData

const MODEL_NODE_NAMES: Array[StringName] = [&"Model", &"Model2", &"Model3"]

## Nombre del raycast de puntería que vive en la cámara del jugador (la mirilla).
const AIM_RAY_NODE_NAME := &"RayCast3D"

@onready var _muzzle: Marker3D = $Muzzle
@onready var _laser: RayCast3D = $Laser
@onready var _beam: MeshInstance3D = $Beam

## True mientras se mantiene pulsado el click izquierdo de disparo.
var _firing := false
var _aim_ray: RayCast3D


func _ready() -> void:
	_resolve_model()
	if model == null:
		return
	_apply_model_visibility()

	if anchor_to_hand:
		# Cambiar de padre no es seguro durante el _ready propio: se difiere un frame.
		_anchor_to_hand.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	# Con el ratón libre (interfaz abierta) el click pertenece a la UI, no al arma.
	_firing = button.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Mantiene el láser mientras se dispara. El haz solo sale si el jugador apunta a
## un mineral, y `Laser` queda orientado del muzzle al impacto para que el paso
## de minado tenga ya el rayo resuelto.
func _physics_process(delta: float) -> void:
	var aim: RayCast3D = _resolve_aim_ray() if _firing else null
	if aim == null or not aim.is_colliding() or not _is_mineral(aim.get_collider()):
		_hide_laser()
		return
	_shoot_laser(aim.get_collision_point())
	_mine(aim.get_collider(), delta)


## Aplica la potencia del láser al depósito apuntado y guarda en el inventario
## los objetos que suelta cuando se rompe.
func _mine(collider: Object, delta: float) -> void:
	if inventory == null:
		return
	var deposit := (collider as Node).get_parent() as MineralDeposit
	if deposit == null:
		return
	for item in deposit.mine(mining_power * delta):
		inventory.add(item)


## Dibuja el haz entre el muzzle y el impacto y apunta el raycast al mismo punto.
func _shoot_laser(target: Vector3) -> void:
	var start := _muzzle.global_position
	_beam.visible = true
	_beam.global_position = start.lerp(target, 0.5)
	_beam.look_at(target)
	_beam.scale = Vector3(1.0, 1.0, start.distance_to(target))
	_laser.enabled = true
	_laser.global_position = start
	_laser.target_position = _laser.to_local(target)


func _hide_laser() -> void:
	_beam.visible = false
	_laser.enabled = false


## Raycast de la cámara que hace de mirilla; se busca una vez y se reutiliza.
func _resolve_aim_ray() -> RayCast3D:
	if _aim_ray == null:
		var cam := _resolve_camera()
		if cam != null:
			_aim_ray = cam.get_node_or_null(NodePath(AIM_RAY_NODE_NAME)) as RayCast3D
	return _aim_ray


func _is_mineral(collider: Object) -> bool:
	var node := collider as Node
	return node != null and node.is_in_group(HighlightController.MINERAL_GROUP)


func _resolve_model() -> void:
	if model != null:
		return
	for candidate in MODEL_NODE_NAMES:
		var found := get_node_or_null(NodePath(candidate)) as Node3D
		if found != null:
			model = found
			return
	push_error(
		"mining_pistol.gd: no se encontró el nodo del modelo. "
		+ "Añade un hijo con la instancia del .glb llamado `Model`, `Model2` o `Model3`, "
		+ "o asigna ese nodo en la propiedad `Model` del Inspector."
	)


## Cuelga esta pistola de la mano derecha de la cámara y la coloca en el encuadre.
## Si ya es hija de la mano, solo refresca su transform.
func _anchor_to_hand() -> void:
	var cam := _resolve_camera()
	if cam == null:
		push_warning(
			"mining_pistol.gd: no se encontró la Camera3D para anclar la pistola a la mano. "
			+ "Asigna la cámara en la propiedad `Camera` del Inspector o desactiva `Anchor To Hand`."
		)
		return

	var hand := cam.get_node_or_null(NodePath(hand_node_name)) as Node3D
	if hand == null:
		hand = Marker3D.new()
		hand.name = hand_node_name
		cam.add_child(hand)

	if get_parent() != hand:
		get_parent().remove_child(self)
		hand.add_child(self)

	# El offset va en la pistola, dentro de la mano, para que la mano quede en el
	# origen de la cámara y no acumule dos desplazamientos.
	hand.position = Vector3.ZERO
	hand.rotation_degrees = Vector3.ZERO
	position = hand_position
	rotation_degrees = hand_rotation_degrees


func _resolve_camera() -> Camera3D:
	if camera != null:
		return camera
	# Primero los ancestros (pistola ya colgada de la cámara o de la mano).
	var node := get_parent()
	while node != null:
		var found := node as Camera3D
		if found != null:
			return found
		node = node.get_parent()
	# Si no, cualquier Camera3D del árbol, empezando por la del jugador al que
	# pertenece esta pistola.
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.current_scene
	if root == null:
		root = tree.root
	return _find_camera(root)


func _find_camera(node: Node) -> Camera3D:
	var found := node as Camera3D
	if found != null:
		return found
	for child in node.get_children():
		var result := _find_camera(child)
		if result != null:
			return result
	return null


func _apply_model_visibility() -> void:
	if model != null:
		model.visible = model_visible
