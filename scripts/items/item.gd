class_name Item
extends Resource

## Plantilla de objeto: lo que se guarda en el inventario. El jugador los obtiene
## de la minería y de otras actividades. Dos unidades con el mismo id se apilan
## en la misma casilla.

@export var id: int = 0
@export var display_name: String = ""
@export var icon: Texture2D
