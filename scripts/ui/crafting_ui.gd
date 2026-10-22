class_name CraftingUi
extends CanvasLayer

## Interfaz de fabricación de la estación de fabricación. Se abre al
## interactuar con la estación. Muestra las recetas en filas de dos: cada ficha
## lleva el icono y el nombre del item que se fabrica y, debajo, los materiales
## con las unidades que hay y las que hacen falta.
##
## La escena se muestra al entrar en el árbol y se libera al cerrarse, así que
## el HUD solo tiene que instanciarla.

const RECIPE_CARD_SCENE := preload("res://scenes/ui/crafting/recipe_card.tscn")
## Recetas por fila.
const RECIPES_PER_ROW := 2

@export var player: PlayerController

@onready var _rows: VBoxContainer = $Root/Backdrop/Rows
@onready var _close_button: Button = $Root/Backdrop/CloseButton

var _cards: Array[RecipeCard] = []
var _recipe_book: RecipeBook
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _is_open := false


func _ready() -> void:
	if player == null:
		# El HUD conoce al jugador; la interfaz lo hereda para no duplicar la ruta.
		player = get_parent().get("player") as PlayerController
	_close_button.pressed.connect(close)
	_recipe_book = RecipeBook.new()
	_recipe_book.load()
	_build_recipes()
	if player != null:
		player.inventory.changed.connect(_refresh_cards)
	open()


## Abre la interfaz y libera el ratón para poder usarla.
func open() -> void:
	visible = true
	_is_open = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Cierra la interfaz y devuelve el ratón al juego.
func close() -> void:
	visible = false
	_is_open = false
	Input.mouse_mode = _previous_mouse_mode
	queue_free()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	# La misma tecla que abre la interfaz la cierra, sin llegar a interactuar
	# con el mundo por debajo.
	if event.is_action_pressed("interaction"):
		get_viewport().set_input_as_handled()
		close()


## Monta las recetas en filas de dos. Las que sobren en la última fila dejan un
## hueco a su lado, para que todas las fichas ocupen la misma mitad de ancho.
func _build_recipes() -> void:
	var recipes := _recipe_book.recipes()
	var index := 0
	while index < recipes.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_rows.add_child(row)
		for _column in RECIPES_PER_ROW:
			if index < recipes.size():
				var card: RecipeCard = RECIPE_CARD_SCENE.instantiate()
				row.add_child(card)
				card.setup(recipes[index], _inventory())
				_cards.append(card)
				index += 1
			else:
				var empty := Control.new()
				empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(empty)


## Inventario del jugador, para los recuentos de materiales.
func _inventory() -> InventoryData:
	return player.inventory if player != null else null


## Refresca los recuentos de materiales de todas las fichas.
func _refresh_cards() -> void:
	for card in _cards:
		card.refresh()
