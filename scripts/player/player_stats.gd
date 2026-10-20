class_name PlayerStats
extends Resource

## Estadísticas vitales del jugador: integridad (vida), oxígeno y hambre.
## Emite señales cuando cambian los valores o llegan a cero para que otros
## sistemas (HUD, efectos, muerte) reaccionen sin acoplarse a esta clase.

signal stat_changed(stat: StringName, current: float, maximum: float)
signal stat_depleted(stat: StringName)
signal died

const STAT_INTEGRITY := &"integrity"
const STAT_OXYGEN := &"oxygen"
const STAT_HUNGER := &"hunger"

@export var max_integrity := 100.0
@export var max_oxygen := 100.0
@export var max_hunger := 100.0

## Puntos por segundo que se pierde cada estadística de forma pasiva.
## El oxígeno solo se pierde fuera de la zona segura; con el valor por defecto
## el tanque completo (100) dura 100 / (100/180) = 180 s = 3 minutos.
@export var oxygen_drain_rate := 100.0 / 180.0
@export var oxygen_refill_rate := 10.0
@export var hunger_drain_rate := 0.5

## Daño por segundo a la integridad cuando el oxígeno o el hambre están a cero.
@export var starvation_damage_rate := 2.0
@export var suffocation_damage_rate := 5.0

var integrity := 0.0
var oxygen := 0.0
var hunger := 0.0

var _alive := true


func _init() -> void:
	integrity = max_integrity
	oxygen = max_oxygen
	hunger = max_hunger


func is_alive() -> bool:
	return _alive


## Drena oxígeno y hambre de forma pasiva. Llamar una vez por frame (o en un
## temporizador) con el delta correspondiente. Dentro de la zona segura el
## oxígeno se recarga en lugar de drenarse y no hay daño por asfixia.
func tick(delta: float, in_safe_zone: bool) -> void:
	if not _alive:
		return
	if in_safe_zone:
		refill_oxygen(oxygen_refill_rate * delta)
	else:
		consume_oxygen(oxygen_drain_rate * delta)
	consume_hunger(hunger_drain_rate * delta)
	if not in_safe_zone and oxygen <= 0.0:
		damage(suffocation_damage_rate * delta)
	if hunger <= 0.0:
		damage(starvation_damage_rate * delta)


## Integridad

func damage(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_INTEGRITY, integrity - amount, max_integrity)
	if integrity <= 0.0:
		_die()


func heal(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_INTEGRITY, integrity + amount, max_integrity)


## Oxígeno

func consume_oxygen(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_OXYGEN, oxygen - amount, max_oxygen)


func refill_oxygen(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_OXYGEN, oxygen + amount, max_oxygen)


## Hambre

func consume_hunger(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_HUNGER, hunger - amount, max_hunger)


func eat(amount: float) -> void:
	if amount <= 0.0 or not _alive:
		return
	_set_stat(STAT_HUNGER, hunger + amount, max_hunger)


## Restaura todas las estadísticas a sus valores máximos (por ejemplo, al reaparecer).
func reset() -> void:
	_alive = true
	_set_stat(STAT_INTEGRITY, max_integrity, max_integrity)
	_set_stat(STAT_OXYGEN, max_oxygen, max_oxygen)
	_set_stat(STAT_HUNGER, max_hunger, max_hunger)


func _set_stat(stat: StringName, value: float, maximum: float) -> void:
	var was_depleted: bool = get(stat) <= 0.0
	set(stat, clampf(value, 0.0, maximum))
	stat_changed.emit(stat, get(stat), maximum)
	if not was_depleted and get(stat) <= 0.0:
		stat_depleted.emit(stat)


func _die() -> void:
	_alive = false
	died.emit()
