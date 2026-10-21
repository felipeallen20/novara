class_name StylizedMaterial
extends Resource

## Parámetros del sombreado estilizado (low-poly voxel, colores planos, difusa en
## bandas). Es un recurso compartido: se configura una vez y todos los objetos que lo
## usen comparten un mismo ShaderMaterial, sin duplicar estado por instancia.
##
## No aplica outlines globales, ruido procedural, parallax ni efectos por encima del
## sombreado base: solo cuantiza y tinta la luz para un look toon controlado.

## Bandas de difusa. A menor número, salto más marcado entre luz y sombra.
@export_range(1, 8, 1) var light_bands: int = 4:
	set(value):
		light_bands = clampi(value, 1, 8)
		emit_changed()

## Suavidad del borde entre bandas. 0 = corte duro, 1 = transición amplia.
@export_range(0.0, 1.0, 0.01) var band_softness: float = 0.25:
	set(value):
		band_softness = clampf(value, 0.0, 1.0)
		emit_changed()

## Intensidad general del sombreado. 1 = tal cual; menor, iluminación más plana.
@export_range(0.0, 2.0, 0.01) var shading_intensity: float = 1.0:
	set(value):
		shading_intensity = maxf(value, 0.0)
		emit_changed()

## Contraste de la luz: separa más la zona iluminada de la sombreada.
@export_range(0.0, 2.0, 0.01) var light_contrast: float = 1.0:
	set(value):
		light_contrast = maxf(value, 0.0)
		emit_changed()

## Tinte de la zona iluminada. Suele ser un blanco cálido.
@export var light_tint: Color = Color(1.0, 0.96, 0.9):
	set(value):
		light_tint = value
		emit_changed()

## Tinte de la zona en sombra. Suele ser un tono frío de la paleta del mundo.
@export var shadow_tint: Color = Color(0.62, 0.6, 0.78):
	set(value):
		shadow_tint = value
		emit_changed()

## Mezcla entre el tinte de sombra y el de luz. 0 = solo sombra, 1 = solo luz.
@export_range(0.0, 1.0, 0.01) var shadow_mix: float = 0.65:
	set(value):
		shadow_mix = clampf(value, 0.0, 1.0)
		emit_changed()

## Saturación del color final. 1 = sin cambios; menor, más desaturado.
@export_range(0.0, 2.0, 0.01) var saturation: float = 1.0:
	set(value):
		saturation = maxf(value, 0.0)
		emit_changed()

## Variación cromática por bloque: desplaza ligeramente el tono de cada vóxel para
## romper la monotonía de superficies grandes. 0 = sin variación.
@export_range(0.0, 0.5, 0.005) var color_variation: float = 0.05:
	set(value):
		color_variation = maxf(value, 0.0)
		emit_changed()

## Brillo especular del material. Bajo para superficies mates.
@export_range(0.0, 1.0, 0.01) var specular: float = 0.1:
	set(value):
		specular = clampf(value, 0.0, 1.0)
		emit_changed()

## Rugosidad del material. Alta para acabado mate low-poly.
@export_range(0.0, 1.0, 0.01) var roughness: float = 0.9:
	set(value):
		roughness = clampf(value, 0.0, 1.0)
		emit_changed()

## Contraste del albedo de textura, medido alrededor de su valor medio. 1 = sin
## cambios; mayor, más separación entre las zonas claras y oscuras de la textura.
@export_range(0.0, 3.0, 0.01) var texture_contrast: float = 1.0:
	set(value):
		texture_contrast = maxf(value, 0.0)
		emit_changed()

## Realce de la definición de la textura (acentuado de bordes). 0 = sin realce;
## valores altos hacen más visibles los detalles finos sin cambiar el color base.
@export_range(0.0, 4.0, 0.01) var texture_detail: float = 0.0:
	set(value):
		texture_detail = maxf(value, 0.0)
		emit_changed()


## Shader estilizado compartido por todos los materiales del sistema.
const SHADER := preload("res://shaders/stylized_voxel.gdshader")


## Crea un ShaderMaterial con estos parámetros. `atlas` y `tile_uv` solo se usan si
## `use_atlas` es true (terreno); los objetos de color plano pueden omitirlos.
func create_material(
	use_atlas: bool, atlas: Texture2D = null, tile_uv: Vector2 = Vector2.ONE
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("use_atlas", use_atlas)
	material.set_shader_parameter("atlas", atlas)
	material.set_shader_parameter("tile_uv", tile_uv)
	_apply_parameters(material)
	return material


## Vuelca los parámetros en un ShaderMaterial ya creado. Permite reconfigurar un
## material existente cuando cambia el recurso.
func _apply_parameters(material: ShaderMaterial) -> void:
	material.set_shader_parameter("light_bands", float(light_bands))
	material.set_shader_parameter("band_softness", band_softness)
	material.set_shader_parameter("shading_intensity", shading_intensity)
	material.set_shader_parameter("light_contrast", light_contrast)
	material.set_shader_parameter("light_tint", light_tint)
	material.set_shader_parameter("shadow_tint", shadow_tint)
	material.set_shader_parameter("shadow_mix", shadow_mix)
	material.set_shader_parameter("saturation", saturation)
	material.set_shader_parameter("color_variation", color_variation)
	material.set_shader_parameter("specular_strength", specular)
	material.set_shader_parameter("roughness", roughness)
	material.set_shader_parameter("texture_contrast", texture_contrast)
	material.set_shader_parameter("texture_detail", texture_detail)
