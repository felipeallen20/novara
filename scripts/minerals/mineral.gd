class_name Mineral
extends Resource

## Plantilla de mineral. Define las propiedades comunes a los minerales del juego:
## datos de minado y de interfaz, el bloque de superficie sobre el que crece y la
## escena que se instancia sobre el terreno.

## Rareza orientativa del mineral. De momento no altera la generación: los
## yacimientos se deciden en MineralSpawner.
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

@export var id: int = 0
@export var display_name: String = ""
@export var rarity: Rarity = Rarity.COMMON
## Resistencia al minado; mineral más duro, más tiempo en romperse.
@export var durability: float = 1.0
## Unidades que se obtienen al minar un depósito.
@export var yield_amount: int = 1
## Tinte del modelo del mineral en el mundo.
@export var color: Color = Color.WHITE
## Bloque de superficie sobre cuyas columnas puede nacer.
@export var host_block_id: int = 0
## Escena de la representación en el mundo, sin posición ni giro aplicados.
@export var model: PackedScene
