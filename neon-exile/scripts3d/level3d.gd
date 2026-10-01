extends Node3D
# Baut Kapitel 1 in 3D aus derselben Textkarte wie die 2D-Version.

const T := 3.0          # Kantenlaenge einer Kachel in Metern
const WALL_H := 6.0
var grid: Array = []
var w := 0
var h := 0
var door_nodes := {}    # Vector2i -> Node3D
var spawns: Array = []
var triggers := {}

var wall_mat := ShaderMaterial.new()
var trim_mat := StandardMaterial3D.new()
var door_mat := StandardMaterial3D.new()
var gate_mat := StandardMaterial3D.new()

func _init() -> void:
	wall_mat.shader = load("res://scripts3d/tiles.gdshader")
	trim_mat.albedo_color = Color(0.8, 0.87, 0.9)
	trim_mat.roughness = 0.2
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
	var fl := _box(Vector3(w * T / 2.0, -0.25, h * T / 2.0), Vector3(w * T, 0.5, h * T), wall_mat, true)
	fl.name = "Floor"
	_build_water_and_ceiling()
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
	for l in [[Vector3(8, 4, 14), "#dff6ff"], [Vector3(33, 4, 14), "#fff4e6"], [Vector3(54, 4, 14), "#e6f0ff"], [Vector3(83, 5, 14), "#ffe0e6"]]:
		var o := OmniLight3D.new()
		o.position = Vector3(l[0].x * T, l[0].y, l[0].z * T)
		o.light_color = Color(l[1])
		o.light_energy = 0.6
		o.omni_range = 50.0
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
const MEMORY_TEXT := ["do you remember this place?", "you learned to swim here", "SHE was waiting by the edge", "it's always 4 PM here", "the water is warm", "don't run near the pool", "MIRA", "nobody comes here anymore", "wake up, ECHO"]
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
	# Erinnerungstext: dunkelblau, erscheint aus mittlerer Entfernung
	for i in MEMORY_TEXT.size():
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var lab := Label3D.new()
		lab.text = MEMORY_TEXT[i]
		lab.font_size = 80
		lab.pixel_size = 0.01
		lab.modulate = Color(0.15, 0.3, 0.45, 0.0)
		lab.outline_size = 0
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = cell_center(c) + Vector3(0, rng.randf_range(2.0, 3.5), 0)
		add_child(lab)
		memories.append(lab)

func dream_update(delta: float, player_pos: Vector3, _t: float) -> void:
	for lab in memories:
		var d: float = lab.global_position.distance_to(player_pos)
		var a := clampf((d - 5.0) / 5.0, 0.0, 1.0) * clampf((26.0 - d) / 8.0, 0.0, 1.0)
		lab.modulate.a = lerpf(lab.modulate.a, a * 0.7, minf(1.0, delta * 2.0))
