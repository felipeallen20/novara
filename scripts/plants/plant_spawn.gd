class_name PlantSpawn
extends RefCounted

## Posición de una planta dentro de un chunk. Datos puros que decide la
## generación en el hilo de cálculo; la representación se crea en el hilo principal.

var plant_id := 0

## Centro de la base de la planta, en coordenadas locales del chunk. La base queda
## sobre la cara superior del bloque de superficie.
var local_position := Vector3.ZERO

## Giro de la planta en radianes: deriva completa en Y y una inclinación leve en X/Z.
var rotation := Vector3.ZERO

var scale := 1.0
