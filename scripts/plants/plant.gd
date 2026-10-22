class_name Plant
extends Resource

## Plantilla de planta. Define las reglas comunes de las plantas: el bloque de
## superficie donde crecen, el desnivel que necesitan al lado, con qué frecuencia
## aparecen y qué modelo usan en el mundo.

@export var id: int = 0
@export var display_name: String = ""
## Escena del modelo de la planta en el mundo.
@export var model: PackedScene
## Bloque de superficie sobre el que puede crecer.
@export var host_block_id: int = 0
## Bloques que cuentan como desnivel: la planta crece al pie de ellos.
@export var cliff_block_ids: Array[int] = []
## Altura mínima del desnivel, en bloques, para que la planta crezca al pie.
@export var min_cliff_height: int = 4
## Probabilidad de que una columna apta tenga planta.
@export var density: float = 0.105
## Separación entre plantas: lado de la celda, en bloques. Como máximo hay una
## planta por celda, así que no se amontonan.
@export var spacing: int = 4
## Rango de escala del modelo, como variación sobre su tamaño base.
@export var scale_range: Vector2 = Vector2(0.85, 1.15)


## True si la planta puede crecer sobre esa superficie.
func can_grow(surface_block_id: int) -> bool:
	return surface_block_id == host_block_id
