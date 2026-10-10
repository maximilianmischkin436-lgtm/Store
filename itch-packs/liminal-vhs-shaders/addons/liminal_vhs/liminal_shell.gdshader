shader_type spatial;
// Liminale Huelle ueber Kreaturen und Bossen: kaltes Randleuchten, wandernde Scanlines,
// ab und zu ein verrutschtes Doppelbild (wie eine kaputte Erinnerung)
render_mode blend_add, unshaded, cull_back, depth_draw_never, shadows_disabled;
uniform vec4 rim_col : source_color = vec4(0.75, 0.95, 1.0, 1.0);
uniform float strength = 1.0;
uniform float glitch = 1.0;
uniform float seed = 0.0;

float h(float n) { return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453); }

void vertex() {
	float slot = floor(TIME * 7.0);
	float g = step(0.9, h(slot)) * glitch;
	VERTEX += NORMAL * 0.012;
	VERTEX.x += g * (h(slot + 1.3) - 0.5) * 0.35;
	VERTEX.y += g * (h(slot + 2.7) - 0.5) * 0.08;
	// leises Atmen / Flimmern
	VERTEX += NORMAL * sin(TIME * 2.3 + VERTEX.y * 6.0 + seed) * 0.006;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float scan = 0.55 + 0.45 * sin(wp.y * 70.0 - TIME * 5.0);
	float band = smoothstep(0.96, 1.0, sin(wp.y * 2.0 - TIME * 1.7));
	float flick = 0.85 + 0.15 * h(floor(TIME * 24.0));
	ALBEDO = rim_col.rgb * (fres * 1.6 * scan + band * 0.35) * strength * flick;
}
