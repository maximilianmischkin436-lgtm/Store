shader_type canvas_item;
// Moderne Nachbearbeitung: Tilt-Shift, Bloom, Farbkorrektur, Vignette, Korn.
// stress (0..1) entsättigt das Bild und lässt den Rand rot pulsieren.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float stress = 0.0;
uniform float night = 0.0;
uniform float flash = 0.0;

vec3 aces(vec3 x) {
	return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// Tilt-Shift: oben und unten weicher, Miniatur-Look
	float d = abs(uv.y - 0.5);
	float blur = smoothstep(0.2, 0.5, d) * 2.2;
	vec3 col = textureLod(screen_tex, uv, blur).rgb;
	// Chromatische Aberration am Rand
	vec2 off = (uv - 0.5) * 0.0025 * (1.0 + stress * 2.0);
	col.r = mix(col.r, textureLod(screen_tex, uv + off, blur).r, 0.7);
	col.b = mix(col.b, textureLod(screen_tex, uv - off, blur).b, 0.7);
	// Bloom aus hellen Bereichen
	vec3 b1 = textureLod(screen_tex, uv, 3.0).rgb;
	vec3 b2 = textureLod(screen_tex, uv, 5.0).rgb;
	vec3 bloom = max(b1 - 0.55, 0.0) * 0.6 + max(b2 - 0.45, 0.0) * 0.9;
	col += bloom * vec3(1.0, 0.82, 0.6) * (0.8 + night * 0.8);
	// Farbkorrektur: kühle Schatten, warme Lichter
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 shadow = vec3(0.86, 0.97, 1.1);
	vec3 high = vec3(1.08, 1.0, 0.9);
	col *= mix(shadow, high, smoothstep(0.15, 0.7, l));
	col = mix(vec3(l), col, 1.15 - stress * 0.45);
	col = aces(col * 1.25);
	// Vignette, unter Stress enger und rot pulsierend
	float r = length((uv - 0.5) * vec2(1.25, 1.0));
	float v = smoothstep(0.95 - stress * 0.25, 0.3, r);
	col *= mix(0.45, 1.0, v);
	float pulse = 0.55 + 0.45 * sin(TIME * (3.0 + stress * 4.0));
	col = mix(col, col * vec3(1.35, 0.45, 0.4), (1.0 - v) * stress * 0.75 * pulse);
	// Treffer-Blitz
	col += vec3(1.0, 0.4, 0.2) * flash * (1.0 - v * 0.6);
	// Filmkorn
	float n = fract(sin(dot(uv * (TIME + 1.0), vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * 0.035;
	COLOR = vec4(col, 1.0);
}
