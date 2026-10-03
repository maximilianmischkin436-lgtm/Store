shader_type spatial;
// Traumhafter, nasser Boden: leichtes Raster, langsame Lichtwellen, die von der Mitte ausgehen
uniform vec3 line_col : source_color = vec3(0.45, 0.4, 1.0);
uniform vec3 wave_col : source_color = vec3(1.0, 0.45, 0.8);
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 f = abs(fract(wp.xz / 3.0) - 0.5);
	float l = smoothstep(0.475, 0.498, max(f.x, f.y));
	float d = length(wp.xz - vec2(140.0, 45.0));
	float wave = pow(0.5 + 0.5 * sin(d * 0.12 - TIME * 0.8), 12.0);
	ALBEDO = vec3(0.03, 0.025, 0.06);
	ROUGHNESS = 0.08;
	METALLIC = 0.85;
	SPECULAR = 0.9;
	EMISSION = line_col * l * 0.35 + wave_col * wave * 0.08;
}
