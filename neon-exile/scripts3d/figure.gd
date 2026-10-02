extends RefCounted
# Baukasten fuer menschliche Figuren (Schueler, Lehrer, Schwimmer, Kaeufer, Buero, Schaufensterpuppe).
# Alle Figuren sind gesichtslos. Geister sind halb durchsichtig.

static func mat(col: Color, alpha: float = 1.0, rough: float = 0.6, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alpha)
	m.roughness = rough
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_BACK
	m.emission_enabled = true
	m.emission = col.lightened(0.3)
	m.emission_energy_multiplier = glow
	return m

static func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, scl: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

static func cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0)
	c.radial_segments = 24
	c.rings = 10
	return c

static func sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 32
	s.rings = 16
	return s

static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 24
	return c

static func pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

# Kleidung pro Typ. Zufall ueber rng, damit nicht alle gleich aussehen.
static func outfit(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var o := {"kind": kind, "skin": Color(0.92, 0.9, 0.88), "shirt": Color.WHITE, "pants": Color(0.2, 0.22, 0.3),
		"shoes": Color(0.12, 0.1, 0.1), "skirt": false, "short_legs": false, "bare_arms": false, "hair": Color(0.15, 0.12, 0.1), "hair_style": 0,
		"height": 1.0, "width": 1.0, "extras": []}
	match kind:
		"student":
			o.height = rng.randf_range(0.78, 0.88)
			o.shirt = [Color(0.95, 0.95, 0.92), Color(0.75, 0.85, 0.95), Color(0.95, 0.88, 0.7)][rng.randi() % 3]
			o.pants = [Color(0.15, 0.2, 0.38), Color(0.3, 0.3, 0.32), Color(0.25, 0.15, 0.15)][rng.randi() % 3]
			o.skirt = rng.randf() < 0.5
			o.hair_style = 2 if o.skirt else 1
			o.extras = ["backpack", "collar"]
			if rng.randf() < 0.4: o.extras.append("tie")
		"teacher":
			o.height = 1.12
			o.shirt = [Color(0.45, 0.32, 0.22), Color(0.35, 0.38, 0.3), Color(0.3, 0.28, 0.35)][rng.randi() % 3]
			o.pants = Color(0.22, 0.2, 0.18)
			o.extras = ["collar", "tie", "glasses", "ruler"]
			o.hair_style = 3
		"swimmer":
			o.shirt = o.skin
			o.bare_arms = true
			o.short_legs = true
			o.pants = [Color(0.1, 0.2, 0.55), Color(0.65, 0.12, 0.15), Color(0.1, 0.45, 0.4)][rng.randi() % 3]
			o.shoes = o.skin
			o.hair_style = 4 if rng.randf() < 0.5 else 1
			o.extras = ["goggles"] if rng.randf() < 0.5 else []
			if rng.randf() < 0.3: o.extras.append("towel")
		"lifeguard":
			o.height = 1.15
			o.shirt = Color(0.85, 0.15, 0.12)
			o.pants = Color(0.85, 0.15, 0.12)
			o.short_legs = true
			o.shoes = o.skin
			o.extras = ["whistle", "buoy"]
		"shopper":
			o.shirt = [Color(0.2, 0.6, 0.6), Color(0.5, 0.3, 0.6), Color(0.8, 0.6, 0.2), Color(0.8, 0.35, 0.45)][rng.randi() % 4]
			o.pants = Color(0.3, 0.4, 0.6)
			o.extras = ["bags", "collar"]
			o.hair_style = rng.randi() % 3 + 1
		"mannequin":
			o.skin = Color(0.85, 0.78, 0.7)
			o.shirt = o.skin
			o.pants = o.skin
			o.shoes = o.skin
			o.bare_arms = true
			o.hair_style = 0
			o.extras = ["tag", "joints"]
		"worker":
			o.shirt = Color(0.92, 0.92, 0.88)
			o.pants = Color(0.3, 0.3, 0.32)
			o.extras = ["collar", "tie", "badge"]
			o.hair_style = rng.randi() % 2 + 1
		"manager":
			o.height = 1.12
			o.shirt = Color(0.12, 0.12, 0.15)
			o.pants = Color(0.12, 0.12, 0.15)
			o.extras = ["collar", "tie", "badge", "briefcase"]
			o.hair_style = 3
		"patient":
			# Krankenhaushemd, nackte Beine, Armband
			o.shirt = [Color(0.72, 0.85, 0.9), Color(0.85, 0.88, 0.8)][rng.randi() % 2]
			o.pants = o.shirt
			o.short_legs = true
			o.shoes = Color(0.85, 0.85, 0.85)
			o.bare_arms = true
			o.height = rng.randf_range(0.8, 1.0)
			o.hair_style = rng.randi() % 3
			o.extras = ["wristband"]
		"nurse":
			o.height = 1.1
			o.shirt = Color(0.95, 0.96, 0.95)
			o.pants = Color(0.95, 0.96, 0.95)
			o.skirt = true
			o.shoes = Color(0.95, 0.95, 0.95)
			o.hair_style = 2
			o.extras = ["nursecap", "badge"]
		"resident":
			o.shirt = [Color(0.55, 0.45, 0.35), Color(0.35, 0.4, 0.5), Color(0.6, 0.55, 0.5)][rng.randi() % 3]
			o.pants = Color(0.25, 0.22, 0.2)
			o.hair_style = rng.randi() % 4 + 1
			o.extras = ["collar"]
		"commuter":
			o.shirt = [Color(0.35, 0.33, 0.3), Color(0.25, 0.28, 0.35), Color(0.45, 0.3, 0.25), Color(0.5, 0.48, 0.42)][rng.randi() % 4]
			o.pants = Color(0.18, 0.18, 0.2)
			o.hair_style = rng.randi() % 4 + 1
			o.extras = ["collar", "briefcase"] if rng.randf() < 0.5 else ["collar", "bags"]
		"inspector":
			o.height = 1.1
			o.shirt = Color(0.12, 0.16, 0.32)
			o.pants = Color(0.1, 0.12, 0.25)
			o.hair_style = 3
			o.extras = ["collar", "tie", "badge", "cap"]
		"parent":
			o.height = 1.1
			o.shirt = Color(0.5, 0.42, 0.38)
			o.pants = Color(0.2, 0.18, 0.16)
			o.hair_style = 2
			o.extras = ["collar", "apron"]
	return o

# Baut die Figur unter root. Gibt Gelenke + Materialien zurueck.
static func build(root: Node3D, o: Dictionary, alpha: float, glow: float, hostile: bool) -> Dictionary:
	var P := {}
	var mats: Array = []
	var skin := mat(o.skin, alpha, 0.45, glow)
	var shirt := mat(o.shirt, alpha, 0.8, glow)
	var pants := mat(o.pants, alpha, 0.85, glow)
	var shoes := mat(o.shoes, alpha, 0.4, glow)
	var dark := mat(Color(0.02, 0.02, 0.03), maxf(alpha, 0.8), 0.2, 0.0)
	var hair := mat(o.hair, alpha, 0.9, glow)
	if o.kind == "mannequin":
		skin.roughness = 0.12
		skin.metallic = 0.1
	mats.append_array([skin, shirt, pants, shoes, hair])
	var body := pivot(root, Vector3.ZERO)
	body.scale = Vector3(o.width, 1.0, o.width) * o.height
	P["body"] = body
	# Beine mit Knie
	var hips := pivot(body, Vector3(0, 0.95, 0))
	P["hips"] = hips
	_mesh(hips, cap(0.17, 0.4), Vector3(0, 0.02, 0), Vector3(1.15, 0.7, 0.8), pants)
	for sd in [-1, 1]:
		var hip := pivot(hips, Vector3(0.1 * sd, -0.05, 0))
		P["hip%d" % sd] = hip
		_mesh(hip, cap(0.075, 0.5), Vector3(0, -0.23, 0), Vector3.ONE, skin if o.short_legs else pants)
		if o.short_legs:
			_mesh(hip, cap(0.085, 0.18), Vector3(0, -0.05, 0), Vector3.ONE, pants)
		var knee := pivot(hip, Vector3(0, -0.46, 0))
		P["knee%d" % sd] = knee
		_mesh(knee, cap(0.06, 0.48), Vector3(0, -0.22, 0), Vector3.ONE, skin if (o.short_legs or o.skirt) else pants)
		_mesh(knee, box(0.1, 0.07, 0.22), Vector3(0, -0.46, -0.04), Vector3.ONE, shoes)
		if o.skirt:
			_mesh(knee, cap(0.065, 0.2), Vector3(0, -0.36, 0), Vector3.ONE, mat(Color(0.95, 0.95, 0.95), alpha, 0.9, glow))
	if o.skirt:
		_mesh(hips, cyl(0.16, 0.3, 0.38), Vector3(0, -0.13, 0), Vector3(1, 1, 0.85), pants)
	# Oberkoerper
	var spine := pivot(hips, Vector3(0, 0.08, 0))
	P["spine"] = spine
	_mesh(spine, cap(0.19, 0.6), Vector3(0, 0.27, 0), Vector3(1.12, 1, 0.72), shirt)
	_mesh(spine, cap(0.2, 0.42), Vector3(0, 0.45, 0), Vector3(1.25, 0.6, 0.75), shirt)
	# Kleinigkeiten: Guertel, Knoepfe, Saum
	if not o.skirt and o.kind != "swimmer":
		_mesh(spine, box(0.36, 0.04, 0.24), Vector3(0, 0.02, 0), Vector3.ONE, mat(o.pants.darkened(0.45), alpha, 0.4, glow))
		_mesh(spine, box(0.05, 0.035, 0.02), Vector3(0, 0.02, -0.125), Vector3.ONE, mat(Color(0.7, 0.65, 0.5), alpha, 0.3, glow))
	if o.kind in ["teacher", "worker", "manager", "shopper", "student"]:
		for b in 4:
			_mesh(spine, sph(0.009), Vector3(0, 0.12 + b * 0.11, -0.142), Vector3(1, 1, 0.5), mat(o.shirt.darkened(0.35), alpha, 0.4, glow))
	if o.extras.has("collar"):
		_mesh(spine, cyl(0.075, 0.1, 0.06), Vector3(0, 0.6, 0), Vector3.ONE, mat(o.shirt.lightened(0.2), alpha, 0.7, glow))
	if o.extras.has("tie"):
		var tie := mat(Color(0.5, 0.1, 0.12) if o.kind != "student" else Color(0.15, 0.2, 0.45), alpha, 0.6, glow)
		_mesh(spine, box(0.05, 0.32, 0.02), Vector3(0, 0.42, -0.14), Vector3.ONE, tie, Vector3(-0.1, 0, 0))
	if o.extras.has("badge"):
		_mesh(spine, box(0.07, 0.09, 0.01), Vector3(0.1, 0.42, -0.15), Vector3.ONE, mat(Color(0.95, 0.95, 0.9), alpha, 0.5, glow))
	if o.extras.has("backpack"):
		var bp := mat([Color(0.7, 0.2, 0.2), Color(0.2, 0.35, 0.65), Color(0.25, 0.5, 0.3), Color(0.8, 0.6, 0.15)][randi() % 4], alpha, 0.85, glow)
		_mesh(spine, box(0.3, 0.38, 0.14), Vector3(0, 0.33, 0.2), Vector3.ONE, bp)
		_mesh(spine, box(0.24, 0.12, 0.05), Vector3(0, 0.2, 0.29), Vector3.ONE, bp)
	if o.extras.has("buoy"):
		var tm := TorusMesh.new()
		tm.inner_radius = 0.18
		tm.outer_radius = 0.3
		_mesh(spine, tm, Vector3(0.22, 0.2, 0.05), Vector3.ONE, mat(Color(0.95, 0.4, 0.15), alpha, 0.5, glow), Vector3(0, 0, 1.2))
	if o.extras.has("whistle"):
		_mesh(spine, box(0.01, 0.25, 0.01), Vector3(0, 0.5, -0.15), Vector3.ONE, dark)
		_mesh(spine, box(0.05, 0.03, 0.03), Vector3(0, 0.37, -0.16), Vector3.ONE, mat(Color(0.8, 0.8, 0.85), alpha, 0.2, glow))
	if o.extras.has("towel"):
		_mesh(spine, box(0.42, 0.06, 0.3), Vector3(0, 0.6, 0.02), Vector3.ONE, mat(Color(0.95, 0.85, 0.4), alpha, 0.9, glow))
	if o.extras.has("apron"):
		_mesh(spine, box(0.3, 0.5, 0.02), Vector3(0, 0.15, -0.14), Vector3.ONE, mat(Color(0.9, 0.85, 0.75), alpha, 0.8, glow))
	if o.extras.has("tag"):
		_mesh(spine, box(0.08, 0.05, 0.005), Vector3(0.12, 0.5, -0.16), Vector3.ONE, mat(Color(1, 1, 1), 1.0, 0.5, 0.0), Vector3(0, 0, 0.4))
	# Arme mit Ellbogen und Haenden
	for sd in [-1, 1]:
		var sh := pivot(spine, Vector3(0.26 * sd, 0.55, 0))
		P["sh%d" % sd] = sh
		_mesh(sh, sph(0.085), Vector3.ZERO, Vector3.ONE, shirt)
		_mesh(sh, cap(0.062, 0.36), Vector3(0, -0.17, 0), Vector3.ONE, skin if o.bare_arms else shirt)
		var el := pivot(sh, Vector3(0, -0.33, 0))
		P["el%d" % sd] = el
		_mesh(el, cap(0.052, 0.34), Vector3(0, -0.16, 0), Vector3.ONE, skin if (o.bare_arms or o.kind == "swimmer") else shirt)
		if not o.bare_arms and o.kind != "swimmer":
			_mesh(el, cyl(0.058, 0.058, 0.04), Vector3(0, -0.31, 0), Vector3.ONE, shirt)
		_mesh(el, box(0.07, 0.1, 0.035), Vector3(0, -0.36, 0), Vector3.ONE, skin)
		for f in 3:
			_mesh(el, cap(0.011, 0.08), Vector3((f - 1) * 0.022, -0.44, 0), Vector3.ONE, skin)
		if o.extras.has("joints"):
			_mesh(el, sph(0.055), Vector3.ZERO, Vector3.ONE, mat(o.skin.darkened(0.15), alpha, 0.2, glow))
		if sd == 1 and o.extras.has("bags"):
			_mesh(el, box(0.22, 0.28, 0.1), Vector3(0, -0.55, 0), Vector3.ONE, mat([Color(0.9, 0.3, 0.6), Color(0.95, 0.95, 0.9), Color(0.3, 0.6, 0.9)][randi() % 3], alpha, 0.7, glow))
		if sd == 1 and o.extras.has("briefcase"):
			_mesh(el, box(0.36, 0.26, 0.09), Vector3(0, -0.56, 0), Vector3.ONE, mat(Color(0.25, 0.15, 0.08), alpha, 0.5, glow))
		if sd == 1 and o.extras.has("ruler"):
			_mesh(el, box(0.03, 0.6, 0.01), Vector3(0, -0.6, -0.05), Vector3.ONE, mat(Color(0.85, 0.7, 0.4), alpha, 0.6, glow))
	# Hals und Kopf (gesichtslos)
	var neck := pivot(spine, Vector3(0, 0.66, 0))
	P["neck"] = neck
	_mesh(neck, cap(0.055, 0.14), Vector3(0, 0.05, 0), Vector3.ONE, skin)
	var head := pivot(neck, Vector3(0, 0.2, 0))
	P["head"] = head
	_mesh(head, sph(0.12), Vector3(0, 0.02, 0), Vector3(1, 1.22, 1.08), skin)
	_mesh(head, sph(0.06), Vector3(0, -0.07, -0.04), Vector3(1.2, 0.8, 1.2), skin)
	for sd in [-1, 1]:
		_mesh(head, sph(0.025), Vector3(0.115 * sd, 0.01, 0), Vector3(0.6, 1, 1), skin)
	match int(o.hair_style):
		1:
			_mesh(head, sph(0.13), Vector3(0, 0.07, 0.02), Vector3(1.0, 0.75, 1.05), hair)
		2:
			_mesh(head, sph(0.13), Vector3(0, 0.07, 0.02), Vector3(1.02, 0.78, 1.06), hair)
			_mesh(head, cap(0.045, 0.3), Vector3(0, -0.05, 0.14), Vector3.ONE, hair, Vector3(0.3, 0, 0))
		3:
			_mesh(head, sph(0.128), Vector3(0, 0.09, 0.02), Vector3(1.0, 0.55, 1.05), mat(Color(0.5, 0.48, 0.45), alpha, 0.9, glow))
		4:
			_mesh(head, sph(0.128), Vector3(0, 0.06, 0.0), Vector3(1.03, 0.85, 1.06), mat(Color(0.95, 0.95, 0.97), alpha, 0.3, glow))
	if o.extras.has("cap"):
		_mesh(head, cyl(0.14, 0.13, 0.08), Vector3(0, 0.13, 0), Vector3.ONE, mat(Color(0.1, 0.12, 0.25), alpha, 0.5, glow))
		_mesh(head, box(0.2, 0.015, 0.1), Vector3(0, 0.1, -0.13), Vector3.ONE, mat(Color(0.05, 0.05, 0.08), alpha, 0.3, glow))
	if o.extras.has("nursecap"):
		_mesh(head, box(0.16, 0.06, 0.1), Vector3(0, 0.15, 0.02), Vector3.ONE, mat(Color(1, 1, 1), alpha, 0.5, glow))
		_mesh(head, box(0.04, 0.04, 0.005), Vector3(0, 0.155, -0.032), Vector3.ONE, mat(Color(0.85, 0.1, 0.1), alpha, 0.5, glow))
	if o.extras.has("glasses"):
		for sd in [-1, 1]:
			var tm := TorusMesh.new()
			tm.inner_radius = 0.025
			tm.outer_radius = 0.033
			_mesh(head, tm, Vector3(0.045 * sd, 0.02, -0.125), Vector3.ONE, dark, Vector3(PI / 2.0, 0, 0))
	if o.extras.has("goggles"):
		_mesh(head, cyl(0.125, 0.125, 0.03), Vector3(0, 0.03, 0), Vector3(1, 1, 1.08), dark)
	if hostile:
		# kaum sichtbare Unterschiede: dunkle Augenhoehlen und ein Riss als Mund
		for sd in [-1, 1]:
			_mesh(head, sph(0.022), Vector3(0.045 * sd, 0.03, -0.118), Vector3(1, 1.3, 0.5), dark)
		_mesh(head, box(0.05, 0.006, 0.01), Vector3(0, -0.06, -0.125), Vector3.ONE, dark)
		# schwarze "Traenen" aus den Augenhoehlen
		for sd in [-1, 1]:
			_mesh(head, box(0.008, 0.09, 0.006), Vector3(0.045 * sd, -0.025, -0.122), Vector3.ONE, dark)
	P["mats"] = mats
	return P

# Gehanimation. ph = Phase, amt = 0..1 (Staerke), jerk = ruckartig (Stop-Motion)
static func walk(P: Dictionary, ph: float, amt: float) -> void:
	for sd in [-1, 1]:
		var s := sin(ph + (0.0 if sd > 0 else PI))
		P["hip%d" % sd].rotation.x = s * 0.55 * amt
		P["knee%d" % sd].rotation.x = maxf(0.0, -s) * 0.8 * amt
		P["sh%d" % sd].rotation.x = -s * 0.45 * amt
		P["el%d" % sd].rotation.x = -0.25 - absf(s) * 0.2 * amt
	P["hips"].position.y = 0.95 + absf(sin(ph)) * 0.03 * amt

# Liminaler Look: weiche, blasse Oberflaeche mit kaltem Rand, darueber eine flimmernde Huelle
static var _shell: Shader
static func liminal(root: Node, rim: Color, strength: float = 1.0, glitch: float = 1.0) -> void:
	if _shell == null:
		_shell = load("res://scripts3d/creature_shell.gdshader")
	var shell := ShaderMaterial.new()
	shell.shader = _shell
	shell.set_shader_parameter("rim_col", rim)
	shell.set_shader_parameter("strength", strength)
	shell.set_shader_parameter("glitch", glitch)
	shell.set_shader_parameter("seed", randf() * 100.0)
	var stack: Array = [root]
	var done := {}
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and n.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = n.material_override
			if done.has(m):
				continue
			done[m] = true
			if m.albedo_color.a < 0.05:
				continue
			# leicht entsaettigt und blass, wie ausgeblichene Fotos
			var c := m.albedo_color
			var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			m.albedo_color = Color(lerpf(c.r, l, 0.35), lerpf(c.g, l, 0.35), lerpf(c.b, l, 0.3), c.a)
			m.rim_enabled = true
			m.rim = 0.8
			m.rim_tint = 0.6
			m.roughness = maxf(m.roughness, 0.55)
			m.next_pass = shell
