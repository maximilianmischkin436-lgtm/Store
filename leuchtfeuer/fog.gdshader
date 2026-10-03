shader_type canvas_item;
// Sporennebel: dichter, wabernder Nebel, der nur vom Licht verdrängt wird.

uniform vec4 lights[32];
uniform int nlights = 0;
uniform vec2 origin;
uniform vec2 size;
uniform float density = 1.0;
uniform float myc = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 wp = origin + UV * size;
	float lit = 0.0;
	for (int i = 0; i < 32; i++) {
		if (i >= nlights) break;
		vec4 L = lights[i];
		float d = length(wp - L.xy) / L.z;
		lit = max(lit, 1.0 - smoothstep(0.55, 1.0, d));
	}
	float t = TIME;
	float n = fbm(wp * 0.005 + vec2(t * 0.03, t * 0.012));
	float n2 = fbm(wp * 0.013 - vec2(t * 0.045, -t * 0.02) + n);
	float fog = clamp((0.45 + 0.7 * n + 0.35 * n2) * density, 0.0, 1.0);
	// Nebelränder kräuseln sich am Licht
	float edge = smoothstep(0.0, 0.35, lit) * (1.0 - smoothstep(0.35, 1.0, lit));
	fog *= 1.0 - lit;
	vec3 col = mix(vec3(0.12, 0.16, 0.12), vec3(0.45, 0.55, 0.38), n2);
	col += vec3(0.25, 0.35, 0.15) * edge * n;
	// Myzel-Weg: der Nebel wird zu leuchtendem, violett-türkisem Sporenschleier
	vec3 mc = mix(vec3(0.12, 0.08, 0.2), vec3(0.2, 0.75, 0.7), n2) + vec3(0.6, 0.3, 0.9) * pow(n, 6.0) * 2.0;
	col = mix(col, mc, myc);
	COLOR = vec4(col, fog * 0.93);
}
