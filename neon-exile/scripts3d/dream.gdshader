shader_type canvas_item;
// Traum-Filter: weiche Vignette, leichte Farbverschiebung an den Raendern, Koernung, sanftes Wabern
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float strength = 1.0;
uniform float glitch = 0.0;

float rand(vec2 c) { return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 30.0 + TIME * 1.3) * 0.0008 * strength + glitch * (rand(vec2(floor(uv.y * 40.0), TIME)) - 0.5) * 0.03;
	vec2 c = uv - 0.5;
	float r = dot(c, c);
	float ca = 0.004 * strength * r * 4.0 + glitch * 0.01;
	vec3 col;
	col.r = texture(screen, uv + c * ca).r;
	col.g = texture(screen, uv).g;
	col.b = texture(screen, uv - c * ca).b;
	col += (rand(uv * TIME) - 0.5) * 0.035 * strength;
	col *= 1.0 - r * 1.1 * strength;
	col = mix(col, col * vec3(1.03, 0.97, 1.06), 0.5);
	COLOR = vec4(col, 1.0);
}
