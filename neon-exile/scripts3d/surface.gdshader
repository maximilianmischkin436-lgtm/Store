shader_type spatial;
// Allzweck-Oberflaeche in Weltkoordinaten fuer alle Kapitel.
// mode: 0 Fliesen, 1 Tapete (Streifen), 2 Teppich, 3 Schachbrett, 4 zweifarbige Wand, 5 Paneele
uniform int mode = 0;
uniform vec3 col_a : source_color = vec3(0.86, 0.89, 0.9);
uniform vec3 col_b : source_color = vec3(0.7, 0.78, 0.8);
uniform vec3 col_c : source_color = vec3(0.35, 0.62, 0.78);
uniform float scale = 0.75;
uniform float rough = 0.2;
varying vec3 wp;
varying vec3 wn;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i), b = hash(i + vec2(1, 0)), c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec3 an = abs(wn);
	bool wall = an.y < 0.5;
	vec2 uv = !wall ? wp.xz : (an.x > 0.5 ? wp.zy : wp.xy);
	vec3 c = col_a;
	float r = rough;
	if (mode == 0) {
		vec2 cell = floor(uv / scale);
		vec2 f = fract(uv / scale);
		float g = max(step(0.965, max(f.x, f.y)), step(f.x, 0.015) + step(f.y, 0.015));
		c = col_a - hash(cell) * 0.05;
		if (wall && cell.y == 1.0) c = col_c;
		c = mix(c, col_b, clamp(g, 0.0, 1.0));
		r = mix(0.12, 0.6, g);
	} else if (mode == 1) {
		float s = step(0.5, fract(uv.x / scale));
		float pat = step(0.82, fract(uv.x / scale * 4.0 + 0.1)) * 0.5;
		c = mix(col_a, col_b, s * 0.35 + pat * 0.4) * (0.92 + noise(uv * 3.0) * 0.12);
		if (wall && wp.y < 0.35) c = col_c;
		r = 0.85;
	} else if (mode == 2) {
		float n = noise(uv * 18.0) * 0.5 + noise(uv * 2.0) * 0.5;
		c = mix(col_a, col_b, n) ;
		r = 1.0;
	} else if (mode == 3) {
		vec2 cell = floor(uv / scale);
		float ch = mod(cell.x + cell.y, 2.0);
		c = mix(col_a, col_b, ch) * (0.95 + hash(cell) * 0.08);
		r = 0.25;
	} else if (mode == 4) {
		float h = wp.y;
		c = h < 1.3 ? col_b : col_a;
		if (abs(h - 1.3) < 0.04) c = col_c;
		if (!wall) c = col_a;
		c *= 0.94 + noise(uv * 2.0) * 0.1;
		r = 0.7;
	} else {
		vec2 f = fract(uv / scale);
		float g = step(0.97, max(f.x, f.y));
		c = mix(col_a, col_b, g) * (0.96 + hash(floor(uv / scale)) * 0.06);
		r = 0.5;
	}
	ALBEDO = c;
	ROUGHNESS = r;
	SPECULAR = 0.5;
}
