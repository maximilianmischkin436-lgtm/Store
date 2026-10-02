class_name LiminalLevelBuilder
extends Node3D
## Builds 3D geometry from a LiminalLevelGen layout.
## Merged wall strips with collision, rounded corners (one MultiMesh), windows with glass,
## an outside yard with open sky, automatic swing doors, bottomless pits, side-room furniture
## and soft floor arrows that guide the player along the main path.
##
## Signals:  fell_into_pit(body)  – something entered a pit;  reached_exit(body) – the exit was touched.

signal fell_into_pit(body: Node3D)
signal reached_exit(body: Node3D)

@export var cell := 3.0
@export var wall_height := 4.0
@export var wall_material: Material
@export var floor_material: Material
@export var ceiling_material: Material
@export var round_corners := true
@export var guide_arrows := true
@export var furniture := true
@export var door_color := Color(0.55, 0.35, 0.22)

var grid: Array = []
var w := 0
var h := 0
var start_position := Vector3.ZERO
var exit_position := Vector3.ZERO
var side_rooms: Array = []       # [{pos, dir}]
var seats: Array = []            # [{pos, yaw}]  free chairs, e.g. for seated NPCs
var _doors: Array = []

func cell_center(c: Vector2i) -> Vector3:
	return Vector3(c.x * cell + cell / 2.0, 0.0, c.y * cell + cell / 2.0)

func clear() -> void:
	for c in get_children():
		c.queue_free()
	grid = []
	side_rooms = []
	seats = []
	_doors = []

func build(rows: Array) -> void:
	clear()
	_defaults()
	h = rows.size()
	w = rows[0].length()
	var pits: Array = []
	var door_cells: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			var ch: String = rows[y][x]
			match ch:
				"P":
					start_position = cell_center(Vector2i(x, y)); ch = "."
				"E":
					exit_position = cell_center(Vector2i(x, y)); ch = "."
				"o":
					door_cells.append(Vector2i(x, y)); ch = "."
				"k", "K":
					side_rooms.append({"pos": cell_center(Vector2i(x, y)), "dir": 1 if ch == "k" else -1}); ch = "."
				"V":
					pits.append(Vector2i(x, y))
			row.append(ch)
		grid.append(row)
	_build_floor_and_ceiling()
	_build_walls()
	if round_corners:
		_build_round_corners()
	for c in pits:
		_pit(c)
	if not pits.is_empty():
		_pit_area(pits)
	for c in door_cells:
		_swing_door(c)
	if _has("Y"):
		_build_yard()
	if furniture:
		for r in side_rooms:
			_furnish(r.pos, r.dir)
	if guide_arrows:
		_arrows()
	_exit_door()
	_lights()

func _defaults() -> void:
	if wall_material == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.86, 0.82, 0.72)
		wall_material = m
	if floor_material == null:
		var f := StandardMaterial3D.new()
		f.albedo_color = Color(0.55, 0.5, 0.45)
		floor_material = f
	if ceiling_material == null:
		var c := StandardMaterial3D.new()
		c.albedo_color = Color(0.9, 0.9, 0.86)
		ceiling_material = c

func _has(c: String) -> bool:
	for row in grid:
		if row.has(c):
			return true
	return false

func is_solid(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return true
	return grid[c.y][c.x] != "."

func _box(pos: Vector3, size: Vector3, m: Material, collide: bool) -> Node3D:
	var node: Node3D = StaticBody3D.new() if collide else Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	node.add_child(mi)
	if collide:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	node.position = pos
	add_child(node)
	return node

func _plain(col: Color, rough: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m

func _emit(col: Color, e: float) -> StandardMaterial3D:
	var m := _plain(col)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = e
	return m

func _build_floor_and_ceiling() -> void:
	for y in h:
		var x := 0
		while x < w:
			if grid[y][x] == "V":
				x += 1
				continue
			var s := x
			while x < w and grid[y][x] != "V":
				x += 1
			_box(Vector3((s + x) * cell / 2.0, -0.25, y * cell + cell / 2.0), Vector3((x - s) * cell, 0.5, cell), floor_material, true)
		x = 0
		while x < w:
			if grid[y][x] == "Y":
				x += 1
				continue
			var s2 := x
			while x < w and grid[y][x] != "Y":
				x += 1
			_box(Vector3((s2 + x) * cell / 2.0, wall_height + 0.25, y * cell + cell / 2.0), Vector3((x - s2) * cell, 0.5, cell), ceiling_material, true)

func _edge(x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var n: Vector2i = Vector2i(x, y) + d
		if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and grid[n.y][n.x] != "#":
			return true
	return false

func _build_walls() -> void:
	var trim := _plain(Color(0.3, 0.27, 0.24), 0.5)
	for y in h:
		var x := 0
		while x < w:
			if grid[y][x] == "#" and _edge(x, y):
				var s := x
				while x < w and grid[y][x] == "#" and _edge(x, y):
					x += 1
				var ln := (x - s) * cell
				var cx := s * cell + ln / 2.0
				var cz := y * cell + cell / 2.0
				_box(Vector3(cx, wall_height / 2.0, cz), Vector3(ln, wall_height, cell), wall_material, true)
				_box(Vector3(cx, 0.1, cz), Vector3(ln + 0.04, 0.2, cell + 0.04), trim, false)
			else:
				if grid[y][x] == "W":
					_window(Vector2i(x, y))
				x += 1

func _build_round_corners() -> void:
	var pts: Array = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var n := int(grid[y - 1][x - 1] == "#") + int(grid[y - 1][x] == "#") + int(grid[y][x - 1] == "#") + int(grid[y][x] == "#")
			if n == 1 or n == 3:
				pts.append(Vector3(x * cell, wall_height / 2.0, y * cell))
	if pts.is_empty():
		return
	var cm := CylinderMesh.new()
	cm.top_radius = cell * 0.15
	cm.bottom_radius = cell * 0.15
	cm.height = wall_height
	cm.radial_segments = 16
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = wall_material
	add_child(mmi)

func _window(c: Vector2i) -> void:
	var p := cell_center(c)
	var sill := 1.0
	var top := minf(2.6, wall_height - 0.5)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(cell, wall_height, 0.4)
	cs.shape = bs
	body.add_child(cs)
	body.position = p + Vector3(0, wall_height / 2.0, 0)
	add_child(body)
	_box(p + Vector3(0, sill / 2.0, 0), Vector3(cell, sill, 0.4), wall_material, false)
	_box(p + Vector3(0, (top + wall_height) / 2.0, 0), Vector3(cell, wall_height - top, 0.4), wall_material, false)
	var frame := _plain(Color(0.88, 0.88, 0.85), 0.4)
	_box(p + Vector3(0, sill, 0), Vector3(cell, 0.08, 0.5), frame, false)
	for k in [-1, 0, 1]:
		_box(p + Vector3(k * cell / 2.0, (sill + top) / 2.0, 0), Vector3(0.08, top - sill, 0.42), frame, false)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.75, 0.85, 0.95, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic_specular = 1.0
	_box(p + Vector3(0, (sill + top) / 2.0, 0), Vector3(cell, top - sill, 0.03), glass, false)

func _build_yard() -> void:
	var asphalt := _plain(Color(0.36, 0.35, 0.37), 0.95)
	var grass := _plain(Color(0.3, 0.5, 0.22), 1.0)
	var trunk := _plain(Color(0.4, 0.28, 0.18), 0.9)
	var leaf := _plain(Color(0.28, 0.48, 0.2), 0.9)
	for y in h:
		var x := 0
		while x < w:
			if grid[y][x] != "Y":
				x += 1
				continue
			var s := x
			while x < w and grid[y][x] == "Y":
				x += 1
			_box(Vector3((s + x) * cell / 2.0, 0.02, y * cell + cell / 2.0), Vector3((x - s) * cell, 0.04, cell), grass if (y < 3 or y > h - 4) else asphalt, false)
			if y % 4 == 1:
				for tx in range(s + 1, x, 3):
					var tp := cell_center(Vector2i(tx, y))
					_box(tp + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3), trunk, false)
					var cr := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = 1.6
					sm.height = 3.0
					cr.mesh = sm
					cr.material_override = leaf
					cr.position = tp + Vector3(0, 4.0, 0)
					add_child(cr)

func _pit(c: Vector2i) -> void:
	var p := cell_center(c)
	var tile := _plain(Color(0.3, 0.6, 0.7))
	tile.cull_mode = BaseMaterial3D.CULL_FRONT
	var deep := _plain(Color(0.02, 0.08, 0.14), 0.2)
	deep.cull_mode = BaseMaterial3D.CULL_FRONT
	_box(p + Vector3(0, -2.0, 0), Vector3(cell, 4.0, cell), tile, false)
	_box(p + Vector3(0, -24.0, 0), Vector3(cell, 40.0, cell), deep, false)
	var surf := _plain(Color(0.02, 0.12, 0.22, 0.35), 0.05)
	surf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box(p + Vector3(0, 0.08, 0), Vector3(cell, 0.02, cell), surf, false)

func _pit_area(pits: Array) -> void:
	var area := Area3D.new()
	for c in pits:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(cell * 0.9, 2.0, cell * 0.9)
		cs.shape = bs
		cs.position = cell_center(c) + Vector3(0, -3.0, 0)
		area.add_child(cs)
	area.body_entered.connect(func(b): fell_into_pit.emit(b))
	add_child(area)

func _swing_door(c: Vector2i) -> void:
	var p := cell_center(c)
	var horiz: bool = grid[c.y][c.x - 1] == "#" or grid[c.y][c.x + 1] == "#"
	var dw := cell * 0.8
	var hinge := Node3D.new()
	hinge.position = p + (Vector3(-dw / 2.0, 0, 0) if horiz else Vector3(0, 0, -dw / 2.0))
	add_child(hinge)
	var hgt := minf(2.3, wall_height - 0.3)
	var panel := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(dw, hgt, 0.08) if horiz else Vector3(0.08, hgt, dw)
	panel.mesh = bm
	panel.material_override = _plain(door_color, 0.6)
	panel.position = Vector3(dw / 2.0, hgt / 2.0, 0) if horiz else Vector3(0, hgt / 2.0, dw / 2.0)
	hinge.add_child(panel)
	var win := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(0.35, 0.5, 0.1) if horiz else Vector3(0.1, 0.5, 0.35)
	win.mesh = wm
	win.material_override = _emit(Color(0.9, 0.85, 0.7), 0.4)
	win.position = panel.position + Vector3(0, 0.45, 0)
	hinge.add_child(win)
	_box(p + Vector3(0, hgt + (wall_height - hgt) / 2.0, 0), Vector3(cell, wall_height - hgt, 0.4) if horiz else Vector3(0.4, wall_height - hgt, cell), wall_material, false)
	_doors.append({"hinge": hinge, "pos": p, "open": 0.0})

## Doors swing open when any node of the group "door_openers" (player, NPCs) comes close.
func _process(delta: float) -> void:
	if _doors.is_empty():
		return
	var who: Array = []
	for n in get_tree().get_nodes_in_group("door_openers"):
		who.append((n as Node3D).global_position)
	for d in _doors:
		var near := false
		for q in who:
			if (q as Vector3).distance_squared_to(d.pos) < 5.0:
				near = true
				break
		d.open = move_toward(d.open, 1.0 if near else 0.0, delta * 3.0)
		d.hinge.rotation.y = -d.open * 1.6

func _desk(p: Vector3, yaw: float) -> void:
	var top := _box(p + Vector3(0, 0.74, 0), Vector3(1.1, 0.05, 0.6), _plain(Color(0.75, 0.6, 0.42)), true)
	top.rotation.y = yaw
	for sx in [-0.5, 0.5]:
		for sz in [-0.25, 0.25]:
			_box(p + Vector3(sx, 0.37, sz).rotated(Vector3.UP, yaw), Vector3(0.05, 0.74, 0.05), _plain(Color(0.3, 0.3, 0.32), 0.4), false)

func _chair(p: Vector3, yaw: float) -> void:
	var col := Color(0.35, 0.45, 0.6)
	var seat := _box(p + Vector3(0, 0.45, 0), Vector3(0.45, 0.05, 0.45), _plain(col), false)
	seat.rotation.y = yaw
	var back := _box(p + Vector3(0, 0.75, 0.2).rotated(Vector3.UP, yaw), Vector3(0.45, 0.55, 0.05), _plain(col), false)
	back.rotation.y = yaw

func _furnish(c: Vector3, dir: int) -> void:
	# a small classroom: board on the left wall, desks facing it
	var cc := Vector2i(floori(c.x / cell), floori(c.z / cell))
	var x0 := cc.x
	while x0 > 0 and grid[cc.y][x0 - 1] == ".":
		x0 -= 1
	var x1 := cc.x
	while x1 < w - 1 and grid[cc.y][x1 + 1] == ".":
		x1 += 1
	var left := x0 * cell
	var right := (x1 + 1) * cell
	var board := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.0, 1.3)
	board.mesh = qm
	board.material_override = _plain(Color(0.1, 0.2, 0.15), 0.9)
	board.position = Vector3(left + 0.06, 1.8, c.z)
	board.rotation.y = PI / 2.0
	add_child(board)
	var x := left + 3.2
	while x < right - 1.3:
		for row in [-1, 0, 1]:
			var dp := Vector3(x, 0, c.z + row * 1.7)
			_desk(dp, PI / 2.0)
			_chair(dp + Vector3(0.75, 0, 0), PI / 2.0)
			seats.append({"pos": dp + Vector3(0.75, 0, 0), "yaw": PI / 2.0})
		x += 2.0

func _arrows() -> void:
	var m := _emit(Color(1.0, 0.95, 0.8), 0.6)
	for x in range(6, w - 4, 6):
		if grid[14][x] != "." or grid[15][x] != ".":
			continue
		var p := Vector3(x * cell + cell / 2.0, 0.03, 15.0 * cell)
		for sgn in [-1, 1]:
			var bar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.7, 0.01, 0.08)
			bar.mesh = bm
			bar.material_override = m
			bar.position = p + Vector3(-0.22, 0, sgn * 0.22)
			bar.rotation.y = sgn * 0.75
			add_child(bar)

func _exit_door() -> void:
	var d := _box(exit_position + Vector3(0, 1.2, 0), Vector3(0.3, 2.4, 1.6), _emit(Color(1.0, 0.95, 0.8), 2.5), false)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.5, 2.5, 2.0)
	cs.shape = bs
	area.add_child(cs)
	area.position = exit_position + Vector3(0, 1.2, 0)
	area.body_entered.connect(func(b): reached_exit.emit(b))
	add_child(area)

func _lights() -> void:
	var lamp := _emit(Color(1.0, 0.96, 0.85), 2.5)
	var n := 0
	for y in range(1, h, 4):
		for x in range(1, w, 4):
			if grid[y][x] != ".":
				continue
			var p := cell_center(Vector2i(x, y)) + Vector3(0, wall_height - 0.03, 0)
			_box(p, Vector3(1.6, 0.05, 0.6), lamp, false)
			n += 1
			if n % 3 == 0:
				var o := OmniLight3D.new()
				o.light_color = Color(1.0, 0.96, 0.85)
				o.light_energy = 0.8
				o.omni_range = 9.0
				o.position = p - Vector3(0, 0.4, 0)
				add_child(o)
