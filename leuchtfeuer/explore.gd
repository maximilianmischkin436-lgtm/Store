extends Control
## Erkundung von Höhlen und Bunkern: Raum für Raum, mit begrenzter Atemluft.

signal finished(result: Dictionary)

const W := 6
const H := 4
const CELL := Vector2(132, 116)
const ORIGIN := Vector2(50, 130)

const NOTES_BUNKER := [
	"Tagebuch, Tag 12: Die Lüftung saugt den Nebel herein. Wir haben sie zugeschweißt.",
	"Dienstanweisung 7: Kein Personal verlässt Sektor C. Keine Ausnahmen. Auch keine Kinder.",
	"Auf einen Spind gekritzelt: \"Mama, ich bin zum Turm gegangen. Da ist Licht.\"",
	"Funkprotokoll: ...Leuchtfeuer Nord meldet Überlebende... wiederhole... Licht hält sie fern...",
	"Laborbericht: Die Sporen meiden Wellenlängen über 580 nm. Licht ist keine Metapher.",
]
const NOTES_CAVE := [
	"In die Wand geritzt: DAS LICHT LÜGT NICHT.",
	"Kinderzeichnungen an der Felswand. Ein Turm. Viele Strichmenschen. Kein Nebel.",
	"Ein Lager. Asche, noch warm. Jemand war vor Kurzem hier.",
	"Die Pilze hier wachsen in Kreisen. Als würden sie sich um etwas versammeln.",
]

var main: Node
var kind := "bunker"
var rooms := {}
var cur := Vector2i.ZERO
var start := Vector2i.ZERO
var air := 10
var air_max := 10
var team := 4
var team0 := 4
var crowbar := false
var loot := {"oil": 0, "scrap": 0, "food": 0, "know": 0}
var people := 0
var steps := 0
var lines: Array = []
var done := false
var rng := RandomNumberGenerator.new()
var font: Font
var ret_btn: Button
var t := 0.0

func setup(k: String, seed_: int, air0: int, team_n: int, can_break: bool) -> void:
	kind = k
	rng.seed = seed_
	air = air0
	air_max = air0
	team = team_n
	team0 = team_n
	crowbar = can_break
	font = ThemeDB.fallback_font
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_generate()
	ret_btn = Button.new()
	ret_btn.position = Vector2(860, 640)
	ret_btn.custom_minimum_size = Vector2(380, 48)
	ret_btn.pressed.connect(_try_return)
	add_child(ret_btn)
	_log("Das Team steigt hinab. Masken dicht. Atemluft für %d Räume." % air)
	_update_btn()

func _generate() -> void:
	start = Vector2i(0, rng.randi_range(0, H - 1))
	for x in W:
		for y in H:
			rooms[Vector2i(x, y)] = {"t": "empty", "seen": false, "done": false, "links": []}
	# Labyrinth: zufälliger Spannbaum + ein paar Querverbindungen
	var stack := [start]
	var vis := {start: true}
	while stack.size() > 0:
		var c: Vector2i = stack.back()
		var opts := []
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if rooms.has(n) and not vis.has(n):
				opts.append(n)
		if opts.is_empty():
			stack.pop_back()
			continue
		var n2: Vector2i = opts[rng.randi() % opts.size()]
		_link(c, n2)
		vis[n2] = true
		stack.append(n2)
	for i in 4:
		var a := Vector2i(rng.randi_range(0, W - 2), rng.randi_range(0, H - 1))
		_link(a, a + Vector2i.RIGHT)
	# Raumtypen
	var pool: Array
	if kind == "bunker":
		pool = ["loot", "loot", "know", "know", "survivor", "spores", "creature", "note", "note", "tank", "locked", "locked", "empty", "empty", "loot", "know"]
	else:
		pool = ["loot", "food", "food", "know", "spores", "spores", "creature", "creature", "note", "tank", "survivor", "empty", "empty", "food", "loot"]
	var far := start
	var dist := _bfs(start, true)
	for k in dist:
		if dist[k] > dist[far]:
			far = k
	for k in rooms:
		if k == start:
			rooms[k].t = "entry"
		elif k == far:
			rooms[k].t = "vault"
		else:
			rooms[k].t = pool[rng.randi() % pool.size()]
	rooms[start].seen = true
	rooms[start].done = true
	cur = start
	_reveal()

func _link(a: Vector2i, b: Vector2i) -> void:
	if not b in rooms[a].links:
		rooms[a].links.append(b)
		rooms[b].links.append(a)

func _bfs(from: Vector2i, all: bool) -> Dictionary:
	var d := {from: 0}
	var q := [from]
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		for n in rooms[c].links:
			if not d.has(n) and (all or rooms[n].done):
				d[n] = d[c] + 1
				q.append(n)
	return d

func _reveal() -> void:
	for n in rooms[cur].links:
		rooms[n].seen = true

func _rect(c: Vector2i) -> Rect2:
	return Rect2(ORIGIN + Vector2(c) * CELL, CELL - Vector2(22, 22))

func _gui_input(e: InputEvent) -> void:
	if done:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for c in rooms[cur].links:
			if _rect(c).has_point(e.position):
				move_to(c)
				return

func move_to(c: Vector2i) -> void:
	var r: Dictionary = rooms[c]
	if r.t == "locked" and not r.done:
		if not crowbar:
			_log("Eine verriegelte Stahltür. Ohne Brecheisen kein Durchkommen.")
			return
		_log("Mit dem Brecheisen aufgestemmt. Dahinter: ein unberührtes Lager.")
		r.t = "vaultlite"
	air -= 1
	steps += 1
	cur = c
	if not r.done:
		r.done = true
		_event(r)
	_reveal()
	if air <= 0 and cur != start:
		_log("Die Filter sind verbraucht. Die Funkgeräte verstummen einer nach dem anderen.")
		_finish(false)
	_update_btn()

func _event(r: Dictionary) -> void:
	match r.t:
		"empty":
			_log(["Leerer Raum. Staub und Stille.", "Umgestürzte Möbel. Nichts Brauchbares.", "Tropfendes Wasser. Sonst nichts."][rng.randi() % 3])
		"loot":
			var k: String = ["oil", "scrap", "scrap"][rng.randi() % 3]
			var n := rng.randi_range(15, 30)
			loot[k] += n
			_log("Vorräte gefunden: +%d %s." % [n, {"oil": "Öl", "scrap": "Schrott"}[k]])
		"food":
			var n := rng.randi_range(12, 25)
			loot.food += n
			_log("Essbare Pilze, sauber genug: +%d Nahrung." % n)
		"know":
			var n := rng.randi_range(10, 20)
			loot.know += n
			_log("Aufzeichnungen und Baupläne: +%d Wissen." % n)
		"survivor":
			var n := rng.randi_range(2, 5) if kind == "bunker" else rng.randi_range(1, 3)
			people += n
			_log("%d Überlebende hinter einer Barrikade! Sie kommen mit." % n)
		"spores":
			air -= 2
			_log("Eine Sporenwolke! Die Filter arbeiten schwer: -2 Atemluft.")
		"creature":
			if rng.randf() < 0.45:
				_log("Etwas Wucherndes bewegt sich in der Ecke. Das Team weicht leise zurück.")
			else:
				team -= 1
				_log("Ein Wucherer! Ein Teammitglied wird in die Dunkelheit gezogen.")
				if team <= 0:
					_finish(false)
		"note":
			var notes: Array = NOTES_BUNKER if kind == "bunker" else NOTES_CAVE
			_log("[Notiz] " + notes[rng.randi() % notes.size()])
			loot.know += 4
		"tank":
			air = mini(air + 3, air_max + 3)
			_log("Volle Filterpatronen! +3 Atemluft.")
		"vault", "vaultlite":
			var big: bool = r.t == "vault"
			loot.oil += 40 if big else 20
			loot.scrap += 40 if big else 25
			loot.know += 25 if big else 10
			_log("%s: Öl, Schrott und Pläne!" % ("DER HAUPTRAUM" if big else "Ein Lager"))

func _return_dist() -> int:
	var d := _bfs(start, false)
	var back := _bfs(cur, false)
	return back.get(start, d.get(cur, 99))

func _update_btn() -> void:
	if done:
		return
	var d := _return_dist()
	ret_btn.text = "Zurückkehren (braucht %d Atemluft)" % d
	ret_btn.disabled = d > air

func _try_return() -> void:
	var d := _return_dist()
	if d > air:
		return
	steps += d
	_log("Das Team kehrt zurück ins Licht.")
	_finish(true)

func _finish(ok: bool) -> void:
	done = true
	var res := {"ok": ok, "loot": loot if ok else {}, "people": people if ok else 0,
		"lost": team0 - (team if ok else 0), "hours": steps * 2}
	ret_btn.text = "Weiter"
	ret_btn.disabled = false
	ret_btn.pressed.disconnect(_try_return)
	ret_btn.pressed.connect(func(): finished.emit(res))
	if main and main.autotest:
		finished.emit(res)

func auto_run() -> void:
	# Testbot: erkundet bis die Luft knapp wird
	var guard := 0
	while not done:
		guard += 1
		if _return_dist() + 2 >= air or guard > 60:
			if _return_dist() <= air: _try_return()
			else: _finish(false)
			break
		var opts := []
		for c in rooms[cur].links:
			if not rooms[c].done and (rooms[c].t != "locked" or crowbar):
				opts.append(c)
		if opts.is_empty():
			for c in rooms[cur].links:
				if rooms[c].t != "locked" or rooms[c].done:
					opts.append(c)
		if opts.is_empty():
			_try_return()
			break
		move_to(opts[rng.randi() % opts.size()])

func _log(s: String) -> void:
	lines.push_front(s)
	if lines.size() > 9:
		lines.pop_back()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var bunker := kind == "bunker"
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.06, 0.97) if bunker else Color(0.06, 0.04, 0.07, 0.97))
	draw_string(font, Vector2(60, 60), ("ERKUNDUNG: VERLASSENER BUNKER" if bunker else "ERKUNDUNG: PILZHÖHLE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.8, 0.45))
	draw_string(font, Vector2(60, 92), "Klicke auf einen angrenzenden Raum. Jeder Schritt kostet Atemluft.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.8, 0.75))
	# Gänge
	for c in rooms:
		for n in rooms[c].links:
			if (rooms[c].seen and rooms[n].seen) and (rooms[c].done or rooms[n].done):
				var a := _rect(c).get_center()
				var b := _rect(n).get_center()
				draw_line(a, b, Color(0.3, 0.3, 0.28) if bunker else Color(0.3, 0.22, 0.32), 14)
	# Räume
	for c in rooms:
		var r: Dictionary = rooms[c]
		var rc := _rect(c)
		if not r.seen:
			continue
		var col: Color
		if bunker:
			col = Color(0.32, 0.33, 0.32) if r.done else Color(0.16, 0.17, 0.17)
		else:
			col = Color(0.3, 0.22, 0.33) if r.done else Color(0.14, 0.11, 0.16)
		var reach: bool = c in rooms[cur].links and not done
		if reach:
			col = col.lightened(0.15 + 0.08 * sin(t * 4))
		if bunker:
			draw_rect(rc, col)
			draw_rect(rc, col.darkened(0.4), false, 3)
			if r.done:
				for k in 4:
					draw_line(rc.position + Vector2(8 + k * 12, rc.size.y - 6), rc.position + Vector2(14 + k * 12, rc.size.y - 12), Color(0.85, 0.7, 0.1), 3)
		else:
			var pts := PackedVector2Array()
			for k in 14:
				var a := k / 14.0 * TAU
				var rad := Vector2(rc.size.x * 0.5, rc.size.y * 0.5) * (0.88 + 0.12 * sin(a * 3 + c.x * 2.1 + c.y))
				pts.append(rc.get_center() + Vector2(cos(a) * rad.x, sin(a) * rad.y))
			draw_colored_polygon(pts, col)
			if r.done:
				for k in 3:
					draw_circle(rc.position + Vector2(14 + k * 9, rc.size.y - 12), 3, Color(0.5, 0.9, 0.8, 0.8))
		var label := "?"
		if r.done:
			label = {"entry": "Eingang", "empty": "leer", "loot": "Vorrat", "food": "Pilze", "know": "Pläne", "survivor": "Menschen",
				"spores": "Sporen", "creature": "Wucherer", "note": "Notiz", "tank": "Filter", "vault": "Hauptraum", "vaultlite": "Lager", "locked": "Tür"}[r.t]
		elif r.t == "locked":
			label = "Stahltür"
		draw_string(font, rc.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.9, 0.8))
	# Team in Schutzanzügen
	var cc := _rect(cur).get_center()
	for i in team:
		var p := cc + Vector2(-24 + i * 14, 18) + Vector2(0, sin(t * 3 + i) * 1.0)
		draw_suit(self, p, 1.4, t + i, true)
	# Taschenlampenkegel
	draw_circle(cc, 70, Color(1, 0.9, 0.6, 0.05))
	# Seitenleiste
	var x := 860.0
	draw_string(font, Vector2(x, 140), "ATEMLUFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.8, 0.45))
	for i in maxi(air_max, air):
		draw_rect(Rect2(Vector2(x + i * 22, 150), Vector2(18, 16)), Color(0.4, 0.8, 0.9) if i < air else Color(0.15, 0.2, 0.22))
	draw_string(font, Vector2(x, 196), "TEAM %d/%d" % [team, team0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.8, 0.45))
	draw_string(font, Vector2(x, 224), "Beute: %d Öl · %d Schrott · %d Nahrung · %d Wissen · %d Menschen" % [loot.oil, loot.scrap, loot.food, loot.know, people], HORIZONTAL_ALIGNMENT_LEFT, 400, 13, Color(0.9, 0.85, 0.75))
	for i in lines.size():
		draw_multiline_string(font, Vector2(x, 262 + i * 40), "• " + lines[i], HORIZONTAL_ALIGNMENT_LEFT, 400, 13, 2, Color(0.9, 0.86, 0.75, 1.0 - i * 0.08))

## Figur im Schutzanzug mit Gasmaske – auch von main.gd benutzt.
static func draw_suit(ci: CanvasItem, p: Vector2, s: float, ph: float, moving: bool) -> void:
	var suit := Color(0.85, 0.62, 0.18)
	var dark := Color(0.2, 0.18, 0.16)
	var sw := sin(ph * 8.0) * 2.0 * s if moving else 0.0
	# Beine
	ci.draw_line(p + Vector2(-1.5, 0) * s, p + Vector2(-1.5 - sw * 0.5, 6) * s, dark, 2.2 * s)
	ci.draw_line(p + Vector2(1.5, 0) * s, p + Vector2(1.5 + sw * 0.5, 6) * s, dark, 2.2 * s)
	# Tank auf dem Rücken
	ci.draw_rect(Rect2(p + Vector2(2.5, -8) * s, Vector2(2.2, 6) * s), Color(0.5, 0.52, 0.55))
	# Anzug
	ci.draw_rect(Rect2(p + Vector2(-3, -9) * s, Vector2(6, 9.5) * s), suit)
	ci.draw_rect(Rect2(p + Vector2(-3, -3) * s, Vector2(6, 1.2) * s), suit.darkened(0.35))
	# Arme
	ci.draw_line(p + Vector2(-3, -8) * s, p + Vector2(-4.5 + sw * 0.3, -2) * s, suit.darkened(0.15), 1.8 * s)
	ci.draw_line(p + Vector2(3, -8) * s, p + Vector2(4.5 - sw * 0.3, -2) * s, suit.darkened(0.15), 1.8 * s)
	# Kopf mit Gasmaske
	ci.draw_circle(p + Vector2(0, -12) * s, 3.4 * s, suit.darkened(0.1))
	ci.draw_circle(p + Vector2(0, -12.3) * s, 2.3 * s, Color(0.12, 0.14, 0.16))
	ci.draw_circle(p + Vector2(-0.8, -13) * s, 0.8 * s, Color(0.7, 0.9, 1.0, 0.8))
	ci.draw_circle(p + Vector2(0, -9.6) * s, 1.3 * s, Color(0.3, 0.3, 0.32))
