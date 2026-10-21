class_name BlockTextures
extends Resource

## Texturas de las seis caras de un bloque. En los bloques con lados repetidos basta
## con asignar la misma imagen a varios lados; el atlas las deduplica por ruta, así
## que no ocupa espacio de más.
##
## Las caras siguen el orden de `ChunkMesher.NEIGHBOR_OFFSETS`:
## +X, -X, +Y (arriba), -Y (abajo), +Z, -Z.

@export var top: Texture2D
@export var bottom: Texture2D
@export var side_1: Texture2D
@export var side_2: Texture2D
@export var side_3: Texture2D
@export var side_4: Texture2D


## Textura de la cara `face_index` (orden de NEIGHBOR_OFFSETS). Devuelve null si la
## cara no tiene textura asignada.
func get_face(face_index: int) -> Texture2D:
	match face_index:
		0:
			return side_1
		1:
			return side_2
		2:
			return top
		3:
			return bottom
		4:
			return side_3
		5:
			return side_4
	return null
