class_name MineralDeposit
extends Node3D

## Representación de un depósito de mineral en el mundo. Cada mineral aporta su
## propia escena (la forma); el color y la variación de la malla llegan con la
## definición del mineral al instanciar el depósito.

## Número de cristales del grupo. El primero es el asta grande del centro y el
## resto son satélites más pequeños.
@export var shard_count: int = 3

@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_mesh_instance.material_override = _create_material()


## Construye el cristal del depósito con el color del mineral. `variation_seed`
## procede de la posición de la columna, así que el mismo sitio del mismo mundo
## luce siempre el mismo depósito.
func apply(mineral: Mineral, variation_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed
	_mesh_instance.mesh = CrystalMesh.create_cluster(shard_count, mineral.color, rng)


func _create_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	# Opaco con algo de brillo, para que las facetas se lean sin volverse espejado.
	material.roughness = 0.4
	return material
