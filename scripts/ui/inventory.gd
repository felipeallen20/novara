extends CanvasLayer

## Interfaz visual del inventario: una UI 2D con una cuadricula de 32 celdas
## (8 columnas x 4 filas). Genera las celdas desde la plantilla y las rellena
## con el InventoryData enlazado en `bind`, refrescando solo al cambiar.

const COLUMNS := 8
const ROWS := 4
const SLOT_COUNT := COLUMNS * ROWS

@onready var _grid: GridContainer = $Root/Backdrop/Grid
@onready var _template: Panel = $Root/Backdrop/Grid/SlotTemplate

var _data: InventoryData
var _icons: Array[TextureRect] = []
var _amounts: Array[Label] = []


func _ready() -> void:
	_build_slots()


## Enlaza el contenido del inventario y pinta las casillas.
func bind(data: InventoryData) -> void:
	_data = data
	_data.changed.connect(_refresh)
	_refresh()


## Genera las celdas a partir de la plantilla y la reutiliza como primera celda.
func _build_slots() -> void:
	_grid.columns = COLUMNS
	var template_style := _template.get_theme_stylebox("panel")
	for index in SLOT_COUNT:
		var slot: Panel
		if index == 0:
			slot = _template
		else:
			slot = Panel.new()
			slot.custom_minimum_size = _template.custom_minimum_size
			slot.add_theme_stylebox_override("panel", template_style)
			_grid.add_child(slot)
		slot.name = "Slot%d" % index
		_add_slot_content(slot)


## Icono y contador de unidades dentro de una celda, ocultos hasta que llegue
## algo al dato.
func _add_slot_content(slot: Panel) -> void:
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.visible = false
	slot.add_child(icon)
	_icons.append(icon)

	var amount := Label.new()
	amount.anchor_left = 1.0
	amount.anchor_top = 1.0
	amount.anchor_right = 1.0
	amount.anchor_bottom = 1.0
	amount.offset_left = -28.0
	amount.offset_top = -18.0
	amount.offset_right = -4.0
	amount.offset_bottom = -2.0
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.add_theme_font_size_override("font_size", 12)
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.visible = false
	slot.add_child(amount)
	_amounts.append(amount)


## Pinta las casillas del dato; solo se llama cuando el inventario cambia.
func _refresh() -> void:
	for index in SLOT_COUNT:
		var stack := _data.get_slot(index)
		var filled := stack != null
		_icons[index].visible = filled
		_amounts[index].visible = filled
		if not filled:
			continue
		_icons[index].texture = stack.item.icon
		_amounts[index].text = str(stack.amount)
