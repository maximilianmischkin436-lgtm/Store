shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
// Flaches tuerkises Wasser mit Lichtmustern (Kaustiken) und leichten Wellen
uniform vec3 col : source_color = vec3(0.1, 0.75, 0.85);
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 0.8 + TIME * 0.9) * 0.015 + sin(wp.z * 1.1 + TIME * 0.7) * 0.015;
}

float caustic(vec2 p) {
	float c = 0.0;
	for (int i = 0; i < 3; i++) {
		p += vec2(sin(p.y * 1.3 + TIME * 0.6), cos(p.x * 1.1 + TIME * 0.5)) * 0.6;
		c += abs(sin(p.x * 1.7) * cos(p.y * 1.7));
	}
	return pow(1.0 - c / 3.0, 6.0);
}

void fragment() {
	float c = caustic(wp.xz * 0.9);
	ALBEDO = col * 0.55 + vec3(c) * 0.45;
	ALPHA = 0.7;
	ROUGHNESS = 0.02;
	METALLIC = 0.2;
	SPECULAR = 1.0;
	EMISSION = col * 0.08 + vec3(c) * 0.15;
	NORMAL_MAP = normalize(vec3(0.5 + sin(wp.x * 3.0 + TIME) * 0.05, 0.5 + cos(wp.z * 3.0 + TIME * 1.2) * 0.05, 1.0));
}
