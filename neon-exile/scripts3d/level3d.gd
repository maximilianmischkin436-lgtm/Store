extends Node3D
# Baut ein Kapitel in 3D aus einer Textkarte. Optik je nach Thema (pool, mall, office, school).

const T := 3.0          # Kantenlaenge einer Kachel in Metern
var WALL_H := 6.0      # wird pro Kapitel gesetzt
var theme := "pool"
var ch: Dictionary = {}
var floor_mat: Material
var ceil_mat: Material
var grid: Array = []
var w := 0
var h := 0
var door_nodes := {}    # Vector2i -> Node3D
var spawns: Array = []
var triggers := {}

var wall_mat: Material = ShaderMaterial.new()
var trim_mat := StandardMaterial3D.new()
var door_mat := StandardMaterial3D.new()
var gate_mat := StandardMaterial3D.new()

func _surf(mode: int, a: Color, b: Color, c: Color, sc: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts3d/surface.gdshader")
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("col_a", a)
	m.set_shader_parameter("col_b", b)
	m.set_shader_parameter("col_c", c)
	m.set_shader_parameter("scale", sc)
	return m

# Echte Texturen (generiert, nahtlos) – werden mit Weltkoordinaten (triplanar) aufgelegt
func _tex(name: String, scale: float, tint: Color = Color.WHITE, rough: float = 0.7) -> Material:
	var path := "res://assets/tex/%s.webp" % name
	if not ResourceLoader.exists(path):
		return null
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / scale
	m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _apply_textures() -> void:
	var cfg := {
		"pool": [["pool_tiles", 2.0], ["pool_tiles", 2.0]],
		"mall": [["mall_wall", 4.0], ["mall_floor", 4.0]],
		"office": [["office_wall", 3.0], ["office_floor", 3.0]],
		"school": [["school_wall", 3.0], ["school_floor", 3.0]],
		"crown": [["crown_floor", 5.0], ["crown_floor", 5.0]],
		"hospital": [["hospital_wall", 2.0], ["hospital_floor", 3.0]],
		"home": [["home_wall", 2.5], ["home_floor", 2.5]],
		"meadow": [["", 1.0], ["meadow_grass", 4.0]],
		"subway": [["subway_wall", 2.0], ["subway_floor", 3.0]],
	}
	if not cfg.has(theme):
		return
	var w = null if cfg[theme][0][0] == "" else _tex(cfg[theme][0][0], cfg[theme][0][1], Color(0.95, 0.95, 0.95), 0.6)
	var f = _tex(cfg[theme][1][0], cfg[theme][1][1], Color.WHITE, 0.35 if theme in ["pool", "mall", "crown"] else 0.85)
	if w:
		wall_mat = w
	if f:
		floor_mat = f

func setup(chapter: Dictionary) -> void:
	ch = chapter
	theme = ch.theme
	WALL_H = ch.wall_h
	MEMORY_TEXT = ch.memories
	_setup_mats()
	_apply_textures()

func _setup_mats() -> void:
	match theme:
		"pool":
			wall_mat = _surf(0, Color(0.86, 0.89, 0.9), Color(0.7, 0.78, 0.8), Color(0.35, 0.62, 0.78), 0.75)
			floor_mat = wall_mat
			ceil_mat = wall_mat
		"mall":
			wall_mat = _surf(5, Color(0.82, 0.76, 0.7), Color(0.55, 0.45, 0.45), Color.WHITE, 2.0)
			floor_mat = _surf(3, Color(0.85, 0.8, 0.74), Color(0.45, 0.3, 0.35), Color.WHITE, 1.5)
			ceil_mat = _surf(5, Color(0.3, 0.26, 0.3), Color(0.18, 0.15, 0.2), Color.WHITE, 1.5)
		"office":
			wall_mat = _surf(1, Color(0.78, 0.72, 0.42), Color(0.68, 0.6, 0.32), Color(0.45, 0.4, 0.25), 0.4)
			floor_mat = _surf(2, Color(0.55, 0.5, 0.3), Color(0.42, 0.38, 0.22), Color.WHITE, 1.0)
			ceil_mat = _surf(5, Color(0.85, 0.83, 0.75), Color(0.6, 0.58, 0.5), Color.WHITE, 1.2)
		"crown":
			# die Krone: blasses, endloses Weiss, Kacheln wie im Schwimmbad, aber ohne Wasser
			wall_mat = _surf(0, Color(0.93, 0.92, 0.95), Color(0.82, 0.8, 0.86), Color(0.75, 0.7, 0.85), 0.9)
			floor_mat = _surf(3, Color(0.9, 0.89, 0.92), Color(0.7, 0.68, 0.75), Color.WHITE, 0.8)
			ceil_mat = _surf(5, Color(0.97, 0.96, 0.98), Color(0.85, 0.84, 0.88), Color.WHITE, 1.2)
		"hospital":
			wall_mat = _surf(0, Color(0.78, 0.9, 0.85), Color(0.6, 0.72, 0.68), Color(0.4, 0.6, 0.55), 0.6)
			floor_mat = _surf(3, Color(0.8, 0.85, 0.82), Color(0.6, 0.66, 0.62), Color.WHITE, 0.8)
			ceil_mat = _surf(5, Color(0.92, 0.95, 0.93), Color(0.75, 0.8, 0.78), Color.WHITE, 1.2)
		"home":
			wall_mat = _surf(1, Color(0.85, 0.72, 0.55), Color(0.7, 0.55, 0.4), Color(0.5, 0.35, 0.25), 0.5)
			floor_mat = _surf(2, Color(0.6, 0.42, 0.25), Color(0.45, 0.3, 0.18), Color.WHITE, 1.0)
			ceil_mat = _surf(5, Color(0.9, 0.86, 0.8), Color(0.7, 0.65, 0.6), Color.WHITE, 1.2)
		"subway":
			wall_mat = _surf(0, Color(0.85, 0.88, 0.8), Color(0.7, 0.75, 0.66), Color(0.3, 0.45, 0.3), 0.5)
			floor_mat = _surf(2, Color(0.45, 0.45, 0.42), Color(0.35, 0.35, 0.33), Color.WHITE, 1.0)
			ceil_mat = _surf(5, Color(0.6, 0.6, 0.56), Color(0.45, 0.45, 0.42), Color.WHITE, 1.2)
		"meadow":
			# draussen: unsichtbare Grenze, Gras, keine Decke
			var inv := StandardMaterial3D.new()
			inv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			inv.albedo_color = Color(1, 1, 1, 0)
			wall_mat = inv
			trim_mat = inv
			floor_mat = _surf(3, Color(0.35, 0.65, 0.25), Color(0.28, 0.55, 0.2), Color.WHITE, 2.0)
			ceil_mat = inv
		"school":
			wall_mat = _surf(4, Color(0.9, 0.85, 0.72), Color(0.35, 0.55, 0.5), Color(0.2, 0.3, 0.3), 1.0)
			floor_mat = _surf(3, Color(0.8, 0.78, 0.7), Color(0.5, 0.35, 0.3), Color.WHITE, 0.6)
			ceil_mat = _surf(5, Color(0.92, 0.9, 0.85), Color(0.7, 0.68, 0.6), Color.WHITE, 1.2)

var secret_cells: Array = []

func _init() -> void:
	(wall_mat as ShaderMaterial).shader = load("res://scripts3d/tiles.gdshader")
	trim_mat.albedo_color = Color(0.8, 0.87, 0.9)
	trim_mat.roughness = 0.2
	for pair in [[door_mat, Color("#e07a8a")], [gate_mat, Color("#e8c86a")]]:
		var m: StandardMaterial3D = pair[0]
		m.albedo_color = Color(pair[1], 0.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = pair[1]
		m.emission_energy_multiplier = 1.5

func load_map(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	var rows := f.get_as_text().strip_edges().split("\n")
	h = rows.size()
	w = rows[0].length()
	for y in h:
		var row: Array = []
		for x in w:
			var c := rows[y][x]
			if c in ["P", "c", "d", "S", "B", "X"]:
				spawns.append({"c": c, "pos": cell_center(Vector2i(x, y))})
				c = "."
			elif c in ["1", "2", "3", "4", "5"]:
				triggers[Vector2i(x, y)] = c
				c = "."
			row.append(c)
		grid.append(row)
	_build()

func cell_center(c: Vector2i) -> Vector3:
	return Vector3(c.x * T + T / 2.0, 0.0, c.y * T + T / 2.0)

func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.z / T))

func solid(p: Vector3) -> bool:
	var c := cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return true
	return grid[c.y][c.x] != "." and grid[c.y][c.x] != "H" and p.y < WALL_H

func _is_edge(x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var n: Vector2i = Vector2i(x, y) + d
		if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and grid[n.y][n.x] != "#":
			return true
	return false

func _box(pos: Vector3, size: Vector3, mat: Material, collide: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if collide else Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	node.add_child(mi)
	if collide:
		node.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	node.position = pos
	add_child(node)
	return node

func _build() -> void:
	# Boden mit leuchtendem Raster (Shader)
	var fl := _box(Vector3(w * T / 2.0, -0.25, h * T / 2.0), Vector3(w * T, 0.5, h * T), floor_mat, true)
	fl.name = "Floor"
	_build_water_and_ceiling()
	# unsichtbarer Deckel ueber allem: man kann nicht ueber Waende springen
	var lid := StaticBody3D.new()
	var lcs := CollisionShape3D.new()
	var lb := BoxShape3D.new()
	lb.size = Vector3(w * T, 1.0, h * T)
	lcs.shape = lb
	lid.add_child(lcs)
	lid.position = Vector3(w * T / 2.0, WALL_H + 0.5, h * T / 2.0)
	add_child(lid)
	# Waende: nur Randkacheln, zu horizontalen Streifen zusammengefasst
	for y in h:
		var x := 0
		while x < w:
			if grid[y][x] == "#" and _is_edge(x, y):
				var s := x
				while x < w and grid[y][x] == "#" and _is_edge(x, y):
					x += 1
				var ln := (x - s) * T
				var cx := s * T + ln / 2.0
				var cz := y * T + T / 2.0
				_box(Vector3(cx, WALL_H / 2.0, cz), Vector3(ln, WALL_H, T), wall_mat, true)
				_box(Vector3(cx, WALL_H + 0.03, cz), Vector3(ln + 0.06, 0.08, T + 0.06), trim_mat, false)
				_box(Vector3(cx, 0.12, cz), Vector3(ln + 0.06, 0.08, T + 0.06), trim_mat, false)
			else:
				if grid[y][x] == "H":
					# falsche Wand: sieht aus wie Wand, man kann aber hindurchgehen
					var fake := _box(cell_center(Vector2i(x, y)) + Vector3(0, WALL_H / 2.0, 0), Vector3(T, WALL_H, T), wall_mat, false)
					fake.name = "FakeWall"
					secret_cells.append(Vector2i(x, y))
				if grid[y][x] in ["D", "G"]:
					var m := door_mat if grid[y][x] == "D" else gate_mat
					door_nodes[Vector2i(x, y)] = _box(cell_center(Vector2i(x, y)) + Vector3(0, WALL_H / 2.0, 0), Vector3(T, WALL_H, T * 0.3), m, true)
				x += 1
	_decorate()
	# Farbiges Licht pro Raum fuer Stimmung
	var lc: Array = ch.lights
	for l in [[Vector3(8, 4, 14), lc[0]], [Vector3(33, 4, 14), lc[1]], [Vector3(54, 4, 14), lc[2]], [Vector3(83, 5, 14), lc[3]]]:
		var o := OmniLight3D.new()
		o.position = Vector3(l[0].x * T, l[0].y, l[0].z * T)
		o.light_color = Color(l[1])
		o.light_energy = ch.light_e
		o.omni_range = 50.0
		o.position.y = minf(o.position.y, WALL_H - 0.5)
		add_child(o)

func open_doors(kind: String, max_x: float = INF) -> bool:
	var opened := false
	for c in door_nodes.keys():
		if grid[c.y][c.x] == kind and c.x * T < max_x:
			grid[c.y][c.x] = "."
			door_nodes[c].queue_free()
			door_nodes.erase(c)
			opened = true
	return opened

func doors_of(kind: String) -> Array:
	var out: Array = []
	for c in door_nodes.keys():
		if grid[c.y][c.x] == kind:
			out.append(c)
	return out

# ---------------- Poolrooms: Wasser, Decke, Saeulen, Leitern, Erinnerungstext ----------------
var rng := RandomNumberGenerator.new()
var memories: Array = []
var skylights: Array = []
var MEMORY_TEXT: Array = ["do you remember this place?", "you learned to swim here", "SHE was waiting by the edge", "it's always 4 PM here", "the water is warm", "don't run near the pool", "MIRA", "nobody comes here anymore", "wake up, ECHO"]
var water_mat := ShaderMaterial.new()
var chrome := StandardMaterial3D.new()

func _floor_cells() -> Array:
	var out: Array = []
	for y in h:
		for x in w:
			if grid[y][x] == ".":
				out.append(Vector2i(x, y))
	return out

func _build_water_and_ceiling() -> void:
	rng.seed = 11
	water_mat.shader = load("res://scripts3d/water.gdshader")
	chrome.albedo_color = Color(0.85, 0.88, 0.9)
	chrome.metallic = 1.0
	chrome.roughness = 0.15
	if theme != "pool" and theme != "meadow":
		_build_ceiling()
		return
	# Wasser: flache Schicht ueber dem ganzen Boden (man watet hindurch)
	var wm := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w * T, h * T)
	pm.subdivide_width = 60
	pm.subdivide_depth = 20
	wm.mesh = pm
	wm.material_override = water_mat
	wm.position = Vector3(w * T / 2.0, 0.12, h * T / 2.0)
	wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wm)
	# Decke in Streifen, einzelne Felder bleiben offen als Dachfenster
	for y in h:
		var x := 0
		while x < w:
			var open: bool = grid[y][x] != "#" and (x * 7 + y * 13) % 17 == 0
			if open:
				skylights.append(Vector2i(x, y))
				x += 1
				continue
			var st := x
			while x < w and not (grid[y][x] != "#" and (x * 7 + y * 13) % 17 == 0):
				x += 1
			var ln := (x - st) * T
			_box(Vector3(st * T + ln / 2.0, WALL_H + 0.25, y * T + T / 2.0), Vector3(ln, 0.5, T), wall_mat, false)
	# Licht durch die Dachfenster
	for i in skylights.size():
		var c: Vector2i = skylights[i]
		if i % 2 == 0:
			var sl := SpotLight3D.new()
			sl.light_color = Color("#fffaf0")
			sl.light_energy = 2.0
			sl.spot_range = 16.0
			sl.spot_angle = 30.0
			sl.position = cell_center(c) + Vector3(0, WALL_H + 2.0, 0)
			sl.rotation.x = -PI / 2.0
			add_child(sl)
		# heller Lichtschacht (leicht sichtbarer Strahl)
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(T * 0.9, WALL_H, T * 0.9)
		beam.mesh = bm
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1, 0.98, 0.9, 0.05)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam.material_override = m
		beam.position = cell_center(c) + Vector3(0, WALL_H / 2.0, 0)
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(beam)

func _decorate() -> void:
	match theme:
		"mall": _deco_mall()
		"office": _deco_office()
		"school": _deco_school()
		"crown": pass
		"hospital": _deco_hospital()
		"home": _deco_home()
		"meadow": _deco_meadow()
		"subway": _deco_subway()
		_: _deco_pool()
	_place_props()
	if theme in ["hospital", "home", "meadow", "subway"]:
		pass
	elif theme == "crown":
		# Bruchstuecke aller vorherigen Orte, durcheinander
		for th in ["pool", "mall", "office", "school"]:
			theme = th
			_extra_deco()
		theme = "crown"
	else:
		_extra_deco()
	_memory_text(Color(0.15, 0.3, 0.45) if theme == "pool" else (Color(1, 0.8, 0.95) if theme == "mall" else Color(0.25, 0.2, 0.1)))

func _deco_pool() -> void:
	var cells := _floor_cells()
	# gekachelte Saeulen in regelmaessigem Raster (gleichfoermig = liminal)
	for y in range(3, h - 2, 5):
		for x in range(4, w - 2, 6):
			var ok := true
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if grid[y + dy][x + dx] != "." :
						ok = false
			if ok and rng.randf() < 0.7:
				var c := cell_center(Vector2i(x, y))
				_box(Vector3(c.x, WALL_H / 2.0, c.z), Vector3(1.0, WALL_H, 1.0), wall_mat, true)
	# Pool-Leitern an Waenden
	for i in 14:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var dir := Vector2i.ZERO
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if grid[n.y][n.x] == "#":
				dir = d
		if dir == Vector2i.ZERO:
			continue
		var base := cell_center(c) + Vector3(dir.x, 0, dir.y) * (T / 2.0 - 0.2)
		var side := Vector3(dir.y, 0, dir.x) * 0.3
		for sgn in [-1, 1]:
			var rail := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.035
			cm.bottom_radius = 0.035
			cm.height = 1.6
			rail.mesh = cm
			rail.material_override = chrome
			rail.position = base + side * sgn + Vector3(0, 0.8, 0)
			add_child(rail)
		for k in 3:
			var step_m := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.6 if dir.y != 0 else 0.08, 0.04, 0.6 if dir.x != 0 else 0.08)
			step_m.mesh = sm
			step_m.material_override = chrome
			step_m.position = base + Vector3(0, 0.3 + k * 0.4, 0)
			add_child(step_m)
	# Durchgaenge ohne Zweck: Rundboegen aus Fliesen
	for i in 6:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var p := cell_center(c)
		_box(p + Vector3(-1.4, 1.5, 0), Vector3(0.4, 3.0, 0.4), wall_mat, true)
		_box(p + Vector3(1.4, 1.5, 0), Vector3(0.4, 3.0, 0.4), wall_mat, true)
		_box(p + Vector3(0, 3.2, 0), Vector3(3.2, 0.4, 0.4), wall_mat, false)
func _memory_text(col: Color) -> void:
	var cells := _floor_cells()
	for i in MEMORY_TEXT.size():
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var lab := Label3D.new()
		lab.text = MEMORY_TEXT[i]
		lab.font_size = 80
		lab.pixel_size = 0.01
		lab.modulate = Color(col, 0.0)
		lab.outline_size = 0
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = cell_center(c) + Vector3(0, minf(rng.randf_range(2.0, 3.5), WALL_H - 0.6), 0)
		add_child(lab)
		memories.append(lab)

# ---------------- gemeinsame Bausteine fuer die anderen Kapitel ----------------
var flicker: Array = []

func _emit(col: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = e
	return m

func _plain(col: Color, rough: float = 0.6, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

func _build_ceiling() -> void:
	# Geschlossene Decke in Streifen
	_box(Vector3(w * T / 2.0, WALL_H + 0.25, h * T / 2.0), Vector3(w * T, 0.5, h * T), ceil_mat, true)
	# Deckenleuchten im Raster
	var lamp_col := Color("#fff6d8") if theme != "mall" else Color("#ffe6f2")
	var lm := _emit(lamp_col, 2.5)
	var n := 0
	for y in range(1, h, 3 if theme == "office" else 4):
		for x in range(1, w, 3 if theme == "office" else 4):
			if grid[y][x] != ".":
				continue
			var p := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.8, 0.05, 0.7) if theme != "mall" else Vector3(1.2, 0.05, 1.2)
			p.mesh = bm
			var mat := lm
			if theme == "office" and rng.randf() < 0.12:
				mat = _emit(lamp_col, 2.5)
				flicker.append(mat)
			p.material_override = mat
			p.position = cell_center(Vector2i(x, y)) + Vector3(0, WALL_H - 0.03, 0)
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(p)
			n += 1
			if n % (5 if theme == "office" else 3) == 0:
				var o := OmniLight3D.new()
				o.light_color = lamp_col
				o.light_energy = 0.9 if theme == "office" else 0.7
				o.omni_range = 9.0
				o.position = p.position - Vector3(0, 0.4, 0)
				add_child(o)

func _wall_cells(min_y: int = 0) -> Array:
	# Bodenzellen direkt an einer Wand, mit Richtung zur Wand
	var out: Array = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if grid[y][x] != "." or y < min_y:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if grid[y + d.y][x + d.x] == "#":
					out.append([Vector2i(x, y), d])
					break
	return out

func _sign(text: String, pos: Vector3, rot: float, col: Color, size: int) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = size
	lab.pixel_size = 0.01
	lab.modulate = col * 1.6
	lab.outline_size = 8
	lab.outline_modulate = Color(col, 0.35)
	lab.position = pos
	lab.rotation.y = rot
	lab.shaded = false
	add_child(lab)

# ---------- Kapitel 2: leere Mall bei Nacht ----------
const SHOPS := ["VIDEO WORLD", "SUNSET CAFE", "CYBER ARCADE", "DREAM MALL", "FOOD COURT", "GAME ZONE", "JUICE BAR", "PET PALACE", "MUSIC HUT", "PHOTO 1HR", "TOY KINGDOM", "SKATE SHOP"]

func _deco_mall() -> void:
	var cells := _floor_cells()
	var walls := _wall_cells()
	walls.shuffle()
	var glass := _emit(Color(0.15, 0.1, 0.25), 0.4)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.2, 0.15, 0.35, 0.5)
	var cols := [Color("#ff4fa3"), Color("#38e8ff"), Color("#ffcf4a"), Color("#9dff6a"), Color("#c77dff")]
	var placed := 0
	for wc in walls:
		if placed >= 18:
			break
		var c: Vector2i = wc[0]
		var d: Vector2i = wc[1]
		if c.x % 3 != 0 and d.y != 0 or c.y % 3 != 0 and d.x != 0:
			continue
		var base := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.06)
		var rot := atan2(-d.x, -d.y)
		# Schaufenster
		var win := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(T * 0.9, 2.6)
		win.mesh = qm
		win.material_override = glass
		win.position = base + Vector3(0, 1.5, 0)
		win.rotation.y = rot
		add_child(win)
		var col: Color = cols[placed % cols.size()]
		_sign(SHOPS[placed % SHOPS.size()], base + Vector3(0, 3.4, 0) - Vector3(d.x, 0, d.y) * 0.02, rot, col, 120)
		placed += 1
	# Palmen in Kuebeln
	var trunk := _plain(Color(0.45, 0.32, 0.2))
	var leaf := _plain(Color(0.25, 0.55, 0.35))
	for i in 12:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var p := cell_center(c)
		_box(p + Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 1.0), _plain(Color(0.9, 0.88, 0.85)), true)
		var tr := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.14
		cm.height = 3.5
		tr.mesh = cm
		tr.material_override = trunk
		tr.position = p + Vector3(0, 2.5, 0)
		add_child(tr)
		for k in 6:
			var lf := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.25, 0.03, 1.6)
			lf.mesh = lb
			lf.material_override = leaf
			lf.position = p + Vector3(0, 4.2, 0)
			lf.rotation = Vector3(0.5, k * TAU / 6.0, 0)
			lf.translate_object_local(Vector3(0, 0, 0.7))
			add_child(lf)
	# Springbrunnen in der Mitte des Fragment-Raums
	var fc := cell_center(Vector2i(56, 9))
	var bowl := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 3.0
	bc.bottom_radius = 3.2
	bc.height = 0.6
	bowl.mesh = bc
	bowl.material_override = _plain(Color(0.85, 0.82, 0.8), 0.3)
	bowl.position = fc + Vector3(0, 0.3, 0)
	add_child(bowl)
	var water := MeshInstance3D.new()
	var wc2 := CylinderMesh.new()
	wc2.top_radius = 2.8
	wc2.bottom_radius = 2.8
	wc2.height = 0.05
	water.mesh = wc2
	var wmat := ShaderMaterial.new()
	wmat.shader = load("res://scripts3d/water.gdshader")
	water.material_override = wmat
	water.position = fc + Vector3(0, 0.62, 0)
	add_child(water)
	var spout := _emit(Color("#8fe9ff"), 1.5)
	spout.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spout.albedo_color = Color(0.6, 0.9, 1.0, 0.5)
	var sp := MeshInstance3D.new()
	var spc := CylinderMesh.new()
	spc.top_radius = 0.05
	spc.bottom_radius = 0.3
	spc.height = 2.5
	sp.mesh = spc
	sp.material_override = spout
	sp.position = fc + Vector3(0, 1.8, 0)
	add_child(sp)
	# Baenke
	for i in 10:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		_box(cell_center(c) + Vector3(0, 0.45, 0), Vector3(2.2, 0.12, 0.6), _plain(Color(0.6, 0.4, 0.3)), false)
		_box(cell_center(c) + Vector3(0, 0.22, 0), Vector3(2.0, 0.44, 0.5), _plain(Color(0.2, 0.2, 0.22), 0.3, 0.8), true)

# ---------- Kapitel 3: Backrooms / Archiv ----------
func _deco_office() -> void:
	var cells := _floor_cells()
	# Aktenschraenke an Waenden
	var cab := _plain(Color(0.62, 0.62, 0.58), 0.4, 0.6)
	var walls := _wall_cells()
	walls.shuffle()
	for i in mini(40, walls.size()):
		var c: Vector2i = walls[i][0]
		var d: Vector2i = walls[i][1]
		var p := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.35)
		_box(p + Vector3(0, 0.75, 0), Vector3(0.6 if d.x != 0 else 0.9, 1.5, 0.9 if d.x != 0 else 0.6), cab, true)
	# Steckdosen-artige Details und Wasserflecken (dunkle Flecken an Waenden)
	var stain := _plain(Color(0.35, 0.3, 0.15, 0.6))
	stain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 25:
		var wc = walls[rng.randi() % walls.size()]
		var c: Vector2i = wc[0]
		var d: Vector2i = wc[1]
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		var sz := rng.randf_range(0.6, 1.6)
		qm.size = Vector2(sz, sz * 0.7)
		q.mesh = qm
		q.material_override = stain
		q.position = cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.02) + Vector3(0, rng.randf_range(1.5, 3.0), 0)
		q.rotation.y = atan2(-d.x, -d.y)
		add_child(q)

# ---------- Kapitel 4: Schule bei Sonnenuntergang ----------
func _deco_school() -> void:
	var cells := _floor_cells()
	var walls := _wall_cells()
	walls.shuffle()
	var locker_cols := [Color(0.35, 0.55, 0.65), Color(0.75, 0.4, 0.35), Color(0.4, 0.6, 0.45)]
	var placed := 0
	for wc in walls:
		var c: Vector2i = wc[0]
		var d: Vector2i = wc[1]
		var p := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.3)
		var rot := atan2(-d.x, -d.y)
		if placed < 30 and rng.randf() < 0.5:
			# Spindreihe
			var lc: Color = locker_cols[(c.x / 6) % 3]
			for k in 3:
				var off := (k - 1) * 0.9
				var lp := p + (Vector3(0, 0, off) if d.x != 0 else Vector3(off, 0, 0))
				_box(lp + Vector3(0, 1.0, 0), Vector3(0.5 if d.x != 0 else 0.85, 2.0, 0.85 if d.x != 0 else 0.5), _plain(lc, 0.35, 0.5), true)
			placed += 1
		elif rng.randf() < 0.25:
			# Fenster mit Abendsonne
			var win := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(T * 0.8, 1.6)
			win.mesh = qm
			win.material_override = _emit(Color(1.0, 0.65, 0.35), 2.2)
			win.position = cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.03) + Vector3(0, 2.2, 0)
			win.rotation.y = rot
			add_child(win)
	# Tafeln mit Kreidetext
	var board := _plain(Color(0.12, 0.22, 0.17), 0.9)
	var chalk := ["2 + 2 = ?", "DON'T FORGET", "Mira <3 Echo", "HOMEWORK: remember", "DATE: OCT 1"]
	for i in chalk.size():
		var wc = walls[(i * 17 + 5) % walls.size()]
		var c: Vector2i = wc[0]
		var d: Vector2i = wc[1]
		var p := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.04) + Vector3(0, 1.9, 0)
		var rot := atan2(-d.x, -d.y)
		var b := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.6, 1.3)
		b.mesh = qm
		b.material_override = board
		b.position = p
		b.rotation.y = rot
		add_child(b)
		var lab := Label3D.new()
		lab.text = chalk[i]
		lab.font_size = 48
		lab.pixel_size = 0.008
		lab.modulate = Color(0.95, 0.95, 0.9)
		lab.position = p - Vector3(d.x, 0, d.y) * 0.02
		lab.rotation.y = rot
		add_child(lab)
	# Schultische in Reihen
	var desk := _plain(Color(0.7, 0.55, 0.38), 0.6)
	var leg := _plain(Color(0.3, 0.3, 0.32), 0.3, 0.8)
	for i in 30:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if 12 <= c.y and c.y <= 17:
			continue
		var p := cell_center(c)
		_box(p + Vector3(0, 0.75, 0), Vector3(1.2, 0.06, 0.7), desk, true)
		for lx in [-0.5, 0.5]:
			_box(p + Vector3(lx, 0.37, 0), Vector3(0.05, 0.74, 0.6), leg, false)

# ---------- Krankenhaus ----------
func _deco_hospital() -> void:
	var cells := _floor_cells()
	var white := _plain(Color(0.92, 0.94, 0.93), 0.5)
	var metal := _plain(Color(0.7, 0.72, 0.74), 0.3, 0.8)
	var sheet := _plain(Color(0.85, 0.92, 0.95), 0.9)
	for i in 34:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if 12 <= c.y and c.y <= 17:
			continue
		var p := cell_center(c)
		var r := rng.randf_range(-0.2, 0.2) + (PI / 2.0 if rng.randf() < 0.5 else 0.0)
		match rng.randi() % 4:
			0, 1:
				# Krankenbett mit Laken, Kissen, Gelaender
				_bx(p + Vector3(0, 0.55, 0), Vector3(0.95, 0.12, 2.0), Color(0.9, 0.92, 0.93), 0.5, 0.0, true, r)
				_bx(p + Vector3(0, 0.66, 0), Vector3(0.9, 0.1, 1.9), Color(0.85, 0.92, 0.95), 0.9, 0.0, false, r)
				var pil := _bx(p + Vector3(0, 0.75, 0), Vector3(0.6, 0.12, 0.35), Color(0.98, 0.98, 0.98), 0.9, 0.0, false, r)
				pil.translate_object_local(Vector3(0, 0, 0.75))
				for lx in [-0.42, 0.42]:
					var rail := _bx(p + Vector3(0, 0.85, 0), Vector3(0.04, 0.3, 1.2), Color(0.7, 0.72, 0.74), 0.3, 0.8, false, r)
					rail.translate_object_local(Vector3(lx, 0, 0))
				for lz in [-0.9, 0.9]:
					for lx in [-0.4, 0.4]:
						var leg := _bx(p + Vector3(0, 0.25, 0), Vector3(0.05, 0.5, 0.05), Color(0.6, 0.62, 0.64), 0.3, 0.8, false, r)
						leg.translate_object_local(Vector3(lx, 0, lz))
				# Herzmonitor daneben
				var mon := _bx(p + Vector3(0, 1.2, 0), Vector3(0.45, 0.35, 0.25), Color(0.2, 0.22, 0.24), 0.4, 0.3, false, r)
				mon.translate_object_local(Vector3(0.75, 0, 0.8))
				var scr := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.38, 0.26)
				scr.mesh = qm
				scr.material_override = _emit(Color(0.2, 1.0, 0.5), 1.6)
				scr.position = Vector3(0, 0, -0.13)
				scr.rotation.y = PI
				mon.add_child(scr)
				flicker.append(scr.material_override)
			2:
				# Infusionsstaender
				_bx(p + Vector3(0, 0.95, 0), Vector3(0.04, 1.9, 0.04), Color(0.7, 0.72, 0.74), 0.3, 0.8, false)
				_bx(p + Vector3(0, 1.75, 0.08), Vector3(0.18, 0.28, 0.06), Color(0.85, 0.95, 1.0), 0.1, 0.0, false)
				_bx(p + Vector3(0, 0.03, 0), Vector3(0.5, 0.05, 0.5), Color(0.5, 0.5, 0.52), 0.3, 0.8, false)
			3:
				# Rollstuhl
				_bx(p + Vector3(0, 0.5, 0), Vector3(0.5, 0.06, 0.5), Color(0.25, 0.25, 0.28), 0.5, 0.0, true, r)
				var back := _bx(p + Vector3(0, 0.8, 0), Vector3(0.5, 0.55, 0.05), Color(0.25, 0.25, 0.28), 0.5, 0.0, false, r)
				back.translate_object_local(Vector3(0, 0, 0.25))
				for sd in [-0.3, 0.3]:
					var tm := TorusMesh.new()
					tm.inner_radius = 0.24
					tm.outer_radius = 0.28
					var wheel := MeshInstance3D.new()
					wheel.mesh = tm
					wheel.material_override = metal
					wheel.position = p + Vector3(0, 0.3, 0)
					wheel.rotation = Vector3(0, r, PI / 2.0)
					add_child(wheel)
					wheel.translate_object_local(Vector3(0, sd, 0))
	# Vorhaenge zwischen den Betten und Schilder
	_on_wall(14, func(p, r, d):
		_bx(p + Vector3(0, 1.4, 0), Vector3(1.8, 2.2, 0.03), Color(0.75, 0.88, 0.85), 0.9, 0.0, false, r))
	_on_wall(6, func(p, r, d):
		_label(["WARD 4", "QUIET PLEASE", "VISITING HOURS 4 - 6", "PEDIATRICS", "NO VISITORS"][rng.randi() % 5], p + Vector3(0, 2.4, 0), r, Color(0.1, 0.35, 0.3), 56))

# ---------- Zuhause ----------
func _deco_home() -> void:
	var cells := _floor_cells()
	# Wohnungstueren mit Nummer 440, Familienfotos, Schuhe vor der Tuer
	_on_wall(26, func(p, r, d):
		var door := _bx(p + Vector3(0, 1.05, 0), Vector3(1.0, 2.1, 0.06), Color(0.45, 0.3, 0.2), 0.6, 0.0, false, r)
		var knob := _bx(p + Vector3(0, 1.0, 0), Vector3(0.06, 0.06, 0.06), Color(0.85, 0.7, 0.3), 0.3, 0.9, false, r)
		knob.translate_object_local(Vector3(0.38, 0, -0.06))
		_label("440", p + Vector3(0, 1.75, 0) - Vector3(d.x, 0, d.y) * 0.05, r, Color(0.85, 0.7, 0.3), 40)
		if rng.randf() < 0.4:
			for k in 2:
				var sh := _bx(p + Vector3(0, 0.05, 0), Vector3(0.1, 0.08, 0.22), Color(0.8, 0.15, 0.15), 0.6, 0.0, false, r)
				sh.translate_object_local(Vector3(-0.1 + k * 0.15, 0, -0.35)))
	_on_wall(18, func(p, r, d):
		var fr := _bx(p + Vector3(0, 1.6, 0), Vector3(0.5, 0.4, 0.04), Color(0.3, 0.2, 0.12), 0.6, 0.0, false, r)
		var pic := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.42, 0.32)
		pic.mesh = qm
		pic.material_override = _plain(Color(0.75, 0.68, 0.6), 0.9)
		pic.position = Vector3(0, 0, -0.025)
		pic.rotation.y = PI
		fr.add_child(pic)
		# drei Gesichter, zerkratzt
		for k in 3:
			var f := _bx(p + Vector3(0, 1.62, 0), Vector3(0.07, 0.09, 0.01), Color(0.15, 0.1, 0.08), 0.9, 0.0, false, r)
			f.translate_object_local(Vector3(-0.12 + k * 0.12, 0, -0.035)))
	for i in 14:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if 12 <= c.y and c.y <= 17:
			continue
		var p := cell_center(c)
		var r := rng.randf() * TAU
		match rng.randi() % 3:
			0:
				# Fernseher mit Rauschen
				_bx(p + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.5), Color(0.35, 0.25, 0.18), 0.6, 0.0, true, r)
				var tv := _bx(p + Vector3(0, 0.85, 0), Vector3(0.7, 0.5, 0.5), Color(0.15, 0.15, 0.17), 0.4, 0.2, false, r)
				var scr := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.55, 0.38)
				scr.mesh = qm
				scr.material_override = _emit(Color(0.75, 0.8, 0.85), 1.5)
				scr.position = Vector3(0, 0, -0.26)
				scr.rotation.y = PI
				tv.add_child(scr)
				flicker.append(scr.material_override)
			1:
				# Kuechentisch, gedeckt fuer drei
				_bx(p + Vector3(0, 0.75, 0), Vector3(1.4, 0.06, 0.9), Color(0.6, 0.45, 0.3), 0.6, 0.0, true, r)
				for k in 3:
					var pl := _bx(p + Vector3(0, 0.8, 0), Vector3(0.22, 0.02, 0.22), Color(0.95, 0.95, 0.92), 0.3, 0.0, false, r)
					pl.translate_object_local(Vector3(-0.45 + k * 0.45, 0, 0.2))
			2:
				# Kuehlschrank mit Zeichnung
				var fr := _bx(p + Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 0.7), Color(0.92, 0.92, 0.9), 0.3, 0.1, true, r)
				var lab := Label3D.new()
				lab.text = "ECHO + MIRA"
				lab.font_size = 36
				lab.modulate = Color(0.9, 0.3, 0.3)
				lab.position = Vector3(0, 0.2, -0.36)
				lab.rotation.y = PI
				fr.add_child(lab)

# ---------- U-Bahn ----------
func _deco_subway() -> void:
	var cells := _floor_cells()
	var yellow := Color(0.95, 0.8, 0.15)
	# Gleisbetten mit Schienen und gelber Sicherheitslinie (entlang der Raender oben und unten)
	for row in [4, 25]:
		for x in range(3, w - 3):
			var c := Vector2i(x, row)
			if grid[c.y][c.x] != ".":
				continue
			var p := cell_center(c)
			_bx(p + Vector3(0, 0.01, 0), Vector3(T, 0.02, T), Color(0.12, 0.12, 0.12), 0.9)
			for rz in [-0.5, 0.5]:
				_bx(p + Vector3(0, 0.07, rz), Vector3(T, 0.08, 0.08), Color(0.55, 0.55, 0.58), 0.3, 0.9)
			for k in 3:
				_bx(p + Vector3(-1.0 + k, 0.03, 0), Vector3(0.2, 0.05, 1.5), Color(0.3, 0.22, 0.15), 0.9)
			var edge := 1.0 if row == 4 else -1.0
			_bx(p + Vector3(0, 0.03, edge * T * 0.5), Vector3(T, 0.03, 0.25), yellow, 0.5)
	# Baenke, Fahrkartenautomaten, Muelleimer
	for i in 26:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if 12 <= c.y and c.y <= 17:
			continue
		var p := cell_center(c)
		var r := (PI / 2.0) * float(rng.randi() % 2)
		match rng.randi() % 3:
			0:
				_bx(p + Vector3(0, 0.45, 0), Vector3(2.0, 0.08, 0.5), Color(0.55, 0.35, 0.2), 0.7, 0.0, true, r)
				var back := _bx(p + Vector3(0, 0.75, 0), Vector3(2.0, 0.5, 0.06), Color(0.55, 0.35, 0.2), 0.7, 0.0, false, r)
				back.translate_object_local(Vector3(0, 0, 0.25))
			1:
				var m := _bx(p + Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 0.6), Color(0.2, 0.35, 0.5), 0.4, 0.4, true, r)
				var scr := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.5, 0.35)
				scr.mesh = qm
				scr.material_override = _emit(Color(0.3, 0.9, 1.0), 1.4)
				scr.position = Vector3(0, 0.35, -0.31)
				scr.rotation.y = PI
				m.add_child(scr)
				flicker.append(scr.material_override)
			2:
				_bx(p + Vector3(0, 0.45, 0), Vector3(0.5, 0.9, 0.5), Color(0.25, 0.3, 0.25), 0.6, 0.3, true)
	# Abfahrtstafeln
	_on_wall(10, func(p, r, d):
		var b := _bx(p + Vector3(0, 2.6, 0), Vector3(2.6, 0.8, 0.08), Color(0.05, 0.05, 0.06), 0.4, 0.0, false, r)
		_label(["4:00  SCHOOL      CANCELLED", "4:12  SERVER 7    PLATFORM 4", "4:40  ---           ---", "NEXT TRAIN: NEVER"][rng.randi() % 4], p + Vector3(0, 2.6, 0) - Vector3(d.x, 0, d.y) * 0.06, r, Color(1.0, 0.75, 0.2), 30, true))
	_on_wall(8, func(p, r, d):
		_label(["MIND THE GAP", "PLATFORM 4", "EXIT", "STAND BEHIND THE YELLOW LINE"][rng.randi() % 4], p + Vector3(0, 3.6, 0), r, Color(0.95, 0.95, 0.9), 44))
	# ein stehengebliebener Wagen im Gleisbett
	var car := Vector3(w * T * 0.3, 0, cell_center(Vector2i(0, 4)).z)
	_bx(car + Vector3(0, 1.8, 0), Vector3(14.0, 3.2, 2.8), Color(0.75, 0.78, 0.8), 0.3, 0.5, true)
	for k in 5:
		var win := _bx(car + Vector3(-5.5 + k * 2.75, 2.2, 1.42), Vector3(1.6, 1.0, 0.04), Color(1, 0.95, 0.7), 0.1)
		win.set_meta("w", 1)
	_bx(car + Vector3(0, 1.0, 1.43), Vector3(14.0, 0.25, 0.03), Color(0.85, 0.15, 0.15), 0.4)

# ---------- Wiese: draussen, blauer Himmel, Haeuser in der Ferne ----------
var butterflies: Array = []

func _deco_meadow() -> void:
	var cx := w * T / 2.0
	var cz := h * T / 2.0
	# weite Graslandschaft weit ueber die (unsichtbare) Grenze hinaus
	var far := _box(Vector3(cx, -0.26, cz), Vector3(w * T * 6.0, 0.5, h * T * 12.0), floor_mat, false)
	far.name = "FarGrass"
	# sanfte Huegel am Horizont
	var hill := _plain(Color(0.3, 0.58, 0.22), 0.95)
	for i in 14:
		var a := rng.randf() * TAU
		var d := rng.randf_range(300.0, 420.0)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(50.0, 90.0)
		sm.height = sm.radius * 2.0
		mi.mesh = sm
		mi.material_override = hill
		mi.position = Vector3(cx + cos(a) * d, -sm.radius * 0.8, cz + sin(a) * d)
		mi.scale = Vector3(1.6, 1.0, 1.6)
		add_child(mi)
	# Haeuser weit weg (kleines Dorf)
	for i in 16:
		var a := rng.randf_range(-1.2, 1.2) + (0.0 if i % 2 == 0 else PI)
		var d := rng.randf_range(90.0, 150.0)
		var p := Vector3(cx + cos(a) * d * 1.3, 0, cz + sin(a) * d)
		var hw := rng.randf_range(5.0, 8.0)
		var hc: Color = [Color(0.95, 0.92, 0.85), Color(0.9, 0.85, 0.75), Color(0.85, 0.88, 0.9), Color(0.95, 0.85, 0.8)][i % 4]
		_bx(p + Vector3(0, 3.0, 0), Vector3(hw, 6.0, hw * 0.8), hc, 0.8, 0.0, false, a)
		var roof := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(hw * 1.1, 3.0, hw * 0.9)
		roof.mesh = pm
		roof.material_override = _plain([Color(0.65, 0.2, 0.15), Color(0.35, 0.3, 0.3), Color(0.55, 0.3, 0.2)][i % 3], 0.8)
		roof.position = p + Vector3(0, 7.5, 0)
		roof.rotation.y = a
		add_child(roof)
		for k in 2:
			var win := _bx(p + Vector3(0, 3.5, 0), Vector3(1.0, 1.2, 0.05), Color(0.6, 0.75, 0.9), 0.1, 0.3, false, a)
			win.translate_object_local(Vector3(-1.5 + k * 3.0, 0, -hw * 0.4 - 0.03))
	# Baeume
	var trunk := _plain(Color(0.4, 0.28, 0.18), 0.9)
	var leaves := _plain(Color(0.25, 0.55, 0.2), 0.9)
	for i in 40:
		var p := Vector3(rng.randf_range(-40, w * T + 40), 0, rng.randf_range(-40, h * T + 40))
		if p.x > 4 and p.x < w * T - 4 and p.z > 4 and p.z < h * T - 4 and rng.randf() < 0.75:
			continue
		var s := rng.randf_range(0.8, 1.6)
		var tr := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.25 * s
		cm.bottom_radius = 0.35 * s
		cm.height = 3.0 * s
		tr.mesh = cm
		tr.material_override = trunk
		tr.position = p + Vector3(0, 1.5 * s, 0)
		add_child(tr)
		for k in 3:
			var lf := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = rng.randf_range(1.3, 2.0) * s
			sm.height = sm.radius * 2.0
			lf.mesh = sm
			lf.material_override = leaves
			lf.position = p + Vector3(rng.randf_range(-0.8, 0.8), 3.5 * s + k * 0.7, rng.randf_range(-0.8, 0.8))
			add_child(lf)
	# Blumen
	var fcols := [Color(1, 1, 1), Color(1, 0.9, 0.2), Color(0.9, 0.4, 0.6), Color(0.6, 0.5, 1.0)]
	for i in 500:
		var p := Vector3(rng.randf_range(4, w * T - 4), 0, rng.randf_range(4, h * T - 4))
		var st := _bx(p + Vector3(0, 0.12, 0), Vector3(0.02, 0.24, 0.02), Color(0.2, 0.5, 0.15), 0.9, 0.0, false)
		var fl := _bx(p + Vector3(0, 0.26, 0), Vector3(0.09, 0.04, 0.09), fcols[i % 4], 0.6, 0.0, false)
	# Grasbuesche
	for i in 260:
		var p := Vector3(rng.randf_range(4, w * T - 4), 0, rng.randf_range(4, h * T - 4))
		for k in 3:
			var g := _bx(p + Vector3(rng.randf_range(-0.15, 0.15), 0.2, rng.randf_range(-0.15, 0.15)), Vector3(0.03, 0.4, 0.01), Color(0.3, 0.6, 0.2), 0.9, 0.0, false, rng.randf() * TAU)
			g.rotation.z = rng.randf_range(-0.3, 0.3)
	# Holzzaun am Rand
	var wood := Color(0.6, 0.45, 0.3)
	var x := 3.0
	while x < w * T - 3.0:
		for z in [3.0, h * T - 3.0]:
			_bx(Vector3(x, 0.55, z), Vector3(0.12, 1.1, 0.12), wood, 0.9, 0.0, false)
			_bx(Vector3(x + 1.0, 0.8, z), Vector3(2.0, 0.08, 0.06), wood, 0.9, 0.0, false)
		x += 2.0
	# Schmetterlinge
	for i in 14:
		var b := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.16, 0.1)
		b.mesh = qm
		var bm := _plain([Color(1, 0.8, 0.2), Color(1, 1, 1), Color(0.5, 0.7, 1)][i % 3], 0.6)
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		b.material_override = bm
		b.position = Vector3(rng.randf_range(10, w * T - 10), 1.0, rng.randf_range(8, h * T - 8))
		add_child(b)
		butterflies.append({"n": b, "o": b.position, "ph": rng.randf() * TAU})

func dream_update(delta: float, player_pos: Vector3, t: float) -> void:
	for lab in memories:
		var d: float = lab.global_position.distance_to(player_pos)
		var a := clampf((d - 5.0) / 5.0, 0.0, 1.0) * clampf((26.0 - d) / 8.0, 0.0, 1.0)
		lab.modulate.a = lerpf(lab.modulate.a, a * 0.7, minf(1.0, delta * 2.0))
	for bf in butterflies:
		var ph: float = t * 1.3 + bf.ph
		bf.n.position = bf.o + Vector3(sin(ph) * 2.0, sin(ph * 2.7) * 0.4 + 0.3, cos(ph * 0.8) * 2.0)
		bf.n.rotation.x = sin(t * 18.0 + bf.ph) * 1.2
	for m in flicker:
		m.emission_energy_multiplier = 0.0 if fmod(t * 7.3 + m.get_instance_id() * 0.37, 5.0) < 0.35 else 2.5

# ---------- echte 3D-Modelle (Khronos glTF Sample Assets) ----------
const PROPS := {
	"pool": [["ToyCar", 3, 0.35], ["Duck", 10, 0.35], ["WaterBottle", 3, 0.3]],
	"mall": [["GlamVelvetSofa", 5, 0.9], ["Corset", 4, 1.1], ["Avocado", 4, 0.25], ["BarramundiFish", 2, 0.6], ["ChairDamaskPurplegold", 3, 1.0]],
	"office": [["SheenChair", 9, 1.0], ["WaterBottle", 6, 0.3], ["Lantern", 2, 1.6], ["AntiqueCamera", 2, 0.5]],
	"school": [["SheenChair", 3, 1.0], ["ToyCar", 3, 0.35], ["Duck", 2, 0.3], ["Lantern", 2, 1.4], ["Avocado", 2, 0.2]],
	"hospital": [["WaterBottle", 6, 0.3], ["Lantern", 2, 1.4], ["SheenChair", 4, 1.0]],
	"home": [["GlamVelvetSofa", 4, 0.9], ["ChairDamaskPurplegold", 5, 1.0], ["ToyCar", 4, 0.35], ["Duck", 2, 0.3], ["AntiqueCamera", 1, 0.5], ["Avocado", 3, 0.2]],
	"subway": [["WaterBottle", 5, 0.3], ["ToyCar", 2, 0.35], ["Lantern", 3, 1.4], ["Duck", 1, 0.3]],
	"crown": [["SheenChair", 3, 1.0], ["ToyCar", 2, 0.35], ["GlamVelvetSofa", 2, 0.9], ["ChairDamaskPurplegold", 4, 1.0], ["AntiqueCamera", 2, 0.5], ["Lantern", 3, 1.6], ["Duck", 3, 0.3], ["Corset", 2, 1.1]],
}

func _aabb_world(n: Node) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array = [n]
	while stack.size() > 0:
		var c = stack.pop_back()
		if c is MeshInstance3D and c.mesh:
			var b: AABB = c.global_transform * c.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		stack.append_array(c.get_children())
	return box

# Manche Modelle bringen eigene Kameras/Lichter mit: entfernen
func _strip(n: Node) -> void:
	for c in n.get_children():
		if c is Camera3D or c is Light3D:
			c.free()
		else:
			_strip(c)

func prop(name: String, pos: Vector3, height: float, rot: float) -> Node3D:
	var sc: PackedScene = load("res://assets/khronos/%s.glb" % name)
	var n: Node3D = sc.instantiate()
	_strip(n)
	add_child(n)
	var bb := _aabb_world(n)
	var s: float = height / maxf(bb.size.y, 0.001)
	n.scale = Vector3.ONE * s
	n.rotation.y = rot
	n.position = pos - Vector3(0, bb.position.y * s, 0)
	return n

func _place_props() -> void:
	var walls := _wall_cells()
	if walls.is_empty():
		return
	for entry in PROPS.get(theme, []):
		for i in entry[1]:
			var wc = walls[rng.randi() % walls.size()]
			var c: Vector2i = wc[0]
			var d: Vector2i = wc[1]
			var p := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.9)
			if theme == "pool":
				p.y = 0.0
			prop(entry[0], p, entry[2], atan2(-d.x, -d.y) + PI)

# ---------- zusaetzliche Details pro Ort ----------
const FigureLib = preload("res://scripts3d/figure.gd")

func _bx(pos: Vector3, size: Vector3, col: Color, rough: float = 0.6, metal: float = 0.0, collide: bool = false, rot: float = 0.0) -> Node3D:
	var n := _box(pos, size, _plain(col, rough, metal), collide)
	n.rotation.y = rot
	return n

func _label(text: String, pos: Vector3, rot: float, col: Color, size: int, emissive: bool = false) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = size
	lab.pixel_size = 0.008
	lab.modulate = col
	lab.position = pos
	lab.rotation.y = rot
	lab.shaded = not emissive
	add_child(lab)

func _on_wall(count: int, fn: Callable) -> void:
	var walls := _wall_cells()
	walls.shuffle()
	for i in mini(count, walls.size()):
		var c: Vector2i = walls[i][0]
		var d: Vector2i = walls[i][1]
		var p := cell_center(c) + Vector3(d.x, 0, d.y) * (T / 2.0 - 0.04)
		fn.call(p, atan2(-d.x, -d.y), Vector3(d.x, 0, d.y))

func _random_floor(count: int, fn: Callable, avoid_path: bool = true) -> void:
	var cells := _floor_cells()
	for i in count:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if avoid_path and c.y >= 13 and c.y <= 16:
			continue
		fn.call(cell_center(c), rng.randf() * TAU)

func _static_figure(kind: String, pos: Vector3, rot: float, solid: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot
	add_child(root)
	var o := FigureLib.outfit(kind, rng)
	var P := FigureLib.build(root, o, 1.0 if solid else 0.3, 0.0 if solid else 0.3, false)
	P.head.rotation = Vector3(rng.randf_range(-0.3, 0.2), rng.randf_range(-0.5, 0.5), rng.randf_range(-0.3, 0.3))
	for sd in [-1, 1]:
		P["sh%d" % sd].rotation.x = rng.randf_range(-0.6, 0.3)

func _extra_deco() -> void:
	match theme:
		"pool":
			# Liegestuehle, Rettungsringe, Schilder, Badeenten, Bademeister-Hochsitze
			_random_floor(14, func(p, r):
				_bx(p + Vector3(0, 0.35, 0), Vector3(0.7, 0.06, 1.9), Color(0.95, 0.95, 0.95), 0.4, 0.0, true, r)
				var back := _bx(p + Vector3(0, 0.65, 0), Vector3(0.7, 0.06, 0.7), Color(0.95, 0.95, 0.95), 0.4, 0.0, false, r)
				back.translate_object_local(Vector3(0, 0, 0.85))
				back.rotate_object_local(Vector3.RIGHT, 0.9))
			_on_wall(10, func(p, r, d):
				var tm := TorusMesh.new()
				tm.inner_radius = 0.25
				tm.outer_radius = 0.42
				var mi := MeshInstance3D.new()
				mi.mesh = tm
				mi.material_override = _plain(Color(0.95, 0.35, 0.2), 0.5)
				mi.position = p + Vector3(0, 2.0, 0) - d * 0.1
				mi.rotation = Vector3(PI / 2.0, r, 0)
				add_child(mi))
			_on_wall(8, func(p, r, d):
				_bx(p + Vector3(0, 2.7, 0) - d * 0.03, Vector3(1.4, 0.45, 0.02), Color(0.95, 0.95, 0.92), 0.5, 0.0, false, r)
				_label(["NO DIVING", "NO RUNNING", "DEEP END", "SHALLOW", "SHOWER BEFORE SWIMMING", "LIFEGUARD ON DUTY"][rng.randi() % 6], p + Vector3(0, 2.7, 0) - d * 0.05, r, Color(0.7, 0.1, 0.1), 40))
			var duck := _plain(Color(1, 0.85, 0.1), 0.3)
			_random_floor(12, func(p, r):
				var b := MeshInstance3D.new()
				b.mesh = FigureLib.sph(0.12)
				b.material_override = duck
				b.position = p + Vector3(rng.randf_range(-1, 1), 0.2, rng.randf_range(-1, 1))
				add_child(b)
				var h := MeshInstance3D.new()
				h.mesh = FigureLib.sph(0.07)
				h.material_override = duck
				h.position = b.position + Vector3(0.08, 0.12, 0)
				add_child(h), false)
			_random_floor(4, func(p, r):
				for lx in [-0.5, 0.5]:
					for lz in [-0.5, 0.5]:
						_bx(p + Vector3(lx, 1.2, lz), Vector3(0.08, 2.4, 0.08), Color(0.95, 0.95, 0.95), 0.4, 0.0, false)
				_bx(p + Vector3(0, 2.4, 0), Vector3(1.2, 0.1, 1.2), Color(0.85, 0.2, 0.15), 0.6, 0.0, true)
				_bx(p + Vector3(0, 2.8, 0.5), Vector3(1.2, 0.8, 0.1), Color(0.85, 0.2, 0.15), 0.6))
			# Rutsche ins Nichts
			_random_floor(2, func(p, r):
				for k in 8:
					_bx(p + Vector3(0, 0.4 + k * 0.45, k * 0.6).rotated(Vector3.UP, r), Vector3(1.2, 0.1, 0.8), Color(0.2, 0.55, 0.9), 0.2, 0.0, false, r))
		"mall":
			# Kioske, Muelleimer, Rolltreppe, Schaufensterpuppen, Banner
			_random_floor(6, func(p, r):
				_bx(p + Vector3(0, 0.55, 0), Vector3(2.2, 1.1, 1.2), Color(0.85, 0.75, 0.6), 0.5, 0.0, true, r)
				_bx(p + Vector3(0, 2.4, 0), Vector3(2.4, 0.15, 1.4), Color(0.9, 0.3, 0.55), 0.5, 0.0, false, r)
				for lx in [-1.1, 1.1]:
					_bx(p + Vector3(lx, 1.7, 0).rotated(Vector3.UP, r), Vector3(0.08, 1.3, 0.08), Color(0.8, 0.8, 0.8), 0.3, 0.8)
				_label(["PRETZELS", "PHONE CASES", "SUNGLASSES", "CALENDARS 1998"][rng.randi() % 4], p + Vector3(0, 2.6, 0), r, Color(1, 1, 1), 48, true))
			_random_floor(10, func(p, r):
				var m := MeshInstance3D.new()
				m.mesh = FigureLib.cyl(0.28, 0.25, 0.9)
				m.material_override = _plain(Color(0.3, 0.3, 0.32), 0.4, 0.7)
				m.position = p + Vector3(0, 0.45, 0)
				add_child(m))
			_random_floor(6, func(p, r):
				_static_figure("mannequin", p, r, true), true)
			_random_floor(2, func(p, r):
				var esc := _bx(p + Vector3(0, 2.0, 0), Vector3(1.6, 0.3, 8.0), Color(0.6, 0.6, 0.62), 0.3, 0.8, false, r)
				esc.rotate_object_local(Vector3.RIGHT, 0.5)
				_bx(p + Vector3(0, 2.6, 0), Vector3(1.8, 0.05, 8.2), Color(0.1, 0.1, 0.1), 0.2, 0.0, false, r).rotate_object_local(Vector3.RIGHT, 0.5))
			_on_wall(6, func(p, r, d):
				_label(["SALE", "50% OFF", "CLOSING DOWN", "EVERYTHING MUST GO"][rng.randi() % 4], p + Vector3(0, 4.6, 0) - d * 0.05, r, Color(1, 0.3, 0.5), 120, true))
		"office":
			# Grossraumbuero: Schreibtische mit Roehrenmonitoren, Trennwaende, Wasserspender
			var desk_c := Color(0.55, 0.5, 0.42)
			_random_floor(26, func(p, r):
				_bx(p + Vector3(0, 0.74, 0), Vector3(1.4, 0.05, 0.75), desk_c, 0.6, 0.0, true, r)
				for lx in [-0.65, 0.65]:
					_bx(p + Vector3(lx, 0.37, 0).rotated(Vector3.UP, r), Vector3(0.05, 0.74, 0.7), desk_c.darkened(0.3), 0.6)
				var mon := _bx(p + Vector3(0, 1.0, 0.1).rotated(Vector3.UP, r), Vector3(0.45, 0.4, 0.4), Color(0.75, 0.73, 0.65), 0.5, 0.0, false, r)
				var scr := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.36, 0.28)
				scr.mesh = qm
				scr.material_override = _emit(Color(0.4, 0.9, 0.5) if rng.randf() < 0.6 else Color(0.2, 0.3, 0.9), 0.9)
				scr.position = Vector3(0, 0.02, -0.205)
				scr.rotation.y = PI
				mon.add_child(scr)
				_bx(p + Vector3(0, 1.1, 0.75).rotated(Vector3.UP, r), Vector3(1.6, 1.4, 0.06), Color(0.45, 0.48, 0.5), 0.9, 0.0, true, r))
			_random_floor(5, func(p, r):
				_bx(p + Vector3(0, 0.5, 0), Vector3(0.4, 1.0, 0.4), Color(0.9, 0.9, 0.88), 0.4, 0.0, true)
				var jug := MeshInstance3D.new()
				jug.mesh = FigureLib.cyl(0.15, 0.15, 0.45)
				var jm := _plain(Color(0.5, 0.75, 1.0, 0.5), 0.1)
				jm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				jug.material_override = jm
				jug.position = p + Vector3(0, 1.25, 0)
				add_child(jug))
			_on_wall(8, func(p, r, d):
				_label(["MEMO: ALL FILES MUST BE DELETED", "DO NOT REMEMBER", "QUOTA: 10,000 / DAY", "EMPLOYEE OF THE MONTH: ECHO", "EXIT ->", "ROOM 404"][rng.randi() % 6], p + Vector3(0, 1.8, 0) - d * 0.05, r, Color(0.15, 0.12, 0.05), 40))
		"school":
			# Rucksaecke auf dem Boden, Vitrine, Uhren, Kinderzeichnungen
			_random_floor(14, func(p, r):
				_bx(p + Vector3(rng.randf_range(-1, 1), 0.18, rng.randf_range(-1, 1)), Vector3(0.32, 0.36, 0.16), [Color(0.7, 0.2, 0.2), Color(0.2, 0.35, 0.65), Color(0.85, 0.65, 0.15)][rng.randi() % 3], 0.85, 0.0, false, r), false)
			_on_wall(6, func(p, r, d):
				var clk := MeshInstance3D.new()
				clk.mesh = FigureLib.cyl(0.3, 0.3, 0.05)
				clk.material_override = _plain(Color(0.95, 0.95, 0.9), 0.4)
				clk.position = p + Vector3(0, 3.1, 0) - d * 0.03
				clk.rotation = Vector3(PI / 2.0, r, 0)
				add_child(clk)
				_label("4:40", p + Vector3(0, 3.1, 0) - d * 0.07, r, Color(0.1, 0.1, 0.1), 40))
			_on_wall(12, func(p, r, d):
				var pic := _bx(p + Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(1.4, 2.2), 0) - d * 0.02, Vector3(0.5, 0.4, 0.01), Color(0.95, 0.93, 0.85), 0.9, 0.0, false, r)
				_label(["me + Echo", "my family", "Echo is my robot", "MOM", "summer", "wait for me"][rng.randi() % 6], pic.position - d * 0.02, r, Color(0.2, 0.3, 0.8), 28))
			_random_floor(2, func(p, r):
				_bx(p + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 0.6), Color(0.45, 0.3, 0.2), 0.6, 0.0, true, r)
				for k in 3:
					var tr := MeshInstance3D.new()
					tr.mesh = FigureLib.cyl(0.05, 0.12, 0.35)
					tr.material_override = _plain(Color(0.85, 0.7, 0.2), 0.2, 0.9)
					tr.position = p + Vector3(-0.6 + k * 0.6, 2.2, 0).rotated(Vector3.UP, r)
					add_child(tr))
