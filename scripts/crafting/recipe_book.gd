class_name RecipeBook
extends RefCounted

## Recetas de fabricación del juego. Se leen del archivo JSON de datos, donde
## los items se referencian por id y el catálogo los resuelve.

## Archivo de datos con las recetas.
const RECIPES_FILE := "res://data/recipes.json"

var _recipes: Array[Recipe] = []


## Carga las recetas del archivo JSON de datos. Devuelve false si el archivo no
## existe o no tiene el formato esperado.
func load(file_path: String = RECIPES_FILE, registry: ItemRegistry = null) -> bool:
	if registry == null:
		registry = ItemRegistry.with_default_items()
	var file := load(file_path) as JSON
	if file == null:
		push_error("RecipeBook: no se encuentra el archivo de recetas %s" % file_path)
		return false
	var data: Variant = file.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("RecipeBook: %s no tiene el formato esperado" % file_path)
		return false
	var entries: Array = (data as Dictionary).get("recipes", [])
	for entry: Variant in entries:
		var recipe := _build_recipe(entry as Dictionary, registry)
		if recipe != null:
			_recipes.append(recipe)
	return true


## Recetas cargadas.
func recipes() -> Array[Recipe]:
	return _recipes


## Convierte una entrada del JSON en una receta, resolviendo los ids de item.
func _build_recipe(entry: Dictionary, registry: ItemRegistry) -> Recipe:
	var result := registry.get_item(int(entry.get("result", 0)))
	if result == null:
		push_error("RecipeBook: la receta '%s' produce un item que no existe" % str(entry.get("id", "")))
		return null
	var recipe := Recipe.new()
	recipe.id = StringName(str(entry.get("id", "")))
	recipe.result = result
	for ingredient: Variant in entry.get("ingredients", []):
		var item := registry.get_item(int((ingredient as Dictionary).get("item", 0)))
		if item == null:
			push_error("RecipeBook: la receta '%s' usa un material que no existe" % str(entry.get("id", "")))
			return null
		recipe.ingredients.append(ItemStack.new(item, int((ingredient as Dictionary).get("amount", 0))))
	return recipe
