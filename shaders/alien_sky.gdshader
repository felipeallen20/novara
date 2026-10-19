shader_type sky;

// Cielo alienígena de NOVARA: degradado atmosférico vertical, sin texturas externas.
// Paleta: violeta en el cénit -> lavanda -> rosa -> melocotón -> naranja cálido pegado al
// horizonte, como si una estrella iluminara la atmósfera.
// Los valores están pensados como color de editor y se mantienen en un rango medio: el
// cielo no debe lavarse, saturarse en exceso ni acercarse al neón.

uniform vec3 zenith_color : source_color = vec3(0.28, 0.24, 0.48);
uniform vec3 upper_color : source_color = vec3(0.50, 0.44, 0.70);
uniform vec3 middle_color : source_color = vec3(0.72, 0.60, 0.76);
uniform vec3 lower_color : source_color = vec3(0.90, 0.68, 0.62);
uniform vec3 horizon_color : source_color = vec3(0.98, 0.74, 0.50);
uniform vec3 ground_color : source_color = vec3(0.34, 0.28, 0.36);

// Exponente de la altura del ojo. Por encima de 1.0 ensancha la banda cálida del horizonte.
uniform float horizon_gradient : hint_range(0.25, 3.0) = 1.25;
// Fuerza del resplandor cálido sobre el horizonte.
uniform float horizon_glow : hint_range(0.0, 1.0) = 0.35;


void sky() {
	float t = pow(clamp(EYEDIR.y, 0.0, 1.0), horizon_gradient);

	vec3 atmosphere = horizon_color;
	atmosphere = mix(atmosphere, lower_color, smoothstep(0.0, 0.08, t));
	atmosphere = mix(atmosphere, middle_color, smoothstep(0.06, 0.20, t));
	atmosphere = mix(atmosphere, upper_color, smoothstep(0.16, 0.45, t));
	atmosphere = mix(atmosphere, zenith_color, smoothstep(0.40, 0.85, t));

	float glow = horizon_glow * pow(1.0 - t, 3.0);
	atmosphere += vec3(0.35, 0.18, 0.04) * glow;

	// Bajo el horizonte no hay suelo visible, pero la zona inferior sigue aportando color.
	vec3 below = mix(ground_color, horizon_color, smoothstep(-0.20, 0.0, EYEDIR.y));
	COLOR = mix(below, atmosphere, smoothstep(-0.015, 0.015, EYEDIR.y));
}
