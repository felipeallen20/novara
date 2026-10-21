shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Resolución de la variación cromática: a mayor valor, manchas de color más pequeñas.
const float VARIATION_CELL = 8.0;

// Sombreado estilizado low-poly voxel: difusa en bandas discretas, tinte de luz y
// sombra, contraste, saturación y variación cromática por bloque.
//
// Es un único shader reutilizable. El terreno lo usa con `use_atlas = true` (color por
// textura); otros objetos con `use_atlas = false` (color plano por vértice). Todos los
// parámetros vienen de un recurso StylizedMaterial.
//
// Por vértice llegan:
//   UV  : coordenada local [0,1] dentro de la celda del atlas (solo terreno).
//   UV2 : esquina de la celda del atlas; negativa si la cara no tiene textura.
//   COLOR: albedo base por vértice. En el terreno lleva el AO (grises) y, sin textura,
//          el color plano del bloque. Fuera del terreno puede llevar el color del objeto.
//   NORMAL: normal de la cara, para leer las facetas geométricas.
//
// La textura se muestrea en el fragment: es lo único que da detalle por píxel y elige
// bien la mipmap según las derivadas de UV. La variación cromática va por vértice.
//
// No hay outlines, ruido procedural, parallax ni efecto adicional: solo sombreado.

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 tile_uv = vec2(1.0, 1.0);
uniform bool use_atlas = false;

uniform float light_bands = 4.0;
uniform float band_softness = 0.25;
uniform float shading_intensity = 1.0;
uniform float light_contrast = 1.0;
uniform vec3 light_tint : source_color = vec3(1.0, 0.96, 0.9);
uniform vec3 shadow_tint : source_color = vec3(0.62, 0.6, 0.78);
uniform float shadow_mix = 0.65;
uniform float saturation = 1.0;
uniform float color_variation = 0.05;
uniform float specular_strength = 0.1;
uniform float roughness = 0.9;

// Realce del albedo de textura. `texture_contrast` separa claros y oscuros alrededor
// del gris medio; `texture_detail` acentúa las diferencias locales (definición).
uniform float texture_contrast = 1.0;
uniform float texture_detail = 0.0;

// Variación cromática calculada una vez por vértice y multiplicada en el fragment.
varying float variation_shift;

// Ajusta la saturación conservando la luminancia percibida.
vec3 apply_saturation(vec3 color) {
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	return clamp(mix(vec3(luma), color, saturation), 0.0, 1.0);
}

// Variación cromática barata: desplaza el tono según la celda del vértice, sin ruido
// procedural por fragmento. Se calcula en el vertex y se aplica a plano en el fragment.
float color_variation_shift(vec3 position) {
	if (color_variation <= 0.0) {
		return 0.0;
	}
	vec3 cell = floor(position * VARIATION_CELL);
	float hash = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	return (hash - 0.5) * color_variation;
}

// Ajusta el contraste alrededor de 0.5 y luego aplica el sesgo de intensidad.
float shape_light(float amount) {
	float shaped = clamp((amount - 0.5) * light_contrast + 0.5, 0.0, 1.0);
	return shaped * shading_intensity;
}

// Cuantiza la cantidad de luz en bandas discretas. `amount` es la luz entrante
// (incluye la atenuación de sombra de la escena).
float quantize_light(float amount) {
	if (light_bands <= 1.0) {
		return clamp(amount, 0.0, 1.0);
	}
	float banded = floor(amount * light_bands + 0.5) / light_bands;
	// Suaviza el salto entre bandas acercando el resultado al valor continuo.
	return clamp(mix(banded, amount, band_softness), 0.0, 1.0);
}

// Muestrea la celda del atlas correspondiente a esta cara. Devuelve blanco si la cara
// no tiene textura, para poder multiplicar siempre sin condicionales extra. Recibe las
// UV del fragment (los built-ins solo existen dentro de las funciones de etapa).
vec3 sample_atlas(vec2 uv, vec2 uv2) {
	if (!use_atlas || uv2.x < 0.0) {
		return vec3(1.0);
	}
	return texture(atlas, uv2 + uv * tile_uv).rgb;
}

// Realza el albedo de textura: sube el contraste alrededor de su brillo medio y, si se
// pide, acentúa las diferencias locales con un realce barato de bordes. El contraste se
// aplica sobre el brillo para no desviar el tono. Todo por píxel, sin tocar las imágenes.
vec3 enhance_texture(vec3 texel, vec2 uv, vec2 uv2) {
	vec3 enhanced = texel;
	if (texture_contrast != 1.0) {
		float luma = dot(texel, vec3(0.2126, 0.7152, 0.0722));
		// Escala la desviación respecto al gris medio conservando el tono del píxel.
		float boosted = mix(0.5, luma, texture_contrast);
		enhanced = texel * (boosted / max(luma, 0.001));
	}
	enhanced = clamp(enhanced, 0.0, 1.0);
	if (texture_detail <= 0.0) {
		return enhanced;
	}
	// Realce de bordes: compara la muestra con su promedio en un vecindario pequeño y
	// amplifica la diferencia. El vecindario es un offset fijo en la celda del atlas.
	vec2 center = uv2 + uv * tile_uv;
	vec2 offset = tile_uv * 0.02;
	vec3 blurred = (
		texture(atlas, center + vec2(offset.x, 0.0)).rgb
		+ texture(atlas, center - vec2(offset.x, 0.0)).rgb
		+ texture(atlas, center + vec2(0.0, offset.y)).rgb
		+ texture(atlas, center - vec2(0.0, offset.y)).rgb
	) * 0.25;
	// Acentúa solo la luminancia de la diferencia para no introducir cambios de tono.
	float detail = dot(enhanced - blurred, vec3(0.2126, 0.7152, 0.0722)) * texture_detail;
	return clamp(enhanced + vec3(detail), 0.0, 1.0);
}

void vertex() {
	variation_shift = color_variation_shift(VERTEX);
}

void fragment() {
	// Albedo base por vértice (AO del terreno o color plano del objeto).
	vec3 albedo = COLOR.rgb;
	// Textura del atlas: muestreada por píxel para conservar el detalle y la mipmap.
	// El realce de contraste/definición solo actúa cuando hay textura.
	if (use_atlas && UV2.x >= 0.0) {
		albedo *= enhance_texture(sample_atlas(UV, UV2), UV, UV2);
	}
	albedo += vec3(variation_shift, variation_shift * 0.5, -variation_shift);
	ALBEDO = apply_saturation(albedo);
	ROUGHNESS = roughness;
	SPECULAR = specular_strength;
}

void light() {
	// Difusa en bandas: cuantiza la luz difusa entrante. ATTENUATION conserva las
	// sombras de la escena; NORMAL y LIGHT permiten leer las facetas geométricas.
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float shade = quantize_light(shape_light(ndotl * ATTENUATION));
	// Tinte de luz/sombra: `shadow_mix` sesga el resultado hacia luz o hacia sombra.
	float tint_position = clamp(shade + (shadow_mix - 0.5), 0.0, 1.0);
	vec3 tint = mix(shadow_tint, light_tint, tint_position);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * tint * shade;
}
