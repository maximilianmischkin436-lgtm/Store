shader_type spatial;
// Kleidung auf der X-Bot-Figur nach Koerperhoehe: Schuhe, Hose, Shirt, Haut, Haare.
// Dazu ein verschwommenes Gesicht (Augen/Mund nur als weiche Schatten).
render_mode depth_prepass_alpha, cull_back;
uniform vec4 skin : source_color = vec4(0.9, 0.86, 0.82, 1.0);
uniform vec4 shirt : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 pants : source_color = vec4(0.2, 0.22, 0.3, 1.0);
uniform vec4 shoes : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 hair : source_color = vec4(0.15, 0.12, 0.1, 1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 emit_col : source_color = vec4(1.0);
uniform float emit_e = 0.0;
uniform float rough = 0.65;
uniform float face = 1.0;
uniform float short_sleeves = 0.0;
uniform float skirt = 0.0;
uniform int part = -1;   // -1 nach Hoehe; 0 Haut, 1 Oberteil, 2 Hose, 3 Schuhe, 4 Haare, 5 Kopf (Haut + Gesicht), 6 Augen/Zaehne
uniform float hgt = 1.8;
uniform float ymin = 0.0;
varying vec3 mp;

void vertex() {
	// in Welt-Metern relativ zum Ursprung der Figur, ausgerichtet an der Figur
	vec3 lw = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - NODE_POSITION_WORLD;
	mp = vec3(dot(lw, normalize(MODEL_MATRIX[0].xyz)), dot(lw, normalize(MODEL_MATRIX[1].xyz)), dot(lw, normalize(MODEL_MATRIX[2].xyz)));
}

void fragment() {
	float y = (mp.y - ymin) / hgt;
	float ax = abs(mp.x) / hgt;
	float z = mp.z / hgt;
	vec3 c = shirt.rgb;
	if (y < 0.05) c = shoes.rgb;
	else if (y < 0.53 && ax < 0.12) c = (skirt > 0.5 && y < 0.33) ? skin.rgb : pants.rgb;
	if (ax >= 0.12 && y > 0.38 && y < 0.84) {
		// Arme: Aermel oben, Haut an Haenden/Unterarmen
		bool sleeve = y > (short_sleeves > 0.5 ? 0.72 : 0.6);
		c = sleeve ? shirt.rgb : skin.rgb;
	}
	if (part == 0) c = skin.rgb;
	if (part == 1) c = shirt.rgb;
	if (part == 2) c = pants.rgb;
	if (part == 3) c = shoes.rgb;
	if (part == 4) c = hair.rgb;
	if (part == 6) c = skin.rgb * 0.55;
	if ((part == -1 && y >= 0.84) || part == 5) {
		c = skin.rgb;
		if (y > 0.935 || (y > 0.87 && z < -0.01)) c = hair.rgb;
		// verschwommenes Gesicht: weiche dunkle Flecken fuer Augen und Mund
		float front = smoothstep(0.02, 0.06, z);
		float eyes = 0.0;
		for (int s = -1; s <= 1; s += 2) {
			vec2 d = vec2(mp.x / hgt - float(s) * 0.021, y - 0.905);
			eyes = max(eyes, 1.0 - smoothstep(0.0, 0.018, length(d * vec2(1.0, 1.4))));
		}
		vec2 md = vec2(mp.x / hgt, (y - 0.868) * 2.5);
		float mouth = 1.0 - smoothstep(0.0, 0.025, length(md));
		c = mix(c, c * 0.35, (eyes * 0.75 + mouth * 0.4) * front * face);
	}
	ALBEDO = c * tint.rgb;
	ALPHA = tint.a;
	ROUGHNESS = rough;
	RIM = 0.6;
	RIM_TINT = 0.5;
	EMISSION = emit_col.rgb * emit_e;
}
