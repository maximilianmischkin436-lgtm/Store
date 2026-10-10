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
var expedition := {}

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
	expedition = {}
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
	tower_max = 400.0 * (1.0 + 0.2 * meta.level("tower_hp")) * (1.0 + 0.06 * meta.rel("iron_will"))
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

func cons_time(type: String, lvl: int) -> float:
	var base: float = 3.5 + B[type].cost / 9.0
	return base * (0.7 + 0.55 * (lvl - 1)) * pow(0.94, meta.rel("swift_hands"))

func builder_slots() -> int:
	var n := 3
	for t in tiles:
		if t.type == "clinic" and not t.ruined and t.get("cons", 0.0) <= 0: n += 1
	return n

func build_cost(type: String) -> int:
	return int(B[type].cost * pow(0.85, pk("cheap")))

func upgrade_cost(t: Dictionary) -> int:
	if t.type == "tower":
		return int(60 * pow(1.9, tower_lvl - 1) * pow(0.85, pk("cheap")))
	return int(B[t.type].cost * 0.9 * pow(1.75, t.lvl) * pow(0.85, pk("cheap")))

func repair_cost(t: Dictionary) -> int:
	return int(build_cost(t.type) * 0.5)

func bmaxhp(t: Dictionary) -> float:
	return B[t.type].hp * 1.3 * (1.0 + 0.06 * meta.rel("bell_bronze")) * lvl_mul(t.lvl) * (1.0 + 0.2 * meta.level("bhp")) * (1.0 + 0.3 * pk("hp"))

func housing() -> int:
	var h := 0
	for t in tiles:
		if t.type in B and not t.ruined:
			h += int((B[t.type].get("house", 0) + (pk("pop") if t.type == "hut" else 0)) * lvl_mul(t.lvl))
	return h

func tower_radius() -> float:
	var hw := HEX * SQ3
	var r := 2.4 + tower_lvl * 0.45 + 0.3 * meta.level("light") + 0.4 * pk("radius")
	r *= 1.0 + 0.04 * meta.rel("amber_lens")
	if res.oil <= 0: r = 1.2
	return r * hw

func burn_dps() -> float:
	return (6.0 + tower_lvl * 2.0) * (1.0 + 0.2 * meta.level("burn")) * (1.0 + 0.4 * pk("burn"))

func glut_mul() -> float:
	return (1.0 + 0.15 * meta.level("glut")) * (1.0 + 0.3 * pk("glut")) * (1.0 + 0.06 * meta.rel("glut_shard")) * meta.rank_bonus()

func light_sources() -> Array:
	var out := [Vector3(0, -40, tower_radius())]
	if res.oil > 0:
		for t in tiles:
			if t.type in B and B[t.type].has("lamp") and not t.ruined and t.get("cons", 0.0) <= 0:
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
	var prod_mul := (1.0 + 0.1 * meta.level("prod")) * meta.rank_bonus()
	var relm := {"food": meta.rel("fungal_seed"), "oil": meta.rel("oil_idol"), "scrap": meta.rel("scrap_saint")}
	_sim_construction(dt)
	for k in rates: rates[k] = 0.0
	var burn := 0.18 + tower_lvl * 0.06
	for t in tiles:
		t.wk = 0
		if not (t.type in B) or t.ruined or t.get("cons", 0.0) > 0: continue
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
			var m: float = (1.0 + 0.25 * pk(k)) * (1.0 + 0.08 * relm.get(k, 0))
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
	_sim_expedition(dt)
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
		toast("Ein Koloss erhebt sich!", Color(1, 0.4, 0.3))
		sfx("alarm", -2.0)
	say("[color=#9fb4ff]Nacht %d[/color] · %d Wucherer nähern sich." % [night, n])
	toast("☾  Nacht %d bricht herein" % night, Color(0.65, 0.75, 1.0))
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
		var spd: float = c.spd * (1.0 - 0.25 * pk("slow") * lit) * pow(0.97, meta.rel("moth_wing"))
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
		toast("%s zerstört" % B[t.type].n, Color(1, 0.45, 0.35))
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
		if not (t.type in B) or t.ruined or not B[t.type].has("dmg") or t.wk == 0 or t.get("cons", 0.0) > 0: continue
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
		var dmg: float = b.dmg * lvl_mul(t.lvl) * (float(t.wk) / b.w) * (1.0 + 0.15 * meta.level("guard")) * (1.0 + 0.25 * pk("gdmg")) * (1.0 + 0.06 * meta.rel("watch_eye"))
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
	var dmg := (55.0 + tower_lvl * 25.0) * (1.0 + 0.25 * meta.level("pulse")) * (1.0 + 0.4 * pk("pulse")) * (1.0 + 0.08 * meta.rel("ember_heart"))
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
				toast("Auftrag erfüllt  ·  ✦ %d" % g, Color(1, 0.8, 0.45))
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
	t.hp = t.maxhp * 0.35
	t.cons = cons_time(type, 1)
	t.cons_max = t.cons
	t.queue = Time.get_ticks_msec()
	t.up = false
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
		if t.lvl >= MAX_LVL or t.ruined or t.get("cons", 0.0) > 0: return
		res.scrap -= c
		t.cons = cons_time(t.type, t.lvl + 1)
		t.cons_max = t.cons
		t.queue = Time.get_ticks_msec()
		t.up = true
		sfx("build", -6.0)
		return
	t.born = Time.get_ticks_msec() / 1000.0
	sfx("build", -2.0)

func repair(i: int) -> void:
	var t: Dictionary = tiles[i]
	if not t.ruined or res.scrap < repair_cost(t): return
	res.scrap -= repair_cost(t)
	t.ruined = false
	t.hp = t.maxhp * 0.35
	t.cons = cons_time(t.type, 1) * 0.6
	t.cons_max = t.cons
	t.queue = Time.get_ticks_msec()
	t.up = false
	t.born = Time.get_ticks_msec() / 1000.0
	sfx("build", -4.0)

func _sim_construction(dt: float) -> void:
	var sites := []
	for t in tiles:
		t.active = false
		if t.get("cons", 0.0) > 0 and not t.ruined: sites.append(t)
	sites.sort_custom(func(a, b): return a.queue < b.queue)
	var slots := builder_slots()
	for i in mini(slots, sites.size()):
		var t: Dictionary = sites[i]
		t.active = true
		t.cons -= dt
		t.hp = minf(t.maxhp, t.hp + t.maxhp * 0.65 * dt / t.cons_max)
		if t.cons <= 0:
			t.cons = 0.0
			if t.up:
				t.lvl += 1
				t.maxhp = bmaxhp(t)
				_quest_progress("upgrade", 1)
				toast("%s erreicht Stufe %d" % [B[t.type].n, t.lvl], Color(1, 0.85, 0.55))
			t.hp = t.maxhp
			t.born = Time.get_ticks_msec() / 1000.0
			rings.append({"p": t.pos, "r": 6.0, "max": 40.0, "t": 0.5, "c": Color(1, 0.85, 0.5)})
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
		toast("Dieser Ort ist bereits erkundet.", Color(0.8, 0.75, 0.7)); return
	if expedition.size() > 0:
		toast("Ein Team ist bereits unterwegs.", Color(0.8, 0.75, 0.7)); return
	var scouts := 0
	for o in tiles:
		if o.type == "scout" and not o.ruined and o.get("cons", 0.0) <= 0: scouts += 1
	if scouts == 0:
		toast("Baue zuerst einen Späherposten.", Color(1, 0.7, 0.5)); return
	if pop < 8:
		toast("Zu wenige Bewohner für ein Team.", Color(1, 0.7, 0.5)); return
	pop -= 4
	expedition = {"site": i, "phase": "out", "p": Vector2(0, 10), "res": {}}
	say("[color=#8fd0ff]Vier Späher[/color] brechen zur %s auf." % ("Höhle" if t.terr == "cave" else "Bunker-Ruine"))
	sfx("click", -4.0)

func _sim_expedition(dt: float) -> void:
	if expedition.is_empty(): return
	var site: Dictionary = tiles[expedition.site]
	var spd := 46.0 * (1.4 if autotest else 1.0)
	if expedition.phase == "out":
		expedition.p = (expedition.p as Vector2).move_toward(site.pos, spd * dt)
		if (expedition.p as Vector2).distance_to(site.pos) < 4:
			expedition.phase = "in"
			_open_explore(expedition.site)
	elif expedition.phase == "back":
		expedition.p = (expedition.p as Vector2).move_toward(Vector2(0, 10), spd * dt)
		if (expedition.p as Vector2).length() < 14:
			_explore_done(expedition.site, expedition.res)
			expedition = {}

func _open_explore(i: int) -> void:
	var t: Dictionary = tiles[i]
	explore_node = Explore.new()
	explore_node.main = self
	var air := 10 + meta.level("air") * 2 + meta.rel("old_map")
	explore_node.setup(t.terr, int(t.seed * 100000), air, 4, true, 2, SPR.get("creature"))
	explore_node.finished.connect(func(r: Dictionary):
		explore_node.queue_free()
		explore_node = null
		expedition.res = r
		expedition.phase = "back"
		say("Das Team macht sich auf den Rückweg."))
	ui.add_child(explore_node)
	toast("Die Späher erreichen den Eingang.", Color(0.6, 0.85, 1.0))
	if autotest: explore_node.auto_run()

func _explore_done(i: int, r: Dictionary) -> void:
	tiles[i].explored = true
	var l: Dictionary = r.loot
	res.oil += l.get("oil", 0)
	res.scrap += l.get("scrap", 0)
	res.food += l.get("food", 0)
	var g := int((l.get("know", 0) * 1.5 + 10) * glut_mul()) if r.ok else 0
	_add_glut(g)
	pop = maxi(1, pop + 4 - r.lost + r.people)
	_quest_progress("explore", 1)
	if r.ok:
		say("[color=#8fd0ff]Team zurück:[/color] +%d Glut · +%d Öl · +%d Schrott · +%d Leute" % [g, l.get("oil", 0), l.get("scrap", 0), r.people])
		toast("Die Späher sind zurück  ·  ✦ %d" % g, Color(0.6, 0.85, 1.0))
		if r.get("relic", false):
			var id := meta.add_relic(rng)
			toast("Reliquie gefunden: %s" % Meta.RELICS[id][0], RARITY_COL[Meta.RELICS[id][2]])
			say("[color=#e6c27a]Reliquie:[/color] %s (%s)" % [Meta.RELICS[id][0], Meta.RELICS[id][1]])
			sfx("win", -6.0)
	else:
		say("[color=#ff8a6a]Das Team kehrt nicht zurück.[/color]")
		toast("Das Team ist verloren.", Color(1, 0.5, 0.4))

# ================================================================ Ende
func _game_over() -> void:
	state = "over"
	var earned := int(run_glut)
	meta.glut += earned
	meta.xp += earned
	if explore_node:
		explore_node.queue_free()
		explore_node = null
	expedition = {}
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
	if OS.get_cmdline_user_args().has("--dbg"): print("DBG n=%d night=%s st=%s exp=%s cr=%d sl=%d pt=%.1f" % [night, is_night, state, expedition.get("phase", "-"), creatures.size(), spawn_left, phase_t])
	if creatures.size() >= 5: light_pulse()
	var plan := ["pump", "hut", "guard", "farm", "yard", "hut", "guard", "scout", "lamp", "pump", "farm", "clinic", "guard", "hut", "lamp",
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
	if not is_night and night >= 2 and expedition.is_empty():
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
					if res.scrap < build_cost(sel_build): toast("Zu wenig Schrott", Color(1, 0.6, 0.45))
					elif not can_place(hover, sel_build): toast("%s passt hier nicht hin" % B[sel_build].n, Color(1, 0.75, 0.55))
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
				var ic := img.duplicate()
				ic.clear_mipmaps()
				var sc := 96.0 / maxf(ic.get_width(), ic.get_height())
				ic.resize(maxi(1, int(ic.get_width() * sc)), maxi(1, int(ic.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
				ICON[f.get_basename()] = ImageTexture.create_from_image(ic)
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
	if t.get("cons", 0.0) > 0 and not t.ruined:
		_draw_site(t, p, tm, key)
		return
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

## Baustelle: halb durchsichtiges Gebäude im Holzgerüst mit Fortschrittsring
func _draw_site(t: Dictionary, p: Vector2, tm: float, key: String) -> void:
	var k: float = 1.0 - t.cons / t.cons_max
	spr(self, key, p, Color(1, 0.9, 0.75, 0.25 + 0.6 * k), 0.92)
	var wood := Color(0.55, 0.4, 0.25)
	var h := 30.0 + 14.0 * k
	for x in [-22.0, 22.0]:
		draw_line(p + Vector2(x, 10), p + Vector2(x * 0.9, -h), wood, 2.5)
	draw_line(p + Vector2(-22, -h * 0.5), p + Vector2(22, -h * 0.5), wood, 2)
	draw_line(p + Vector2(-20, -h), p + Vector2(20, -h), wood, 2)
	draw_line(p + Vector2(-22, 8), p + Vector2(20, -h * 0.5), Color(wood, 0.7), 1.5)
	if t.get("active", false):
		# Funken und Hammerschläge
		var ph := fmod(tm * 2.2 + t.seed * 5.0, 1.0)
		if ph < 0.15:
			for j in 4:
				var a: float = t.seed * 30.0 + j * 1.6
				draw_circle(p + Vector2(8, -h * 0.5) + Vector2.from_angle(a) * (6 + ph * 40), 1.6, Color(1, 0.8, 0.4, 1.0 - ph * 6))
		draw_arc(p + Vector2(0, -h - 14), 9, -PI / 2, -PI / 2 + TAU * k, 24, Color(1, 0.8, 0.45), 3)
		draw_arc(p + Vector2(0, -h - 14), 9, 0, TAU, 24, Color(0, 0, 0, 0.35), 1)
	else:
		draw_string(font, p + Vector2(-20, -h - 8), "wartet", HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(0.85, 0.8, 0.7, 0.8))

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
	if expedition.size() > 0 and expedition.phase != "in":
		var ep: Vector2 = expedition.p
		var site: Vector2 = tiles[expedition.site].pos
		markers.draw_dashed_line(ep, site if expedition.phase == "out" else Vector2(0, 10), Color(0.6, 0.85, 1.0, 0.35), 2.0, 8.0)
		for j in 4:
			Explore.draw_suit(markers, ep + Vector2(-12 + j * 8, (j % 2) * 4), 0.9, tm * 1.5 + j, true)
		markers.draw_circle(ep + Vector2(0, -22), 14, Color(1, 0.85, 0.5, 0.12))
	for bo in bolts:
		var col := Color(0.6, 1, 0.4) if bo.foe else Color(1, 0.65, 0.25)
		markers.draw_line(bo.p, (bo.p as Vector2).lerp(bo.a, 0.08), Color(col, 0.6), 3)
		markers.draw_circle(bo.p, 4.5 if not bo.get("splash", 0.0) else 7.0, col)
	for r in rings:
		markers.draw_arc(r.p, r.r, 0, TAU, 64, Color(r.c, clampf(r.t * 2.0, 0, 1)), 4)
	for f in floats:
		markers.draw_string(font, f.p + Vector2(-60, 0), f.s, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(f.c, minf(f.t, 1.0)))

# ================================================================ UI
const BRASS := Color(0.78, 0.6, 0.32)
const EMBER := Color(1.0, 0.62, 0.25)
const INK := Color(0.055, 0.05, 0.045)
const CATS := [["Wirtschaft", ["hut", "pump", "yard", "farm", "water", "forge"]], ["Licht & Wehr", ["lamp", "guard", "beacon", "mortar"]], ["Werkstätten", ["clinic", "scout"]]]

var font_head: SystemFont
var font_body: SystemFont
var disp := {"oil": 0.0, "scrap": 0.0, "food": 0.0, "glut": 0.0}
var toast_box: VBoxContainer
var sel_panel: PanelContainer
var sel_icon: TextureRect
var sel_title: Label
var cat_idx := 0
var cat_btns: Array = []
var build_row: HBoxContainer
var queue_lbl: Label
var ICON := {}

func _style(c: Color, border: Color = Color(BRASS, 0.45), radius: int = 6, bw: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 12
	s.anti_aliasing = true
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 9; s.content_margin_bottom = 9
	return s

func _flat(c: Color, bottom: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = bottom
	s.border_width_bottom = 2
	s.content_margin_left = 6; s.content_margin_right = 6
	s.content_margin_top = 4; s.content_margin_bottom = 4
	return s

func _bar(fill: Color, w: float, h: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(w, h)
	var bg := StyleBoxFlat.new(); bg.bg_color = Color(0, 0, 0, 0.45); bg.set_corner_radius_all(3)
	bg.border_color = Color(BRASS, 0.35); bg.set_border_width_all(1)
	var fg := StyleBoxFlat.new(); fg.bg_color = fill; fg.set_corner_radius_all(3)
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
	r.add_theme_color_override("default_color", Color(0.88, 0.85, 0.8))
	return r

func _head(text: String, size: int, col: Color = BRASS) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_head)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _make_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	font_head = SystemFont.new()
	font_head.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Georgia", "Palatino", "Times New Roman", "Noto Serif", "DejaVu Serif"])
	font_head.font_weight = 600
	font_body = SystemFont.new()
	font_body.font_names = PackedStringArray(["Inter", "SF Pro Text", "Helvetica Neue", "Segoe UI", "Roboto", "Noto Sans", "DejaVu Sans"])
	th = Theme.new()
	th.default_font = font_body
	th.set_stylebox("normal", "Button", _style(Color(0.08, 0.07, 0.06, 0.82)))
	th.set_stylebox("hover", "Button", _style(Color(0.16, 0.12, 0.08, 0.9), EMBER))
	th.set_stylebox("pressed", "Button", _style(Color(0.3, 0.18, 0.07, 0.92), EMBER, 6, 2))
	th.set_stylebox("disabled", "Button", _style(Color(0.05, 0.05, 0.05, 0.6), Color(BRASS, 0.12)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("panel", "PanelContainer", _style(Color(INK, 0.86)))
	th.set_stylebox("panel", "TooltipPanel", _style(Color(INK, 0.96), EMBER))
	th.set_color("font_color", "Button", Color(0.93, 0.88, 0.8))
	th.set_color("font_hover_color", "Button", Color(1, 0.86, 0.6))
	th.set_color("font_pressed_color", "Button", Color(1, 0.8, 0.5))
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.42, 0.4))
	th.set_color("font_color", "Label", Color(0.9, 0.86, 0.8))
	th.set_color("font_color", "TooltipLabel", Color(0.95, 0.9, 0.82))
	th.set_font_size("font_size", "Button", 13)
	th.set_font_size("font_size", "Label", 13)
	root = Control.new()
	root.theme = th
	root.size = Vector2(1280, 720)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	# ---------- Ressourcenleiste
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", _style(Color(INK, 0.9), Color(BRASS, 0.6), 4))
	tp.position = Vector2(306, 8)
	root.add_child(tp)
	top = _rich(14)
	top.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.custom_minimum_size = Vector2(640, 20)
	tp.add_child(top)
	hud_nodes.append(tp)
	# ---------- Phase
	var pp := PanelContainer.new()
	pp.add_theme_stylebox_override("panel", _style(Color(INK, 0.8), Color(BRASS, 0.3), 4))
	pp.position = Vector2(478, 54)
	root.add_child(pp)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 4)
	pp.add_child(pv)
	phase_lbl = _head("", 15)
	phase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_lbl.custom_minimum_size = Vector2(296, 0)
	pv.add_child(phase_lbl)
	phase_bar = _bar(EMBER, 296, 5)
	pv.add_child(phase_bar)
	hud_nodes.append(pp)
	# ---------- Einblendungen
	toast_box = VBoxContainer.new()
	toast_box.position = Vector2(440, 112)
	toast_box.custom_minimum_size = Vector2(400, 0)
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	# ---------- Links: Aufträge & Chronik
	var lp := PanelContainer.new()
	lp.position = Vector2(8, 8)
	lp.custom_minimum_size = Vector2(290, 0)
	root.add_child(lp)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	lp.add_child(lv)
	lv.add_child(_head("Aufträge", 15))
	quest_lbl = _rich(12)
	quest_lbl.custom_minimum_size = Vector2(262, 0)
	lv.add_child(quest_lbl)
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", _flat(Color(0, 0, 0, 0), Color(BRASS, 0.3)))
	lv.add_child(sep)
	lv.add_child(_head("Chronik", 15))
	logl = _rich(11)
	logl.custom_minimum_size = Vector2(262, 150)
	logl.add_theme_constant_override("line_separation", 3)
	logl.add_theme_color_override("default_color", Color(0.75, 0.73, 0.7))
	lv.add_child(logl)
	hud_nodes.append(lp)
	# ---------- Rechts: Leuchtturm
	side = PanelContainer.new()
	side.position = Vector2(992, 8)
	side.custom_minimum_size = Vector2(280, 0)
	root.add_child(side)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	side.add_child(sv)
	sv.add_child(_head("Leuchtturm", 15))
	tower_bar = _bar(Color(1, 0.72, 0.35), 252, 9)
	sv.add_child(tower_bar)
	side_lbl = _rich(12)
	side_lbl.custom_minimum_size = Vector2(252, 0)
	sv.add_child(side_lbl)
	pulse_btn = Button.new()
	pulse_btn.custom_minimum_size = Vector2(252, 42)
	pulse_btn.pressed.connect(light_pulse)
	sv.add_child(pulse_btn)
	night_btn = Button.new()
	night_btn.custom_minimum_size = Vector2(252, 34)
	night_btn.text = "Nacht herbeirufen   N"
	night_btn.tooltip_text = "Die Nacht beginnt sofort. Mehr Zeit für Glut."
	night_btn.pressed.connect(func(): if not is_night: phase_t = 0.01)
	sv.add_child(night_btn)
	queue_lbl = Label.new()
	queue_lbl.add_theme_font_size_override("font_size", 11)
	queue_lbl.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	sv.add_child(queue_lbl)
	hud_nodes.append(side)
	# ---------- Rechts unten: Auswahl
	sel_panel = PanelContainer.new()
	sel_panel.position = Vector2(992, 330)
	sel_panel.custom_minimum_size = Vector2(280, 0)
	sel_panel.visible = false
	root.add_child(sel_panel)
	var selv := VBoxContainer.new()
	selv.add_theme_constant_override("separation", 6)
	sel_panel.add_child(selv)
	var selh := HBoxContainer.new()
	selh.add_theme_constant_override("separation", 10)
	selv.add_child(selh)
	sel_icon = TextureRect.new()
	sel_icon.custom_minimum_size = Vector2(56, 56)
	sel_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sel_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selh.add_child(sel_icon)
	sel_title = _head("", 17, Color(1, 0.85, 0.6))
	sel_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	sel_title.custom_minimum_size = Vector2(180, 0)
	selh.add_child(sel_title)
	var sinfo := _rich(12)
	sinfo.name = "Info"
	sinfo.custom_minimum_size = Vector2(252, 0)
	selv.add_child(sinfo)
	up_btn = Button.new()
	up_btn.custom_minimum_size = Vector2(252, 38)
	up_btn.pressed.connect(func(): if sel_tile >= 0: upgrade(sel_tile))
	selv.add_child(up_btn)
	rep_btn = Button.new()
	rep_btn.custom_minimum_size = Vector2(252, 32)
	rep_btn.pressed.connect(func():
		if sel_tile >= 0:
			if tiles[sel_tile].ruined: repair(sel_tile)
			else: demolish(sel_tile))
	selv.add_child(rep_btn)
	# ---------- Unten: Bauleiste mit Kategorien
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", _style(Color(INK, 0.9), Color(BRASS, 0.5), 6))
	bp.position = Vector2(8, 590)
	root.add_child(bp)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	bp.add_child(bv)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	bv.add_child(tabs)
	for ci in CATS.size():
		var tb := Button.new()
		tb.text = CATS[ci][0]
		tb.toggle_mode = true
		tb.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0)))
		tb.add_theme_stylebox_override("hover", _flat(Color(1, 1, 1, 0.04), Color(EMBER, 0.6)))
		tb.add_theme_stylebox_override("pressed", _flat(Color(1, 0.6, 0.2, 0.08), EMBER))
		tb.add_theme_font_override("font", font_head)
		tb.add_theme_font_size_override("font_size", 13)
		var idx2 := ci
		tb.pressed.connect(func(): _set_cat(idx2))
		tabs.add_child(tb)
		cat_btns.append(tb)
	build_row = HBoxContainer.new()
	build_row.add_theme_constant_override("separation", 6)
	bv.add_child(build_row)
	for k in ORDER:
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 76)
		b.icon = ICON.get(SPRITE_OF.get(k, k))
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_constant_override("icon_max_width", 46)
		b.toggle_mode = true
		b.tooltip_text = "%s\n%s" % [B[k].n, B[k].d]
		b.pressed.connect(func():
			sel_build = k
			sel_tile = -1
			for x in build_btns.values(): x.button_pressed = x == b)
		build_row.add_child(b)
		build_btns[k] = b
		b.mouse_entered.connect(func(): _hover_tween(b, 1.06))
		b.mouse_exited.connect(func(): _hover_tween(b, 1.0))
	build_btns["hut"].button_pressed = true
	_set_cat(0)
	hud_nodes.append(bp)
	var help := _rich(11)
	help.position = Vector2(640, 694)
	help.size = Vector2(740, 24)
	help.autowrap_mode = TextServer.AUTOWRAP_OFF
	help.add_theme_color_override("default_color", Color(0.75, 0.7, 0.62, 0.75))
	help.text = "[color=#e0a860]Q[/color] Lichtstoß   [color=#e0a860]U[/color] Ausbauen   [color=#e0a860]N[/color] Nacht   [color=#e0a860]WASD[/color] Kamera   [color=#e0a860]Leertaste[/color] Pause   [color=#e0a860]1·2·3[/color] Tempo"
	root.add_child(help)
	hud_nodes.append(help)
	for n in hud_nodes: n.visible = false

func _set_cat(i: int) -> void:
	cat_idx = i
	for j in cat_btns.size(): cat_btns[j].button_pressed = j == i
	for k in build_btns:
		var locked: bool = B[k].has("unlock") and meta.level(B[k].unlock) == 0
		build_btns[k].visible = k in CATS[i][1] and not locked

func _hover_tween(c: Control, s: float) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(s, s), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Einblendung mittig oben, gleitet herein und verblasst
func toast(text: String, col: Color = Color(1, 0.85, 0.6)) -> void:
	if toast_box == null or state == "menu": return
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(INK, 0.88), Color(col, 0.7), 4))
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_head)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", col)
	l.custom_minimum_size = Vector2(372, 0)
	p.add_child(l)
	toast_box.add_child(p)
	toast_box.move_child(p, 0)
	while toast_box.get_child_count() > 3:
		var old := toast_box.get_child(toast_box.get_child_count() - 1)
		toast_box.remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)

func _update_ui() -> void:
	for k in ["oil", "scrap", "food"]:
		disp[k] = lerpf(disp[k], res[k], 0.18)
	disp.glut = lerpf(disp.glut, run_glut, 0.15)
	var chip := func(col: String, name: String, v: float, r: float, low: float) -> String:
		var rc := "#9fd88a" if r >= 0 else "#ff8a6a"
		var vc := "#ff6a5a" if v < low and sin(Time.get_ticks_msec() * 0.01) > 0 else "#f3ead9"
		return "[color=%s]◆[/color] [color=#a89c88]%s[/color] [color=%s][b]%d[/b][/color][color=%s] %+.1f[/color]" % [col, name, vc, int(v), rc, r]
	top.text = "%s    %s    %s    [color=#7fc8ff]◆[/color] [color=#a89c88]Leute[/color] [b]%d[/b][color=#a89c88]/%d[/color]    [color=#ff9a4a]✦[/color] [color=#a89c88]Glut[/color] [b]%d[/b]" % [
		chip.call("#ffb347", "Öl", disp.oil, rates.oil, 15), chip.call("#d2a679", "Schrott", disp.scrap, rates.scrap, 0),
		chip.call("#a3e07a", "Nahrung", disp.food, rates.food, 5), pop, housing(), int(disp.glut)]
	if is_night:
		phase_lbl.text = "☾  Nacht %d   ·   %d Wucherer" % [night, creatures.size() + spawn_left]
		phase_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 1.0))
		phase_bar.max_value = maxf(1.0, creatures.size() + spawn_left + 0.01)
		phase_bar.value = creatures.size() + spawn_left
	else:
		phase_lbl.text = "☀  Tag   ·   Nacht %d in %d s" % [night + 1, int(phase_t)]
		phase_lbl.add_theme_color_override("font_color", Color(1, 0.84, 0.55))
		phase_bar.max_value = DAY_LEN
		phase_bar.value = phase_t
	tower_bar.max_value = tower_max
	tower_bar.value = lerpf(tower_bar.value, tower_hp, 0.2)
	var ready: bool = pulse_cd <= 0 and res.oil >= 15
	pulse_btn.text = ("☀  Lichtstoß   Q   ·   15 Öl" if pulse_cd <= 0 else "Lichtstoß lädt …  %d s" % int(ceil(pulse_cd)))
	pulse_btn.disabled = not ready
	pulse_btn.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.1, 0.85), (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)) if ready else 0.0)
	night_btn.visible = not is_night
	var building := 0
	var waiting := 0
	for t in tiles:
		if t.get("cons", 0.0) > 0:
			if t.get("active", false): building += 1
			else: waiting += 1
	queue_lbl.text = "Baumeister  %d / %d   ·   Warteschlange %d" % [building, builder_slots(), waiting]
	var s := "[color=#a89c88]Lebenspunkte[/color]  %d / %d     [color=#a89c88]Stufe[/color]  %d" % [int(tower_hp), int(tower_max), tower_lvl]
	if expedition.size() > 0:
		s += "\n[color=#8fd0ff]Späher unterwegs[/color]  ·  " + {"out": "auf dem Hinweg", "in": "in der Tiefe", "back": "auf dem Rückweg"}[expedition.phase]
	if perks.size() > 0:
		var parts := []
		for k in perks: parts.append("%s ×%d" % [CARDS[k][0], perks[k]])
		s += "\n[color=#c9a7ff]Karten[/color]  [color=#b8b0a6]" + ", ".join(parts) + "[/color]"
	side_lbl.text = s
	var qt := ""
	for q in quests:
		var pct: float = float(mini(q.have, q.goal)) / q.goal
		var bar_n := int(pct * 14)
		qt += "%s\n[color=#e0a860]%s[/color][color=#4a4036]%s[/color]  [color=#a89c88]%d/%d[/color]  [color=#ff9a4a]✦%d[/color]\n" % [q.text, "▰".repeat(bar_n), "▱".repeat(14 - bar_n), mini(q.have, q.goal), q.goal, q.reward]
	quest_lbl.text = qt.strip_edges()
	_update_sel()
	for k in build_btns:
		var b: Button = build_btns[k]
		b.text = "%s\n%d" % [B[k].n, build_cost(k)]
		b.modulate = Color(1, 1, 1) if res.scrap >= build_cost(k) else Color(0.55, 0.52, 0.5)

func _update_sel() -> void:
	var info: RichTextLabel = sel_panel.get_node("VBoxContainer/Info") if sel_panel.has_node("VBoxContainer/Info") else null
	if info == null:
		for c in sel_panel.get_child(0).get_children():
			if c is RichTextLabel: info = c
	var show: bool = sel_tile >= 0 or (hover >= 0 and tiles[hover].type == "" and state == "play")
	sel_panel.visible = show
	if not show: return
	up_btn.visible = false
	rep_btn.visible = false
	var s := ""
	if sel_tile >= 0:
		var t: Dictionary = tiles[sel_tile]
		if t.type == "tower":
			sel_icon.texture = ICON.get("tower")
			sel_title.text = "Leuchtturm"
			s = "Stufe %d / 8\n[color=#a89c88]Mehr Licht, mehr Lebenspunkte, stärkerer Lichtstoß.[/color]" % tower_lvl
			up_btn.visible = tower_lvl < 8
			up_btn.text = "Ausbauen   ·   %d Schrott" % upgrade_cost(t)
			up_btn.disabled = res.scrap < upgrade_cost(t)
		elif t.type in B:
			var b: Dictionary = B[t.type]
			sel_icon.texture = ICON.get(SPRITE_OF.get(t.type, t.type))
			sel_title.text = b.n
			s = "Stufe %d / %d   %s\n[color=#a89c88]%s[/color]" % [t.lvl, MAX_LVL, "[color=#e0a860]" + "★".repeat(t.lvl) + "[/color][color=#4a4036]" + "★".repeat(MAX_LVL - t.lvl) + "[/color]", b.d]
			if t.get("cons", 0.0) > 0:
				s += "\n\n[color=#ffcf8a]%s  %d %%[/color]" % ["Im Bau" if t.get("active", false) else "Wartet auf Baumeister", int(100.0 * (1.0 - t.cons / t.cons_max))]
			s += "\n\n[color=#a89c88]Lebenspunkte[/color]  %d / %d" % [int(t.hp), int(t.maxhp)]
			if b.w > 0: s += "\n[color=#a89c88]Arbeiter[/color]  %d / %d" % [t.wk, b.w]
			if b.has("dmg"): s += "\n[color=#a89c88]Schaden[/color]  %.0f   [color=#a89c88]Reichweite[/color]  %.1f" % [b.dmg * lvl_mul(t.lvl), b.range + 0.25 * (t.lvl - 1)]
			for k in b.get("prod", {}):
				s += "\n[color=#a89c88]Ertrag[/color]  %.2f %s/s" % [b.prod[k] * lvl_mul(t.lvl) * (2.0 if b.get("bonus", "") == t.terr else 1.0), {"oil": "Öl", "scrap": "Schrott", "food": "Nahrung"}[k]]
			if t.ruined:
				s += "\n[color=#ff7b6b]Zerstört[/color]"
				rep_btn.visible = true
				rep_btn.text = "Wiederaufbauen   ·   %d Schrott" % repair_cost(t)
				rep_btn.disabled = res.scrap < repair_cost(t)
			elif t.get("cons", 0.0) <= 0:
				up_btn.visible = t.lvl < MAX_LVL
				up_btn.text = "Ausbauen   ·   %d Schrott   ·   %d s" % [upgrade_cost(t), int(cons_time(t.type, t.lvl + 1))]
				up_btn.disabled = res.scrap < upgrade_cost(t)
				rep_btn.visible = true
				rep_btn.text = "Abreißen   ·   +%d Schrott" % int(build_cost(t.type) * 0.4)
	else:
		var h: Dictionary = tiles[hover]
		var tn: String = {"ground": "Boden", "fungus": "Pilzfeld", "oil": "Ölquelle", "ruin": "Ruine", "rock": "Fels", "cave": "Höhle", "bunker": "Bunker"}.get(h.terr, "Gelände")
		var td: String = {"ground": "Bebaubar.", "fungus": "Pilzzucht bringt hier doppelt.", "oil": "Nur für Ölpumpen.", "ruin": "Klicken: plündern für Schrott.\nSchrottplatz bringt hier doppelt.",
			"rock": "Nicht bebaubar.", "cave": "Klicken: Späher hineinschicken.", "bunker": "Klicken: Späher hineinschicken."}.get(h.terr, "")
		sel_icon.texture = ICON.get(h.terr) if h.terr in ["oil", "ruin", "rock", "cave", "bunker"] else ICON.get(SPRITE_OF.get(sel_build, sel_build))
		sel_title.text = tn
		s = "[color=#a89c88]%s[/color]" % td
		if h.terr in ["ground", "fungus", "oil", "ruin"]:
			s += "\n\nHier bauen: [b]%s[/b]  ·  %d Schrott  ·  %d s" % [B[sel_build].n, build_cost(sel_build), int(cons_time(sel_build, 1))]
	if info: info.text = s

func say(s: String) -> void:
	if autotest and OS.get_cmdline_user_args().has("--verbose"): print(s)
	log_lines.push_front(s)
	if log_lines.size() > 7: log_lines.pop_back()
	if logl: logl.text = "\n".join(log_lines)

# ---------------------------------------------------------------- Menüs
func _hide_overlays() -> void:
	for n in [menu_box, forge_box, card_box, over_box]:
		if n: n.queue_free()
	menu_box = null; forge_box = null; card_box = null; over_box = null

func _fade_in(c: CanvasItem, dur: float = 0.35) -> void:
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, dur)

func _embers(parent: Node, area: Vector2, amount: int = 70) -> void:
	var e := CPUParticles2D.new()
	e.position = Vector2(area.x / 2, area.y + 10)
	e.amount = amount
	e.lifetime = 7.0
	e.preprocess = 7.0
	e.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	e.emission_rect_extents = Vector2(area.x / 2, 10)
	e.direction = Vector2(0, -1)
	e.spread = 25
	e.gravity = Vector2(4, -6)
	e.initial_velocity_min = 25
	e.initial_velocity_max = 70
	e.scale_amount_min = 1.0
	e.scale_amount_max = 3.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.75, 0.35, 0.0))
	g.add_point(0.15, Color(1, 0.65, 0.25, 0.9))
	g.set_color(1, Color(1, 0.3, 0.1, 0.0))
	e.color_ramp = g
	parent.add_child(e)

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 46)
	b.add_theme_font_override("font", font_head)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0)))
	b.add_theme_stylebox_override("hover", _flat(Color(1, 0.6, 0.2, 0.06), EMBER))
	b.add_theme_stylebox_override("pressed", _flat(Color(1, 0.6, 0.2, 0.12), EMBER))
	b.add_theme_color_override("font_color", Color(0.86, 0.8, 0.7))
	b.add_theme_color_override("font_hover_color", Color(1, 0.8, 0.45))
	b.pressed.connect(cb)
	b.mouse_entered.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 12.0, 0.12))
	b.mouse_exited.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 0.0, 0.12))
	return b

func show_menu() -> void:
	state = "menu"
	_hide_overlays()
	for n in hud_nodes: n.visible = false
	if sel_panel: sel_panel.visible = false
	creatures.clear()
	menu_box = Control.new()
	menu_box.size = Vector2(1280, 720)
	root.add_child(menu_box)
	var shade := ColorRect.new()
	shade.size = Vector2(620, 720)
	shade.color = Color(0, 0, 0, 0.0)
	var grad := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.set_color(0, Color(0.02, 0.02, 0.02, 0.92))
	gg.set_color(1, Color(0.02, 0.02, 0.02, 0.0))
	grad.gradient = gg
	grad.fill_to = Vector2(1, 0)
	var tr := TextureRect.new()
	tr.texture = grad
	tr.size = Vector2(760, 720)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_box.add_child(tr)
	_embers(menu_box, Vector2(1280, 720))
	var v := VBoxContainer.new()
	v.position = Vector2(90, 120)
	v.add_theme_constant_override("separation", 6)
	menu_box.add_child(v)
	var kicker := Label.new()
	kicker.text = "EIN SPIEL ÜBER LICHT UND NEBEL"
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", Color(BRASS, 0.9))
	v.add_child(kicker)
	var t := _head("Das Leuchtfeuer", 64, Color(1, 0.84, 0.58))
	t.add_theme_color_override("font_shadow_color", Color(1, 0.45, 0.1, 0.45))
	t.add_theme_constant_override("shadow_offset_y", 0)
	t.add_theme_constant_override("shadow_outline_size", 14)
	v.add_child(t)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(380, 2)
	line.color = Color(BRASS, 0.6)
	v.add_child(line)
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 26); v.add_child(sp)
	v.add_child(_menu_button("Neuer Lauf", start_run))
	v.add_child(_menu_button("Glutschmiede", show_forge))
	v.add_child(_menu_button("Reliquien", show_relics))
	v.add_child(_menu_button("Beenden", func(): get_tree().quit()))
	# Werte-Karte
	var card := PanelContainer.new()
	card.position = Vector2(90, 520)
	card.add_theme_stylebox_override("panel", _style(Color(INK, 0.75), Color(BRASS, 0.35), 4))
	menu_box.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)
	var rk := HBoxContainer.new()
	rk.add_theme_constant_override("separation", 12)
	cv.add_child(rk)
	rk.add_child(_head("Wächter-Rang %d" % meta.rank(), 18, Color(1, 0.82, 0.55)))
	var rb := _bar(EMBER, 180, 6)
	rb.max_value = 1.0
	rb.value = meta.rank_progress()
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rk.add_child(rb)
	var st := _rich(13)
	st.custom_minimum_size = Vector2(440, 0)
	var nrel := 0
	for k in meta.relics: nrel += meta.relics[k]
	st.text = "[color=#ff9a4a]✦ %d Glut[/color]     [color=#a89c88]Längste Nacht[/color] [b]%d[/b]     [color=#a89c88]Läufe[/color] [b]%d[/b]     [color=#a89c88]Reliquien[/color] [b]%d[/b]" % [meta.glut, meta.best_night, meta.runs, nrel]
	cv.add_child(st)
	_fade_in(menu_box, 0.6)

func _forge_tab(tab: int) -> void:
	show_forge(tab)

func show_forge(tab: int = 0) -> void:
	_hide_overlays()
	state = "menu"
	forge_box = Control.new()
	forge_box.size = Vector2(1280, 720)
	root.add_child(forge_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	forge_box.add_child(dim)
	_embers(forge_box, Vector2(1280, 720), 40)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(INK, 0.94), Color(BRASS, 0.6), 6, 2))
	p.position = Vector2(170, 46)
	p.custom_minimum_size = Vector2(940, 620)
	forge_box.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var hb := HBoxContainer.new()
	v.add_child(hb)
	var t := _head("Glutschmiede", 32, Color(1, 0.82, 0.55))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	hb.add_child(_head("✦ %d" % meta.glut, 26, Color(1, 0.6, 0.3)))
	var sub := Label.new()
	sub.text = "Was du hier schmiedest, bleibt für immer."
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.58))
	v.add_child(sub)
	var groups := [["Turm", ["tower_hp", "light", "burn", "pulse"]], ["Wehr & Bau", ["guard", "bhp", "start_scrap", "start_oil"]],
		["Volk & Ertrag", ["growth", "prod", "glut", "air"]], ["Pläne", ["u_beacon", "u_mortar", "u_forge", "cards4", "reroll"]]]
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for gi in groups.size():
		var tb := Button.new()
		tb.text = groups[gi][0]
		tb.toggle_mode = true
		tb.button_pressed = gi == tab
		tb.add_theme_font_override("font", font_head)
		tb.add_theme_font_size_override("font_size", 15)
		tb.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0)))
		tb.add_theme_stylebox_override("hover", _flat(Color(1, 1, 1, 0.04), Color(EMBER, 0.5)))
		tb.add_theme_stylebox_override("pressed", _flat(Color(1, 0.6, 0.2, 0.08), EMBER))
		var g2 := gi
		tb.pressed.connect(func(): _forge_tab(g2))
		tabs.add_child(tb)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	v.add_child(list)
	var i := 0
	for id in groups[tab][1]:
		var u: Array = Meta.UPGRADES[id]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _style(Color(0.1, 0.085, 0.07, 0.9), Color(BRASS, 0.25), 4))
		list.add_child(row)
		var rh := HBoxContainer.new()
		rh.add_theme_constant_override("separation", 16)
		row.add_child(rh)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(tv)
		tv.add_child(_head(u[0], 17, Color(0.98, 0.85, 0.62)))
		var d := Label.new()
		d.text = u[1]
		d.add_theme_color_override("font_color", Color(0.72, 0.68, 0.62))
		tv.add_child(d)
		var lv := meta.level(id)
		var pips := Label.new()
		pips.text = "◆".repeat(lv) + "◇".repeat(u[2] - lv)
		pips.add_theme_color_override("font_color", EMBER)
		pips.add_theme_font_size_override("font_size", 15)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rh.add_child(pips)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var maxed: bool = lv >= u[2]
		b.text = "Gemeistert" if maxed else "✦ %d" % meta.cost(id)
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not meta.can_buy(id)
		b.pressed.connect(func():
			if meta.buy(id):
				sfx("build", -2.0)
				show_forge(tab))
		rh.add_child(b)
		row.modulate.a = 0.0
		var tw := row.create_tween()
		tw.tween_interval(0.04 * i)
		tw.tween_property(row, "modulate:a", 1.0, 0.25)
		i += 1
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var back := _menu_button("‹  Zurück", show_menu)
	back.add_theme_font_size_override("font_size", 18)
	v.add_child(back)

func show_relics() -> void:
	_hide_overlays()
	state = "menu"
	forge_box = Control.new()
	forge_box.size = Vector2(1280, 720)
	root.add_child(forge_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	forge_box.add_child(dim)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(INK, 0.94), Color(BRASS, 0.6), 6, 2))
	p.position = Vector2(170, 46)
	p.custom_minimum_size = Vector2(940, 620)
	forge_box.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_head("Reliquien", 32, Color(1, 0.82, 0.55)))
	var sub := Label.new()
	sub.text = "Gefunden in den Hauptkammern von Höhlen und Bunkern. Doppelte Funde verstärken sie."
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.58))
	v.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for id in Meta.RELICS:
		var r: Array = Meta.RELICS[id]
		var n := meta.rel(id)
		var c := PanelContainer.new()
		var col: Color = RARITY_COL[r[2]]
		c.add_theme_stylebox_override("panel", _style(Color(0.1, 0.085, 0.07, 0.9), Color(col, 0.55 if n > 0 else 0.12), 4))
		c.custom_minimum_size = Vector2(296, 92)
		grid.add_child(c)
		var cv := VBoxContainer.new()
		c.add_child(cv)
		cv.add_child(_head(r[0] if n > 0 else "? ? ?", 16, col if n > 0 else Color(0.4, 0.38, 0.35)))
		var d := Label.new()
		d.text = ("%s pro Stufe\nStufe %d" % [r[1], n]) if n > 0 else "Noch nicht gefunden"
		d.add_theme_color_override("font_color", Color(0.72, 0.68, 0.62) if n > 0 else Color(0.4, 0.38, 0.35))
		cv.add_child(d)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var back := _menu_button("‹  Zurück", show_menu)
	back.add_theme_font_size_override("font_size", 18)
	v.add_child(back)
	_fade_in(forge_box)

const CARD_ICON := {"oil": "⛽", "scrap": "⚒", "food": "❀", "gdmg": "➶", "grate": "➶", "grange": "♜", "burn": "☀", "radius": "◎", "pulse": "✺",
	"pulsecd": "✺", "hp": "▣", "pop": "☺", "glut": "✦", "cheap": "⚖", "regen": "✚", "slow": "☁", "crit": "✧", "tower": "♖"}

func _build_card_ui() -> void:
	if card_box: card_box.queue_free()
	card_box = Control.new()
	card_box.size = Vector2(1280, 720)
	root.add_child(card_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	card_box.add_child(dim)
	_fade_in(dim, 0.4)
	var title := _head("Morgengrauen", 34, Color(1, 0.84, 0.58))
	title.position = Vector2(0, 118)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(title)
	var sub := Label.new()
	sub.text = "Nacht %d überstanden  ·  Wähle eine Gabe" % night
	sub.position = Vector2(0, 162)
	sub.size = Vector2(1280, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
	card_box.add_child(sub)
	var n := card_opts.size()
	var w := 214.0
	var gap := 22.0
	var x0 := (1280 - (n * w + (n - 1) * gap)) / 2.0
	for i in n:
		var id: String = card_opts[i]
		var c: Array = CARDS[id]
		var col: Color = RARITY_COL[c[2]]
		var b := Button.new()
		b.size = Vector2(w, 300)
		b.position = Vector2(x0 + i * (w + gap), 760)
		b.pivot_offset = b.size / 2.0
		b.add_theme_stylebox_override("normal", _style(Color(0.08, 0.07, 0.06, 0.97), Color(col, 0.75), 8, 2))
		b.add_theme_stylebox_override("hover", _style(Color(0.13, 0.1, 0.08, 0.99), col, 8, 3))
		b.add_theme_stylebox_override("pressed", _style(Color(0.2, 0.14, 0.08, 1.0), col, 8, 3))
		card_box.add_child(b)
		var vb := VBoxContainer.new()
		vb.position = Vector2(0, 22)
		vb.size = Vector2(w, 260)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_theme_constant_override("separation", 12)
		b.add_child(vb)
		var ic := Label.new()
		ic.text = CARD_ICON.get(id, "✦")
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", 52)
		ic.add_theme_color_override("font_color", col.lightened(0.15))
		vb.add_child(ic)
		var nm := _head(c[0], 19, Color(1, 0.88, 0.66))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(nm)
		var de := Label.new()
		de.text = c[1]
		de.autowrap_mode = TextServer.AUTOWRAP_WORD
		de.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		de.custom_minimum_size = Vector2(w - 30, 0)
		de.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72))
		vb.add_child(de)
		var ra := Label.new()
		ra.text = RARITY_NAME[c[2]].to_upper() + (("   ·   Stufe %d" % (pk(id) + 1)) if pk(id) > 0 else "")
		ra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ra.add_theme_font_size_override("font_size", 11)
		ra.add_theme_color_override("font_color", col)
		vb.add_child(ra)
		for nd in [ic, nm, de, ra]: nd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tw := b.create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_property(b, "position:y", 220.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		b.mouse_entered.connect(func(): _hover_tween(b, 1.05))
		b.mouse_exited.connect(func(): _hover_tween(b, 1.0))
		b.pressed.connect(func(): pick_card(id))
	if reroll_left > 0:
		var rb := Button.new()
		rb.text = "Neu mischen"
		rb.position = Vector2(560, 560)
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
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = Vector2(1280, 720)
	over_box.add_child(dim)
	_fade_in(over_box, 0.8)
	_embers(over_box, Vector2(1280, 720), 30)
	var v := VBoxContainer.new()
	v.position = Vector2(340, 170)
	v.custom_minimum_size = Vector2(600, 0)
	v.add_theme_constant_override("separation", 14)
	over_box.add_child(v)
	var t := _head("Das Licht ist erloschen", 44, Color(1, 0.75, 0.52))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var nights := _head("%d Nächte" % night, 26, Color(0.9, 0.86, 0.78))
	nights.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nights)
	if record:
		var rl := _head("Neuer Rekord", 18, EMBER)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	var gl := _head("✦ 0", 34, Color(1, 0.6, 0.3))
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gl)
	var tw := gl.create_tween()
	tw.tween_interval(0.6)
	tw.tween_method(func(x: float): gl.text = "✦ +%d Glut" % int(x), 0.0, float(earned), 1.4)
	var st := Label.new()
	st.text = "%d Wucherer besiegt   ·   Wächter-Rang %d" % [run_kills, meta.rank()]
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	v.add_child(st)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	for item in [["Glutschmiede", show_forge], ["Neuer Lauf", start_run], ["Hauptmenü", show_menu]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(170, 44)
		b.add_theme_font_override("font", font_head)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(func(): item[1].call())
		hb.add_child(b)

func _snap(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://shot_%s.png" % name)

func _shot() -> void:
	res.scrap = 900
	for p in ["pump", "guard", "guard", "lamp", "farm", "yard", "guard", "clinic", "lamp", "hut", "scout"]:
		for i in tiles.size():
			if can_place(i, p) and tiles[i].d >= (2 if p == "guard" else 1) and tiles[i].d <= 3:
				build(i, p); break
	await get_tree().create_timer(1.5).timeout
	_snap("bau")
	for t in tiles:
		if t.get("cons", 0.0) > 0: t.cons = 0.01
	await get_tree().create_timer(1.0).timeout
	sel_tile = idx[Vector2i(0, 0)]
	_snap("tag")
	sel_tile = -1
	phase_t = 0.01
	night = 5
	await get_tree().create_timer(10.0).timeout
	_snap("nacht")
	creatures.clear(); spawn_left = 0
	_end_night()
	await get_tree().create_timer(1.2).timeout
	_snap("karten")
	get_tree().quit()

func _shot_menu() -> void:
	await get_tree().create_timer(2.0).timeout
	_snap("menu")
	show_forge()
	await get_tree().create_timer(1.2).timeout
	_snap("schmiede")
	show_relics()
	await get_tree().create_timer(0.8).timeout
	_snap("reliquien")
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
