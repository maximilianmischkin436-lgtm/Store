extends Node2D
# Baut die Karte aus einer Textdatei. Waende werden als StaticBody2D erzeugt.

const TILE := 48
var grid: Array = []          # Array von PackedStringArray-Zeilen (als Arrays von Zeichen)
var w := 0
var h := 0
var door_bodies := {}         # Vector2i -> StaticBody2D
var spawns: Array = []        # [{"c": char, "pos": Vector2}]
var triggers := {}            # Vector2i -> String

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
	_build_bodies()
	queue_redraw()

func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)

func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))

func solid(p: Vector2) -> bool:
	var c := cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return true
	return grid[c.y][c.x] != "."

func _add_body(rect: Rect2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	b.add_child(cs)
	add_child(b)
	return b

func _build_bodies() -> void:
	for y in h:
		var x := 0
		while x < w:
			if grid[y][x] == "#":
				var start := x
				while x < w and grid[y][x] == "#":
					x += 1
				_add_body(Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
			else:
				if grid[y][x] in ["D", "G"]:
					door_bodies[Vector2i(x, y)] = _add_body(Rect2(x * TILE, y * TILE, TILE, TILE))
				x += 1

func open_doors(kind: String, max_x: float = INF) -> bool:
	var opened := false
	for c in door_bodies.keys():
		if grid[c.y][c.x] == kind and c.x * TILE < max_x:
			grid[c.y][c.x] = "."
			door_bodies[c].queue_free()
			door_bodies.erase(c)
			opened = true
	if opened:
		queue_redraw()
	return opened

func doors_of(kind: String) -> Array:
	var out: Array = []
	for c in door_bodies.keys():
		if grid[c.y][c.x] == kind:
			out.append(c)
	return out

func _draw() -> void:
	var t := TILE
	for y in h:
		for x in w:
			var c: String = grid[y][x]
			var r := Rect2(x * t, y * t, t, t)
			if c == ".":
				draw_rect(r, Color(0.05, 0.05, 0.1))
				draw_rect(r, Color(0.3, 0.3, 0.9, 0.07), false, 1.0)
			elif c == "#":
				# nur Waende mit Boden-Nachbarn zeichnen (Rand leuchtet)
				var edge := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and grid[n.y][n.x] != "#":
						edge = true
				if edge:
					draw_rect(r, Color(0.09, 0.07, 0.18))
					draw_rect(r.grow(-3), Color(0.45, 0.3, 1.0, 0.55), false, 2.0)
			elif c == "D":
				draw_rect(r, Color(1, 0.2, 0.35, 0.35))
				draw_rect(r.grow(-4), Color(1, 0.2, 0.35), false, 3.0)
			elif c == "G":
				draw_rect(r, Color(1, 0.82, 0.24, 0.3))
				draw_rect(r.grow(-4), Color(1, 0.82, 0.24), false, 3.0)
