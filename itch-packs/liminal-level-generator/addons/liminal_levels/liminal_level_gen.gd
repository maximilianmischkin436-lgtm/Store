class_name LiminalLevelGen
extends RefCounted
## Generates a liminal level layout as text rows (one character per cell).
##   #  wall          .  floor        P  player start     E  exit
##   o  doorway with a swing door    W  wall with window   Y  outside (yard, open sky, not walkable)
##   V  bottomless pit (no floor)    k / K  centre of a side room (door below / above)
##
## Styles:
##   "rooms" – a narrow corridor with classrooms / offices / wards left and right (doors, connecting doors)
##   "halls" – a chain of low halls with partitions, alcoves and dead ends
##   "pool"  – like halls, plus bottomless pools and narrow walkways
## The main path is always guaranteed to stay connected from P to E.

static func generate(seed: int = 1, style: String = "rooms", sections: int = 3, windows: bool = true, width: int = 0) -> Array:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed
	var H := 30
	var W := width if width > 0 else 14 + sections * 28
	var g: Array = []
	for y in H:
		var row: Array = []
		row.resize(W)
		row.fill("#")
		g.append(row)
	var c0 := 14
	var c1 := 15
	var rooms_style := style == "rooms"
	# start room
	_rect(g, 2, 12, 9, 17, ".")
	var x := 10
	var keep := {}
	for si in sections:
		var sw := rnd.randi_range(22, 30)
		var x1 := x
		var x2 := mini(x + sw, W - 4)
		# doorway column between sections
		_rect(g, x - 1, c0, x, c1, ".")
		if rooms_style:
			_rect(g, x1, c0, x2, c1, ".")
			for side in [-1, 1]:
				var rx := x1
				while rx + 3 <= x2:
					var rw := rnd.randi_range(3, 5)
					if rx + rw - 1 > x2:
						rw = x2 - rx + 1
					if rw < 3:
						break
					var ry1: int = c0 - 5 if side < 0 else c1 + 2
					var ry2: int = c0 - 2 if side < 0 else c1 + 5
					var wall_y: int = c0 - 1 if side < 0 else c1 + 1
					_rect(g, rx, ry1, rx + rw - 1, ry2, ".")
					g[wall_y][rx + rnd.randi_range(0, rw - 1)] = "o"
					if rx > x1 + 1 and rnd.randf() < 0.6:
						g[rnd.randi_range(ry1, ry2)][rx - 1] = "o"
					g[(ry1 + ry2) / 2][rx + rw / 2] = "k" if side < 0 else "K"
					if windows:
						var oy: int = ry1 - 1 if side < 0 else ry2 + 1
						for xx in range(rx, rx + rw):
							g[oy][xx] = "W"
					rx += rw + 1
			# chicanes in the corridor
			var flip := 0
			var cx := x1 + 4
			while cx < x2 - 3:
				g[c0 if flip % 2 == 0 else c1][cx] = "#"
				flip += 1
				cx += rnd.randi_range(5, 7)
		else:
			var hgt := rnd.randi_range(1, 3)
			_rect(g, x1, c0 - hgt, x2, c1 + hgt, ".")
			for _a in rnd.randi_range(1, 2):
				var ax := rnd.randi_range(x1, x2 - 6)
				var aw := rnd.randi_range(4, 7)
				if rnd.randf() < 0.5:
					_rect(g, ax, c0 - hgt - 3, mini(x2, ax + aw), c0 - hgt, ".")
				else:
					_rect(g, ax, c1 + hgt, mini(x2, ax + aw), c1 + hgt + 3, ".")
			var px := x1 + 3
			while px < x2 - 2:
				if rnd.randf() < 0.5:
					for yy in range(2, c0 - 1):
						if g[yy][px] == ".": g[yy][px] = "#"
				else:
					for yy in range(c1 + 2, H - 2):
						if g[yy][px] == ".": g[yy][px] = "#"
				px += 4
			if style == "pool":
				for _p in 5:
					var pw := rnd.randi_range(2, 4)
					var ph := rnd.randi_range(2, 3)
					var ppx := rnd.randi_range(x1 + 2, maxi(x1 + 2, x2 - pw - 1))
					var ppy: int = rnd.randi_range(2, maxi(2, c0 - ph - 1)) if rnd.randf() < 0.5 else rnd.randi_range(c1 + 2, maxi(c1 + 2, H - 3 - ph))
					for yy in range(ppy, ppy + ph):
						for xx in range(ppx, ppx + pw):
							if g[yy][xx] == "." and (yy < c0 or yy > c1):
								g[yy][xx] = "V"
				# narrow walkway: one row of the path becomes pool
				var sx := rnd.randi_range(x1 + 4, x2 - 6)
				var row_v: int = c0 if rnd.randf() < 0.5 else c1
				var other: int = c1 if row_v == c0 else c0
				var ok := true
				for xx in range(sx - 1, sx + 5):
					if g[other][xx] != ".": ok = false
				if ok:
					for xx in range(sx, sx + 4):
						g[row_v][xx] = "V"
		x = x2 + 2
	# exit room
	var ex := mini(x, W - 10)
	_rect(g, ex - 1, c0, ex, c1, ".")
	_rect(g, ex, 11, mini(ex + 6, W - 3), 18, ".")
	g[14][4] = "P"
	g[14][mini(ex + 4, W - 4)] = "E"
	if windows and rooms_style:
		for y in H:
			for xx in W:
				if g[y][xx] == "#" and (y < c0 - 6 or y > c1 + 6) and xx > 10 and xx < ex - 1:
					g[y][xx] = "Y"
	var out: Array = []
	for row in g:
		out.append("".join(PackedStringArray(row)))
	return out

static func _rect(g: Array, x1: int, y1: int, x2: int, y2: int, c: String) -> void:
	var H := g.size()
	var W: int = g[0].size()
	for y in range(maxi(2, y1), mini(H - 2, y2 + 1)):
		for x in range(maxi(2, x1), mini(W - 2, x2 + 1)):
			g[y][x] = c
