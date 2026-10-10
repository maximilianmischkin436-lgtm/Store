shader_type spatial;
// Weisse Schwimmbad-Fliesen in Weltkoordinaten (Waende, Boden, Decke)
uniform vec3 tile_col : source_color = vec3(0.86, 0.89, 0.9);
uniform vec3 grout_col : source_color = vec3(0.7, 0.78, 0.8);
uniform float tile = 0.75;
varying vec3 wp;
varying vec3 wn;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec3 an = abs(wn);
	vec2 uv = an.y > 0.5 ? wp.xz : (an.x > 0.5 ? wp.zy : wp.xy);
	vec2 cell = floor(uv / tile);
	vec2 f = fract(uv / tile);
	float g = step(0.965, max(f.x, f.y));
	g = max(g, step(f.x, 0.015) + step(f.y, 0.015));
	float v = hash(cell) * 0.05;
	vec3 base = tile_col - v;
	// seltene blaue Akzentfliesen in einer Reihe (typisch Hallenbad)
	if (an.y < 0.5 && cell.y == 1.0) base = vec3(0.35, 0.62, 0.78);
	ALBEDO = mix(base, grout_col, clamp(g, 0.0, 1.0));
	ROUGHNESS = mix(0.12, 0.6, g);
	SPECULAR = 0.7;
}
