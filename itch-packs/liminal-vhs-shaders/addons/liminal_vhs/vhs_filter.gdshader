shader_type canvas_item;
// VHS-Filter: Scanlines, Farbsaum, verwaschene Farben, Rauschen, wandernder Tracking-Streifen, Vignette
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float strength = 1.0;
uniform float glitch = 0.0;

float rand(vec2 c) { return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float s = strength;
	// Tracking-Streifen, der langsam durchs Bild wandert
	float bandmask = 1.0 - smoothstep(0.0, 0.015, abs(fract(uv.y - TIME * 0.05) - 0.5) - 0.0);
	bandmask = smoothstep(0.985, 1.0, bandmask);
	uv.x += bandmask * (rand(vec2(uv.y * 80.0, TIME)) - 0.5) * 0.012 * s;
	uv.x += sin(uv.y * 240.0 + TIME * 3.0) * 0.0006 * s;
	uv.x += glitch * (rand(vec2(floor(uv.y * 30.0), floor(TIME * 20.0))) - 0.5) * 0.05;
	// Farbsaum: Rot und Blau leicht verschoben (wie Kassette)
	float off = 0.0025 * s + glitch * 0.01;
	vec3 col;
	col.r = texture(screen, uv + vec2(off, 0.0)).r;
	col.g = texture(screen, uv).g;
	col.b = texture(screen, uv - vec2(off, 0.0)).b;
	// verwaschene, warme Farben
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(l), 0.08 * s);
	col = col * vec3(1.05, 1.0, 0.92) + vec3(0.02, 0.015, 0.03) * s;
	// Scanlines und Rauschen
	col *= 1.0 - 0.07 * s * step(0.5, fract(SCREEN_UV.y * 270.0));
	col += (rand(uv * 900.0 + TIME) - 0.5) * 0.06 * s;
	col += bandmask * 0.06 * s;
	// Vignette
	vec2 c = SCREEN_UV - 0.5;
	col *= 1.0 - dot(c, c) * 1.3 * s;
	COLOR = vec4(col, 1.0);
}
