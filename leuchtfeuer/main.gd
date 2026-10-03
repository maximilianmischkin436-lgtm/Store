extends Node2D
## DAS LEUCHTFEUER — Kolonie-Überleben im Sporennebel.
## Ein alter Leuchtturm hält den giftigen Nebel zurück. Alles, was im Dunkeln liegt, verwächst.

const HEX := 34.0
const MAP_R := 7
const LAST_DAY := 16
const SEC_PER_HOUR := 1.5
const SQ3 := 1.7320508

const B := {
	"hut":   {"n": "Hütte", "cost": {"scrap": 12}, "w": 0, "house": 8, "col": Color(0.55, 0.42, 0.3), "d": "Wohnraum für 8."},
	"stone": {"n": "Steinhaus", "cost": {"scrap": 30}, "w": 0, "house": 12, "seal": true, "col": Color(0.5, 0.5, 0.52), "d": "Wohnraum für 12. Dicht gegen Sporen."},
	"pump":  {"n": "Ölpumpe", "cost": {"scrap": 20}, "w": 6, "out": {"oil": 7.0}, "terr": "oil", "col": Color(0.2, 0.2, 0.24), "d": "6 Arbeiter. Nur auf Ölquellen."},
	"yard":  {"n": "Schrottplatz", "cost": {"scrap": 10}, "w": 8, "out": {"scrap": 2.5}, "bonus": "ruin", "col": Color(0.55, 0.38, 0.25), "d": "8 Arbeiter. Doppelt auf Ruinen."},
	"farm":  {"n": "Pilzzucht", "cost": {"scrap": 15}, "w": 5, "out": {"food": 3.0}, "bonus": "fungus", "col": Color(0.35, 0.3, 0.45), "d": "5 Arbeiter. Doppelt auf Pilzfeldern."},
	"lamp":  {"n": "Laterne", "cost": {"scrap": 15}, "w": 0, "lamp": true, "col": Color(0.95, 0.75, 0.35), "d": "Licht vertreibt den Nebel. 0.6 Öl/h."},
	"clinic":{"n": "Heilstube", "cost": {"scrap": 25}, "w": 4, "heal": true, "seal": true, "col": Color(0.85, 0.85, 0.88), "d": "4 Arbeiter. Heilt Befallene."},
	"scout": {"n": "Späherposten", "cost": {"scrap": 20}, "w": 2, "scout": true, "col": Color(0.4, 0.5, 0.35), "d": "Ermöglicht Erkundungen von Höhlen und Bunkern."},
	"water": {"n": "Wasserwerk", "cost": {"scrap": 20}, "w": 4, "out": {"water": 5.0}, "col": Color(0.4, 0.5, 0.6), "d": "4 Arbeiter. Sauberes Wasser. Ohne Wasser: Befall und Zorn."},
	"guard": {"n": "Wachposten", "cost": {"scrap": 25}, "w": 3, "guard": true, "col": Color(0.5, 0.4, 0.3), "d": "3 Wachen. Verbrennen Wucherer im Umkreis von 3 Feldern."},
	"lab":   {"n": "Werkstatt", "cost": {"scrap": 25}, "w": 4, "out": {"know": 1.5}, "col": Color(0.45, 0.4, 0.35), "d": "4 Arbeiter. Erzeugt Wissen für die Forschung."},
	"green": {"n": "Gewächshaus", "cost": {"scrap": 25}, "w": 4, "out": {"food": 3.2}, "req": "V1", "col": Color(0.5, 0.7, 0.6), "d": "4 Arbeiter. Nahrung, überall."},
	"filter":{"n": "Filterhaus", "cost": {"scrap": 30}, "w": 2, "filter": true, "req": "V2", "col": Color(0.6, 0.65, 0.7), "d": "2 Arbeiter. Befall im Umkreis -70%."},
	"brew":  {"n": "Pilzbrennerei", "cost": {"scrap": 25}, "w": 4, "brew": true, "req": "T1", "col": Color(0.45, 0.3, 0.35), "d": "4 Arbeiter. 2 Nahrung → 5 Öl pro Stunde."},
	"beacon":{"n": "Leuchtmast", "cost": {"scrap": 40}, "w": 0, "lamp": true, "big": true, "req": "L2", "col": Color(1, 0.85, 0.5), "d": "Großes Licht. 1.5 Öl/h."},
}

const TECH := {
	"L1": {"n": "Spiegellinsen", "c": 20, "req": "", "d": "Turmlicht reicht weiter."},
	"L2": {"n": "Leuchtmast", "c": 40, "req": "L1", "d": "Schaltet den Leuchtmast frei."},
	"L3": {"n": "Gekühlte Linse", "c": 60, "req": "L2", "d": "Linse überhitzt halb so schnell."},
	"V1": {"n": "Gewächshaus", "c": 20, "req": "", "d": "Schaltet Gewächshäuser frei."},
	"V2": {"n": "Luftfilter", "c": 40, "req": "V1", "d": "Schaltet Filterhäuser frei."},
	"V3": {"n": "Sporenserum", "c": 70, "req": "V2", "d": "Heilstuben doppelt, weniger Tote."},
	"T1": {"n": "Brennerei", "c": 25, "req": "", "d": "Schaltet die Pilzbrennerei frei."},
	"T2": {"n": "Tiefpumpen", "c": 40, "req": "T1", "d": "Ölpumpen +50%."},
	"T3": {"n": "Dampfbagger", "c": 60, "req": "T2", "d": "Schrottplätze +50%."},
	"E1": {"n": "Schutzanzüge", "c": 20, "req": "", "d": "Arbeit im Nebel halb so riskant. +3 Atemluft."},
	"E2": {"n": "Brecheisen", "c": 35, "req": "E1", "d": "Öffnet Stahltüren in Bunkern."},
	"E3": {"n": "Sauerstofftanks", "c": 55, "req": "E2", "d": "+5 Atemluft, 5er-Team."},
}
const BRANCHES := [["LICHT", ["L1", "L2", "L3"]], ["LEBEN", ["V1", "V2", "V3"]], ["TECHNIK", ["T1", "T2", "T3"]], ["ERKUNDUNG", ["E1", "E2", "E3"]]]
const Explore := preload("res://explore.gd")
const ORDER := ["hut", "stone", "pump", "yard", "farm", "water", "lamp", "guard", "clinic", "scout", "lab", "green", "filter", "brew", "beacon"]
const RES_NAME := {"oil": "Öl", "scrap": "Schrott", "food": "Nahrung", "water": "Wasser", "know": "Wissen"}

const LAWS := {
	"mask":   {"n": "Maskenpflicht", "d": "Befall -40%. Zorn +1/Tag."},
	"double": {"n": "Doppelschicht", "d": "Arbeit 6–22 Uhr. Zorn +3/Tag."},
	"watch":  {"n": "Lichtwache", "d": "Laternen leuchten 25% weiter, brauchen 50% mehr Öl."},
	"kitchen":{"n": "Gemeinschaftsküche", "d": "Alle essen 25% weniger. Zuversicht -1/Tag."},
	"pyre":   {"n": "Totenfeuer", "d": "Tote kosten halb so viel Zuversicht und geben je 3 Öl."},
}

# ---------- Zustand ----------
var res := {"oil": 110.0, "scrap": 85.0, "food": 95.0, "water": 70.0, "know": 0.0}
var SPR := {}
var draw_order: Array = []
var creatures: Array = []
var shots: Array = []
var striking := false
var nest_burned := false
var thirst := 0
var tech: Array = []
var explore_node: Control
var build_btns := {}
var tech_panel: PanelContainer
var tech_btns := {}
var markers: Node2D
var pop := 60
var infected := 0
var hope := 55.0
var anger := 8.0
var day := 1
var hour := 7
var hour_t := 0.0
var speed := 1.0
var tower_lvl := 1   # 0 aus, 1 normal, 2 hell, 3 grell
var wear := 0.0
var laws: Array = []
var law_cd := 0
var hunger := 0
var out_day := -1
var deaths := 0
var quarantine := 0
var tiles: Array = []
var idx := {}
var sel := "hut"
var over := ""
var hover := -1
var autotest := false
var paused_event := false
var rng := RandomNumberGenerator.new()
var walkers: Array = []
var events_done := {}
var font: Font

# ---------- Szene ----------
var cam: Camera2D
var fog_rect: ColorRect
var fog_mat: ShaderMaterial
var night: CanvasModulate
var spores: CPUParticles2D
var tower_light: PointLight2D
var lamp_lights := {}
var glow_tex: GradientTexture2D
# ---------- UI ----------
var ui: CanvasLayer
var top: Label
var info: Label
var logl: RichTextLabel
var gen_btns: Array = []
var law_box: VBoxContainer
var exp_btn: Button
var banner: Label
var popup: PanelContainer
var pop_text: Label
var pop_btns: HBoxContainer
var log_lines: Array = []

func _ready() -> void:
	rng.seed = 11
	font = ThemeDB.fallback_font
	var args := OS.get_cmdline_user_args()
	autotest = "--autotest" in args or "--shot" in args
	_gen_map()
	_make_world()
	_make_ui()
	say("Tag 1. Der Nebel kam vor drei Wochen. Nur das Licht des alten Turms hält ihn fern.")
	say("Baut Hütten, fördert Öl, züchtet Pilze. Und lasst den Turm nie erlöschen.")
	if autotest:
		speed = 40.0
	if "--shotx" in args or "--shotc" in args:
		speed = 0.0
		_shotx()
		return
	if "--shot" in args:
		speed = 30.0
		_shot()

# ================= Karte =================

func hex_pos(q: int, r: int) -> Vector2:
	return Vector2(HEX * SQ3 * (q + r * 0.5), HEX * 1.5 * r)

func pos_hex(p: Vector2) -> Vector2i:
	var qf := (SQ3 / 3.0 * p.x - p.y / 3.0) / HEX
	var rf := (2.0 / 3.0 * p.y) / HEX
	var sf := -qf - rf
	var q := roundi(qf)
	var r := roundi(rf)
	var s := roundi(sf)
	var dq := absf(q - qf)
	var dr := absf(r - rf)
	var ds := absf(s - sf)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(q, r)

func _gen_map() -> void:
	for q in range(-MAP_R, MAP_R + 1):
		for r in range(-MAP_R, MAP_R + 1):
			var s := -q - r
			if absi(s) > MAP_R:
				continue
			var d := (absi(q) + absi(r) + absi(s)) / 2
			var t := {"q": q, "r": r, "d": d, "pos": hex_pos(q, r), "terr": "ground", "type": "",
				"on": true, "wk": 0, "dark": 0, "grown": false, "shade": rng.randf_range(-0.05, 0.05), "seed": rng.randf()}
			if d == 0:
				t.type = "tower"
			elif d >= 2:
				var x := rng.randf()
				if x < 0.11: t.terr = "ruin"
				elif x < 0.16: t.terr = "oil"
				elif x < 0.26: t.terr = "fungus"
				elif x < 0.31 and d >= 3: t.terr = "rock"
			idx[Vector2i(q, r)] = tiles.size()
			tiles.append(t)
	# Fundorte draußen im Nebel
	var sites := ["bunker", "cave", "cave", "bunker", "cave"]
	var cands := []
	for t in tiles:
		if t.d >= 4 and t.terr == "ground" and t.type == "":
			cands.append(t)
	for k in sites:
		var t: Dictionary = cands[rng.randi() % cands.size()]
		cands.erase(t)
		t.terr = k
		t.explored = false
	# garantiert eine Ölquelle in Reichweite
	for t in tiles:
		if t.d == 2:
			t.terr = "oil"
			break

func light_sources() -> Array:
	var out := []
	var hw := HEX * SQ3
	var dayf := daylight()
	var flood := 0.62 if flood_now() else 1.0
	var nightm := lerpf(0.85, 1.0, dayf) * flood
	if tower_lvl > 0:
		out.append(Vector3(0, 0, maxf(1.6, 2.6 + tower_lvl * 1.15 + (0.7 if has_tech("L1") else 0.0) - (day - 1) * 0.07) * hw * nightm))
	if res.oil > 0:
		var lr := (2.4 * (1.25 if "watch" in laws else 1.0)) * hw * nightm
		for t in tiles:
			if (t.type == "lamp" or t.type == "beacon") and t.on and not t.grown:
				out.append(Vector3(t.pos.x, t.pos.y, lr * (1.55 if t.type == "beacon" else 1.0)))
	return out

func lit_at(p: Vector2, src: Array) -> float:
	var lit := 0.0
	for L in src:
		var d: float = p.distance_to(Vector2(L.x, L.y)) / L.z
		lit = maxf(lit, 1.0 - smoothstep(0.55, 1.0, d))
	return lit

func flood_now() -> bool:
	return (day >= 10 and day <= 12) or day >= 15

func daylight() -> float:
	var h := hour + hour_t / SEC_PER_HOUR
	return clampf(sin((h - 6.0) / 24.0 * TAU) * 1.6, 0.0, 1.0)

func count(type: String) -> int:
	var c := 0
	for t in tiles:
		if t.type == type and not t.grown:
			c += 1
	return c

func housing() -> int:
	var h := 0
	for t in tiles:
		if t.type in B and not t.grown:
			h += B[t.type].get("house", 0)
	return h

# ================= Simulation =================

func _process(delta: float) -> void:
	_update_visuals(delta)
	if over == "" and not paused_event:
		hour_t += delta * speed
		while hour_t >= SEC_PER_HOUR and over == "" and not paused_event:
			hour_t -= SEC_PER_HOUR
			_tick_hour()
	_update_ui()
	queue_redraw()
	markers.queue_redraw()

func work_hours() -> Vector2i:
	return Vector2i(6, 22) if "double" in laws else Vector2i(8, 18)

func _tick_hour() -> void:
	if autotest:
		_auto_play()
	hour += 1
	if hour >= 24:
		hour = 0
		_new_day()
		if over != "": return
	# Turm und Laternen verbrennen Öl
	var burn: float = [0.0, 3.0, 6.0, 10.0][tower_lvl]
	burn += (count("lamp") * 0.6 + count("beacon") * 1.5) * (1.5 if "watch" in laws else 1.0)
	if res.oil < burn:
		res.oil = 0
		if tower_lvl > 0:
			tower_lvl = 0
			if out_day != day:
				out_day = day
				say("[color=#ff7050]DAS LICHT IST ERLOSCHEN.[/color] Der Nebel kriecht herein.")
				hope -= 8
	else:
		res.oil -= burn
	var heat: float = 4.0 if tower_lvl == 3 else (0.6 if tower_lvl == 2 else -2.0)
	if heat > 0 and has_tech("L3"): heat *= 0.5
	wear = clampf(wear + heat, 0, 100)
	if wear >= 100:
		_lose("Die Linse des Turms ist geplatzt. Ohne Licht gibt es keine Stadt.")
		return
	# Licht/Nebel pro Feld
	var src := light_sources()
	for t in tiles:
		var dark: bool = lit_at(t.pos, src) < 0.5
		t.lit = not dark
		if t.type in B and not t.grown:
			t.dark = t.dark + 1 if dark else 0
			if t.dark >= 20:
				t.grown = true
				say("%s ist vom Nebel überwuchert worden." % B[t.type].n)
		# Wilde Pilze breiten sich im Dunkeln aus
		if dark and t.terr == "ground" and t.type == "" and rng.randf() < 0.004:
			t.terr = "fungus"
	# Arbeit
	var free := pop - infected
	var wh := work_hours()
	var working := hour >= wh.x and hour < wh.y
	for t in tiles:
		t.wk = 0
		if not (t.type in B) or not t.on or t.grown:
			continue
		var need: int = B[t.type].w
		if need == 0:
			continue
		var w := mini(need, free)
		free -= w
		t.wk = w
		if w == 0 or not working:
			continue
		var f := float(w) / need * (1.0 if t.lit else 0.5) * (0.5 if striking else 1.0)
		if B[t.type].get("bonus", "") == t.terr:
			f *= 2.0
		if t.type == "pump" and has_tech("T2"): f *= 1.5
		if t.type == "yard" and has_tech("T3"): f *= 1.5
		if B[t.type].get("brew", false):
			var use := minf(res.food, 2.0 * f)
			res.food -= use
			res.oil += use * 2.5
		var out: Dictionary = B[t.type].get("out", {})
		for k in out:
			res[k] += out[k] * f
	# Heilung
	if infected > 0 and working:
		var cap := 0.0
		for t in tiles:
			if t.type == "clinic" and t.wk > 0 and not t.grown:
				cap += 0.5 * t.wk / 4.0 * (2.0 if has_tech("V3") else 1.0)
		infected -= mini(infected, int(cap + rng.randf()))
	# Befall: Wer im Dunkeln wohnt oder arbeitet, atmet Sporen
	var risk := 0.0
	var left := pop
	var filters := []
	for t in tiles:
		if t.type == "filter" and t.wk > 0 and not t.grown:
			filters.append(t.pos)
	for t in tiles:
		if not (t.type in B) or t.grown:
			continue
		var fm := 1.0
		for fp in filters:
			if (fp as Vector2).distance_to(t.pos) < HEX * SQ3 * 2.2:
				fm = 0.3
		var h: int = B[t.type].get("house", 0)
		if h > 0 and left > 0:
			var n := mini(h, left)
			left -= n
			if not t.lit:
				risk += n * (0.004 if B[t.type].get("seal", false) else 0.012) * fm
		if t.wk > 0 and not t.lit and working:
			risk += t.wk * 0.01 * fm * (0.5 if has_tech("E1") else 1.0)
	risk += left * 0.004 # Obdachlose
	if "mask" in laws: risk *= 0.6
	if quarantine > 0: risk *= 0.5
	risk += infected * 0.002 * (0.3 if quarantine > 0 else 1.0)
	var add := int(risk) + (1 if rng.randf() < fmod(risk, 1.0) else 0)
	infected = mini(pop, infected + add)
	_tick_creatures()
	if hour == 19:
		_meal()
	_check_end()

func _check_end() -> void:
	if over != "": return
	hope = clampf(hope, 0, 100)
	anger = clampf(anger, 0, 100)
	if hope <= 0: _lose("Die Zuversicht ist erloschen. Die Menschen gehen schweigend in den Nebel.")
	elif anger >= 100: _lose("Aufstand. Sie stoßen dich hinaus ins Grau.")
	elif pop <= 0: _lose("Niemand ist mehr übrig, der das Licht hütet.")

func _meal() -> void:
	var need := pop * (0.75 if "kitchen" in laws else 1.0)
	var eat := minf(res.food, need)
	res.food -= eat
	need -= eat
	if need > 0.5:
		hunger += 1
		anger += 5
		hope -= 4
		say("%d Menschen bleiben hungrig." % int(need))
		if hunger >= 2:
			_kill(maxi(1, int(need * 0.08)), "verhungert")
	else:
		hunger = 0
	var drink := pop * 0.8
	var got := minf(res.water, drink)
	res.water -= got
	if drink - got > 0.5:
		thirst += 1
		var short := int(drink - got)
		infected = mini(pop, infected + int(short * 0.12) + 1)
		anger += 4
		say("[color=#90c0ff]%d Menschen trinken Nebelwasser.[/color] Der Befall breitet sich aus." % short)
		if thirst >= 3:
			_kill(maxi(1, short / 10), "verdurstet")
	else:
		thirst = 0

func _kill(n: int, why: String) -> void:
	n = mini(n, pop)
	if n <= 0: return
	pop -= n
	infected = mini(infected, pop)
	deaths += n
	hope -= n * (0.7 if "pyre" in laws else 1.4)
	if "pyre" in laws: res.oil += n * 3
	say(("1 Mensch ist %s." % why) if n == 1 else ("%d Menschen sind %s." % [n, why]))

func _new_day() -> void:
	day += 1
	law_cd = maxi(0, law_cd - 1)
	quarantine = maxi(0, quarantine - 1)
	var cap := 0
	for t in tiles:
		if t.type == "clinic" and t.wk > 0 and not t.grown:
			cap += 8
	var untreated := maxi(0, infected - cap)
	if untreated > 0:
		_kill(int(untreated * (0.07 if has_tech("V3") else 0.15) + rng.randf()), "dem Befall erlegen")
	var homeless := maxi(0, pop - housing())
	anger += homeless * 0.2
	if "mask" in laws: anger += 1
	if "double" in laws: anger += 3
	if "kitchen" in laws: hope -= 1
	if tower_lvl == 0: anger += 6
	if anger >= 65 and not striking:
		striking = true
		say("[color=#ff9050]STREIK![/color] Die Arbeiter legen die Werkzeuge nieder. Produktion halbiert.")
	elif anger < 50 and striking:
		striking = false
		say("Der Streik ist vorbei. Die Arbeit geht weiter.")
	if anger >= 85 and rng.randf() < 0.4:
		var lost := minf(res.oil, 30.0)
		res.oil -= lost
		say("[color=#ff7050]Sabotage![/color] Jemand hat %d Öl in den Nebel gekippt." % int(lost))
	if day >= 4:
		say("Der Nebel wird dichter. Das Licht des Turms reicht jeden Tag ein wenig weniger weit.") if day % 4 == 0 else null
	if infected == 0 and homeless == 0 and hunger == 0 and thirst == 0:
		hope += 3
		anger -= 2
	hope = clampf(hope, 0, 100)
	anger = clampf(anger, 0, 100)
	if day == 8: say("[color=#c0ff90]Die Pilze an den Rändern leuchten heller. Die Alten sagen: eine Nebelflut kommt.[/color]")
	if day == 9: say("[color=#c0ff90]NEBELFLUT.[/color] Das Licht reicht nur noch halb so weit.")
	if day == 12: say("Die Flut weicht zurück. Wir atmen noch.")
	if day > LAST_DAY:
		_win()
		return
	_maybe_event()
	if autotest:
		print("TAG %d pop %d inf %d hope %.0f anger %.0f oil %.0f scrap %.0f food %.0f" % [day, pop, infected, hope, anger, res.oil, res.scrap, res.food])

# ================= Ereignisse =================

func _maybe_event() -> void:
	var ev := {
		2: ["Ein Kind ist hinter die Laternen in den Nebel gelaufen. Die Mutter schreit nach Hilfe.",
			"Suchtrupp schicken", "Tore schließen", "child"],
		4: ["Fremde mit Gasmasken stehen am Rand des Lichts. Sie bieten 70 Öl für 35 Schrott.",
			"Handeln", "Fortschicken", "trade"],
		6: ["Die Befallenen wollen zurück zu ihren Familien. Andere fürchten die Ansteckung.",
			"Quarantäne erzwingen", "Familien vereinen", "quar"],
		8: ["Ein Prediger ruft: Der Nebel ist unsere Strafe, nur das Licht ist heilig!",
			"Predigen lassen", "Verbannen", "preach"],
		5: ["Das Wasser schmeckt nach Pilzen. Einige husten schon nach dem Trinken.",
			"Abkochen (25 Öl)", "Weitertrinken", "boil"],
		9: ["Späher entdecken ein Wucherer-Nest nahe der Stadt. Nachts kommen sie von dort.",
			"Nest niederbrennen (Leben riskieren)", "Mauern verstärken (30 Schrott)", "nest"],
		13: ["Die Kinder zeichnen Bilder vom Licht im Norden. Die Erwachsenen streiten, ob man aufbrechen soll.",
			"Hoffnung schüren", "Bleiben befehlen", "north"],
		12: ["Vom Turm aus sieht man es: ein zweites Licht, weit im Norden. Ein Funkspruch knistert.",
			"Antworten", "Schweigen", "radio"],
	}
	if day in ev and not events_done.has(day):
		events_done[day] = true
		var e: Array = ev[day]
		show_event(e[0], e[1], e[2], e[3])
	if day == 3:
		say("[color=#ff9070]In der Nacht kratzt etwas an den Hütten am Rand.[/color] Die Wucherer sind wach. Baut Wachposten!")

func show_event(text: String, a: String, b: String, id: String) -> void:
	if autotest:
		_resolve(id, 0)
		return
	paused_event = true
	pop_text.text = text
	for c in pop_btns.get_children(): c.queue_free()
	for i in 2:
		var btn := Button.new()
		btn.text = a if i == 0 else b
		btn.custom_minimum_size = Vector2(220, 40)
		btn.pressed.connect(func():
			popup.visible = false
			paused_event = false
			_resolve(id, i))
		pop_btns.add_child(btn)
	popup.visible = true

func _resolve(id: String, c: int) -> void:
	match id:
		"child":
			if c == 0:
				if rng.randf() < 0.6:
					hope += 10; say("Sie haben das Kind gefunden. Es lebt. Die Stadt weint vor Glück.")
				else:
					infected += 3; hope -= 2; say("Kein Kind. Drei Sucher kommen hustend zurück.")
			else:
				hope -= 7; anger += 4; say("Die Tore bleiben zu. Die ganze Nacht hört man die Mutter.")
		"trade":
			if c == 0 and res.scrap >= 35:
				res.scrap -= 35; res.oil += 70; say("Der Handel gelingt. Die Fremden verschwinden wortlos.")
			else:
				say("Die Fremden ziehen weiter in den Nebel.")
		"quar":
			if c == 0:
				quarantine = 4; anger += 8; say("Quarantäne. Hinter den Brettern hört man sie singen.")
			else:
				hope += 6; infected += 4; say("Die Familien sind wieder vereint. Der Husten breitet sich aus.")
		"preach":
			if c == 0:
				hope += 8; anger += 3; say("Jeden Abend versammeln sie sich am Turm und beten ins Licht.")
			else:
				anger += 6; say("Der Prediger geht in den Nebel. Seine Anhänger schauen dir lange nach.")
		"boil":
			if c == 0 and res.oil >= 25:
				res.oil -= 25; say("Das Wasser wird abgekocht. Es schmeckt nach Rauch, aber es ist sauber.")
			else:
				infected += 6; say("Sie trinken weiter. In der Nacht hört man überall Husten.")
		"nest":
			if c == 0:
				nest_burned = true
				_kill(rng.randi_range(2, 4), "beim Angriff auf das Nest gestorben")
				hope += 6; say("Das Nest brennt. Die Nächte werden ruhiger.")
			else:
				if res.scrap >= 30: res.scrap -= 30
				anger += 3; say("Palisaden werden gezogen. Die Wucherer kommen trotzdem.")
		"north":
			if c == 0:
				hope += 8; anger += 4; say("Jeden Abend erzählt man sich vom Licht im Norden.")
			else:
				anger += 8; hope -= 3; say("Niemand verlässt die Stadt. Die Kinder hören auf zu zeichnen.")
		"radio":
			if c == 0:
				hope += 15; say("[color=#ffe090]\"Wir hören euch. Haltet durch. Wir kommen.\"[/color]")
			else:
				hope -= 5; say("Das fremde Licht flackert und erlischt.")
	_check_end()

func has_tech(id: String) -> bool:
	return id in tech

func can_research(id: String) -> bool:
	var tt: Dictionary = TECH[id]
	return not has_tech(id) and (tt.req == "" or has_tech(tt.req)) and res.know >= tt.c

func research(id: String) -> void:
	if not can_research(id): return
	res.know -= TECH[id].c
	tech.append(id)
	say("[color=#90d0ff]Erforscht: %s[/color] – %s" % [TECH[id].n, TECH[id].d])

func start_explore(i: int) -> void:
	var t: Dictionary = tiles[i]
	var team := 5 if has_tech("E3") else 4
	if t.get("explored", false):
		say("Dieser Ort ist bereits erkundet."); return
	if count("scout") == 0:
		say("Für Erkundungen braucht ihr einen Späherposten."); return
	if pop - infected < team + 6 or res.food < 10:
		say("Nicht genug gesunde Leute oder Nahrung für eine Erkundung."); return
	res.food -= 10
	paused_event = true
	explore_node = Explore.new()
	explore_node.main = self
	var air := 10 + (3 if has_tech("E1") else 0) + (5 if has_tech("E3") else 0)
	explore_node.setup(t.terr, int(t.seed * 100000), air, team, has_tech("E2"))
	explore_node.finished.connect(func(r: Dictionary): _explore_done(i, r))
	ui.add_child(explore_node)
	if autotest:
		explore_node.auto_run()

func _explore_done(i: int, r: Dictionary) -> void:
	tiles[i].explored = true
	explore_node.queue_free()
	explore_node = null
	paused_event = false
	var l: Dictionary = r.loot
	for k in l:
		res[k] += l[k]
	pop += r.people
	if r.lost > 0:
		_kill(r.lost, "bei der Erkundung verschollen")
	if r.ok:
		say("Das Erkundungsteam ist zurück: %d Öl, %d Schrott, %d Nahrung, %d Wissen, %d Überlebende." % [l.get("oil", 0), l.get("scrap", 0), l.get("food", 0), l.get("know", 0), r.people])
		hope += 3 + r.people
	for h in int(r.hours):
		if over == "": _tick_hour()

# ================= Bauen =================

func can_place(i: int, type: String) -> bool:
	var t: Dictionary = tiles[i]
	if t.type != "" or t.terr in ["rock", "cave", "bunker"]:
		return false
	if B[type].has("req") and not has_tech(B[type].req):
		return false
	var need: String = B[type].get("terr", "")
	if need != "" and t.terr != need:
		return false
	if need == "" and t.terr == "oil":
		return false
	return t.get("lit", true) or type == "lamp"

func can_afford(type: String) -> bool:
	for k in B[type].cost:
		if res[k] < B[type].cost[k]:
			return false
	return true

func build(i: int, type: String) -> bool:
	var t: Dictionary = tiles[i]
	if t.grown:
		if res.scrap >= 8:
			res.scrap -= 8; t.grown = false; t.dark = 0
			say("%s vom Bewuchs befreit." % B[t.type].n)
			return true
		return false
	if t.terr == "ruin" and t.type == "" and type != "yard":
		res.scrap += 15; t.terr = "ground"
		say("Ruine ausgeschlachtet: +15 Schrott.")
		return true
	if not can_place(i, type) or not can_afford(type):
		return false
	for k in B[type].cost:
		res[k] -= B[type].cost[k]
	t.type = type
	t.on = true
	t.dark = 0
	return true

func _auto_play() -> void:
	var plan := ["pump", "yard", "farm", "yard", "water", "hut", "hut", "farm", "hut", "guard", "farm", "hut", "lab", "clinic", "hut", "pump", "lamp", "scout", "guard", "water", "yard", "farm", "lamp", "stone", "guard", "lamp", "stone", "green", "filter", "beacon", "brew"]
	var have := {}
	for t in tiles:
		if t.type in B: have[t.type] = have.get(t.type, 0) + 1
	var seen := {}
	for p in plan:
		seen[p] = seen.get(p, 0) + 1
		if have.get(p, 0) < seen[p]:
			if B[p].has("req") and not has_tech(B[p].req):
				continue
			if can_afford(p):
				var best := -1
				for i in tiles.size():
					if can_place(i, p) and (best < 0 or tiles[i].d < tiles[best].d or (B[p].get("bonus", "") == tiles[i].terr and tiles[best].terr != tiles[i].terr)):
						best = i
				if best >= 0: build(best, p)
			break
	for t in tiles:
		if t.grown and res.scrap > 20: build(tiles.find(t), "hut")
	if laws.size() < 3 and law_cd == 0:
		sign_law(["mask", "watch", "pyre"][laws.size()])
	for id in ["V1", "E1", "L1", "V2", "T1", "E2", "L2", "T2", "V3", "L3", "E3", "T3"]:
		if can_research(id): research(id)
	if hour == 9 and day % 2 == 0 and explore_node == null:
		for i in tiles.size():
			if tiles[i].terr in ["cave", "bunker"] and not tiles[i].get("explored", false):
				start_explore(i)
				break
	tower_lvl = (2 if (flood_now() and wear < 60 and res.oil > 80) else 1) if res.oil > 25 else 0

func sign_law(k: String) -> void:
	if k in laws or law_cd > 0: return
	laws.append(k)
	law_cd = 2
	say("Erlass verkündet: [b]%s[/b]" % LAWS[k].n)

# ================= Eingabe =================

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := pos_hex(get_global_mouse_position())
		hover = idx.get(h, -1)
		if e.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			cam.position -= e.relative / cam.zoom
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom = (cam.zoom * 1.1).clamp(Vector2(0.6, 0.6), Vector2(2.2, 2.2))
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom = (cam.zoom / 1.1).clamp(Vector2(0.6, 0.6), Vector2(2.2, 2.2))
		elif over == "" and not paused_event and hover >= 0:
			var t: Dictionary = tiles[hover]
			if e.button_index == MOUSE_BUTTON_LEFT:
				if t.type == "tower":
					tower_lvl = (tower_lvl + 1) % 4
				elif t.terr in ["cave", "bunker"]:
					start_explore(hover)
				elif not build(hover, sel) and t.type == "":
					if not can_afford(sel): say("Nicht genug Material für %s." % B[sel].n)
					elif not t.get("lit", true) and sel != "lamp": say("Im Nebel kann man nicht bauen – erst eine Laterne.")
					else: say("%s passt hier nicht hin." % B[sel].n)
			elif e.button_index == MOUSE_BUTTON_RIGHT and t.type in B:
				t.on = not t.on
	elif e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_T: tech_panel.visible = not tech_panel.visible
			KEY_SPACE: speed = 0.0 if speed > 0 else 1.0
			KEY_1: speed = 1.0
			KEY_2: speed = 3.0
			KEY_3: speed = 8.0
			KEY_R: if over != "": get_tree().reload_current_scene()

func _process_keys(delta: float) -> void:
	var v := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_W): v.y -= 1
	if Input.is_key_pressed(KEY_S): v.y += 1
	cam.position += v * 500.0 * delta / cam.zoom.x
	cam.position = cam.position.clamp(Vector2(-450, -400), Vector2(450, 400))

# ================= Darstellung =================

func _load_sprites() -> void:
	for f in DirAccess.get_files_at("res://sprites"):
		if f.ends_with(".png"):
			var img := Image.load_from_file(ProjectSettings.globalize_path("res://sprites/" + f))
			if img:
				img.generate_mipmaps()
				SPR[f.get_basename()] = ImageTexture.create_from_image(img)
	draw_order = range(tiles.size())
	draw_order.sort_custom(func(a, b): return tiles[a].pos.y < tiles[b].pos.y)

func _make_world() -> void:
	_load_sprites()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	cam = Camera2D.new()
	cam.position = Vector2(60, 10)
	cam.zoom = Vector2(1.1, 1.1)
	add_child(cam)
	glow_tex = GradientTexture2D.new()
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 256
	glow_tex.height = 256
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	glow_tex.gradient = g
	tower_light = PointLight2D.new()
	tower_light.texture = glow_tex
	tower_light.color = Color(1.0, 0.8, 0.5)
	tower_light.energy = 1.2
	add_child(tower_light)
	night = CanvasModulate.new()
	add_child(night)
	fog_mat = ShaderMaterial.new()
	fog_mat.shader = load("res://fog.gdshader")
	fog_rect = ColorRect.new()
	fog_rect.material = fog_mat
	fog_rect.position = Vector2(-1100, -900)
	fog_rect.size = Vector2(2200, 1800)
	fog_rect.z_index = 10
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fog_rect)
	fog_mat.set_shader_parameter("origin", fog_rect.position)
	fog_mat.set_shader_parameter("size", fog_rect.size)
	markers = Node2D.new()
	markers.z_index = 12
	markers.draw.connect(_draw_markers)
	add_child(markers)
	spores = CPUParticles2D.new()
	spores.z_index = 11
	spores.amount = 160
	spores.lifetime = 9.0
	spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spores.emission_rect_extents = Vector2(700, 500)
	spores.gravity = Vector2(6, -4)
	spores.initial_velocity_min = 4
	spores.initial_velocity_max = 14
	spores.spread = 180
	spores.scale_amount_min = 1.0
	spores.scale_amount_max = 2.5
	spores.color = Color(0.7, 1.0, 0.5, 0.55)
	spores.preprocess = 9.0
	add_child(spores)

func _update_visuals(delta: float) -> void:
	_process_keys(delta)
	for sh in shots: sh.t -= delta
	shots = shots.filter(func(x): return x.t > 0)
	var dl := daylight()
	var c := Color(0.32, 0.36, 0.5).lerp(Color(1, 0.98, 0.94), dl)
	if flood_now(): c = c.lerp(Color(0.55, 0.65, 0.5), 0.35)
	night.color = c
	var src := light_sources()
	var arr := PackedVector4Array()
	for L in src:
		arr.append(Vector4(L.x, L.y, L.z, 0))
	fog_mat.set_shader_parameter("lights", arr)
	fog_mat.set_shader_parameter("nlights", arr.size())
	fog_mat.set_shader_parameter("density", 1.25 if flood_now() else 1.0)
	spores.position = cam.position
	# echte 2D-Lichter (warmes Glühen nachts)
	tower_light.enabled = tower_lvl > 0
	if src.size() > 0 and tower_lvl > 0:
		tower_light.texture_scale = src[0].z * 2.0 / 256.0
	tower_light.energy = (0.4 + 0.9 * (1.0 - dl)) * (0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.006))
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		var want: bool = (t.type == "lamp" or t.type == "beacon") and t.on and res.oil > 0 and not t.grown
		if want and not lamp_lights.has(i):
			var l := PointLight2D.new()
			l.texture = glow_tex
			l.color = Color(1.0, 0.75, 0.4)
			l.position = t.pos
			l.texture_scale = 2.2 if t.type == "beacon" else 1.4
			add_child(l)
			lamp_lights[i] = l
		elif lamp_lights.has(i):
			lamp_lights[i].enabled = want
			lamp_lights[i].energy = 0.3 + 0.9 * (1.0 - dl)
	# Bewohner laufen zwischen Häusern und Arbeit
	var homes := []
	var works := []
	for t in tiles:
		if t.type in B and not t.grown:
			if B[t.type].get("house", 0) > 0: homes.append(t.pos)
			elif B[t.type].w > 0 and t.wk > 0: works.append(t.pos)
	var want_n := mini(40, (pop - infected) / 3) if homes.size() > 0 and works.size() > 0 and dl > 0.2 else 0
	while walkers.size() < want_n:
		walkers.append({"a": homes.pick_random(), "b": works.pick_random(), "t": randf(), "dir": 1.0, "sp": randf_range(0.08, 0.16)})
	while walkers.size() > want_n:
		walkers.pop_back()
	for w in walkers:
		w.t += w.dir * w.sp * delta * minf(speed, 4.0)
		if w.t >= 1.0 or w.t <= 0.0:
			w.dir = -w.dir
			w.t = clampf(w.t, 0.0, 1.0)
			if w.t <= 0.0 and homes.size() > 0 and works.size() > 0:
				w.a = homes.pick_random(); w.b = works.pick_random()

func _dome(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 13:
		pts.append(c + Vector2.from_angle(PI + k / 12.0 * PI) * r)
	return pts

func _hex_pts(p: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 6:
		pts.append(p + Vector2.from_angle(deg_to_rad(60 * k - 30)) * s)
	return pts

const SPR_W := {"tower": 64, "hut": 76, "stone": 78, "pump": 74, "yard": 78, "farm": 78, "lamp": 26, "clinic": 80,
	"scout": 52, "lab": 76, "green": 78, "filter": 78, "brew": 78, "beacon": 40, "water": 74, "guard": 78,
	"ruin": 66, "rock": 66, "oil": 62, "cave": 82, "bunker": 82}

func spr(ci: CanvasItem, key: String, p: Vector2, mod: Color = Color.WHITE, wmul: float = 1.0) -> bool:
	if not SPR.has(key):
		return false
	var tex: Texture2D = SPR[key]
	var w: float = SPR_W.get(key, 70) * wmul
	var h: float = w * tex.get_height() / tex.get_width()
	ci.draw_texture_rect(tex, Rect2(p - Vector2(w * 0.5, h - w * 0.18), Vector2(w, h)), false, mod)
	return true

func _draw() -> void:
	var tm := Time.get_ticks_msec() / 1000.0
	var dl := daylight()
	draw_circle(Vector2.ZERO, 820, Color(0.09, 0.1, 0.09))
	var gtex: Texture2D = SPR.get("tex_ground")
	var ftex: Texture2D = SPR.get("tex_fungus")
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		var p: Vector2 = t.pos
		var pts := _hex_pts(p, HEX + 0.6)
		var uvs := PackedVector2Array()
		for v in pts: uvs.append(v / 300.0)
		var tex: Texture2D = ftex if t.terr == "fungus" else gtex
		var tint := Color(1, 1, 1).darkened(0.12 - t.shade)
		if t.terr == "rock": tint = tint.darkened(0.15)
		if tex:
			draw_colored_polygon(pts, tint, uvs, tex)
		else:
			draw_colored_polygon(pts, Color(0.35, 0.32, 0.27))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.18), 1.0)
		if i == hover:
			var ok: bool = t.type == "" and can_place(i, sel) and can_afford(sel)
			draw_colored_polygon(pts, Color(0.6, 1, 0.6, 0.12) if ok else Color(1, 0.6, 0.3, 0.12))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.6, 1, 0.6) if ok else Color(1, 0.8, 0.5), 2.5)
	# Objekte von hinten nach vorne
	for i in draw_order:
		var t: Dictionary = tiles[i]
		var p: Vector2 = t.pos
		if t.type == "" and t.terr in ["ruin", "rock", "oil"]:
			if not spr(self, t.terr, p + Vector2(0, 4)):
				_draw_terrain(t, p, tm)
		elif t.type == "" and t.terr == "fungus":
			_draw_terrain(t, p, tm)
		if t.type != "":
			# weicher Schatten
			draw_set_transform(p + Vector2(4, 6), 0, Vector2(1, 0.45))
			draw_circle(Vector2.ZERO, HEX * 0.85, Color(0, 0, 0, 0.28))
			draw_set_transform(Vector2.ZERO)
			_draw_building(t, p, tm, dl)
	# Bewohner in Schutzanzügen
	var ptex: Texture2D = SPR.get("person")
	for w in walkers:
		var wp: Vector2 = (w.a as Vector2).lerp(w.b, w.t)
		var bob := absf(sin(w.t * 90.0)) * 1.5
		if ptex:
			var hh := 24.0
			var ww := hh * ptex.get_width() / ptex.get_height()
			var left: bool = ((w.b as Vector2).x - (w.a as Vector2).x) * w.dir < 0
			draw_set_transform(wp + Vector2(0, -bob), 0, Vector2(-1 if left else 1, 1))
			draw_circle(Vector2(0, 0), 4, Color(0, 0, 0, 0.25))
			draw_texture_rect(ptex, Rect2(Vector2(-ww * 0.5, -hh), Vector2(ww, hh)), false)
			draw_set_transform(Vector2.ZERO)
		else:
			Explore.draw_suit(self, wp, 0.9, w.t * 8.0, true)

func _draw_terrain(t: Dictionary, p: Vector2, tm: float) -> void:
	var sd: float = t.seed
	match t.terr:
		"fungus":
			for k in 5:
				var o := Vector2.from_angle(sd * 20 + k * 1.3) * (6 + k * 3.0)
				var glow := 0.6 + 0.4 * sin(tm * 1.5 + k + sd * 10)
				draw_line(p + o, p + o + Vector2(0, -5), Color(0.75, 0.7, 0.6), 1.5)
				draw_circle(p + o + Vector2(0, -6), 3.5 - k * 0.3, Color(0.4, 0.9 * glow, 0.75, 1).lerp(Color(0.8, 0.4, 1), sd))
		"oil":
			if t.type == "":
				draw_circle(p, 13, Color(0.05, 0.05, 0.06))
				draw_arc(p + Vector2(-3, -3), 6, 3.6, 5.2, 8, Color(0.4, 0.35, 0.6, 0.7), 2)
		"ruin":
			if t.type == "":
				draw_rect(Rect2(p + Vector2(-14, -8), Vector2(8, 16)), Color(0.5, 0.45, 0.42))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 8), p + Vector2(12, 8), p + Vector2(12, -4), p + Vector2(4, 2)]), Color(0.45, 0.4, 0.38))
				draw_line(p + Vector2(-6, 10), p + Vector2(8, -10), Color(0.3, 0.2, 0.15), 2)
		"rock":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 8), p + Vector2(-6, -14), p + Vector2(4, -6), p + Vector2(14, -12), p + Vector2(18, 8)]), Color(0.42, 0.42, 0.44))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -14), p + Vector2(4, -6), p + Vector2(-2, 8), p + Vector2(-16, 8)]), Color(0.52, 0.52, 0.55))

func _house(p: Vector2, w: float, h: float, wall: Color, roof: Color, lit: bool, dl: float) -> void:
	var l := p + Vector2(-w * 0.5, 6)
	draw_colored_polygon(PackedVector2Array([l + Vector2(0, 4), l + Vector2(w, 4), l + Vector2(w + 4, 0), l + Vector2(4, 0)]), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(l + Vector2(0, -h), Vector2(w, h)), wall)
	draw_rect(Rect2(l + Vector2(w * 0.55, -h), Vector2(w * 0.45, h)), wall.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([l + Vector2(-3, -h), l + Vector2(w * 0.5, -h - w * 0.45), l + Vector2(w + 3, -h)]), roof)
	draw_colored_polygon(PackedVector2Array([l + Vector2(w * 0.5, -h - w * 0.45), l + Vector2(w + 3, -h), l + Vector2(w * 0.5, -h)]), roof.darkened(0.25))
	var win := Color(1.0, 0.75, 0.35) if lit and dl < 0.7 else Color(0.15, 0.17, 0.2)
	draw_rect(Rect2(l + Vector2(w * 0.18, -h * 0.7), Vector2(4, 4)), win)
	draw_rect(Rect2(l + Vector2(w * 0.68, -h * 0.7), Vector2(4, 4)), win)
	draw_rect(Rect2(l + Vector2(w * 0.4, -h * 0.45), Vector2(5, h * 0.45)), wall.darkened(0.5))

func _draw_building(t: Dictionary, p: Vector2, tm: float, dl: float) -> void:
	var on: bool = t.on and not t.grown
	var mod := Color.WHITE
	if t.grown: mod = Color(0.55, 0.85, 0.6)
	elif not t.on: mod = Color(0.55, 0.55, 0.55)
	if spr(self, t.type, p, mod):
		_building_fx(t, p, tm, on)
	else:
		_draw_building_vec(t, p, tm, dl, on)
	_building_status(t, p)

func _building_fx(t: Dictionary, p: Vector2, tm: float, on: bool) -> void:
	match t.type:
		"tower":
			var lc: Color = [Color(0.2, 0.2, 0.2), Color(1, 0.85, 0.5), Color(1, 0.95, 0.75), Color(1, 1, 1)][tower_lvl]
			var top := p + Vector2(0, -SPR_W.tower * 1.62)
			if tower_lvl > 0:
				draw_circle(top, 10 + sin(tm * 5) * 1.5, Color(lc.r, lc.g, lc.b, 0.45))
				var a := tm * 0.9
				for s in [0.0, PI]:
					var d: Vector2 = Vector2.from_angle(a + s)
					draw_colored_polygon(PackedVector2Array([top, top + d.rotated(0.13) * 360, top + d.rotated(-0.13) * 360]), Color(lc.r, lc.g, lc.b, 0.13))
		"lamp", "beacon":
			if on and res.oil > 0:
				var top2 := p + Vector2(0, -SPR_W[t.type] * (2.95 if t.type == "lamp" else 1.75))
				draw_circle(top2, 9 if t.type == "lamp" else 15, Color(1, 0.8, 0.45, 0.35 + 0.08 * sin(tm * 7 + t.seed * 9)))
		"brew", "lab", "hut", "stone":
			if on and (t.wk > 0 or B[t.type].w == 0):
				for k in 3:
					var sm := fmod(tm * 0.35 + k * 0.33 + t.seed, 1.0)
					draw_circle(p + Vector2(14 + sm * 10, -50 - sm * 26), 3 + sm * 5, Color(0.65, 0.65, 0.6, 0.35 * (1.0 - sm)))
		"filter":
			if on and t.wk > 0:
				draw_arc(p, HEX * SQ3 * 2.2, 0, TAU, 48, Color(0.6, 0.85, 1, 0.12), 2)
		"guard":
			if on and t.wk > 0:
				draw_arc(p, HEX * SQ3 * 3.0, 0, TAU, 48, Color(1, 0.55, 0.3, 0.10), 2)
				draw_circle(p + Vector2(10, -56), 4 + sin(tm * 9) * 1.2, Color(1, 0.6, 0.2, 0.8))
	if t.grown:
		for k in 9:
			var o := Vector2.from_angle(k * 0.9 + t.seed * 9) * (6 + k * 2.2)
			draw_circle(p + o + Vector2(0, -14), 4.5, Color(0.35, 0.85, 0.65, 0.75))

func _building_status(t: Dictionary, p: Vector2) -> void:
	if t.grown or not t.type in B:
		return
	if not t.on:
		draw_string(font, p + Vector2(-12, 20), "AUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.4, 0.3))
	elif B[t.type].w > 0 and t.wk < B[t.type].w:
		draw_circle(p + Vector2(20, -30), 5, Color(0, 0, 0, 0.5))
		draw_circle(p + Vector2(20, -30), 3.5, Color(0.95, 0.3, 0.2))
	if t.dark > 0:
		draw_arc(p, HEX * 0.65, -PI / 2, -PI / 2 + TAU * t.dark / 20.0, 24, Color(0.5, 1, 0.5, 0.9), 3)

func _draw_building_vec(t: Dictionary, p: Vector2, tm: float, dl: float, on0: bool) -> void:
	var on := on0
	match t.type:
		"tower":
			draw_colored_polygon(_hex_pts(p, 24), Color(0.3, 0.28, 0.27))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 10), p + Vector2(-7, -48), p + Vector2(7, -48), p + Vector2(12, 10)]), Color(0.78, 0.74, 0.68))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 10), p + Vector2(0, -48), p + Vector2(7, -48), p + Vector2(12, 10)]), Color(0.6, 0.56, 0.52))
			for k in 3:
				draw_rect(Rect2(p + Vector2(-11 + k * 0.8, -6 - k * 16), Vector2(22 - k * 1.6, 4)), Color(0.65, 0.2, 0.15))
			draw_rect(Rect2(p + Vector2(-9, -60), Vector2(18, 12)), Color(0.2, 0.2, 0.22))
			var lc: Color = [Color(0.2, 0.2, 0.2), Color(1, 0.85, 0.5), Color(1, 0.95, 0.75), Color(1, 1, 1)][tower_lvl]
			draw_circle(p + Vector2(0, -54), 6, lc)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-11, -62), p + Vector2(0, -72), p + Vector2(11, -62)]), Color(0.25, 0.25, 0.27))
			if tower_lvl > 0:
				var a := tm * 0.9
				var beam := Color(lc.r, lc.g, lc.b, 0.16)
				for s in [0.0, PI]:
					var d: Vector2 = Vector2.from_angle(a + s)
					draw_colored_polygon(PackedVector2Array([p + Vector2(0, -54), p + Vector2(0, -54) + d.rotated(0.12) * 320, p + Vector2(0, -54) + d.rotated(-0.12) * 320]), beam)
		"hut":
			_house(p + Vector2(-7, 0), 18, 12, Color(0.5, 0.38, 0.27), Color(0.35, 0.25, 0.18), on, dl)
			_house(p + Vector2(9, -6), 14, 10, Color(0.46, 0.35, 0.25), Color(0.33, 0.22, 0.16), on, dl)
		"stone":
			_house(p, 26, 18, Color(0.58, 0.57, 0.56), Color(0.3, 0.32, 0.38), on, dl)
		"pump":
			var bob := sin(tm * 3.0) * 6.0 if on and t.wk > 0 else 0.0
			draw_circle(p + Vector2(0, 6), 12, Color(0.06, 0.06, 0.07))
			draw_line(p + Vector2(-10, 8), p + Vector2(0, -20), Color(0.35, 0.3, 0.25), 3)
			draw_line(p + Vector2(10, 8), p + Vector2(0, -20), Color(0.35, 0.3, 0.25), 3)
			draw_line(p + Vector2(-16, -20 + bob), p + Vector2(16, -20 - bob), Color(0.2, 0.2, 0.22), 4)
			draw_line(p + Vector2(-16, -20 + bob), p + Vector2(-16, -4 + bob), Color(0.2, 0.2, 0.22), 2)
			draw_rect(Rect2(p + Vector2(10, -4), Vector2(10, 10)), Color(0.55, 0.2, 0.15))
		"yard":
			for k in 4:
				var o := Vector2.from_angle(k * 1.7 + t.seed * 6) * 10
				draw_colored_polygon(PackedVector2Array([p + o + Vector2(-7, 6), p + o + Vector2(0, -7), p + o + Vector2(8, 6)]), Color(0.5, 0.35, 0.25).lerp(Color(0.4, 0.42, 0.45), k / 4.0))
			draw_line(p + Vector2(-12, 8), p + Vector2(-12, -22), Color(0.6, 0.5, 0.2), 3)
			draw_line(p + Vector2(-12, -22), p + Vector2(8, -18), Color(0.6, 0.5, 0.2), 3)
			draw_line(p + Vector2(8, -18), p + Vector2(8, -6 + sin(tm) * 3), Color(0.2, 0.2, 0.2), 1)
		"farm":
			for k in 3:
				var y := -8.0 + k * 8
				draw_rect(Rect2(p + Vector2(-16, y), Vector2(32, 5)), Color(0.25, 0.18, 0.12))
				for m in 5:
					draw_circle(p + Vector2(-13 + m * 6.5, y), 2.5, Color(0.55, 0.85, 0.7) if on else Color(0.3, 0.3, 0.3))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -12), p + Vector2(0, -24), p + Vector2(18, -12)]), Color(0.5, 0.55, 0.5, 0.45))
		"lamp":
			draw_line(p + Vector2(0, 8), p + Vector2(0, -24), Color(0.15, 0.15, 0.15), 3)
			draw_line(p + Vector2(0, -24), p + Vector2(7, -24), Color(0.15, 0.15, 0.15), 2)
			var lit2: bool = on and res.oil > 0
			if lit2:
				draw_circle(p + Vector2(7, -20), 9, Color(1, 0.8, 0.4, 0.25))
			draw_circle(p + Vector2(7, -20), 4, Color(1, 0.85, 0.5) if lit2 else Color(0.3, 0.3, 0.3))
		"clinic":
			_house(p, 26, 15, Color(0.85, 0.85, 0.82), Color(0.6, 0.6, 0.62), on, dl)
			draw_rect(Rect2(p + Vector2(-3, -26), Vector2(6, 14)), Color(0.8, 0.15, 0.15))
			draw_rect(Rect2(p + Vector2(-7, -22), Vector2(14, 6)), Color(0.8, 0.15, 0.15))
		"scout":
			draw_line(p + Vector2(-8, 8), p + Vector2(-4, -26), Color(0.4, 0.3, 0.2), 3)
			draw_line(p + Vector2(8, 8), p + Vector2(4, -26), Color(0.4, 0.3, 0.2), 3)
			draw_rect(Rect2(p + Vector2(-9, -32), Vector2(18, 8)), Color(0.45, 0.35, 0.25))
			draw_line(p + Vector2(4, -32), p + Vector2(4, -44), Color(0.3, 0.3, 0.3), 1.5)
			draw_colored_polygon(PackedVector2Array([p + Vector2(4, -44), p + Vector2(14, -41 + sin(tm * 4) * 1.5), p + Vector2(4, -38)]), Color(0.75, 0.3, 0.2))
		"lab":
			_house(p, 24, 16, Color(0.45, 0.4, 0.36), Color(0.3, 0.28, 0.3), on, dl)
			var ga := tm * (1.5 if on and t.wk > 0 else 0.0)
			draw_circle(p + Vector2(10, -24), 6, Color(0.6, 0.55, 0.3))
			for k in 6:
				draw_line(p + Vector2(10, -24), p + Vector2(10, -24) + Vector2.from_angle(ga + k * TAU / 6) * 8, Color(0.6, 0.55, 0.3), 2)
			draw_circle(p + Vector2(10, -24), 2.5, Color(0.2, 0.2, 0.2))
		"green":
			draw_rect(Rect2(p + Vector2(-17, -2), Vector2(34, 10)), Color(0.35, 0.3, 0.25))
			draw_arc(p + Vector2(0, -2), 17, PI, TAU, 16, Color(0.75, 0.9, 0.95, 0.9), 2)
			draw_colored_polygon(_dome(p + Vector2(0, -2), 16), Color(0.6, 0.9, 0.8, 0.35))
			for k in 4:
				draw_circle(p + Vector2(-10 + k * 7, -5), 3, Color(0.3, 0.75, 0.35))
		"filter":
			_house(p + Vector2(-4, 0), 22, 14, Color(0.6, 0.64, 0.68), Color(0.35, 0.38, 0.42), on, dl)
			var fa := tm * (6.0 if on and t.wk > 0 else 0.0)
			draw_circle(p + Vector2(12, -20), 8, Color(0.25, 0.27, 0.3))
			for k in 3:
				draw_line(p + Vector2(12, -20), p + Vector2(12, -20) + Vector2.from_angle(fa + k * TAU / 3) * 7, Color(0.8, 0.85, 0.9), 2.5)
			if on and t.wk > 0:
				draw_arc(p, HEX * SQ3 * 2.2, 0, TAU, 48, Color(0.6, 0.85, 1, 0.12), 2)
		"brew":
			draw_rect(Rect2(p + Vector2(-16, -14), Vector2(12, 20)), Color(0.5, 0.35, 0.3))
			draw_circle(p + Vector2(-10, -14), 6, Color(0.55, 0.4, 0.33))
			draw_rect(Rect2(p + Vector2(0, -8), Vector2(16, 14)), Color(0.4, 0.3, 0.32))
			draw_rect(Rect2(p + Vector2(10, -28), Vector2(4, 20)), Color(0.3, 0.25, 0.25))
			if on and t.wk > 0:
				for k in 3:
					var sm := fmod(tm * 0.6 + k * 0.33, 1.0)
					draw_circle(p + Vector2(12 + sm * 8, -30 - sm * 20), 3 + sm * 4, Color(0.6, 0.6, 0.55, 0.5 * (1.0 - sm)))
		"beacon":
			draw_line(p + Vector2(-8, 8), p + Vector2(0, -40), Color(0.25, 0.25, 0.27), 3)
			draw_line(p + Vector2(8, 8), p + Vector2(0, -40), Color(0.25, 0.25, 0.27), 3)
			draw_line(p + Vector2(-5, -10), p + Vector2(5, -10), Color(0.25, 0.25, 0.27), 2)
			var lit3: bool = on and res.oil > 0
			if lit3:
				draw_circle(p + Vector2(0, -42), 14, Color(1, 0.85, 0.5, 0.25))
			draw_circle(p + Vector2(0, -42), 6, Color(1, 0.9, 0.6) if lit3 else Color(0.3, 0.3, 0.3))

# ================= UI =================

func _style(c: Color, border: Color = Color(0.5, 0.42, 0.3)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 8; s.content_margin_right = 8
	s.content_margin_top = 4; s.content_margin_bottom = 4
	return s

func _make_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var th := Theme.new()
	th.set_stylebox("normal", "Button", _style(Color(0.12, 0.11, 0.1, 0.92)))
	th.set_stylebox("hover", "Button", _style(Color(0.22, 0.19, 0.15, 0.95), Color(0.9, 0.7, 0.4)))
	th.set_stylebox("pressed", "Button", _style(Color(0.35, 0.26, 0.15, 0.95), Color(1, 0.8, 0.45)))
	th.set_stylebox("disabled", "Button", _style(Color(0.08, 0.08, 0.08, 0.8), Color(0.25, 0.25, 0.25)))
	th.set_stylebox("panel", "PanelContainer", _style(Color(0.07, 0.07, 0.07, 0.86)))
	th.set_color("font_color", "Button", Color(0.95, 0.88, 0.75))
	th.set_color("font_color", "Label", Color(0.95, 0.9, 0.8))
	th.set_font_size("font_size", "Button", 14)
	th.set_font_size("font_size", "Label", 14)
	var root := Control.new()
	root.theme = th
	root.size = Vector2(1280, 720)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	var tp := PanelContainer.new()
	tp.position = Vector2(0, 0)
	tp.size = Vector2(1280, 36)
	root.add_child(tp)
	top = Label.new()
	top.add_theme_font_size_override("font_size", 16)
	tp.add_child(top)
	# Bauleiste
	var bar := HBoxContainer.new()
	bar.position = Vector2(8, 662)
	bar.add_theme_constant_override("separation", 3)
	root.add_child(bar)
	for k in ORDER:
		var b := Button.new()
		b.text = "%s\n%s" % [B[k].n, _cost_str(B[k].cost)]
		b.custom_minimum_size = Vector2(80, 50)
		b.add_theme_font_size_override("font_size", 11)
		build_btns[k] = b
		b.toggle_mode = true
		b.button_pressed = k == sel
		b.tooltip_text = B[k].d
		b.pressed.connect(func():
			sel = k
			for x in bar.get_children(): x.button_pressed = x == b)
		bar.add_child(b)
	# rechts
	var sp := PanelContainer.new()
	sp.position = Vector2(1012, 44)
	sp.custom_minimum_size = Vector2(260, 0)
	root.add_child(sp)
	var side := VBoxContainer.new()
	sp.add_child(side)
	var gl := Label.new()
	gl.text = "LEUCHTFEUER"
	gl.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
	side.add_child(gl)
	var gh := HBoxContainer.new()
	side.add_child(gh)
	for n in ["Aus", "Normal", "Hell", "Grell"]:
		var b := Button.new()
		b.text = n
		b.custom_minimum_size = Vector2(58, 28)
		var lv := gen_btns.size()
		b.pressed.connect(func(): tower_lvl = lv)
		gh.add_child(b)
		gen_btns.append(b)
	var ll := Label.new()
	ll.text = "ERLASSE"
	ll.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
	side.add_child(ll)
	law_box = VBoxContainer.new()
	side.add_child(law_box)
	for k in LAWS:
		var b := Button.new()
		b.name = k
		b.tooltip_text = LAWS[k].d
		b.pressed.connect(func(): sign_law(k))
		law_box.add_child(b)
	exp_btn = Button.new()
	exp_btn.text = "⚙ FORSCHUNG  (T)"
	exp_btn.pressed.connect(func(): tech_panel.visible = not tech_panel.visible)
	side.add_child(exp_btn)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 13)
	side.add_child(info)
	# Chronik links
	var lp := PanelContainer.new()
	lp.position = Vector2(8, 44)
	lp.custom_minimum_size = Vector2(320, 230)
	root.add_child(lp)
	logl = RichTextLabel.new()
	logl.bbcode_enabled = true
	logl.custom_minimum_size = Vector2(304, 220)
	logl.add_theme_font_size_override("normal_font_size", 13)
	logl.add_theme_color_override("default_color", Color(0.92, 0.86, 0.74))
	lp.add_child(logl)
	var help := Label.new()
	help.position = Vector2(12, 290)
	help.text = "Links: bauen · Ruinen ausschlachten\nRechts: Gebäude an/aus\nWASD/Mitte ziehen: Kamera · Rad: Zoom\nLeertaste: Pause · 1/2/3: Tempo\nKlick auf Turm: Lichtstufe\nKlick auf Höhle/Bunker: Erkundung\nT: Forschung"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75, 0.8))
	root.add_child(help)
	# Ereignis-Fenster
	popup = PanelContainer.new()
	popup.position = Vector2(390, 250)
	popup.custom_minimum_size = Vector2(500, 0)
	popup.add_theme_stylebox_override("panel", _style(Color(0.1, 0.09, 0.08, 0.97), Color(1, 0.75, 0.4)))
	popup.visible = false
	root.add_child(popup)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	popup.add_child(pv)
	pop_text = Label.new()
	pop_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	pop_text.custom_minimum_size = Vector2(480, 0)
	pop_text.add_theme_font_size_override("font_size", 17)
	pv.add_child(pop_text)
	pop_btns = HBoxContainer.new()
	pop_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	pop_btns.add_theme_constant_override("separation", 16)
	pv.add_child(pop_btns)
	tech_panel = PanelContainer.new()
	tech_panel.position = Vector2(300, 120)
	tech_panel.visible = false
	tech_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.08, 0.1, 0.97), Color(0.5, 0.75, 1)))
	root.add_child(tech_panel)
	var tv := VBoxContainer.new()
	tech_panel.add_child(tv)
	var tl := Label.new()
	tl.text = "FORSCHUNG – Werkstätten erzeugen Wissen, Bunker enthalten Pläne"
	tl.add_theme_color_override("font_color", Color(0.6, 0.85, 1))
	tv.add_child(tl)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)
	tv.add_child(grid)
	for br in BRANCHES:
		var col := VBoxContainer.new()
		grid.add_child(col)
		var bl := Label.new()
		bl.text = br[0]
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(bl)
		for id in br[1]:
			var tb := Button.new()
			tb.custom_minimum_size = Vector2(150, 54)
			tb.tooltip_text = TECH[id].d
			tb.pressed.connect(func(): research(id))
			col.add_child(tb)
			tech_btns[id] = tb
			if id != br[1][2]:
				var ar := Label.new()
				ar.text = "↓"
				ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				col.add_child(ar)
	var tc := Button.new()
	tc.text = "Schließen"
	tc.pressed.connect(func(): tech_panel.visible = false)
	tv.add_child(tc)
	banner = Label.new()
	banner.size = Vector2(1280, 720)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 40)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 12)
	banner.visible = false
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(banner)
	_refresh_log()

func _cost_str(c: Dictionary) -> String:
	var s := []
	for k in c:
		s.append("%d %s" % [c[k], RES_NAME[k]])
	return ", ".join(s)

func _bar(v: float) -> String:
	var n := clampi(int(v / 10), 0, 10)
	return "█".repeat(n) + "░".repeat(10 - n)

func _update_ui() -> void:
	top.text = "  Tag %d/%d   %02d:00 %s   │   Öl %d   Schrott %d   Nahrung %d   Wasser %d   │   Bewohner %d   Befallen %d   Wohnraum %d" % [
		day, LAST_DAY, hour, "  ☁ NEBELFLUT" if flood_now() else "", res.oil, res.scrap, res.food, res.water, pop, infected, housing()]
	var free := pop - infected
	for t in tiles: free -= t.wk
	var s := "Zuversicht %s %d\nZorn       %s %d\nLinsen-Hitze %d%%\nFreie Hände %d" % [_bar(hope), hope, _bar(anger), anger, wear, maxi(0, free)]
	s += "\nWissen %d" % res.know
	if striking: s += "\n[STREIK – Produktion halbiert]"
	if creatures.size() > 0: s += "\n⚠ %d Wucherer unterwegs!" % creatures.size()
	if hover >= 0:
		var h: Dictionary = tiles[hover]
		var tn: String = {"ground": "Boden", "fungus": "Pilzfeld", "oil": "Ölquelle", "ruin": "Ruine", "rock": "Fels"}[h.terr]
		var nm: String = "Leuchtturm" if h.type == "tower" else (B[h.type].n if h.type in B else tn)
		s += "\n\n[%s]%s" % [nm, " – im Licht" if h.get("lit", true) else " – im NEBEL"]
		if h.type in B:
			s += "\n" + B[h.type].d
			if h.grown: s += "\nÜBERWUCHERT – klicken (8 Schrott)"
			elif B[h.type].w > 0: s += "\nArbeiter %d/%d" % [h.wk, B[h.type].w]
	info.text = s
	for i in gen_btns.size():
		gen_btns[i].modulate = Color(1, 0.75, 0.35) if i == tower_lvl else Color(1, 1, 1)
	for b in law_box.get_children():
		b.disabled = b.name in laws or law_cd > 0
		b.text = LAWS[b.name].n + ("  ✓" if b.name in laws else "")
	for k in build_btns:
		build_btns[k].visible = not B[k].has("req") or has_tech(B[k].req)
	if tech_panel.visible:
		for id in tech_btns:
			var tb: Button = tech_btns[id]
			tb.text = "%s\n%s" % [TECH[id].n, "✓ erforscht" if has_tech(id) else "%d Wissen" % TECH[id].c]
			tb.disabled = not can_research(id) and not has_tech(id)
			tb.modulate = Color(0.6, 1, 0.6) if has_tech(id) else Color(1, 1, 1)

func say(s: String) -> void:
	if autotest and OS.get_cmdline_user_args().has("--verbose"): print(s)
	log_lines.push_front("• " + s)
	if log_lines.size() > 10: log_lines.pop_back()
	_refresh_log()

func _refresh_log() -> void:
	if logl: logl.text = "\n".join(log_lines)

func _win() -> void:
	over = "win"
	banner.text = "DAS LICHT BRENNT WEITER\n%d Überlebende · %d Tote\nIm Norden antwortet ein zweites Feuer." % [pop, deaths]
	banner.visible = true
	if autotest and not "--shot" in OS.get_cmdline_user_args():
		print("RESULT WIN pop=%d deaths=%d" % [pop, deaths]); get_tree().quit()

func _lose(why: String) -> void:
	over = "lose"
	banner.text = "DAS LICHT IST ERLOSCHEN\n" + why + "\n\nR = Neustart"
	banner.visible = true
	if autotest and not "--shot" in OS.get_cmdline_user_args():
		print("RESULT LOSE day=%d %s" % [day, why]); get_tree().quit()

func _shot() -> void:
	if "--zoom" in OS.get_cmdline_user_args(): cam.zoom = Vector2(2.0, 2.0); cam.position = Vector2(20, -20)
	for n in [5.0, 9.0]:
		await get_tree().create_timer(n).timeout
		get_viewport().get_texture().get_image().save_png("res://shot%d.png" % int(n))
	get_tree().quit()

func _draw_markers() -> void:
	var tm := Time.get_ticks_msec() / 1000.0
	var f := clampf(hour_t / SEC_PER_HOUR, 0, 1)
	var ctex: Texture2D = SPR.get("creature")
	for c in creatures:
		var cp: Vector2 = (c.prev as Vector2).lerp(c.pos, f)
		var sway := sin(tm * 4 + cp.x) * 0.08
		if ctex:
			var hh := 34.0
			var ww := hh * ctex.get_width() / ctex.get_height()
			markers.draw_set_transform(cp, sway, Vector2(1, 1))
			markers.draw_circle(Vector2.ZERO, 8, Color(0.3, 1, 0.7, 0.18))
			markers.draw_texture_rect(ctex, Rect2(Vector2(-ww * 0.5, -hh), Vector2(ww, hh)), false)
			markers.draw_set_transform(Vector2.ZERO)
		else:
			markers.draw_circle(cp, 6, Color(0.4, 0.9, 0.6))
	for sh in shots:
		markers.draw_line(sh.a, sh.b, Color(1, 0.6, 0.2, sh.t), 3)
		markers.draw_circle(sh.b, 10 * sh.t, Color(1, 0.5, 0.1, sh.t * 0.7))
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if not t.terr in ["cave", "bunker"]:
			continue
		var p: Vector2 = t.pos
		var ex: bool = t.get("explored", false)
		if spr(markers, t.terr, p + Vector2(0, 6), Color(0.75, 0.75, 0.75) if ex else Color.WHITE):
			pass
		elif t.terr == "bunker":
			markers.draw_rect(Rect2(p + Vector2(-16, -6), Vector2(32, 14)), Color(0.4, 0.42, 0.4))
			markers.draw_rect(Rect2(p + Vector2(-8, -2), Vector2(16, 10)), Color(0.08, 0.08, 0.08))
			for k in 4:
				markers.draw_line(p + Vector2(-16 + k * 8, -6), p + Vector2(-12 + k * 8, -10), Color(0.9, 0.75, 0.1), 3)
		else:
			markers.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 8), p + Vector2(-12, -14), p + Vector2(0, -20), p + Vector2(13, -12), p + Vector2(20, 8)]), Color(0.32, 0.28, 0.33))
			markers.draw_colored_polygon(_dome(p + Vector2(0, 8), 9), Color(0.04, 0.03, 0.05))
			markers.draw_circle(p + Vector2(-14, 4), 3, Color(0.5, 0.95, 0.8))
		if not ex:
			var a := 0.6 + 0.4 * sin(tm * 3 + i)
			markers.draw_arc(p, 24, 0, TAU, 24, Color(1, 0.8, 0.4, a), 2)
			markers.draw_string(font, p + Vector2(-26, 28), "BUNKER" if t.terr == "bunker" else "HÖHLE", HORIZONTAL_ALIGNMENT_CENTER, 52, 11, Color(1, 0.85, 0.5, a))
		else:
			markers.draw_string(font, p + Vector2(-26, 28), "erkundet", HORIZONTAL_ALIGNMENT_CENTER, 52, 10, Color(0.6, 0.6, 0.6))

func _shotx() -> void:
	var e := Explore.new()
	e.setup("bunker" if "--shotx" in OS.get_cmdline_user_args() else "cave", 4242, 13, 4, true)
	ui.add_child(e)
	for k in 5:
		var opts: Array = e.rooms[e.cur].links
		e.move_to(opts[k % opts.size()])
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://shotx.png")
	get_tree().quit()

# ================= Wucherer =================

func _tick_creatures() -> void:
	var night := hour >= 21 or hour < 5
	for c in creatures:
		c.prev = c.pos
	if night and day >= 3:
		var chance := 0.06 + day * 0.025
		if flood_now(): chance *= 1.8
		if nest_burned: chance *= 0.5
		if rng.randf() < chance:
			var a := rng.randf() * TAU
			var start := Vector2.from_angle(a) * HEX * SQ3 * (MAP_R + 0.5)
			var best := -1
			var bd := 1e9
			for i in tiles.size():
				var t: Dictionary = tiles[i]
				if t.type in B and not t.grown:
					var d: float = start.distance_to(t.pos)
					if d < bd:
						bd = d; best = i
			if best >= 0:
				creatures.append({"pos": start, "prev": start, "target": best, "hp": 2})
	var src := light_sources()
	var guards := []
	for t in tiles:
		if t.type == "guard" and t.wk > 0 and not t.grown:
			guards.append(t)
	for c in creatures.duplicate():
		if not night:
			c.hp = 0
			continue
		var tp: Vector2 = tiles[c.target].pos
		var spd := HEX * SQ3 * (0.8 if lit_at(c.pos, src) < 0.5 else 0.45)
		c.pos = (c.pos as Vector2).move_toward(tp, spd)
		for g in guards:
			if (g.pos as Vector2).distance_to(c.pos) < HEX * SQ3 * 3.0 and rng.randf() < 0.35 * g.wk / 3.0:
				c.hp -= 1
				shots.append({"a": g.pos + Vector2(0, -30), "b": c.pos, "t": 0.6})
		if c.hp > 0 and (c.pos as Vector2).distance_to(tp) < 8.0:
			var t: Dictionary = tiles[c.target]
			if t.type in B and not t.grown:
				t.grown = true
				t.dark = 20
				var victims := rng.randi_range(1, 3) if B[t.type].get("house", 0) > 0 or B[t.type].w > 0 else 0
				say("[color=#ff6040]Ein Wucherer hat %s verwüstet![/color]" % B[t.type].n)
				if victims > 0: _kill(victims, "von Wucherern gerissen")
				anger += 2
			c.hp = 0
	creatures = creatures.filter(func(c): return c.hp > 0)
