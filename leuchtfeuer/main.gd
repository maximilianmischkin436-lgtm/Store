extends Node2D
## DAS LEUCHTFEUER — Licht gegen den Nebel.
## Tagsüber bauen und ausbauen, nachts Wellen von Wucherern abwehren.
## Jede Nacht bringt eine Karte, jeder Lauf Glut für die Glutschmiede.

const Explore := preload("res://explore.gd")
const Meta := preload("res://meta.gd")

const HEX := 34.0
const MAP_R := 7
const SQ3 := 1.7320508
const DAY_LEN := 45.0
const MAX_LVL := 5

# ---------------------------------------------------------------- Gebäude
## prod: Ertrag pro Sekunde bei voller Besetzung (Stufe 1)
const B := {
	"hut":    {"n": "Hütte", "cost": 15, "hp": 60, "w": 0, "house": 6, "d": "Wohnraum für 6 Bewohner."},
	"pump":   {"n": "Ölpumpe", "cost": 25, "hp": 70, "w": 3, "prod": {"oil": 0.9}, "terr": "oil", "d": "Fördert Öl. Nur auf Ölquellen."},
	"yard":   {"n": "Schrottplatz", "cost": 15, "hp": 70, "w": 3, "prod": {"scrap": 0.55}, "bonus": "ruin", "d": "Sammelt Schrott. Doppelt auf Ruinen."},
	"farm":   {"n": "Pilzzucht", "cost": 20, "hp": 60, "w": 3, "prod": {"food": 0.75}, "bonus": "fungus", "d": "Erzeugt Nahrung. Doppelt auf Pilzfeldern."},
	"water":  {"n": "Wasserwerk", "cost": 25, "hp": 70, "w": 2, "prod": {"food": 0.35, "oil": 0.15}, "d": "Kleiner Ertrag an Nahrung und Öl."},
	"lamp":   {"n": "Laterne", "cost": 20, "hp": 40, "w": 0, "lamp": 2.3, "burn": 0.05, "d": "Licht verbrennt Wucherer. Braucht Öl."},
	"guard":  {"n": "Wachturm", "cost": 40, "hp": 90, "w": 2, "dmg": 11.0, "rate": 1.1, "range": 3.2, "d": "Schießt Feuer auf Wucherer."},
	"clinic": {"n": "Werkhütte", "cost": 35, "hp": 70, "w": 2, "repair": 3.0, "d": "Repariert Gebäude in der Nähe."},
	"scout":  {"n": "Späherposten", "cost": 30, "hp": 60, "w": 1, "d": "Erlaubt Erkundungen von Höhlen und Bunkern."},
	"beacon": {"n": "Leuchtmast", "cost": 60, "hp": 80, "w": 0, "lamp": 3.6, "burn": 0.12, "unlock": "u_beacon", "d": "Großes Licht, verbrennt stark."},
	"mortar": {"n": "Feuerkanone", "cost": 70, "hp": 100, "w": 3, "dmg": 22.0, "rate": 0.35, "range": 4.0, "splash": 1.2, "unlock": "u_mortar", "d": "Langsam, trifft mehrere Gegner."},
	"forge":  {"n": "Glutofen", "cost": 80, "hp": 70, "w": 2, "glut": 0.02, "unlock": "u_forge", "d": "Gewinnt Glut im Leerlauf."},
}
const ORDER := ["hut", "pump", "yard", "farm", "water", "lamp", "guard", "clinic", "scout", "beacon", "mortar", "forge"]
const SPRITE_OF := {"clinic": "clinic", "mortar": "guard", "forge": "brew"}

# ---------------------------------------------------------------- Karten
## id: [Name, Beschreibung, Seltenheit 0..2]
const CARDS := {
	"oil": ["Tiefe Quellen", "Öl +25 %", 0], "scrap": ["Schrottsammler", "Schrott +25 %", 0], "food": ["Pilzgarten", "Nahrung +25 %", 0],
	"gdmg": ["Brandpfeile", "Wachen +25 % Schaden", 0], "grate": ["Schnelle Hände", "Wachen feuern 20 % schneller", 1],
	"grange": ["Hohe Türme", "Wachen +0,6 Felder Reichweite", 1], "burn": ["Gleißen", "Licht verbrennt 40 % stärker", 1],
	"radius": ["Klare Linse", "Turmlicht +0,4 Felder", 1], "pulse": ["Sonnenkern", "Lichtstoß +40 % Schaden", 1],
	"pulsecd": ["Schneller Funke", "Lichtstoß 20 % schneller bereit", 1], "hp": ["Stahlbalken", "Gebäude +30 % Lebenspunkte", 0],
	"pop": ["Flüchtlinge", "+5 Bewohner, Hütten +1 Platz", 0], "glut": ["Glutfänger", "+30 % Glut", 2],
	"cheap": ["Sparsam", "Bauen und Ausbauen 15 % billiger", 1], "regen": ["Selbstheilung", "Gebäude heilen 1,5 LP/s", 2],
	"slow": ["Blendung", "Wucherer im Licht 25 % langsamer", 1], "crit": ["Glutspitzen", "Wachen: 15 % Chance auf dreifachen Schaden", 2],
	"tower": ["Bollwerk", "Turm +150 Lebenspunkte und volle Heilung", 0],
}
const RARITY_COL := [Color(0.75, 0.78, 0.82), Color(0.45, 0.75, 1.0), Color(0.85, 0.55, 1.0)]
const RARITY_NAME := ["Gewöhnlich", "Selten", "Episch"]

# ---------------------------------------------------------------- Gegner
const FOES := {
	"crawler": {"n": "Kriecher", "hp": 28.0, "spd": 34.0, "dmg": 4.0, "glut": 1, "size": 30.0},
	"runner":  {"n": "Läufer", "hp": 18.0, "spd": 72.0, "dmg": 4.0, "glut": 1, "size": 26.0},
	"brute":   {"n": "Wüterich", "hp": 130.0, "spd": 22.0, "dmg": 16.0, "glut": 4, "size": 44.0},
	"spitter": {"n": "Sporenspeier", "hp": 40.0, "spd": 30.0, "dmg": 10.0, "glut": 2, "size": 32.0, "ranged": true},
	"boss":    {"n": "Koloss", "hp": 480.0, "spd": 15.0, "dmg": 22.0, "glut": 30, "size": 72.0},
}

# ---------------------------------------------------------------- Aufträge
const QUESTS := [
	["kills", "Töte %d Wucherer", [25, 60, 120]],
	["build", "Errichte %d Gebäude", [6, 12, 20]],
	["upgrade", "Baue %d Stufen aus", [4, 10, 20]],
	["nights", "Überstehe %d Nächte", [3, 6, 10]],
	["pulse", "Töte %d Wucherer mit dem Lichtstoß", [8, 20, 40]],
	["explore", "Erkunde %d Orte", [1, 2, 3]],
	["boss", "Besiege %d Koloss", [1, 1, 2]],
]

# ================================================================ Zustand
var meta := Meta.new()
var state := "menu"          # menu, play, cards, over, explore
var res := {"oil": 0.0, "scrap": 0.0, "food": 0.0}
var rates := {"oil": 0.0, "scrap": 0.0, "food": 0.0}
var pop := 12
var pop_t := 0.0
var night := 0
var is_night := false
var phase_t := 0.0
var spawn_left := 0
var spawn_t := 0.0
var tower_hp := 400.0
var tower_max := 400.0
var tower_lvl := 1
var pulse_cd := 0.0
var perks := {}
var quests: Array = []
var run_glut := 0.0
var run_kills := 0
var tiles: Array = []
var idx := {}
var draw_order: Array = []
var creatures: Array = []
var bolts: Array = []
var rings: Array = []
var floats: Array = []
var walkers: Array = []
var sel_build := "hut"
var sel_tile := -1
var hover := -1
var speed := 1.0
var autotest := false
var rng := RandomNumberGenerator.new()
var font: Font
var stress_v := 0.0
var flash_v := 0.0
var shake := 0.0
var reroll_left := 0
var card_opts: Array = []
var explore_node: Control

# Szene
var cam: Camera2D
var cam_target := Vector2(40, 10)
var fog_mat: ShaderMaterial
var post_mat: ShaderMaterial
var night_mod: CanvasModulate
var spores: CPUParticles2D
var tower_light: PointLight2D
var glow_tex: GradientTexture2D
var lamp_lights := {}
var markers: Node2D
var SPR := {}

# UI
var ui: CanvasLayer
var root: Control
var th: Theme
var top: RichTextLabel
var phase_bar: ProgressBar
var phase_lbl: Label
var night_btn: Button
var pulse_btn: Button
var quest_lbl: RichTextLabel
var logl: RichTextLabel
var log_lines: Array = []
var side: PanelContainer
var side_lbl: RichTextLabel
var up_btn: Button
var rep_btn: Button
var tower_bar: ProgressBar
var build_btns := {}
var hud_nodes: Array = []
var menu_box: Control
var forge_box: Control
var card_box: Control
var over_box: Control

# ================================================================ Start
func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	meta.load_data()
	var args := OS.get_cmdline_user_args()
	autotest = "--autotest" in args
	_gen_map()
	_load_sprites()
	_make_world()
	_make_post()
	_make_audio()
	_make_ui()
	if autotest:
		meta = Meta.new()
		if "--meta" in args:
			for id in Meta.UPGRADES: meta.lvl[id] = mini(3, Meta.UPGRADES[id][2])
		start_run()
		speed = 1.0
		Engine.time_scale = 6.0
	elif "--shot" in args:
		start_run()
		_shot()
	elif "--shotmenu" in args:
		meta.glut = 640
		show_menu()
		_shot_menu()
	else:
		show_menu()

func start_run() -> void:
	rng.randomize()
	tiles.clear(); idx.clear(); creatures.clear(); bolts.clear(); rings.clear(); floats.clear()
	for k in lamp_lights: lamp_lights[k].queue_free()
	lamp_lights.clear()
	_gen_map()
	draw_order = range(tiles.size())
	draw_order.sort_custom(func(a, b): return tiles[a].pos.y < tiles[b].pos.y)
	res = {"oil": 80.0 + meta.level("start_oil") * 50, "scrap": 70.0 + meta.level("start_scrap") * 40, "food": 40.0}
	pop = 12
	night = 0
	is_night = false
	phase_t = DAY_LEN + 15.0
	tower_lvl = 1
	tower_max = 400.0 * (1.0 + 0.2 * meta.level("tower_hp"))
	tower_hp = tower_max
	pulse_cd = 0.0
	perks = {}
	run_glut = 0.0
	run_kills = 0
	quests.clear()
	for i in 3: quests.append(_new_quest())
	var starter := 0
	for i in tiles.size():
		if tiles[i].d == 1 and starter < 2 and tiles[i].terr == "ground":
			var t: Dictionary = tiles[i]
			t.type = "hut"; t.lvl = 1; t.maxhp = bmaxhp(t); t.hp = t.maxhp
			starter += 1
	log_lines.clear()
	sel_tile = -1
	state = "play"
	_hide_overlays()
	for n in hud_nodes: n.visible = true
	say("Der Nebel kommt jede Nacht. Halte das Licht am Brennen.")
	say("Baue Ölpumpen, Hütten und Wachtürme, bevor es dunkel wird.")
	meta.runs += 1
	meta.save_data()

# ================================================================ Karte
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
	if dq > dr and dq > ds: q = -r - s
	elif dr > ds: r = -q - s
	return Vector2i(q, r)

func _gen_map() -> void:
	tiles.clear(); idx.clear()
	for q in range(-MAP_R, MAP_R + 1):
		for r in range(-MAP_R, MAP_R + 1):
			var s := -q - r
			if absi(s) > MAP_R: continue
			var d := (absi(q) + absi(r) + absi(s)) / 2
			var t := {"q": q, "r": r, "d": d, "pos": hex_pos(q, r), "terr": "ground", "type": "", "lvl": 1,
				"hp": 0.0, "maxhp": 0.0, "wk": 0, "cd": 0.0, "ruined": false, "born": -10.0,
				"shade": rng.randf_range(-0.05, 0.05), "seed": rng.randf(), "explored": false}
			if d == 0:
				t.type = "tower"
			elif d >= 2:
				var x := rng.randf()
				if x < 0.10: t.terr = "ruin"
				elif x < 0.16: t.terr = "oil"
				elif x < 0.27: t.terr = "fungus"
				elif x < 0.32 and d >= 3: t.terr = "rock"
			idx[Vector2i(q, r)] = tiles.size()
			tiles.append(t)
	var cands := []
	for t in tiles:
		if t.d >= 5 and t.terr == "ground": cands.append(t)
	for k in ["cave", "cave", "bunker", "cave", "bunker"]:
		var t: Dictionary = cands[rng.randi() % cands.size()]
		cands.erase(t)
		t.terr = k
	var n_oil := 0
	for t in tiles:
		if t.d == 2 and n_oil < 2:
			t.terr = "oil"; n_oil += 1

# ================================================================ Werte & Formeln
func pk(id: String) -> int:
	return perks.get(id, 0)

func lvl_mul(l: int) -> float:
	return 1.0 + 0.6 * (l - 1)

func build_cost(type: String) -> int:
	return int(B[type].cost * pow(0.85, pk("cheap")))

func upgrade_cost(t: Dictionary) -> int:
	if t.type == "tower":
		return int(60 * pow(1.9, tower_lvl - 1) * pow(0.85, pk("cheap")))
	return int(B[t.type].cost * 0.9 * pow(1.75, t.lvl) * pow(0.85, pk("cheap")))

func repair_cost(t: Dictionary) -> int:
	return int(build_cost(t.type) * 0.5)

func bmaxhp(t: Dictionary) -> float:
	return B[t.type].hp * 1.3 * lvl_mul(t.lvl) * (1.0 + 0.2 * meta.level("bhp")) * (1.0 + 0.3 * pk("hp"))

func housing() -> int:
	var h := 0
	for t in tiles:
		if t.type in B and not t.ruined:
			h += int((B[t.type].get("house", 0) + (pk("pop") if t.type == "hut" else 0)) * lvl_mul(t.lvl))
	return h

func tower_radius() -> float:
	var hw := HEX * SQ3
	var r := 2.4 + tower_lvl * 0.45 + 0.3 * meta.level("light") + 0.4 * pk("radius")
	if res.oil <= 0: r = 1.2
	return r * hw

func burn_dps() -> float:
	return (6.0 + tower_lvl * 2.0) * (1.0 + 0.2 * meta.level("burn")) * (1.0 + 0.4 * pk("burn"))

func glut_mul() -> float:
	return (1.0 + 0.15 * meta.level("glut")) * (1.0 + 0.3 * pk("glut"))

func light_sources() -> Array:
	var out := [Vector3(0, -40, tower_radius())]
	if res.oil > 0:
		for t in tiles:
			if t.type in B and B[t.type].has("lamp") and not t.ruined:
				out.append(Vector3(t.pos.x, t.pos.y, B[t.type].lamp * HEX * SQ3 * (1.0 + 0.15 * (t.lvl - 1))))
	return out

func lit_at(p: Vector2, src: Array) -> float:
	var lit := 0.0
	for L in src:
		var d: float = p.distance_to(Vector2(L.x, L.y)) / L.z
		lit = maxf(lit, 1.0 - smoothstep(0.55, 1.0, d))
	return lit

func daylight() -> float:
	if state == "menu": return 0.15
	if is_night: return clampf(0.25 - phase_t * 0.01, 0.05, 0.25)
	return clampf(phase_t / 8.0, 0.25, 1.0) if phase_t < 8.0 else 1.0

# ================================================================ Simulation
func _process(delta: float) -> void:
	var sd := delta * speed
	if state == "play":
		_sim(sd)
	stress_v = lerpf(stress_v, _calc_stress(), 1.0 - exp(-delta * 1.5))
	flash_v = maxf(0.0, flash_v - delta * 2.0)
	shake = maxf(0.0, shake - delta * 2.5)
	if post_mat:
		post_mat.set_shader_parameter("stress", stress_v)
		post_mat.set_shader_parameter("night", 1.0 - daylight())
		post_mat.set_shader_parameter("flash", flash_v)
	_update_audio(delta)
	_update_visuals(delta, sd)
	if state != "menu":
		_update_ui()
	queue_redraw()
	markers.queue_redraw()

func _sim(dt: float) -> void:
	if autotest: _bot(dt)
	# ---- Phasen
	if is_night:
		phase_t += dt
		spawn_t -= dt
		if spawn_left > 0 and spawn_t <= 0:
			_spawn_foe()
			spawn_left -= 1
			spawn_t = maxf(0.35, 2.2 - night * 0.08) * rng.randf_range(0.6, 1.3)
		if spawn_left == 0 and creatures.is_empty() and phase_t > 6.0:
			_end_night()
			return
		if phase_t > 55.0 + night * 2.0 and spawn_left == 0:
			# Das Morgenlicht verbrennt die Nachzügler
			for c in creatures:
				rings.append({"p": c.pos, "r": 4.0, "max": 34.0, "t": 0.5, "c": Color(1, 0.9, 0.6)})
			creatures.clear()
			say("Das erste Tageslicht verbrennt die letzten Wucherer.")
			_end_night()
			return
	else:
		phase_t -= dt
		if phase_t <= 0:
			_start_night()
	# ---- Wirtschaft
	var free := pop
	var prod_mul := 1.0 + 0.1 * meta.level("prod")
	for k in rates: rates[k] = 0.0
	var burn := 0.18 + tower_lvl * 0.06
	for t in tiles:
		t.wk = 0
		if not (t.type in B) or t.ruined: continue
		var b: Dictionary = B[t.type]
		if b.has("burn"): burn += b.burn * (1.0 + 0.3 * (t.lvl - 1))
		var need: int = b.w
		if need > 0:
			var w := mini(need, free)
			free -= w
			t.wk = w
		var f := (float(t.wk) / need if need > 0 else 1.0) * lvl_mul(t.lvl) * prod_mul
		if b.get("bonus", "") == t.terr: f *= 2.0
		for k in b.get("prod", {}):
			var m := 1.0 + 0.25 * pk(k)
			rates[k] += b.prod[k] * f * m
		if b.has("glut") and t.wk > 0:
			_add_glut(b.glut * f * dt)
		if b.has("repair") and t.wk > 0:
			for o in tiles:
				if o.type in B and not o.ruined and o.hp < o.maxhp and (o.pos as Vector2).distance_to(t.pos) < HEX * SQ3 * 2.5:
					o.hp = minf(o.maxhp, o.hp + b.repair * f * dt)
		if pk("regen") > 0 and t.hp < t.maxhp:
			t.hp = minf(t.maxhp, t.hp + 1.5 * pk("regen") * dt)
	rates.oil -= burn
	rates.food -= pop * 0.045
	for k in rates:
		res[k] = maxf(0.0, res[k] + rates[k] * dt)
	# Bevölkerung
	pop_t += dt
	var grow_every := 7.0 / (1.0 + 0.2 * meta.level("growth"))
	if res.food > 1 and pop < housing() and pop_t > grow_every:
		pop_t = 0.0; pop += 1
	elif res.food <= 0 and pop > 1 and pop_t > 5.0:
		pop_t = 0.0; pop -= 1
		say("[color=#ff8a6a]Hunger.[/color] Ein Bewohner ist gestorben.")
	pulse_cd = maxf(0.0, pulse_cd - dt)
	# ---- Kampf
	_sim_guards(dt)
	_sim_creatures(dt)
	_sim_bolts(dt)
	if tower_hp <= 0:
		_game_over()

func _start_night() -> void:
	night += 1
	is_night = true
	phase_t = 0.0
	var n := int(3 + night * 1.8 + pow(night, 1.5) * 0.45)
	spawn_left = n
	spawn_t = 1.0
	if night % 5 == 1 and night > 1:
		_spawn_foe("boss")
		say("[color=#ff5a4a]Ein Koloss erhebt sich aus dem Nebel.[/color]")
		sfx("alarm", -2.0)
	say("[color=#9fb4ff]Nacht %d[/color] · %d Wucherer nähern sich." % [night, n])
	sfx("bell", -4.0)

func _end_night() -> void:
	is_night = false
	var bonus := int((10 + night * 6) * glut_mul())
	_add_glut(bonus)
	res.scrap += 10 + night * 5
	_quest_progress("nights", 1)
	say("[color=#ffd27a]Morgengrauen.[/color] Nacht %d überstanden · +%d Glut" % [night, bonus])
	sfx("win", -8.0)
	phase_t = DAY_LEN
	open_cards()

func _foe_scale() -> float:
	return pow(1.2, night - 1)

func _spawn_foe(force: String = "") -> void:
	var type := force
	if type == "":
		var pool := ["crawler", "crawler", "crawler"]
		if night >= 2: pool.append("runner")
		if night >= 3: pool.append("spitter")
		if night >= 4: pool.append("brute")
		if night >= 7: pool += ["runner", "brute"]
		type = pool[rng.randi() % pool.size()]
	var f: Dictionary = FOES[type]
	var a := rng.randf() * TAU
	var p := Vector2.from_angle(a) * HEX * SQ3 * (MAP_R + 0.8)
	var hp: float = f.hp * _foe_scale()
	creatures.append({"type": type, "pos": p, "hp": hp, "max": hp, "spd": f.spd, "dmg": f.dmg * sqrt(_foe_scale()),
		"target": -1, "atk": 0.0, "wob": rng.randf() * 10.0})
	if rng.randf() < 0.3: sfx("growl", -12.0)

func _find_target(p: Vector2) -> int:
	var best := 0
	var bd := 1e9
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if t.type == "tower" or (t.type in B and not t.ruined):
			var d: float = p.distance_to(t.pos) * (1.4 if t.type == "tower" else 1.0)
			if d < bd: bd = d; best = i
	return best

func _sim_creatures(dt: float) -> void:
	var src := light_sources()
	var bdps := burn_dps()
	var dead := []
	for c in creatures:
		var f: Dictionary = FOES[c.type]
		if c.target < 0 or (tiles[c.target].type != "tower" and (tiles[c.target].ruined or tiles[c.target].type == "")):
			c.target = _find_target(c.pos)
		var t: Dictionary = tiles[c.target]
		var tp: Vector2 = t.pos
		var lit := lit_at(c.pos, src)
		# Licht verbrennt
		if lit > 0.3:
			c.hp -= bdps * lit * dt * (0.4 if c.type == "boss" else 1.0)
		var spd: float = c.spd * (1.0 - 0.25 * pk("slow") * lit)
		var reach := 70.0 if f.get("ranged", false) else 16.0
		if (c.pos as Vector2).distance_to(tp) > reach:
			c.pos = (c.pos as Vector2).move_toward(tp, spd * dt)
		else:
			c.atk -= dt
			if c.atk <= 0:
				c.atk = 1.0
				if f.get("ranged", false):
					bolts.append({"a": c.pos, "p": c.pos, "b": tp, "spd": 220.0, "dmg": c.dmg, "foe": true, "tgt": c.target})
				else:
					_hit_tile(c.target, c.dmg)
		if c.hp <= 0:
			dead.append(c)
	for c in dead:
		_kill_foe(c, false)

func _hit_tile(i: int, dmg: float) -> void:
	var t: Dictionary = tiles[i]
	if t.type == "tower":
		tower_hp -= dmg
		shake = maxf(shake, 0.35)
		if tower_hp < tower_max * 0.3 and rng.randf() < 0.1:
			sfx("alarm", -8.0)
		return
	if not (t.type in B) or t.ruined: return
	t.hp -= dmg
	if t.hp <= 0:
		t.ruined = true
		t.hp = 0
		say("[color=#ff6a5a]Zerstört:[/color] %s" % B[t.type].n)
		shake = 0.8
		flash_v = 0.3
		sfx("alarm", -6.0)

func _kill_foe(c: Dictionary, by_pulse: bool) -> void:
	if not c in creatures: return
	creatures.erase(c)
	var g: int = FOES[c.type].glut
	_add_glut(g * glut_mul())
	res.scrap += 1 + g
	run_kills += 1
	_quest_progress("kills", 1)
	if by_pulse: _quest_progress("pulse", 1)
	if c.type == "boss":
		_quest_progress("boss", 1)
		say("[color=#ffd27a]Der Koloss fällt.[/color]")
		shake = 1.0
	floats.append({"p": c.pos + Vector2(0, -20), "t": 1.0, "s": "+%d" % int(g * glut_mul()), "c": Color(1, 0.6, 0.25)})
	rings.append({"p": c.pos, "r": 4.0, "max": 30.0, "t": 0.4, "c": Color(0.5, 1, 0.75)})

func _sim_guards(dt: float) -> void:
	for t in tiles:
		if not (t.type in B) or t.ruined or not B[t.type].has("dmg") or t.wk == 0: continue
		var b: Dictionary = B[t.type]
		t.cd -= dt * (1.0 + 0.2 * pk("grate"))
		if t.cd > 0: continue
		var rng_px: float = (b.range + 0.6 * pk("grange") + 0.25 * (t.lvl - 1)) * HEX * SQ3
		var best: Dictionary = {}
		var bd := 1e9
		for c in creatures:
			var d: float = (c.pos as Vector2).distance_to(t.pos)
			if d < rng_px and d < bd: bd = d; best = c
		if best.is_empty(): continue
		t.cd = 1.0 / b.rate
		var dmg: float = b.dmg * lvl_mul(t.lvl) * (float(t.wk) / b.w) * (1.0 + 0.15 * meta.level("guard")) * (1.0 + 0.25 * pk("gdmg"))
		if pk("crit") > 0 and rng.randf() < 0.15 * pk("crit"): dmg *= 3.0
		bolts.append({"a": t.pos + Vector2(0, -34), "p": t.pos + Vector2(0, -34), "c": best, "spd": 420.0 if not b.has("splash") else 260.0,
			"dmg": dmg, "foe": false, "splash": b.get("splash", 0.0)})
		if rng.randf() < 0.5: sfx("flame", -14.0)

func _sim_bolts(dt: float) -> void:
	var done := []
	for bo in bolts:
		var target: Vector2
		if bo.foe:
			target = bo.b
		else:
			if not bo.c in creatures:
				done.append(bo); continue
			target = bo.c.pos
		bo.p = (bo.p as Vector2).move_toward(target, bo.spd * dt)
		if (bo.p as Vector2).distance_to(target) < 6:
			done.append(bo)
			if bo.foe:
				_hit_tile(bo.tgt, bo.dmg)
			elif bo.splash > 0:
				rings.append({"p": target, "r": 6.0, "max": bo.splash * HEX * SQ3, "t": 0.45, "c": Color(1, 0.55, 0.2)})
				for c in creatures.duplicate():
					if (c.pos as Vector2).distance_to(target) < bo.splash * HEX * SQ3:
						c.hp -= bo.dmg
						if c.hp <= 0: _kill_foe(c, false)
			else:
				bo.c.hp -= bo.dmg
				if bo.c.hp <= 0: _kill_foe(bo.c, false)
	for bo in done: bolts.erase(bo)

func light_pulse() -> void:
	if state != "play" or pulse_cd > 0 or res.oil < 15: return
	res.oil -= 15
	pulse_cd = 18.0 * pow(0.8, pk("pulsecd"))
	var dmg := (55.0 + tower_lvl * 25.0) * (1.0 + 0.25 * meta.level("pulse")) * (1.0 + 0.4 * pk("pulse"))
	var r := tower_radius() * 1.1
	rings.append({"p": Vector2(0, -40), "r": 10.0, "max": r, "t": 0.6, "c": Color(1, 0.9, 0.6)})
	flash_v = 0.6
	shake = 0.4
	sfx("flame", -2.0)
	for c in creatures.duplicate():
		if (c.pos as Vector2).length() < r:
			c.hp -= dmg
			if c.hp <= 0: _kill_foe(c, true)

func _add_glut(v: float) -> void:
	run_glut += v

func _calc_stress() -> float:
	if state != "play": return 0.0
	var st := minf(creatures.size() * 0.06, 0.6)
	if tower_hp < tower_max * 0.5: st += 0.3
	if res.oil < 15: st += 0.25
	if res.food <= 0: st += 0.2
	for c in creatures:
		if c.type == "boss": st += 0.3; break
	return clampf(st, 0.0, 1.0)

# ================================================================ Aufträge
func _new_quest() -> Dictionary:
	var q: Array = QUESTS[rng.randi() % QUESTS.size()]
	var tier := mini(rng.randi_range(0, 2), 2)
	var goal: int = q[2][tier]
	return {"id": q[0], "text": q[1] % goal, "goal": goal, "have": 0, "reward": 12 + tier * 14 + goal / 3}

func _quest_progress(id: String, n: int) -> void:
	for q in quests:
		if q.id == id:
			q.have += n
			if q.have >= q.goal and not q.get("done", false):
				q.done = true
				var g := int(q.reward * glut_mul())
				_add_glut(g)
				say("[color=#ffcf8a]Auftrag erfüllt:[/color] %s · +%d Glut" % [q.text, g])
				sfx("sting", -6.0)
	for i in quests.size():
		if quests[i].get("done", false):
			quests[i] = _new_quest()

# ================================================================ Karten
func open_cards() -> void:
	state = "cards"
	card_opts.clear()
	var n := 4 if meta.level("cards4") > 0 else 3
	# Seltenheit gewichtet: gewöhnlich 6, selten 3, episch 1
	var pool := []
	for id in CARDS:
		for k in [6, 3, 1][CARDS[id][2]]: pool.append(id)
	while card_opts.size() < n:
		var id: String = pool[rng.randi() % pool.size()]
		if not id in card_opts: card_opts.append(id)
	reroll_left = meta.level("reroll")
	if autotest:
		pick_card(card_opts[0])
		return
	_build_card_ui()

func pick_card(id: String) -> void:
	perks[id] = pk(id) + 1
	match id:
		"pop": pop += 5
		"tower":
			tower_max += 150
			tower_hp = tower_max
		"hp":
			for t in tiles:
				if t.type in B:
					var old: float = t.maxhp
					t.maxhp = bmaxhp(t)
					t.hp += t.maxhp - old
	say("[color=#c9a7ff]Karte:[/color] %s" % CARDS[id][0])
	state = "play"
	if card_box: card_box.visible = false

# ================================================================ Bauen
func can_place(i: int, type: String) -> bool:
	var t: Dictionary = tiles[i]
	if t.type != "" or t.terr in ["rock", "cave", "bunker"]: return false
	var need: String = B[type].get("terr", "")
	if need != "" and t.terr != need: return false
	if need == "" and t.terr == "oil": return false
	if B[type].has("unlock") and meta.level(B[type].unlock) == 0: return false
	return true

func build(i: int, type: String) -> bool:
	var t: Dictionary = tiles[i]
	if t.terr == "ruin" and t.type == "" and type != "yard":
		res.scrap += 12; t.terr = "ground"
		floats.append({"p": t.pos + Vector2(0, -30), "t": 1.2, "s": "+12 Schrott", "c": Color(0.85, 0.75, 0.55)})
		sfx("build", -8.0)
		return true
	if not can_place(i, type) or res.scrap < build_cost(type): return false
	res.scrap -= build_cost(type)
	t.type = type
	t.lvl = 1
	t.ruined = false
	t.maxhp = bmaxhp(t)
	t.hp = t.maxhp
	t.born = Time.get_ticks_msec() / 1000.0
	floats.append({"p": t.pos + Vector2(0, -40), "t": 1.2, "s": "-%d Schrott" % build_cost(type), "c": Color(1, 0.8, 0.5)})
	sfx("build", -4.0)
	_quest_progress("build", 1)
	return true

func upgrade(i: int) -> void:
	var t: Dictionary = tiles[i]
	var c := upgrade_cost(t)
	if res.scrap < c: return
	if t.type == "tower":
		if tower_lvl >= 8: return
		res.scrap -= c
		tower_lvl += 1
		tower_max += 120
		tower_hp = minf(tower_max, tower_hp + 200)
	else:
		if t.lvl >= MAX_LVL or t.ruined: return
		res.scrap -= c
		t.lvl += 1
		t.maxhp = bmaxhp(t)
		t.hp = t.maxhp
	t.born = Time.get_ticks_msec() / 1000.0
	sfx("build", -2.0)
	_quest_progress("upgrade", 1)

func repair(i: int) -> void:
	var t: Dictionary = tiles[i]
	if not t.ruined or res.scrap < repair_cost(t): return
	res.scrap -= repair_cost(t)
	t.ruined = false
	t.hp = t.maxhp
	t.born = Time.get_ticks_msec() / 1000.0
	sfx("build", -4.0)

func demolish(i: int) -> void:
	var t: Dictionary = tiles[i]
	if not t.type in B: return
	res.scrap += int(build_cost(t.type) * 0.4)
	t.type = ""
	t.ruined = false
	sel_tile = -1

# ================================================================ Erkundung
func start_explore(i: int) -> void:
	var t: Dictionary = tiles[i]
	if t.explored:
		say("Dieser Ort ist bereits erkundet."); return
	var scouts := 0
	for o in tiles:
		if o.type == "scout" and not o.ruined: scouts += 1
	if scouts == 0:
		say("Baue zuerst einen Späherposten."); return
	if is_night:
		say("Nachts kann niemand hinaus."); return
	if pop < 8:
		say("Zu wenige Bewohner für ein Team."); return
	state = "explore"
	explore_node = Explore.new()
	explore_node.main = self
	var air := 10 + meta.level("air") * 2
	explore_node.setup(t.terr, int(t.seed * 100000), air, 4, true, 2, SPR.get("creature"))
	explore_node.finished.connect(func(r: Dictionary): _explore_done(i, r))
	ui.add_child(explore_node)
	if autotest: explore_node.auto_run()

func _explore_done(i: int, r: Dictionary) -> void:
	tiles[i].explored = true
	explore_node.queue_free()
	explore_node = null
	state = "play"
	var l: Dictionary = r.loot
	res.oil += l.get("oil", 0)
	res.scrap += l.get("scrap", 0)
	res.food += l.get("food", 0)
	var g := int((l.get("know", 0) * 1.5 + 10) * glut_mul()) if r.ok else 0
	_add_glut(g)
	pop = maxi(1, pop - r.lost + r.people)
	_quest_progress("explore", 1)
	if r.ok:
		say("[color=#8fd0ff]Team zurück:[/color] +%d Glut · +%d Öl · +%d Schrott · +%d Leute" % [g, l.get("oil", 0), l.get("scrap", 0), r.people])
	else:
		say("[color=#ff8a6a]Das Team kehrt nicht zurück.[/color]")

# ================================================================ Ende
func _game_over() -> void:
	state = "over"
	var earned := int(run_glut)
	meta.glut += earned
	meta.total_kills += run_kills
	var record := night > meta.best_night
	meta.best_night = maxi(meta.best_night, night)
	meta.save_data()
	sfx("lose", 0.0)
	if autotest:
		print("RESULT night=%d glut=%d kills=%d" % [night, earned, run_kills])
		get_tree().quit()
		return
	_build_over_ui(earned, record)

# ================================================================ Testbot
var bot_t := 0.0
func _bot(dt: float) -> void:
	bot_t -= dt
	if bot_t > 0: return
	bot_t = 1.0
	if creatures.size() >= 5: light_pulse()
	var plan := ["pump", "hut", "guard", "farm", "yard", "hut", "guard", "lamp", "pump", "farm", "clinic", "guard", "hut", "lamp",
		"scout", "guard", "yard", "farm", "hut", "guard", "lamp", "guard", "hut", "guard"]
	var have := {}
	for t in tiles:
		if t.type in B: have[t.type] = have.get(t.type, 0) + 1
	var seen := {}
	for p in plan:
		seen[p] = seen.get(p, 0) + 1
		if have.get(p, 0) < seen[p]:
			if res.scrap >= build_cost(p):
				var best := -1
				for i in tiles.size():
					if can_place(i, p) and (best < 0 or tiles[i].d < tiles[best].d or (B[p].get("bonus", "") == tiles[i].terr and tiles[best].terr != tiles[i].terr)):
						if p == "guard" and tiles[i].d < 2: continue
						best = i
				if best >= 0: build(best, p)
			break
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if t.ruined and not is_night: repair(i)
		elif t.type in ["guard", "pump", "farm"] and t.lvl < 3 and res.scrap > upgrade_cost(t) + 30: upgrade(i)
	if res.scrap > upgrade_cost(tiles[idx[Vector2i(0, 0)]]) + 60: upgrade(idx[Vector2i(0, 0)])
	if not is_night and night >= 2 and night % 2 == 0 and explore_node == null:
		for i in tiles.size():
			if tiles[i].terr in ["cave", "bunker"] and not tiles[i].explored:
				start_explore(i); break
	if night >= 25:
		print("RESULT night=%d glut=%d kills=%d (Limit)" % [night, int(run_glut), run_kills])
		get_tree().quit()

# ================================================================ Eingabe
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = idx.get(pos_hex(get_global_mouse_position()), -1)
		if e.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			cam_target -= e.relative / cam.zoom
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom = (cam.zoom * 1.1).clamp(Vector2(0.6, 0.6), Vector2(2.2, 2.2))
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom = (cam.zoom / 1.1).clamp(Vector2(0.6, 0.6), Vector2(2.2, 2.2))
		elif state == "play" and hover >= 0:
			var t: Dictionary = tiles[hover]
			if e.button_index == MOUSE_BUTTON_LEFT:
				if t.type != "":
					sel_tile = hover
					sfx("click", -10.0)
				elif t.terr in ["cave", "bunker"]:
					start_explore(hover)
				elif not build(hover, sel_build):
					if res.scrap < build_cost(sel_build): say("Zu wenig Schrott.")
					elif not can_place(hover, sel_build): say("%s passt hier nicht hin." % B[sel_build].n)
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				sel_tile = -1
	elif e is InputEventKey and e.pressed and state == "play":
		match e.keycode:
			KEY_SPACE: speed = 0.0 if speed > 0 else 1.0
			KEY_1: speed = 1.0
			KEY_2: speed = 2.0
			KEY_3: speed = 3.0
			KEY_Q: light_pulse()
			KEY_N: if not is_night: phase_t = 0.01
			KEY_U: if sel_tile >= 0: upgrade(sel_tile)
			KEY_ESCAPE: sel_tile = -1

# ================================================================ Welt & Darstellung
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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	cam = Camera2D.new()
	cam.position = cam_target
	cam.zoom = Vector2(1.05, 1.05)
	add_child(cam)
	glow_tex = GradientTexture2D.new()
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 256; glow_tex.height = 256
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	glow_tex.gradient = g
	tower_light = PointLight2D.new()
	tower_light.texture = glow_tex
	tower_light.color = Color(1.0, 0.8, 0.5)
	tower_light.position = Vector2(0, -40)
	add_child(tower_light)
	night_mod = CanvasModulate.new()
	add_child(night_mod)
	fog_mat = ShaderMaterial.new()
	fog_mat.shader = load("res://fog.gdshader")
	var fog_rect := ColorRect.new()
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

func _make_post() -> void:
	var pl := CanvasLayer.new()
	pl.layer = 1
	add_child(pl)
	var r := ColorRect.new()
	r.size = Vector2(1280, 720)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://post.gdshader")
	r.material = post_mat
	pl.add_child(r)

func _update_visuals(delta: float, sd: float) -> void:
	var v := Vector2.ZERO
	if state == "play" or state == "cards":
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	elif state == "menu":
		cam_target = Vector2(cos(Time.get_ticks_msec() * 0.00008), sin(Time.get_ticks_msec() * 0.0001)) * 60.0
	cam_target += v * 520.0 * delta / cam.zoom.x
	cam_target = cam_target.clamp(Vector2(-450, -400), Vector2(450, 400))
	cam.position = cam.position.lerp(cam_target, 1.0 - exp(-delta * 9.0))
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 9.0
	var dl := daylight()
	night_mod.color = Color(0.3, 0.34, 0.5).lerp(Color(1, 0.98, 0.94), dl)
	var src := light_sources()
	var arr := PackedVector4Array()
	for L in src: arr.append(Vector4(L.x, L.y, L.z, 0))
	fog_mat.set_shader_parameter("lights", arr)
	fog_mat.set_shader_parameter("nlights", arr.size())
	fog_mat.set_shader_parameter("density", 1.2 if is_night else 0.95)
	spores.position = cam.position
	tower_light.texture_scale = tower_radius() * 2.0 / 256.0
	tower_light.energy = (0.4 + 0.9 * (1.0 - dl)) * (0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.006))
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		var want: bool = t.type in B and B[t.type].has("lamp") and not t.ruined and res.oil > 0
		if want and not lamp_lights.has(i):
			var l := PointLight2D.new()
			l.texture = glow_tex
			l.color = Color(1.0, 0.75, 0.4)
			l.position = t.pos
			l.texture_scale = B[t.type].lamp * 0.6
			add_child(l)
			lamp_lights[i] = l
		elif lamp_lights.has(i):
			lamp_lights[i].enabled = want
			lamp_lights[i].energy = 0.3 + 0.9 * (1.0 - dl)
	for r in rings:
		r.t -= delta
		r.r = lerpf(r.r, r.max, 1.0 - exp(-delta * 9.0))
	rings = rings.filter(func(x): return x.t > 0)
	for f in floats:
		f.t -= delta
		f.p += Vector2(0, -24) * delta
	floats = floats.filter(func(x): return x.t > 0)
	# Bewohner laufen tagsüber
	var homes := []
	var works := []
	for t in tiles:
		if t.type in B and not t.ruined:
			if B[t.type].get("house", 0) > 0: homes.append(t.pos)
			elif t.wk > 0: works.append(t.pos)
	var want_n := mini(36, pop / 2) if homes.size() > 0 and works.size() > 0 and not is_night and state != "menu" else 0
	while walkers.size() < want_n:
		walkers.append({"a": homes.pick_random(), "b": works.pick_random(), "t": randf(), "dir": 1.0, "sp": randf_range(0.08, 0.16)})
	while walkers.size() > want_n: walkers.pop_back()
	for w in walkers:
		w.t += w.dir * w.sp * sd
		if w.t >= 1.0 or w.t <= 0.0:
			w.dir = -w.dir
			w.t = clampf(w.t, 0.0, 1.0)
			if w.t <= 0.0 and homes.size() > 0 and works.size() > 0:
				w.a = homes.pick_random(); w.b = works.pick_random()

const SPR_W := {"tower": 64, "hut": 76, "stone": 78, "pump": 74, "yard": 78, "farm": 78, "lamp": 26, "clinic": 80,
	"scout": 52, "lab": 76, "green": 78, "filter": 78, "brew": 78, "beacon": 40, "water": 74, "guard": 78,
	"ruin": 66, "rock": 66, "oil": 62, "cave": 82, "bunker": 82}

func spr(ci: CanvasItem, key: String, p: Vector2, mod: Color = Color.WHITE, wmul: float = 1.0) -> bool:
	if not SPR.has(key): return false
	var tex: Texture2D = SPR[key]
	var w: float = SPR_W.get(key, 70) * wmul
	var h: float = w * tex.get_height() / tex.get_width()
	ci.draw_texture_rect(tex, Rect2(p - Vector2(w * 0.5, h - w * 0.18), Vector2(w, h)), false, mod)
	return true

func _hex_pts(p: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 6: pts.append(p + Vector2.from_angle(deg_to_rad(60 * k - 30)) * s)
	return pts

func _draw() -> void:
	var tm := Time.get_ticks_msec() / 1000.0
	draw_circle(Vector2.ZERO, 820, Color(0.09, 0.1, 0.09))
	var gtex: Texture2D = SPR.get("tex_ground")
	var ftex: Texture2D = SPR.get("tex_fungus")
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		var p: Vector2 = t.pos
		var pts := _hex_pts(p, HEX + 0.6)
		var uvs := PackedVector2Array()
		for vv in pts: uvs.append(vv / 300.0)
		var tex: Texture2D = ftex if t.terr == "fungus" else gtex
		var tint := Color(1, 1, 1).darkened(0.12 - t.shade)
		if tex: draw_colored_polygon(pts, tint, uvs, tex)
		else: draw_colored_polygon(pts, Color(0.35, 0.32, 0.27))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.18), 1.0)
		if state == "play" and i == hover:
			var ok: bool = t.type == "" and can_place(i, sel_build) and res.scrap >= build_cost(sel_build)
			if t.type != "": ok = true
			draw_colored_polygon(pts, Color(0.6, 1, 0.6, 0.12) if ok else Color(1, 0.6, 0.3, 0.12))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.6, 1, 0.6) if ok else Color(1, 0.8, 0.5), 2.5)
			if t.type == "" and B[sel_build].has("range"):
				draw_arc(p, B[sel_build].range * HEX * SQ3, 0, TAU, 48, Color(1, 0.6, 0.3, 0.35), 2)
		if i == sel_tile:
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 0.85, 0.5), 3.0)
	for i in draw_order:
		var t: Dictionary = tiles[i]
		var p: Vector2 = t.pos
		if t.type == "" and t.terr in ["ruin", "rock", "oil"]:
			spr(self, t.terr, p + Vector2(0, 4))
		elif t.type == "" and t.terr == "fungus":
			for k in 5:
				var o := Vector2.from_angle(t.seed * 20 + k * 1.3) * (6 + k * 3.0)
				var glow := 0.6 + 0.4 * sin(tm * 1.5 + k + t.seed * 10)
				draw_circle(p + o + Vector2(0, -6), 3.5 - k * 0.3, Color(0.4, 0.9 * glow, 0.75).lerp(Color(0.8, 0.4, 1), t.seed))
		if t.type != "":
			draw_set_transform(p + Vector2(4, 6), 0, Vector2(1, 0.45))
			draw_circle(Vector2.ZERO, HEX * 0.85, Color(0, 0, 0, 0.28))
			draw_set_transform(Vector2.ZERO)
			_draw_building(t, p, tm)
	var ptex: Texture2D = SPR.get("person")
	for w in walkers:
		var wp: Vector2 = (w.a as Vector2).lerp(w.b, w.t)
		var bob := absf(sin(w.t * 90.0)) * 1.5
		if ptex:
			var hh := 24.0
			var ww := hh * ptex.get_width() / ptex.get_height()
			var left: bool = ((w.b as Vector2).x - (w.a as Vector2).x) * w.dir < 0
			draw_set_transform(wp + Vector2(0, -bob), 0, Vector2(-1 if left else 1, 1))
			draw_circle(Vector2.ZERO, 4, Color(0, 0, 0, 0.25))
			draw_texture_rect(ptex, Rect2(Vector2(-ww * 0.5, -hh), Vector2(ww, hh)), false)
			draw_set_transform(Vector2.ZERO)

func _draw_building(t: Dictionary, p: Vector2, tm: float) -> void:
	var key: String = t.type if t.type == "tower" else SPRITE_OF.get(t.type, t.type)
	var mod := Color.WHITE
	if t.ruined: mod = Color(0.35, 0.33, 0.32)
	elif t.type == "mortar": mod = Color(1, 0.75, 0.6)
	elif t.type == "forge": mod = Color(1.0, 0.7, 0.55)
	var age: float = tm - t.born
	var pop_s := 1.0
	if age < 0.5:
		var k := age / 0.5
		pop_s = 1.0 + sin(k * PI * 1.5) * (1.0 - k) * 0.35 - (1.0 - minf(k * 4.0, 1.0)) * 0.6
		for j in 6:
			var a: float = j * TAU / 6.0 + t.seed
			draw_circle(p + Vector2.from_angle(a) * (10 + k * 30) * Vector2(1, 0.5), 6 * (1.0 - k), Color(0.7, 0.65, 0.55, 0.5 * (1.0 - k)))
	var sc: float = pop_s * ((1.0 + 0.05 * (tower_lvl - 1)) if t.type == "tower" else (1.0 + 0.04 * (t.lvl - 1)))
	spr(self, key, p, mod, sc)
	if t.type == "tower":
		var top := p + Vector2(0, -SPR_W.tower * 1.62 * sc)
		var lc := Color(1, 0.9, 0.6) if res.oil > 0 else Color(0.3, 0.3, 0.3)
		draw_circle(top, 10 + sin(tm * 5) * 1.5, Color(lc, 0.45))
		if res.oil > 0:
			var a := tm * 0.9
			for s in [0.0, PI]:
				var d: Vector2 = Vector2.from_angle(a + s)
				draw_colored_polygon(PackedVector2Array([top, top + d.rotated(0.13) * 380, top + d.rotated(-0.13) * 380]), Color(lc, 0.12))
		return
	if t.ruined:
		for k in 4:
			var sm := fmod(tm * 0.4 + k * 0.25 + t.seed, 1.0)
			draw_circle(p + Vector2(-6 + k * 4, -10 - sm * 30), 3 + sm * 6, Color(0.25, 0.25, 0.25, 0.5 * (1.0 - sm)))
		return
	var b: Dictionary = B[t.type]
	if b.has("lamp") and res.oil > 0:
		var top2 := p + Vector2(0, -SPR_W.get(t.type, 30) * (2.95 if t.type == "lamp" else 1.75))
		draw_circle(top2, 9 if t.type == "lamp" else 15, Color(1, 0.8, 0.45, 0.35 + 0.08 * sin(tm * 7 + t.seed * 9)))
	if t.type in ["hut", "forge", "clinic"]:
		for k in 3:
			var sm := fmod(tm * 0.35 + k * 0.33 + t.seed, 1.0)
			draw_circle(p + Vector2(14 + sm * 10, -50 - sm * 26), 3 + sm * 5, Color(0.65, 0.6, 0.55, 0.35 * (1.0 - sm)) if t.type != "forge" else Color(1, 0.5, 0.2, 0.5 * (1.0 - sm)))
	# Stufen-Punkte
	for k in t.lvl:
		draw_circle(p + Vector2(-((t.lvl - 1) * 5) + k * 10, 22), 3.2, Color(1, 0.8, 0.4))
	if t.hp < t.maxhp:
		var w := 40.0
		draw_rect(Rect2(p + Vector2(-w / 2, 28), Vector2(w, 4)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(p + Vector2(-w / 2, 28), Vector2(w * t.hp / t.maxhp, 4)), Color(0.4, 0.9, 0.5).lerp(Color(1, 0.3, 0.2), 1.0 - t.hp / t.maxhp))
	if b.w > 0 and t.wk < b.w:
		draw_circle(p + Vector2(20, -30), 5, Color(0, 0, 0, 0.5))
		draw_circle(p + Vector2(20, -30), 3.5, Color(0.95, 0.3, 0.2))

func _draw_markers() -> void:
	var tm := Time.get_ticks_msec() / 1000.0
	for i in tiles.size():
		var t: Dictionary = tiles[i]
		if not t.terr in ["cave", "bunker"]: continue
		var p: Vector2 = t.pos
		spr(markers, t.terr, p + Vector2(0, 6), Color(0.6, 0.6, 0.6) if t.explored else Color.WHITE)
		if not t.explored and state != "menu":
			var a := 0.6 + 0.4 * sin(tm * 3 + i)
			markers.draw_arc(p, 26, 0, TAU, 32, Color(1, 0.8, 0.4, a), 2)
	var ctex: Texture2D = SPR.get("creature")
	for c in creatures:
		var f: Dictionary = FOES[c.type]
		var cp: Vector2 = c.pos
		var hh: float = f.size
		var tint := Color.WHITE
		match c.type:
			"runner": tint = Color(1, 0.75, 0.6)
			"brute": tint = Color(0.8, 0.95, 0.7)
			"spitter": tint = Color(0.75, 0.7, 1.0)
			"boss": tint = Color(1, 0.6, 0.6)
		var sway := sin(tm * (6.0 if c.type == "runner" else 3.5) + c.wob) * 0.08
		markers.draw_circle(cp, hh * 0.3, Color(0.3, 1, 0.7, 0.15))
		if ctex:
			var ww := hh * ctex.get_width() / ctex.get_height()
			markers.draw_set_transform(cp, sway, Vector2.ONE)
			markers.draw_texture_rect(ctex, Rect2(Vector2(-ww * 0.5, -hh), Vector2(ww, hh)), false, tint)
			markers.draw_set_transform(Vector2.ZERO)
		if c.hp < c.max:
			var w := hh * 0.9
			markers.draw_rect(Rect2(cp + Vector2(-w / 2, -hh - 8), Vector2(w, 3)), Color(0, 0, 0, 0.6))
			markers.draw_rect(Rect2(cp + Vector2(-w / 2, -hh - 8), Vector2(w * c.hp / c.max, 3)), Color(1, 0.35, 0.25))
	for bo in bolts:
		var col := Color(0.6, 1, 0.4) if bo.foe else Color(1, 0.65, 0.25)
		markers.draw_line(bo.p, (bo.p as Vector2).lerp(bo.a, 0.08), Color(col, 0.6), 3)
		markers.draw_circle(bo.p, 4.5 if not bo.get("splash", 0.0) else 7.0, col)
	for r in rings:
		markers.draw_arc(r.p, r.r, 0, TAU, 64, Color(r.c, clampf(r.t * 2.0, 0, 1)), 4)
	for f in floats:
		markers.draw_string(font, f.p + Vector2(-60, 0), f.s, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(f.c, minf(f.t, 1.0)))

# ================================================================ UI
func _style(c: Color, border: Color = Color(1, 1, 1, 0.08), radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 10
	s.anti_aliasing = true
	s.content_margin_left = 12; s.content_margin_right = 12
	s.content_margin_top = 7; s.content_margin_bottom = 7
	return s

func _bar(fill: Color, w: float, h: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(w, h)
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(1, 1, 1, 0.08); bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new(); fg.bg_color = fill; fg.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb

func _rich(size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size + 1)
	r.add_theme_color_override("default_color", Color(0.86, 0.87, 0.88))
	return r

func _make_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	th = Theme.new()
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Inter", "SF Pro Text", "Helvetica Neue", "Segoe UI", "Roboto", "Noto Sans", "DejaVu Sans"])
	th.default_font = sf
	var accent := Color(1.0, 0.72, 0.35)
	th.set_stylebox("normal", "Button", _style(Color(0.09, 0.1, 0.12, 0.66)))
	th.set_stylebox("hover", "Button", _style(Color(0.16, 0.15, 0.14, 0.8), Color(accent, 0.7)))
	th.set_stylebox("pressed", "Button", _style(Color(0.32, 0.22, 0.1, 0.85), accent))
	th.set_stylebox("disabled", "Button", _style(Color(0.06, 0.06, 0.07, 0.5), Color(1, 1, 1, 0.04)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("panel", "PanelContainer", _style(Color(0.05, 0.06, 0.08, 0.7)))
	th.set_stylebox("panel", "TooltipPanel", _style(Color(0.05, 0.06, 0.08, 0.94), Color(accent, 0.5)))
	th.set_color("font_color", "Button", Color(0.93, 0.92, 0.9))
	th.set_color("font_hover_color", "Button", Color(1, 0.9, 0.75))
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.52))
	th.set_color("font_color", "Label", Color(0.92, 0.92, 0.9))
	th.set_font_size("font_size", "Button", 13)
	th.set_font_size("font_size", "Label", 13)
	root = Control.new()
	root.theme = th
	root.size = Vector2(1280, 720)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	# Oben: Ressourcen
	var tp := PanelContainer.new()
	tp.position = Vector2(300, 8)
	root.add_child(tp)
	top = _rich(15)
	top.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.custom_minimum_size = Vector2(660, 22)
	tp.add_child(top)
	hud_nodes.append(tp)
	# Phase
	var pp := PanelContainer.new()
	pp.position = Vector2(470, 52)
	root.add_child(pp)
	var pv := VBoxContainer.new()
	pp.add_child(pv)
	phase_lbl = Label.new()
	phase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_lbl.custom_minimum_size = Vector2(316, 0)
	pv.add_child(phase_lbl)
	phase_bar = _bar(Color(1, 0.8, 0.45), 316, 6)
	pv.add_child(phase_bar)
	hud_nodes.append(pp)
	# Links: Aufträge + Chronik
	var lp := PanelContainer.new()
	lp.position = Vector2(8, 8)
	lp.custom_minimum_size = Vector2(280, 0)
	root.add_child(lp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	lp.add_child(lv)
	var qh := Label.new(); qh.text = "AUFTRÄGE"; qh.add_theme_color_override("font_color", accent); qh.add_theme_font_size_override("font_size", 11)
	lv.add_child(qh)
	quest_lbl = _rich(12)
	quest_lbl.custom_minimum_size = Vector2(256, 0)
	lv.add_child(quest_lbl)
	var lh := Label.new(); lh.text = "CHRONIK"; lh.add_theme_color_override("font_color", accent); lh.add_theme_font_size_override("font_size", 11)
	lv.add_child(lh)
	logl = _rich(12)
	logl.custom_minimum_size = Vector2(256, 190)
	logl.add_theme_constant_override("line_separation", 4)
	lv.add_child(logl)
	hud_nodes.append(lp)
	# Rechts: Turm & Auswahl
	side = PanelContainer.new()
	side.position = Vector2(1000, 8)
	side.custom_minimum_size = Vector2(272, 0)
	root.add_child(side)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	side.add_child(sv)
	var tl := Label.new(); tl.text = "LEUCHTTURM"; tl.add_theme_color_override("font_color", accent); tl.add_theme_font_size_override("font_size", 11)
	sv.add_child(tl)
	tower_bar = _bar(Color(1, 0.75, 0.4), 248, 8)
	sv.add_child(tower_bar)
	pulse_btn = Button.new()
	pulse_btn.custom_minimum_size = Vector2(248, 40)
	pulse_btn.pressed.connect(light_pulse)
	sv.add_child(pulse_btn)
	night_btn = Button.new()
	night_btn.custom_minimum_size = Vector2(248, 34)
	night_btn.text = "Nacht jetzt beginnen  [N]"
	night_btn.pressed.connect(func(): if not is_night: phase_t = 0.01)
	sv.add_child(night_btn)
	side_lbl = _rich(12)
	side_lbl.custom_minimum_size = Vector2(248, 0)
	sv.add_child(side_lbl)
	up_btn = Button.new()
	up_btn.custom_minimum_size = Vector2(248, 36)
	up_btn.pressed.connect(func(): if sel_tile >= 0: upgrade(sel_tile))
	sv.add_child(up_btn)
	rep_btn = Button.new()
	rep_btn.custom_minimum_size = Vector2(248, 32)
	rep_btn.pressed.connect(func():
		if sel_tile >= 0:
			if tiles[sel_tile].ruined: repair(sel_tile)
			else: demolish(sel_tile))
	sv.add_child(rep_btn)
	hud_nodes.append(side)
	# Unten: Bauleiste
	var bar := HBoxContainer.new()
	bar.position = Vector2(8, 662)
	bar.add_theme_constant_override("separation", 4)
	root.add_child(bar)
	for k in ORDER:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 50)
		b.add_theme_font_size_override("font_size", 12)
		b.toggle_mode = true
		b.tooltip_text = B[k].d
		b.pressed.connect(func():
			sel_build = k
			sel_tile = -1
			for x in bar.get_children(): x.button_pressed = x == b)
		bar.add_child(b)
		build_btns[k] = b
	build_btns["hut"].button_pressed = true
	hud_nodes.append(bar)
	var help := _rich(11)
	help.position = Vector2(16, 560)
	help.size = Vector2(280, 90)
	help.add_theme_color_override("default_color", Color(0.75, 0.77, 0.8, 0.8))
	help.text = "[color=#ffcf8a]Linksklick[/color] Bauen / Auswählen   [color=#ffcf8a]Q[/color] Lichtstoß\n[color=#ffcf8a]U[/color] Ausbauen   [color=#ffcf8a]N[/color] Nacht starten   [color=#ffcf8a]WASD[/color] Kamera\n[color=#ffcf8a]Leertaste[/color] Pause   [color=#ffcf8a]1 2 3[/color] Tempo"
	root.add_child(help)
	hud_nodes.append(help)
	for n in hud_nodes: n.visible = false

func _update_ui() -> void:
	var chip := func(col: String, name: String, v: float, r: float) -> String:
		var rc := "#8fdc8f" if r >= 0 else "#ff7b6b"
		return "[color=%s]●[/color] [color=#9aa0a6]%s[/color] [b]%d[/b] [color=%s]%+.1f[/color]" % [col, name, int(v), rc, r]
	top.text = "%s    %s    %s    [color=#6fd3ff]●[/color] [color=#9aa0a6]Leute[/color] [b]%d[/b][color=#9aa0a6]/%d[/color]    [color=#ff9a4a]◆[/color] [color=#9aa0a6]Glut[/color] [b]%d[/b]" % [
		chip.call("#ffb347", "Öl", res.oil, rates.oil), chip.call("#c9a27a", "Schrott", res.scrap, rates.scrap),
		chip.call("#9be37a", "Nahrung", res.food, rates.food), pop, housing(), int(run_glut)]
	if is_night:
		phase_lbl.text = "NACHT %d  ·  %d Wucherer" % [night, creatures.size() + spawn_left]
		phase_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 1.0))
		phase_bar.max_value = maxf(1.0, creatures.size() + spawn_left + 0.01)
		phase_bar.value = creatures.size() + spawn_left
	else:
		phase_lbl.text = "TAG  ·  Nacht %d in %d s" % [night + 1, int(phase_t)]
		phase_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.55))
		phase_bar.max_value = DAY_LEN
		phase_bar.value = phase_t
	tower_bar.max_value = tower_max
	tower_bar.value = tower_hp
	pulse_btn.text = ("Lichtstoß  [Q]   · 15 Öl" if pulse_cd <= 0 else "Lichtstoß lädt … %d s" % int(ceil(pulse_cd)))
	pulse_btn.disabled = pulse_cd > 0 or res.oil < 15
	night_btn.visible = not is_night
	var qt := ""
	for q in quests:
		qt += "%s\n[color=#9aa0a6]%d / %d[/color]   [color=#ff9a4a]+%d Glut[/color]\n" % [q.text, mini(q.have, q.goal), q.goal, q.reward]
	quest_lbl.text = qt.strip_edges()
	# Auswahl
	var s := "[color=#9aa0a6]Turm[/color]  %d / %d LP   ·   Stufe %d" % [int(tower_hp), int(tower_max), tower_lvl]
	up_btn.visible = false
	rep_btn.visible = false
	if sel_tile >= 0:
		var t: Dictionary = tiles[sel_tile]
		if t.type == "tower":
			s += "\n\n[b]Leuchtturm[/b]  ·  Stufe %d\n[color=#9aa0a6]Mehr Licht, mehr Lebenspunkte, stärkerer Lichtstoß.[/color]" % tower_lvl
			up_btn.visible = tower_lvl < 8
			up_btn.text = "Ausbauen  ·  %d Schrott  [U]" % upgrade_cost(t)
			up_btn.disabled = res.scrap < upgrade_cost(t)
		elif t.type in B:
			var b: Dictionary = B[t.type]
			s += "\n\n[b]%s[/b]  ·  Stufe %d / %d" % [b.n, t.lvl, MAX_LVL]
			s += "\n[color=#9aa0a6]%s[/color]" % b.d
			s += "\nLebenspunkte  %d / %d" % [int(t.hp), int(t.maxhp)]
			if b.w > 0: s += "\nArbeiter  %d / %d" % [t.wk, b.w]
			if b.has("dmg"): s += "\nSchaden  %.0f   ·   Reichweite %.1f" % [b.dmg * lvl_mul(t.lvl), b.range + 0.25 * (t.lvl - 1)]
			for k in b.get("prod", {}):
				s += "\nErtrag  %.2f %s/s" % [b.prod[k] * lvl_mul(t.lvl) * (2.0 if b.get("bonus", "") == t.terr else 1.0), {"oil": "Öl", "scrap": "Schrott", "food": "Nahrung"}[k]]
			if t.ruined:
				s += "\n[color=#ff7b6b]Zerstört[/color]"
				rep_btn.visible = true
				rep_btn.text = "Reparieren  ·  %d Schrott" % repair_cost(t)
				rep_btn.disabled = res.scrap < repair_cost(t)
			else:
				up_btn.visible = t.lvl < MAX_LVL
				up_btn.text = "Ausbauen  ·  %d Schrott  [U]" % upgrade_cost(t)
				up_btn.disabled = res.scrap < upgrade_cost(t)
				rep_btn.visible = true
				rep_btn.text = "Abreißen  ·  +%d Schrott" % int(build_cost(t.type) * 0.4)
				rep_btn.disabled = false
	elif hover >= 0 and tiles[hover].type == "":
		var h: Dictionary = tiles[hover]
		var tn: String = {"ground": "Boden", "fungus": "Pilzfeld", "oil": "Ölquelle", "ruin": "Ruine · klicken für Schrott", "rock": "Fels",
			"cave": "Höhle · klicken zum Erkunden", "bunker": "Bunker · klicken zum Erkunden"}.get(h.terr, "Gelände")
		s += "\n\n[b]%s[/b]" % tn
	if perks.size() > 0:
		s += "\n\n[color=#c9a7ff]Karten[/color]  "
		var parts := []
		for k in perks: parts.append("%s ×%d" % [CARDS[k][0], perks[k]])
		s += ", ".join(parts)
	side_lbl.text = s
	for k in build_btns:
		var b: Button = build_btns[k]
		var locked: bool = B[k].has("unlock") and meta.level(B[k].unlock) == 0
		b.visible = not locked
		b.text = "%s\n%d Schrott" % [B[k].n, build_cost(k)]
		b.modulate = Color(1, 1, 1) if res.scrap >= build_cost(k) else Color(0.6, 0.6, 0.62)

func say(s: String) -> void:
	if autotest and OS.get_cmdline_user_args().has("--verbose"): print(s)
	log_lines.push_front(s)
	if log_lines.size() > 8: log_lines.pop_back()
	if logl: logl.text = "\n".join(log_lines)

# ---------------------------------------------------------------- Überlagerungen
func _hide_overlays() -> void:
	for n in [menu_box, forge_box, card_box, over_box]:
		if n: n.queue_free()
	menu_box = null; forge_box = null; card_box = null; over_box = null

func _center_panel(w: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.04, 0.05, 0.07, 0.86), Color(1, 0.75, 0.4, 0.35), 16))
	p.custom_minimum_size = Vector2(w, 0)
	p.position = Vector2((1280 - w) / 2.0, 90)
	return p

func show_menu() -> void:
	state = "menu"
	_hide_overlays()
	for n in hud_nodes: n.visible = false
	creatures.clear()
	menu_box = Control.new()
	menu_box.size = Vector2(1280, 720)
	root.add_child(menu_box)
	var v := VBoxContainer.new()
	v.position = Vector2(80, 170)
	v.add_theme_constant_override("separation", 14)
	menu_box.add_child(v)
	var t := Label.new()
	t.text = "DAS LEUCHTFEUER"
	t.add_theme_font_size_override("font_size", 56)
	t.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Halte das Licht. Überlebe die Nächte. Werde stärker mit jedem Lauf."
	sub.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	sub.add_theme_font_size_override("font_size", 16)
	v.add_child(sub)
	var st := _rich(14)
	st.custom_minimum_size = Vector2(500, 0)
	st.text = "[color=#ff9a4a]◆ %d Glut[/color]      [color=#9aa0a6]Längste Nacht[/color]  [b]%d[/b]      [color=#9aa0a6]Läufe[/color]  [b]%d[/b]      [color=#9aa0a6]Wucherer besiegt[/color]  [b]%d[/b]" % [meta.glut, meta.best_night, meta.runs, meta.total_kills]
	v.add_child(st)
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 20); v.add_child(sp)
	for item in [["Lauf beginnen", start_run], ["Glutschmiede", show_forge], ["Beenden", func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(280, 48)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(item[1])
		v.add_child(b)

func show_forge() -> void:
	_hide_overlays()
	state = "menu"
	forge_box = Control.new()
	forge_box.size = Vector2(1280, 720)
	root.add_child(forge_box)
	var p := _center_panel(1000)
	p.position.y = 50
	forge_box.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var hb := HBoxContainer.new()
	v.add_child(hb)
	var t := Label.new()
	t.text = "Glutschmiede"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color(1, 0.8, 0.5))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var gl := Label.new()
	gl.text = "◆ %d Glut" % meta.glut
	gl.add_theme_font_size_override("font_size", 22)
	gl.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	hb.add_child(gl)
	var info := Label.new()
	info.text = "Dauerhafte Verbesserungen für alle zukünftigen Läufe."
	info.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
	v.add_child(info)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for id in Meta.UPGRADES:
		var u: Array = Meta.UPGRADES[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(316, 66)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var lv := meta.level(id)
		var maxed: bool = lv >= u[2]
		b.text = "%s   %s\n%s\n%s" % [u[0], "%d/%d" % [lv, u[2]], u[1], "Maximal" if maxed else "◆ %d Glut" % meta.cost(id)]
		b.add_theme_font_size_override("font_size", 12)
		b.disabled = not meta.can_buy(id)
		b.pressed.connect(func():
			if meta.buy(id):
				sfx("build", -2.0)
				show_forge())
		grid.add_child(b)
	var back := Button.new()
	back.text = "Zurück"
	back.custom_minimum_size = Vector2(200, 40)
	back.pressed.connect(show_menu)
	v.add_child(back)

func _build_card_ui() -> void:
	if card_box: card_box.queue_free()
	card_box = Control.new()
	card_box.size = Vector2(1280, 720)
	root.add_child(card_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(1280, 720)
	card_box.add_child(dim)
	var title := Label.new()
	title.text = "Nacht %d überstanden  ·  Wähle eine Karte" % night
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(title)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	card_box.add_child(hb)
	var n := card_opts.size()
	hb.position = Vector2((1280 - (n * 220 + (n - 1) * 18)) / 2.0, 220)
	for id in card_opts:
		var c: Array = CARDS[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 280)
		var col: Color = RARITY_COL[c[2]]
		b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.07, 0.1, 0.95), Color(col, 0.7), 14))
		b.add_theme_stylebox_override("hover", _style(Color(0.1, 0.1, 0.14, 0.98), col, 14))
		b.text = "%s\n\n%s\n\n\n%s%s" % [c[0], c[1], RARITY_NAME[c[2]], ("\nStufe %d" % (pk(id) + 1)) if pk(id) > 0 else ""]
		b.add_theme_font_size_override("font_size", 15)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.add_theme_color_override("font_color", col.lightened(0.3))
		b.pressed.connect(func(): pick_card(id))
		hb.add_child(b)
	if reroll_left > 0:
		var rb := Button.new()
		rb.text = "Neu mischen"
		rb.position = Vector2(560, 530)
		rb.custom_minimum_size = Vector2(160, 38)
		rb.pressed.connect(func():
			reroll_left -= 1
			var keep := reroll_left
			open_cards()
			reroll_left = keep
			_build_card_ui())
		card_box.add_child(rb)

func _build_over_ui(earned: int, record: bool) -> void:
	over_box = Control.new()
	over_box.size = Vector2(1280, 720)
	root.add_child(over_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	over_box.add_child(dim)
	var p := _center_panel(520)
	p.position.y = 170
	over_box.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var t := Label.new()
	t.text = "Das Licht ist erloschen"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(1, 0.75, 0.55))
	v.add_child(t)
	var st := _rich(15)
	st.text = "Du hast [b]%d Nächte[/b] überstanden.%s\n\n[color=#9aa0a6]Wucherer besiegt[/color]  %d\n[color=#ff9a4a]◆ +%d Glut[/color] für die Glutschmiede" % [night, "  [color=#ffd27a]Neuer Rekord![/color]" if record else "", run_kills, earned]
	v.add_child(st)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	v.add_child(hb)
	for item in [["Glutschmiede", show_forge], ["Neuer Lauf", start_run], ["Hauptmenü", show_menu]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(150, 42)
		b.pressed.connect(item[1])
		hb.add_child(b)

func _snap(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://shot_%s.png" % name)

func _shot() -> void:
	# Basis aufbauen, Nacht starten, Kampf fotografieren, Karten zeigen
	res.scrap = 600
	for p in ["pump", "guard", "guard", "lamp", "farm", "yard", "guard", "clinic", "lamp", "hut"]:
		for i in tiles.size():
			if can_place(i, p) and tiles[i].d >= (2 if p == "guard" else 1) and tiles[i].d <= 3:
				build(i, p); break
	await get_tree().create_timer(2.0).timeout
	_snap("tag")
	phase_t = 0.01
	night = 5
	await get_tree().create_timer(9.0).timeout
	light_pulse()
	await get_tree().create_timer(0.25).timeout
	_snap("nacht")
	creatures.clear(); spawn_left = 0
	_end_night()
	await get_tree().create_timer(1.0).timeout
	_snap("karten")
	get_tree().quit()

func _shot_menu() -> void:
	await get_tree().create_timer(2.0).timeout
	_snap("menu")
	show_forge()
	await get_tree().create_timer(1.0).timeout
	_snap("schmiede")
	get_tree().quit()

# ================================================================ Audio
var music := {}
var sfx_players: Array = []
var audio_cache := {}

func _stream(name: String) -> AudioStream:
	if audio_cache.has(name): return audio_cache[name]
	var path := "res://audio/%s.mp3" % name
	if not FileAccess.file_exists(path): return null
	var st := AudioStreamMP3.new()
	st.data = FileAccess.get_file_as_bytes(path)
	audio_cache[name] = st
	return st

func _make_audio() -> void:
	for n in ["calm", "tense", "night", "wind", "heart"]:
		var st := _stream(n)
		if st == null: continue
		st.loop = true
		var pl := AudioStreamPlayer.new()
		pl.stream = st
		pl.volume_db = -80.0
		add_child(pl)
		pl.play()
		music[n] = pl
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	get_tree().node_added.connect(func(n):
		if n is Button: n.pressed.connect(func(): sfx("click", -10.0)))

func sfx(name: String, db: float = 0.0) -> void:
	if autotest or sfx_players.is_empty(): return
	var st := _stream(name)
	if st == null: return
	for p in sfx_players:
		if not p.playing:
			p.stream = st
			p.volume_db = db
			p.pitch_scale = randf_range(0.94, 1.06)
			p.play()
			return

func _mix(n: String, w: float, base_db: float, delta: float) -> void:
	if not music.has(n): return
	var target := base_db + linear_to_db(maxf(w, 0.0001))
	var pl: AudioStreamPlayer = music[n]
	pl.volume_db = lerpf(pl.volume_db, maxf(target, -80.0), 1.0 - exp(-delta * 1.2))

func _update_audio(delta: float) -> void:
	var st := stress_v
	var n := 1.0 if is_night or state == "menu" else 0.0
	_mix("tense", st if is_night else st * 0.5, -6.0, delta)
	_mix("calm", (1.0 - st) * (1.0 - n), -8.0, delta)
	_mix("night", (1.0 - st) * n, -7.0, delta)
	_mix("wind", 0.6, -15.0, delta)
	_mix("heart", clampf((st - 0.6) * 2.2, 0.0, 1.0), -6.0, delta)
