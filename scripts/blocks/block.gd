class_name Block
extends Resource

## Plantilla de bloque. Define las características comunes a todos los bloques del juego.

@export var id: int = 0
@export var display_name: String = ""
@export var color: Color = Color.WHITE
## Texturas de las caras del bloque. Si es null, el bloque se dibuja con su color plano.
@export var textures: BlockTextures
@export var opaque: bool = true
@export var solid: bool = true
