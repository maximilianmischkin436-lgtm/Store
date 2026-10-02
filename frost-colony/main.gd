extends Node2D
## LETZTE GLUT — Überlebens-Städtebau im ewigen Frost.
## Eine Kolonie um einen Kohlegenerator in einem gefrorenen Krater.

const RINGS := 5
const R0 := 46.0
const RW := 46.0
const LAST_DAY := 15
const SEC_PER_HOUR := 1.6

const B := {
	"tent":  {"n": "Zelte", "cost": {"wood": 10}, "w": 0, "house": 10, "ins": 0, "col": Color(0.78, 0.66, 0.48), "d": "Wohnraum für 10. Kaum Schutz."},
	"bunk":  {"n": "Baracke", "cost": {"wood": 25, "steel": 5}, "w": 0, "house": 10, "ins": 1, "col": Color(0.52, 0.42, 0.33), "d": "Wohnraum für 10. +1 Wärmestufe."},
	"coal":  {"n": "Kohlesammler", "cost": {"wood": 15}, "w": 10, "out": {"coal": 8.5}, "col": Color(0.18, 0.18, 0.2), "d": "10 Arbeiter. Kohle aus dem Schnee."},
	"saw":   {"n": "Sägewerk", "cost": {"wood": 10}, "w": 10, "out": {"wood": 3.5}, "col": Color(0.5, 0.33, 0.16), "d": "10 Arbeiter. Holz aus gefrorenen Bäumen."},
	"steel": {"n": "Stahlwerk", "cost": {"wood": 20}, "w": 10, "out": {"steel": 1.2}, "col": Color(0.4, 0.46, 0.56), "d": "10 Arbeiter. Stahl aus Wracks."},
	"hunt":  {"n": "Jägerhütte", "cost": {"wood": 15}, "w": 5, "out": {"raw": 2.5}, "col": Color(0.34, 0.5, 0.3), "d": "5 Arbeiter. Rohes Fleisch."},
	"cook":  {"n": "Kochhaus", "cost": {"wood": 20}, "w": 2, "cook": true, "col": Color(0.8, 0.42, 0.18), "d": "2 Arbeiter. Fleisch → Rationen."},
	"med":   {"n": "Lazarett", "cost": {"wood": 25, "steel": 5}, "w": 5, "heal": true, "ins": 1, "col": Color(0.86, 0.86, 0.9), "d": "5 Arbeiter. Heilt Kranke."},
	"hub":   {"n": "Dampfknoten", "cost": {"wood": 10, "steel": 15}, "w": 0, "hub": true, "col": Color(0.85, 0.52, 0.3), "d": "+1 Wärme in der Umgebung. 1 Kohle/h."},
}
const ORDER := ["tent", "bunk", "coal", "saw", "steel", "hunt", "cook", "med", "hub"]

const LAWS := {
	"soup":   {"n": "Suppe", "d": "Kochhaus macht 3 statt 2 Rationen. Unzufriedenheit +1/Tag."},
	"shift":  {"n": "Lange Schichten", "d": "Arbeit bis 22 Uhr. Unzufriedenheit +3/Tag."},
	"beds":   {"n": "Notbetten", "d": "Lazarette heilen doppelt so viele."},
	"grave":  {"n": "Friedhof", "d": "Tode kosten nur halb so viel Hoffnung."},
	"chapel": {"n": "Gebetsstunde", "d": "Hoffnung +3/Tag, aber jeden Abend 1h weniger Arbeit."},
}

# --- Zustand ---
var res := {"coal": 220.0, "wood": 90.0, "steel": 20.0, "raw": 30.0, "food": 120.0}
var pop := 80
var sick := 0
var hope := 55.0
var disc := 10.0
var day := 1
var hour := 8
var hour_t := 0.0
var speed := 1.0
var gen_lvl := 1     # 0 aus, 1 an, 2 Überlast
var stress := 0.0
var laws: Array = []
var law_cd := 0
var hunger_days := 0
var deaths := 0
var tiles: Array = []
var sel := "tent"
var heat_view := false
var over := ""       # "", "win", "lose"
var log_lines: Array = []
var hover := -1
var autotest := false
var rng := RandomNumberGenerator.new()

# --- UI ---
var ui: CanvasLayer
var top: Label
var info: Label
var logl: Label
var gen_btns: Array = []
var law_box: VBoxContainer
var banner: Label
var night: CanvasModulate
var snow: CPUParticles2D
var font: Font

func _ready() -> void:
	rng.seed = 7
	font = ThemeDB.fallback_font
	autotest = "--autotest" in OS.get_cmdline_user_args()
	for r in range(1, RINGS + 1):
		var n := 6 + 4 * r
		for s in n:
			var t := {"r": r, "s": s, "n": n, "type": "", "on": true, "wk": 0}
			if r >= 4 and rng.randf() < 0.18:
				t.type = "wreck"
			tiles.append(t)
	night = CanvasModulate.new()
	add_child(night)
	_make_snow()
	_make_ui()
	say("Tag 1. Die Welt ist erfroren. Der Generator ist alles, was wir haben.")
	say("Baue Zelte, Kohle und Nahrung. In %d Tagen kommt der große Sturm." % (LAST_DAY - 5))
	if autotest:
		speed = 40.0
	if "--shot" in OS.get_cmdline_user_args():
		speed = 60.0
		autotest = true
		_shot()

func center() -> Vector2:
	return Vector2(656, 354)

# ---------------- Simulation ----------------

func outside_temp() -> float:
	var t := -20.0 - (day - 1) * 2.5
	if day >= 11 and day <= 13:
		t = -70.0
	var dayh := sin((hour - 8) / 24.0 * TAU) * 4.0
	return t + dayh

func storm() -> bool:
	return day >= 11 and day <= 13

func gen_bonus(r: int) -> int:
	if gen_lvl == 0:
		return 0
	var b: int = [3, 3, 2, 1, 0][r - 1]
	if gen_lvl == 2 and r <= 4:
		b += 1
	return b

func hub_bonus(i: int) -> int:
	var t: Dictionary = tiles[i]
	var a := _ang(t)
	for j in tiles.size():
		var h: Dictionary = tiles[j]
		if h.type == "hub" and absi(h.r - t.r) <= 1:
			var d := absf(angle_difference(a, _ang(h)))
			if d < 0.75:
				return 1
	return 0

func tile_temp(i: int) -> float:
	var t: Dictionary = tiles[i]
	var ins := 0
	if t.type in B:
		ins = B[t.type].get("ins", 0)
	return outside_temp() + 10.0 * (gen_bonus(t.r) + ins + hub_bonus(i))

static func heat_cat(temp: float) -> int:
	# 0 angenehm, 1 kühl, 2 kalt, 3 sehr kalt, 4 eisig
	if temp >= -10: return 0
	if temp >= -20: return 1
	if temp >= -30: return 2
	if temp >= -40: return 3
	return 4

const CAT_NAME := ["angenehm", "kühl", "kalt", "sehr kalt", "eisig"]
const CAT_COL := [Color(0.95, 0.6, 0.25), Color(0.85, 0.75, 0.5), Color(0.55, 0.7, 0.85), Color(0.35, 0.5, 0.85), Color(0.25, 0.3, 0.7)]

func work_hours() -> Vector2i:
	var end := 22 if "shift" in laws else 18
	if "chapel" in laws:
		end -= 1
	return Vector2i(8, end)

func count(type: String) -> int:
	var c := 0
	for t in tiles:
		if t.type == type:
			c += 1
	return c

func housing() -> int:
	var h := 0
	for t in tiles:
		if t.type in B:
			h += B[t.type].get("house", 0)
	return h

func _process(delta: float) -> void:
	if over != "":
		queue_redraw()
		return
	hour_t += delta * speed
	while hour_t >= SEC_PER_HOUR and over == "":
		hour_t -= SEC_PER_HOUR
		_tick_hour()
	_update_visuals(delta)
	_update_ui()
	queue_redraw()

func _tick_hour() -> void:
	if autotest:
		_auto_build()
	hour += 1
	if hour >= 24:
		hour = 0
		_new_day()
	# Generator
	var burn := 0.0
	if gen_lvl > 0:
		burn = (4.0 + (3.0 if storm() else 0.0)) * gen_lvl + count("hub") * 1.5
		if res.coal < burn:
			gen_lvl = 0
			say("Die Kohle ist aus! Der Generator erlischt.")
			hope -= 5
		else:
			res.coal -= burn
	stress = clampf(stress + (5.0 if gen_lvl == 2 else -3.0), 0, 100)
	if stress >= 100:
		_lose("Der Generator ist unter der Überlast zerborsten.")
		return
	# Arbeit
	var healthy := pop - sick
	var wh := work_hours()
	var working := hour >= wh.x and hour < wh.y
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		t.wk = 0
		if not (t.type in B) or not t.on:
			continue
		var need: int = B[t.type].w
		var w := mini(need, healthy)
		healthy -= w
		t.wk = w
		if w == 0 or not working:
			continue
		var eff := 1.0 - heat_cat(tile_temp(i)) * 0.12
		var f := float(w) / need * eff
		var out: Dictionary = B[t.type].get("out", {})
		for k in out:
			if k == "raw" and storm():
				continue
			res[k] += out[k] * f
		if B[t.type].get("cook", false):
			var amt := minf(res.raw, 8.0 * f)
			res.raw -= amt
			res.food += amt * (3.0 if "soup" in laws else 2.0)
	# Medizin
	if sick > 0 and working:
		var cap := 0.0
		for t in tiles:
			if t.type == "med" and t.wk > 0:
				cap += 0.6 * t.wk / 5.0 * (2.0 if "beds" in laws else 1.0)
		var healed := mini(sick, int(cap + rng.randf()))
		sick -= healed
	# Krankheit durch Kälte (stündlich, geringe Rate)
	var housed := mini(pop, housing())
	var rate := 0.0
	var left := housed
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if left <= 0:
			break
		var h: int = B[t.type].get("house", 0) if t.type in B else 0
		if h == 0:
			continue
		var n := mini(h, left)
		left -= n
		rate += n * [0.0, 0.0006, 0.0015, 0.003, 0.005][heat_cat(tile_temp(i))]
	rate += (pop - housed) * [0.002, 0.003, 0.005, 0.007, 0.01][heat_cat(outside_temp())]
	var new_sick := int(rate) + (1 if rng.randf() < fmod(rate, 1.0) else 0)
	sick = mini(pop, sick + new_sick)
	if hour == 19:
		_meal()
	if hope <= 0:
		_lose("Die Hoffnung ist erloschen. Die Menschen legen sich in den Schnee.")
	elif disc >= 100:
		_lose("Aufstand! Du wirst in die Kälte verbannt.")
	elif pop <= 0:
		_lose("Niemand ist mehr übrig.")

func _meal() -> void:
	var need := float(pop)
	var eat := minf(res.food, need)
	res.food -= eat
	need -= eat
	if need > 0:
		var r := minf(res.raw, need)
		res.raw -= r
		need -= r
		if r > 0:
			sick = mini(pop, sick + int(r * 0.05))
	if need > 0.5:
		hunger_days += 1
		disc += 6
		hope -= 4
		say("%d Menschen gehen hungrig schlafen." % int(need))
		if hunger_days >= 2:
			_kill(maxi(1, int(need * 0.1)), "verhungert")
	else:
		hunger_days = 0

func _kill(n: int, why: String) -> void:
	n = mini(n, pop)
	if n <= 0:
		return
	pop -= n
	sick = mini(sick, pop)
	deaths += n
	hope -= n * (0.75 if "grave" in laws else 1.5)
	say(("1 Mensch ist %s." % why) if n == 1 else ("%d Menschen sind %s." % [n, why]))

func _new_day() -> void:
	day += 1
	if law_cd > 0:
		law_cd -= 1
	# unbehandelte Kranke
	var cap := 0
	for t in tiles:
		if t.type == "med" and t.wk > 0:
			cap += 10
	var untreated := maxi(0, sick - cap)
	if untreated > 0:
		_kill(int(untreated * 0.12 + rng.randf()), "an Erfrierungen gestorben")
	var homeless := maxi(0, pop - housing())
	disc += homeless * 0.15
	if "soup" in laws: disc += 1
	if "shift" in laws: disc += 3
	if "chapel" in laws: hope += 3
	if gen_lvl == 0: disc += 5
	if sick == 0 and homeless == 0 and hunger_days == 0:
		hope += 3
		disc -= 2
	hope = clampf(hope, 0, 100)
	disc = clampf(disc, 0, 100)
	if day == 6:
		say("Die Temperaturen fallen weiter. Späher melden einen Sturm im Norden.")
	if day == 10:
		say("MORGEN KOMMT DER STURM. Kohle horten, Häuser wärmen!")
		hope -= 5
	if day == 11:
		say("Der Sturm ist da. -70°C. Die Jäger können nicht hinaus.")
	if day == 14:
		say("Der Sturm zieht ab. Wir haben überlebt... fast.")
	if day > LAST_DAY:
		_win()
	if day % 3 == 0 and pop > 0 and day < 11:
		var n := rng.randi_range(5, 12)
		pop += n
		hope += 2
		say("%d Flüchtlinge erreichen den Krater und bitten um Wärme." % n)
	if autotest:
		print("TAG %d  pop %d sick %d hope %.0f disc %.0f coal %.0f wood %.0f steel %.0f food %.0f" % [day, pop, sick, hope, disc, res.coal, res.wood, res.steel, res.food])

func _win() -> void:
	over = "win"
	banner.text = "DIE STADT LEBT\n%d Überlebende · %d Tote\nDer Frost hat uns nicht bekommen." % [pop, deaths]
	banner.visible = true
	if autotest:
		print("RESULT WIN pop=%d deaths=%d" % [pop, deaths])
		get_tree().quit()

func _lose(why: String) -> void:
	over = "lose"
	banner.text = "DIE GLUT IST ERLOSCHEN\n" + why + "\n\nR = Neustart"
	banner.visible = true
	if autotest:
		print("RESULT LOSE day=%d %s" % [day, why])
		get_tree().quit()

# ---------------- Bauen ----------------

func can_afford(type: String) -> bool:
	var c: Dictionary = B[type].cost
	for k in c:
		if res[k] < c[k]:
			return false
	return true

func build(i: int, type: String) -> bool:
	var t: Dictionary = tiles[i]
	if t.type == "wreck":
		res.wood += 15
		res.steel += 5
		t.type = ""
		say("Wrack geplündert: +15 Holz, +5 Stahl.")
		return true
	if t.type != "" or not can_afford(type):
		return false
	var c: Dictionary = B[type].cost
	for k in c:
		res[k] -= c[k]
	t.type = type
	t.on = true
	return true

func _auto_build() -> void:
	var plan := ["coal", "hunt", "cook", "tent", "tent", "saw", "tent", "tent", "hunt", "tent", "tent", "steel",
		"med", "coal", "tent", "saw", "hunt", "bunk", "hub", "bunk", "coal", "med", "bunk", "hub", "bunk", "hunt", "bunk", "coal"]
	var have := {}
	for t in tiles:
		if t.type in B:
			have[t.type] = have.get(t.type, 0) + 1
	var seen := {}
	for p in plan:
		seen[p] = seen.get(p, 0) + 1
		if have.get(p, 0) < seen[p]:
			if not can_afford(p):
				return
			var best := -1
			for i in tiles.size():
				var tt: Dictionary = tiles[i]
				if tt.type == "wreck" and res.wood < 15:
					build(i, p)
				if tt.type == "" and (best < 0 or (tt.r < tiles[best].r) == (B[p].get("house", 0) > 0 or p == "med")):
					best = i
			if best >= 0:
				build(best, p)
			return
	if day == 2 and laws.is_empty():
		sign_law("soup")
	if day == 9 and "beds" not in laws:
		sign_law("beds")
	if storm() and stress < 40:
		gen_lvl = 2
	elif gen_lvl == 2 and stress > 70:
		gen_lvl = 1

func sign_law(k: String) -> void:
	if k in laws or law_cd > 0:
		return
	laws.append(k)
	law_cd = 2
	hope += 2
	say("Gesetz erlassen: " + LAWS[k].n)

# ---------------- Eingabe ----------------

func _ang(t: Dictionary) -> float:
	return (t.s + 0.5) / float(t.n) * TAU - PI / 2

func tile_at(p: Vector2) -> int:
	var v := p - center()
	var d := v.length()
	if d < R0:
		return -2
	var r := int((d - R0) / RW) + 1
	if r > RINGS:
		return -1
	var n := 6 + 4 * r
	var a := fposmod(v.angle() + PI / 2, TAU)
	var s := int(a / TAU * n)
	var idx := 0
	for rr in range(1, r):
		idx += 6 + 4 * rr
	return idx + s

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = tile_at(e.position)
	elif e is InputEventMouseButton and e.pressed and over == "":
		var i := tile_at(e.position)
		if i == -2 and e.button_index == MOUSE_BUTTON_LEFT:
			gen_lvl = (gen_lvl + 1) % 3
		elif i >= 0:
			if e.button_index == MOUSE_BUTTON_LEFT:
				if not build(i, sel) and tiles[i].type == "":
					say("Nicht genug Material für " + B[sel].n + ".")
			elif e.button_index == MOUSE_BUTTON_RIGHT and tiles[i].type in B:
				tiles[i].on = not tiles[i].on
	elif e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_SPACE: speed = 0.0 if speed > 0 else 1.0
			KEY_1: speed = 1.0
			KEY_2: speed = 3.0
			KEY_3: speed = 8.0
			KEY_H: heat_view = not heat_view
			KEY_R: if over != "": get_tree().reload_current_scene()

# ---------------- Darstellung ----------------

func _make_snow() -> void:
	snow = CPUParticles2D.new()
	snow.amount = 400
	snow.lifetime = 6.0
	snow.position = Vector2(640, -20)
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(760, 10)
	snow.direction = Vector2(0.3, 1)
	snow.spread = 15
	snow.gravity = Vector2(0, 20)
	snow.initial_velocity_min = 60
	snow.initial_velocity_max = 120
	snow.scale_amount_min = 1.0
	snow.scale_amount_max = 3.0
	snow.color = Color(1, 1, 1, 0.7)
	snow.preprocess = 6.0
	add_child(snow)

func _update_visuals(_d: float) -> void:
	var dayl := clampf(sin((hour + hour_t / SEC_PER_HOUR - 6) / 24.0 * TAU) * 1.4, 0, 1)
	var c := Color(0.45, 0.5, 0.7).lerp(Color(1, 1, 1), dayl)
	if storm():
		c = c.darkened(0.25)
	night.color = c
	snow.direction = Vector2(1.6 if storm() else 0.3, 1)
	snow.initial_velocity_max = 320 if storm() else 120

func _draw() -> void:
	var c := center()
	draw_circle(c, R0 + RINGS * RW + 30, Color(0.82, 0.86, 0.92))
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		var a0: float = t.s / float(t.n) * TAU - PI / 2
		var a1: float = (t.s + 1) / float(t.n) * TAU - PI / 2
		var r0: float = R0 + (t.r - 1) * RW + 2
		var r1: float = r0 + RW - 4
		var pts := PackedVector2Array()
		for k in 7:
			pts.append(c + Vector2.from_angle(lerpf(a0, a1, k / 6.0) + 0.012) * r0)
		for k in 7:
			pts.append(c + Vector2.from_angle(lerpf(a1, a0, k / 6.0) - 0.012) * r1)
		var col := Color(0.9, 0.93, 0.97)
		if heat_view:
			col = CAT_COL[heat_cat(tile_temp(i))].lerp(Color.WHITE, 0.25)
		if t.type == "wreck":
			col = col.darkened(0.35)
		elif t.type in B:
			col = B[t.type].col
			if not t.on:
				col = col.darkened(0.5)
			if heat_view:
				col = col.lerp(CAT_COL[heat_cat(tile_temp(i))], 0.5)
		if i == hover:
			col = col.lightened(0.25)
		draw_colored_polygon(pts, col)
		var mid: Vector2 = c + Vector2.from_angle((a0 + a1) * 0.5) * (r0 + r1) * 0.5
		if t.type in B:
			var lbl: String = B[t.type].n.substr(0, 4)
			draw_string(font, mid + Vector2(-16, 4), lbl, HORIZONTAL_ALIGNMENT_CENTER, 32, 10, Color(1, 1, 1) if col.get_luminance() < 0.55 else Color(0.1, 0.1, 0.1))
			if B[t.type].w > 0 and t.wk < B[t.type].w:
				draw_circle(mid + Vector2(0, -10), 3, Color(0.9, 0.2, 0.15))
		elif t.type == "wreck":
			draw_line(mid - Vector2(8, 4), mid + Vector2(8, 4), Color(0.25, 0.22, 0.2), 3)
			draw_line(mid + Vector2(-6, 6), mid + Vector2(5, -6), Color(0.3, 0.25, 0.2), 3)
	# Generator
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	var gcol: Color = [Color(0.25, 0.25, 0.28), Color(1.0, 0.55, 0.15), Color(1.0, 0.25, 0.1)][gen_lvl]
	if gen_lvl > 0:
		draw_circle(c, R0 + 8 + pulse * 6, Color(gcol.r, gcol.g, gcol.b, 0.25))
	draw_circle(c, R0 - 4, Color(0.15, 0.13, 0.12))
	draw_circle(c, R0 - 14, gcol)
	draw_string(font, c + Vector2(-30, 4), "GENERATOR", HORIZONTAL_ALIGNMENT_CENTER, 60, 10, Color(1, 1, 1))

func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08, 0.85)
	bg.size = Vector2(1280, 40)
	ui.add_child(bg)
	top = Label.new()
	top.position = Vector2(12, 8)
	top.add_theme_font_size_override("font_size", 17)
	ui.add_child(top)
	# Bauleiste
	var bar := HBoxContainer.new()
	bar.position = Vector2(8, 668)
	ui.add_child(bar)
	for k in ORDER:
		var b := Button.new()
		b.text = B[k].n
		b.custom_minimum_size = Vector2(118, 44)
		b.toggle_mode = true
		b.button_pressed = k == sel
		b.tooltip_text = B[k].d + "\nKosten: " + _cost_str(B[k].cost)
		b.pressed.connect(func():
			sel = k
			for x in bar.get_children(): x.button_pressed = x == b)
		bar.add_child(b)
	# rechte Seite
	var side := VBoxContainer.new()
	side.position = Vector2(1000, 50)
	side.custom_minimum_size = Vector2(270, 0)
	ui.add_child(side)
	var gl := Label.new()
	gl.text = "GENERATOR"
	side.add_child(gl)
	var gh := HBoxContainer.new()
	side.add_child(gh)
	for n in ["Aus", "An", "Überlast"]:
		var b := Button.new()
		b.text = n
		b.custom_minimum_size = Vector2(86, 30)
		var lv := gen_btns.size()
		b.pressed.connect(func(): gen_lvl = lv)
		gh.add_child(b)
		gen_btns.append(b)
	var ll := Label.new()
	ll.text = "\nGESETZBUCH"
	side.add_child(ll)
	law_box = VBoxContainer.new()
	side.add_child(law_box)
	for k in LAWS:
		var b := Button.new()
		b.name = k
		b.text = LAWS[k].n
		b.tooltip_text = LAWS[k].d
		b.pressed.connect(func(): sign_law(k))
		law_box.add_child(b)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 13)
	side.add_child(info)
	var lbg := ColorRect.new()
	lbg.color = Color(0.05, 0.06, 0.08, 0.75)
	lbg.position = Vector2(4, 44)
	lbg.size = Vector2(318, 250)
	ui.add_child(lbg)
	logl = Label.new()
	logl.position = Vector2(12, 50)
	logl.custom_minimum_size = Vector2(300, 0)
	logl.size = Vector2(300, 400)
	logl.autowrap_mode = TextServer.AUTOWRAP_WORD
	logl.add_theme_font_size_override("font_size", 13)
	logl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	ui.add_child(logl)
	var help := Label.new()
	help.position = Vector2(12, 300)
	help.text = "Links: bauen / Wrack plündern\nRechts: Gebäude an/aus\nH: Wärmekarte\nLeertaste: Pause · 1/2/3: Tempo · Klick auf Generator: Stufe"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	ui.add_child(help)
	banner = Label.new()
	banner.size = Vector2(1280, 720)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 40)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 10)
	banner.visible = false
	ui.add_child(banner)

func _cost_str(c: Dictionary) -> String:
	var s := []
	var names := {"wood": "Holz", "steel": "Stahl", "coal": "Kohle"}
	for k in c:
		s.append("%d %s" % [c[k], names[k]])
	return ", ".join(s)

func _update_ui() -> void:
	var t := outside_temp()
	top.text = "Tag %d/%d  %02d:00   %d°C %s   |   Kohle %d  Holz %d  Stahl %d  Fleisch %d  Rationen %d   |   Leute %d (krank %d, Wohnraum %d)" % [
		day, LAST_DAY, hour, int(t), "STURM" if storm() else "", res.coal, res.wood, res.steel, res.raw, res.food, pop, sick, housing()]
	var free := pop - sick
	for x in tiles:
		free -= x.wk
	var s := "\nHoffnung     %s %d\nUnzufrieden  %s %d\nGenerator-Stress %d%%\nFreie Arbeiter %d\n" % [_bar(hope), hope, _bar(disc), disc, stress, maxi(0, free)]
	if hover >= 0:
		var h: Dictionary = tiles[hover]
		var nm: String = B[h.type].n if h.type in B else ("Wrack (klicken: plündern)" if h.type == "wreck" else "Freie Fläche")
		s += "\n%s\nRing %d · %d°C (%s)" % [nm, h.r, int(tile_temp(hover)), CAT_NAME[heat_cat(tile_temp(hover))]]
		if h.type in B and B[h.type].w > 0:
			s += "\nArbeiter %d/%d%s" % [h.wk, B[h.type].w, "" if h.on else " (AUS)"]
	info.text = s
	for i in gen_btns.size():
		gen_btns[i].modulate = Color(1, 0.7, 0.3) if i == gen_lvl else Color(1, 1, 1)
	for b in law_box.get_children():
		b.disabled = b.name in laws or law_cd > 0
		b.text = LAWS[b.name].n + (" ✓" if b.name in laws else "")

func _bar(v: float) -> String:
	var n := int(v / 10)
	return "█".repeat(n) + "░".repeat(10 - n)

func say(s: String) -> void:
	log_lines.push_front("• " + s)
	if log_lines.size() > 9:
		log_lines.pop_back()
	if logl:
		logl.text = "\n".join(log_lines)

func _shot() -> void:
	await get_tree().create_timer(4.0).timeout
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	get_tree().quit()
