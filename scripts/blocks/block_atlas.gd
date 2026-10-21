class_name BlockAtlas
extends RefCounted

## Empaqueta las texturas de las caras de todos los bloques en una sola imagen y
## resuelve, para cada bloque y cara, el desplazamiento UV de su celda.
##
## El mesher solo necesita UVs locales [0,1] y este desplazamiento por vértice; un
## único material con el atlas sirve para todo el terreno, así que cada chunk sigue
## siendo una sola superficie.
##
## Cada celda lleva un borde de padding que repite el borde de la textura: así el
## filtrado lineal y las mipmaps no mezclan colores de celdas vecinas. El atlas se
## genera con mipmaps para que el detalle se filtre bien a distancia.
##
## Uso: se construye una vez con el registro de bloques, antes de meshear. Después
## solo se lee, por lo que es seguro de usar desde los hilos de generación.

## Borde de padding alrededor de cada celda, en píxeles. Evita el sangrado entre
## celdas al filtrar o al bajar de nivel de mipmap.
const PADDING := 4

## Lado en píxeles de la textura de cada celda (sin padding).
var _tile_pixels: int = 1
var _columns: int = 1
var _rows: int = 1

var _atlas: ImageTexture
## Offset UV de la celda de cada cara: _offsets[block_id][face_index].
var _offsets: Dictionary = {}
## Tamaño UV de la región interior de una celda, sin padding.
var _tile_uv := Vector2.ONE


var atlas_texture: Texture2D:
	get:
		return _atlas

## Tamaño en UV de la región interior de una celda. El shader multiplica la UV local
## por este valor.
var tile_uv: Vector2:
	get:
		return _tile_uv


## Construye el atlas para los bloques del registro que tengan texturas asignadas.
func build(registry: BlockRegistry) -> void:
	# Texturas distintas por ruta: los bloques que comparten imagen ocupan una celda.
	var paths: Dictionary = {}
	var block_layers: Dictionary = {}
	var max_pixels := 1

	for id in registry.ids():
		var block := registry.get_block(id)
		if block == null or block.textures == null:
			continue
		var layers := []
		for face_index in 6:
			var texture := block.textures.get_face(face_index)
			if texture == null:
				layers.append(-1)
				continue
			var key := texture.resource_path
			if key.is_empty():
				# Sin ruta no se puede deduplicar: se le da una clave propia.
				key = "block_%d_face_%d" % [id, face_index]
			if not paths.has(key):
				paths[key] = paths.size()
				max_pixels = maxi(max_pixels, _texture_size(texture))
			layers.append(paths[key])
		block_layers[id] = layers

	if paths.is_empty():
		_atlas = null
		return

	_tile_pixels = max_pixels
	_columns = ceili(sqrt(float(paths.size())))
	_rows = ceili(float(paths.size()) / float(_columns))

	var cell_pixels := _tile_pixels + PADDING * 2
	var atlas_image := Image.create(_columns * cell_pixels, _rows * cell_pixels, false, Image.FORMAT_RGBA8)
	for key: String in paths:
		var layer: int = paths[key]
		var texture: Texture2D = load(key) if ResourceLoader.exists(key) else null
		if texture == null:
			continue
		_blit(atlas_image, texture.get_image(), layer, cell_pixels)
	atlas_image.generate_mipmaps()
	_atlas = ImageTexture.create_from_image(atlas_image)

	var atlas_size := Vector2(atlas_image.get_width(), atlas_image.get_height())
	# La UV local [0,1] cubre solo la región interior de la celda, sin el padding.
	_tile_uv = Vector2(float(_tile_pixels), float(_tile_pixels)) / atlas_size
	_offsets.clear()
	for id: int in block_layers:
		var layers: Array = block_layers[id]
		var face_offsets := []
		for layer: int in layers:
			if layer < 0:
				face_offsets.append(Vector2(-1.0, -1.0))
				continue
			var column := layer % _columns
			var row := layer / _columns
			var interior_origin := Vector2(
				float(column * cell_pixels + PADDING), float(row * cell_pixels + PADDING)
			)
			face_offsets.append(interior_origin / atlas_size)
		_offsets[id] = face_offsets


## Offset UV de la celda del bloque `block_id` en la cara `face_index`. Devuelve
## (-1, -1) si el bloque o la cara no tienen textura, para que el mesher use el color
## plano.
func get_face_offset(block_id: int, face_index: int) -> Vector2:
	var face_offsets: Array = _offsets.get(block_id, [])
	if face_index < 0 or face_index >= face_offsets.size():
		return Vector2(-1.0, -1.0)
	return face_offsets[face_index]


## Copia una textura dentro de su celda, con el padding relleno repitiendo los bordes.
func _blit(atlas: Image, source: Image, layer: int, cell_pixels: int) -> void:
	var column := layer % _columns
	var row := layer / _columns
	var interior_origin := Vector2i(column * cell_pixels + PADDING, row * cell_pixels + PADDING)

	var scaled := source
	if source.get_width() != _tile_pixels or source.get_height() != _tile_pixels:
		scaled = source.duplicate() as Image
		scaled.resize(_tile_pixels, _tile_pixels, Image.INTERPOLATE_LANCZOS)
	if scaled.get_format() != Image.FORMAT_RGBA8:
		scaled.convert(Image.FORMAT_RGBA8)
	atlas.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), interior_origin)

	if PADDING <= 0:
		return
	# Extiende los bordes hacia el padding para que el filtrado no invada la celda vecina.
	var last := _tile_pixels - 1
	for offset in range(1, PADDING + 1):
		# Filas superior e inferior.
		atlas.blit_rect(scaled, Rect2i(0, 0, _tile_pixels, 1),
			interior_origin + Vector2i(0, -offset))
		atlas.blit_rect(scaled, Rect2i(0, last, _tile_pixels, 1),
			interior_origin + Vector2i(0, _tile_pixels + offset - 1))
		# Columnas izquierda y derecha.
		atlas.blit_rect(scaled, Rect2i(0, 0, 1, _tile_pixels),
			interior_origin + Vector2i(-offset, 0))
		atlas.blit_rect(scaled, Rect2i(last, 0, 1, _tile_pixels),
			interior_origin + Vector2i(_tile_pixels + offset - 1, 0))
		# Esquinas.
		atlas.set_pixelv(interior_origin + Vector2i(-offset, -offset), scaled.get_pixel(0, 0))
		atlas.set_pixelv(interior_origin + Vector2i(_tile_pixels + offset - 1, -offset),
			scaled.get_pixel(last, 0))
		atlas.set_pixelv(interior_origin + Vector2i(-offset, _tile_pixels + offset - 1),
			scaled.get_pixel(0, last))
		atlas.set_pixelv(interior_origin + Vector2i(_tile_pixels + offset - 1, _tile_pixels + offset - 1),
			scaled.get_pixel(last, last))


func _texture_size(texture: Texture2D) -> int:
	var image := texture.get_image()
	if image == null:
		return 1
	return maxi(image.get_width(), image.get_height())
