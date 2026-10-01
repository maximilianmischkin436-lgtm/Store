extends Node3D
# Baut Kapitel 1 in 3D aus derselben Textkarte wie die 2D-Version.

const T := 3.0          # Kantenlaenge einer Kachel in Metern
const WALL_H := 5.0
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
	# Farbiges Licht pro Raum fuer Stimmung
	for l in [[Vector3(8, 4, 14), "#38f5c4"], [Vector3(33, 4, 14), "#ff9f3d"], [Vector3(54, 4, 14), "#ff4d6d"], [Vector3(83, 5, 14), "#ff2d55"]]:
		var o := OmniLight3D.new()
		o.position = Vector3(l[0].x * T, l[0].y, l[0].z * T)
		o.light_color = Color(l[1])
		o.light_energy = 3.0
		o.omni_range = 40.0
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
