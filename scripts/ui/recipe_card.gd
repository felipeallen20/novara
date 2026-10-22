class_name RecipeCard
extends PanelContainer

## Ficha de una receta en la interfaz de fabricación: el icono y el nombre del
## item que se fabrica, y debajo los materiales, con el icono pequeño y las
## unidades que hay frente a las que hacen falta ("obtenido/necesario").

## Fila de un material: qué item es, cuántas unidades hacen falta y la etiqueta
## donde se pinta el recuento.
class IngredientRow extends RefCounted:
	var item: Item
	var amount: int
	var label: Label

const FONT := preload("res://assets/fonts/VCR_OSD_MONO_1.001.ttf")
## Color del recuento cuando sobran materiales.
const ENOUGH_COLOR := Color(0.55, 0.9, 0.6, 1)
## Color del recuento cuando faltan materiales.
const MISSING_COLOR := Color(0.95, 0.55, 0.5, 1)

@onready var _icon: TextureRect = $Layout/Header/Icon
@onready var _name_label: Label = $Layout/Header/Name
@onready var _ingredients: HBoxContainer = $Layout/Ingredients
@onready var _craft_button: Button = $Layout/CraftButton

var _recipe: Recipe
var _inventory: InventoryData
var _rows: Array[IngredientRow] = []


## Prepara la ficha con la receta que muestra y el inventario del jugador.
func setup(recipe: Recipe, inventory: InventoryData) -> void:
	_recipe = recipe
	_inventory = inventory
	_icon.texture = recipe.result.icon
	_name_label.text = recipe.result.display_name
	_build_ingredients()
	_craft_button.pressed.connect(_on_craft_pressed)
	refresh()


## Refresca los recuentos de materiales y si la receta se puede fabricar.
func refresh() -> void:
	var can_craft := true
	for row in _rows:
		var owned := 0
		if _inventory != null:
			owned = _inventory.count(row.item)
		row.label.text = "%d/%d" % [owned, row.amount]
		var enough := owned >= row.amount
		row.label.add_theme_color_override("font_color", ENOUGH_COLOR if enough else MISSING_COLOR)
		if not enough:
			can_craft = false
	_craft_button.disabled = not can_craft


## Crea una fila por material, con el icono pequeño y la etiqueta del recuento.
func _build_ingredients() -> void:
	for ingredient in _recipe.ingredients:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var icon := TextureRect.new()
		icon.texture = ingredient.item.icon
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var label := Label.new()
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)

		_ingredients.add_child(row)
		var entry := IngredientRow.new()
		entry.item = ingredient.item
		entry.amount = ingredient.amount
		entry.label = label
		_rows.append(entry)


## Fabrica el item: gasta los materiales y añade el resultado al inventario.
func _on_craft_pressed() -> void:
	if _recipe == null or _inventory == null:
		return
	if not _recipe.can_craft(_inventory):
		return
	for ingredient in _recipe.ingredients:
		_inventory.remove(ingredient.item, ingredient.amount)
	_inventory.add(_recipe.result)
	refresh()
