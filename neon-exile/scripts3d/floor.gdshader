shader_type spatial;
// Dunkler Boden mit leuchtendem Raster in Weltkoordinaten
uniform vec3 line_col : source_color = vec3(0.3, 0.3, 1.0);
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 f = abs(fract(wp.xz / 3.0) - 0.5);
	float l = smoothstep(0.47, 0.495, max(f.x, f.y));
	ALBEDO = vec3(0.02, 0.02, 0.045);
	ROUGHNESS = 0.25;
	METALLIC = 0.6;
	EMISSION = line_col * l * 0.5;
}
