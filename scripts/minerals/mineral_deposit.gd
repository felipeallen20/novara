class_name MineralDeposit
extends Node3D

## Representación de un depósito de mineral en el mundo. Cada mineral aporta su
## propia escena (la forma); el color y la variación de la malla llegan con la
## definición del mineral al instanciar el depósito.

## Número de cristales del grupo. El primero es el asta grande del centro y el
## resto son satélites más pequeños.
@export var shard_count: int = 3

## Sombreado estilizado del depósito. Configurable desde el editor o por código.
@export var style: StylizedMaterial = preload("res://resources/materials/mineral_style.tres")

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _area: Area3D = $Area3D
@onready var _collision_shape: CollisionShape3D = $Area3D/CollisionShape3D

## Mineral del que forma depósito y durabilidad que le queda. El mineral llega
## con `apply`, que también fija la durabilidad inicial.
var mineral: Mineral
var _remaining_durability := 0.0


func _ready() -> void:
	# El cristal lleva su color por vértice, así que basta el modo de color plano.
	_mesh_instance.material_override = style.create_material(false)
	# Marca la colisión para que el resaltado identifique los minerales.
	_area.add_to_group(HighlightController.MINERAL_GROUP)


## Construye el cristal del depósito con el color del mineral. `variation_seed`
## procede de la posición de la columna, así que el mismo sitio del mismo mundo
## luce siempre el mismo depósito.
func apply(mineral: Mineral, variation_seed: int) -> void:
	self.mineral = mineral
	_remaining_durability = mineral.durability
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed
	_mesh_instance.mesh = CrystalMesh.create_cluster(shard_count, mineral.color, rng)
	_update_collision()


## Aplica potencia de minado. Mientras quede durabilidad devuelve una lista
## vacía; al romperse devuelve los objetos de su tabla de loot y el depósito
## desaparece del mundo.
func mine(amount: float) -> Array[Item]:
	_remaining_durability -= amount
	if _remaining_durability > 0.0:
		return []
	var drops: Array[Item] = []
	if mineral != null and mineral.loot != null:
		drops = mineral.loot.roll()
	queue_free()
	return drops


## Ajusta la colisión al volumen del cristal generado, para que el raycast del
## jugador pueda golpearlo y resaltarlo.
func _update_collision() -> void:
	if _mesh_instance.mesh == null:
		return
	var box := BoxShape3D.new()
	box.size = _mesh_instance.get_aabb().size
	_collision_shape.shape = box
	_collision_shape.position = _mesh_instance.get_aabb().get_center()
