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
## Valor del ruido de parche a partir del cual la columna cae dentro de un
## yacimiento del mineral. Cuanto menor, más superficie cubren los yacimientos.
@export var patch_threshold: float = 0.48
## Valor del ruido de dispersión a partir del cual la columna concreta recibe un
## cristal dentro del yacimiento. Cuanto menor, más cristales sueltos hay.
@export var scatter_threshold: float = 0.50
## Objetos que suelta el depósito al romperse.
@export var loot: LootTable
## Escena de la representación en el mundo, sin posición ni giro aplicados.
@export var model: PackedScene
