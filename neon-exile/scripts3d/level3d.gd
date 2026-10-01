extends Node3D
# Baut Kapitel 1 in 3D aus derselben Textkarte wie die 2D-Version.

const T := 3.0          # Kantenlaenge einer Kachel in Metern
const WALL_H := 9.0
var grid: Array = []
var w := 0
var h := 0
var door_nodes := {}    # Vector2i -> Node3D
var spawns: Array = []
var triggers := {}

var wall_mat := StandardMaterial3D.new()
var trim_mat := StandardMaterial3D.new()
var door_mat := StandardMaterial3D.new()
var gate_mat := StandardMaterial3D.new()

func _init() -> void:
	wall_mat.albedo_color = Color(0.13, 0.11, 0.22)
	wall_mat.roughness = 0.6
	wall_mat.metallic = 0.3
	trim_mat.albedo_color = Color.BLACK
	trim_mat.emission_enabled = true
	trim_mat.emission = Color("#7a4dff")
	trim_mat.emission_energy_multiplier = 3.0
	for pair in [[door_mat, Color("#ff2d55")], [gate_mat, Color("#ffd23d")]]:
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
			if c in ["P", "c", "d", "S", "B"]:
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
	return grid[c.y][c.x] != "." and p.y < WALL_H

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
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = load("res://scripts3d/floor.gdshader")
	var fl := _box(Vector3(w * T / 2.0, -0.25, h * T / 2.0), Vector3(w * T, 0.5, h * T), floor_mat, true)
	fl.name = "Floor"
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
				if grid[y][x] in ["D", "G"]:
					var m := door_mat if grid[y][x] == "D" else gate_mat
					door_nodes[Vector2i(x, y)] = _box(cell_center(Vector2i(x, y)) + Vector3(0, WALL_H / 2.0, 0), Vector3(T, WALL_H, T * 0.3), m, true)
				x += 1
	_decorate()
	# Farbiges Licht pro Raum fuer Stimmung
	for l in [[Vector3(8, 4, 14), "#38f5c4"], [Vector3(33, 4, 14), "#ff9f3d"], [Vector3(54, 4, 14), "#ff4d6d"], [Vector3(83, 5, 14), "#ff2d55"]]:
		var o := OmniLight3D.new()
		o.position = Vector3(l[0].x * T, l[0].y, l[0].z * T)
		o.light_color = Color(l[1])
		o.light_energy = 2.0
		o.omni_range = 45.0
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

# ---------------- Traumhafte, liminale Deko ----------------
var rng := RandomNumberGenerator.new()
var floaters: Array = []
var memories: Array = []
const MEMORY_TEXT := ["DO YOU REMEMBER?", "you were here before", "SHE CALLED YOU ECHO", "10 YEARS AGO", "wake up", "THE CITY FORGOT", "it was raining", "don't be afraid", "MIRA", "who turned off the sun?"]

func _emit_mat(col: Color, energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alpha)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _floor_cells() -> Array:
	var out: Array = []
	for y in h:
		for x in w:
			if grid[y][x] == ".":
				out.append(Vector2i(x, y))
	return out

func _frame(pos: Vector3, size: Vector2, col: Color, rot: float) -> void:
	# leuchtender Tuerrahmen, der ins Nichts fuehrt
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot
	add_child(root)
	var m := _emit_mat(col, 2.0)
	for part in [[Vector3(-size.x / 2, size.y / 2, 0), Vector3(0.12, size.y, 0.12)], [Vector3(size.x / 2, size.y / 2, 0), Vector3(0.12, size.y, 0.12)], [Vector3(0, size.y, 0), Vector3(size.x + 0.12, 0.12, 0.12)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		mi.mesh = bm
		mi.material_override = m
		mi.position = part[0]
		root.add_child(mi)
	# schwacher Schimmer im Rahmen
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	q.material_override = _emit_mat(col, 0.6, 0.12)
	q.position = Vector3(0, size.y / 2, 0)
	root.add_child(q)

func _decorate() -> void:
	rng.seed = 7
	var cells := _floor_cells()
	# 1) riesige Monolithen weit draussen im Nebel
	for i in 26:
		var a := rng.randf() * TAU
		var r := rng.randf_range(160.0, 320.0)
		var center := Vector3(w * T / 2.0, 0, h * T / 2.0)
		var hgt := rng.randf_range(60.0, 220.0)
		var wd := rng.randf_range(10.0, 30.0)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(wd, hgt, wd)
		mi.mesh = bm
		mi.material_override = wall_mat
		mi.position = center + Vector3(cos(a) * r, hgt / 2.0 - 5.0, sin(a) * r)
		mi.rotation.y = rng.randf() * TAU
		add_child(mi)
		# Fensterlichter in den Tuermen
		for k in rng.randi_range(2, 6):
			var lm := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(wd + 0.2, 0.6, 1.5)
			lm.mesh = lb
			lm.material_override = _emit_mat([Color("#ff8fd0"), Color("#8fe9ff"), Color("#ffe08f")][rng.randi() % 3], 2.5)
			lm.position = Vector3(0, rng.randf_range(-hgt / 2.0 + 8.0, hgt / 2.0 - 4.0), rng.randf_range(-wd / 3.0, wd / 3.0))
			mi.add_child(lm)
	# 2) schwebende Wuerfel und Ringe ueber den Raeumen
	for i in 40:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var n := MeshInstance3D.new()
		if rng.randf() < 0.6:
			var bm2 := BoxMesh.new()
			var s := rng.randf_range(0.6, 2.5)
			bm2.size = Vector3(s, s, s)
			n.mesh = bm2
			n.material_override = wall_mat if rng.randf() < 0.5 else _emit_mat(Color("#c9a8ff"), 0.8, 0.5)
		else:
			var tm := TorusMesh.new()
			tm.inner_radius = rng.randf_range(1.5, 3.0)
			tm.outer_radius = tm.inner_radius + 0.15
			n.mesh = tm
			n.material_override = _emit_mat(Color("#ff9bd6"), 1.5)
		n.position = cell_center(c) + Vector3(0, rng.randf_range(10.0, 22.0), 0)
		n.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)
		add_child(n)
		floaters.append({"n": n, "base": n.position.y, "spd": rng.randf_range(0.2, 0.6), "ph": rng.randf() * TAU})
	# 3) haengende Lichtpaneele, die weiches Licht nach unten werfen
	for i in 22:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var p := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(3.5, 0.08, 1.2)
		p.mesh = pm
		p.material_override = _emit_mat(Color("#fff3e0"), 3.0)
		p.position = cell_center(c) + Vector3(0, 8.0, 0)
		add_child(p)
		var cable := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.03, 12.0, 0.03)
		cable.mesh = cm
		cable.material_override = wall_mat
		cable.position = Vector3(0, 6.0, 0)
		p.add_child(cable)
		if i % 3 == 0:
			var sl := SpotLight3D.new()
			sl.light_color = Color("#ffe6d0")
			sl.light_energy = 3.0
			sl.spot_range = 14.0
			sl.spot_angle = 40.0
			sl.rotation.x = -PI / 2.0
			p.add_child(sl)
	# 4) Tuerrahmen ins Nichts
	for i in 9:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		_frame(cell_center(c), Vector2(2.2, 3.6), [Color("#8fe9ff"), Color("#ff8fd0"), Color("#ffffff")][i % 3], rng.randf() * TAU)
	# 5) Erinnerungsfetzen: schwebender Text im Nebel
	for i in MEMORY_TEXT.size():
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var lab := Label3D.new()
		lab.text = MEMORY_TEXT[i]
		lab.font_size = 96
		lab.pixel_size = 0.01
		lab.modulate = Color(1, 0.85, 0.95, 0.0)
		lab.outline_size = 0
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = false
		lab.position = cell_center(c) + Vector3(0, rng.randf_range(3.0, 6.0), 0)
		add_child(lab)
		memories.append(lab)

func dream_update(delta: float, player_pos: Vector3, t: float) -> void:
	for f in floaters:
		var n: Node3D = f.n
		n.position.y = f.base + sin(t * f.spd + f.ph) * 1.2
		n.rotate_y(delta * f.spd * 0.3)
		n.rotate_x(delta * f.spd * 0.2)
	# Erinnerungstext erscheint nur, wenn man in mittlerer Entfernung ist, und verblasst nah dran
	for lab in memories:
		var d: float = lab.global_position.distance_to(player_pos)
		var a := clampf((d - 6.0) / 6.0, 0.0, 1.0) * clampf((30.0 - d) / 10.0, 0.0, 1.0)
		lab.modulate.a = lerpf(lab.modulate.a, a * 0.55, minf(1.0, delta * 2.0))
