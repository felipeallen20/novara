class_name MineralSpawn
extends RefCounted

## Posición de un depósito de mineral dentro de un chunk. Datos puros que decide la
## generación en el hilo de cálculo; la representación se crea en el hilo principal.

var mineral_id := 0

## Centro de la base del depósito, en coordenadas locales del chunk. La base queda
## sobre la cara superior del bloque de superficie.
var local_position := Vector3.ZERO

## Giro del depósito en radianes: deriva completa en Y y una inclinación leve en X/Z.
var rotation := Vector3.ZERO

var scale := 1.0

## Semilla de la variación de forma del modelo, derivada de la posición de la
## columna para que el mismo sitio siempre luce el mismo depósito.
var variation_seed := 0
