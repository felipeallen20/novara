shader_type spatial;

// Panel holográfico para la interfaz del inventario de NOVARA.
// Se renderiza como una superficie emisiva translúcida con scanlines,
// tintado cian y un ligero parpadeo para dar sensación de proyección.
//
// Renderizado: sin sombras, sin iluminación de escena, culling desactivado
// para que sea legible desde cualquier ángulo del panel.

render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

// Filtro nearest para conservar la nitidez del pixel art al ampliar la textura.
// Sin el, la interpolacion lineal emborrona el PNG de 128x64 sobre el panel.
uniform sampler2D albedo_texture : source_color, filter_nearest, hint_default_white;
uniform vec3 tint : source_color = vec3(0.35, 0.85, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.9;
// Densidad de las líneas horizontales del holograma.
uniform float scanline_density : hint_range(10.0, 400.0) = 180.0;
// Intensidad de las scanlines (0 = sin líneas).
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;
// Amplitud del parpadeo global.
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.06;
// Velocidad del parpadeo y del desplazamiento de scanlines.
uniform float flicker_speed : hint_range(0.0, 30.0) = 8.0;
// Intensidad del borde exterior resplandeciente.
uniform float edge_glow : hint_range(0.0, 2.0) = 0.8;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	// Scanlines: oscurece bandas horizontales finas.
	float scan = sin(UV.y * scanline_density + TIME * flicker_speed) * 0.5 + 0.5;
	float scan_factor = 1.0 - scanline_strength * scan;

	// Parpadeo global suave e irregular.
	float flicker = 1.0 - flicker_strength * (sin(TIME * flicker_speed) * 0.5 + 0.5);

	// Borde resplandeciente: realza el marco del panel cerca de los límites del UV.
	vec2 edge_dist = min(UV, vec2(1.0) - UV);
	float edge = 1.0 - smoothstep(0.0, 0.02, min(edge_dist.x, edge_dist.y));
	float glow = 1.0 + edge_glow * edge;

	vec3 hologram = mix(tex.rgb, tex.rgb * tint, 0.85) * scan_factor * flicker * glow;
	// La zona transparente de la textura se mantiene transparente.
	float out_alpha = tex.a * alpha * (1.0 + edge * edge_glow);

	ALBEDO = hologram;
	EMISSION = hologram * 1.4;
	ALPHA = clamp(out_alpha, 0.0, 1.0);
}
