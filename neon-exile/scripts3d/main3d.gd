extends Node3D
# Kapitel 1 in First-Person: Welt, Licht, Spieler, Gegner, Projektile, Effekte, Story-Ablauf.

const Level = preload("res://scripts3d/level3d.gd")
const Player = preload("res://scripts3d/player3d.gd")
const Enemy = preload("res://scripts3d/enemy3d.gd")
const Npc = preload("res://scripts3d/npc3d.gd")
const Boss = preload("res://scripts3d/boss3d.gd")
const Hud = preload("res://scripts3d/hud3d.gd")
const Dialog = preload("res://scripts/dialog.gd")
const Chapters = preload("res://scripts3d/chapters.gd")
var ch: Dictionary
var chapter := 1
var boss_spawn := Vector3.ZERO
var pickups: Array = []      # [{n: Node3D, kind: "weapon"/"ability", idx: int, cb: Callable}]
var pickup_hint := ""
var end_after_pickup := false
var tears: Array = []
var door_cols: Array = []     # x-Spalten der beiden Tueren D
var gate_col := 0

var level
var player
var boss
var hud
var dialog
var state := "play"          # play | dialog | dead | end
var checkpoint := Vector3.ZERO
var seen := {}
var shards := 0
# Kapitel 7 (Wiese) hat keinen Splitter, danach zaehlt es eins weniger
func _shard_no() -> int:
	return mini(chapter, 6) if chapter < 9 else 7
var objective := ""
var banner_text := ""
var banner_col := Color.WHITE
var banner_t := 0.0
var title_t := 0.0
var shake_t := 0.0
var hurt_t := 0.0
var hitmark_t := 0.0
var play_time := 0.0
var deaths := 0
var shard_node: Node3D
var projs: Array = []        # [{n: MeshInstance3D, v: Vector3, life: float}]
var tracers: Array = []      # [{n: MeshInstance3D, life: float}]
var mats := {}
var proj_mesh := SphereMesh.new()

func _ready() -> void:
	chapter = clampi(Game.chapter, 1, Chapters.CHAPTERS.size())
	ch = Chapters.CHAPTERS[chapter - 1]
	_setup_input()
	_setup_world()
	Game.ach_popup = _ach_toast
	level = Level.new()
	level.setup(ch)
	add_child(level)
	level.load_map(ch.map)
	var xs := {}
	for c in level.doors_of("D"):
		xs[c.x] = true
	door_cols = xs.keys()
	door_cols.sort()
	for c in level.doors_of("G"):
		gate_col = c.x
	proj_mesh.radius = 0.2
	proj_mesh.height = 0.4
	for s in level.spawns:
		match s.c:
			"P":
				checkpoint = s.pos
			"c":
				spawn_enemy("crawler", s.pos)
			"d":
				spawn_enemy("drone", s.pos)
			"S":
				_make_shard(s.pos)
			"X":
				secret_pos = s.pos
			"B":
				boss = Boss.new()
				boss.main = self
				boss.cfg = ch.boss
				boss_spawn = s.pos
				boss.position = s.pos
				add_child(boss)
	player = Player.new()
	player.main = self
	player.position = checkpoint + Vector3(0, 0.1, 0)
	player.yaw = -PI / 2.0      # Blick nach Osten
	add_child(player)
	_dust()
	_populate_ghosts()
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	hud.main = self
	ui.add_child(hud)
	dialog = Dialog.new()
	ui.add_child(dialog)
	objective = ch.objectives[0]
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.play_music(ch.music)
	Game.play_ambience(ch.theme)
	if chapter == 1:
		state = "wake"
		wake_t = 0.0
		wake_len = 7.0
	else:
		# Ankunft: man tritt durch dieselbe leuchtende Tuer in den neuen Ort
		state = "arrive"
		arrive_t = 0.0
		_make_door(checkpoint + Vector3(-1.0, 0, 0))
		player.global_position = checkpoint + Vector3(-3.5, 0.1, 0)
	# Ausruestung je nach Kapitel: Kapitel 1 startet ohne Waffe (sie liegt vor dir)
	if chapter > 1 and Game.carry_chapter == chapter and not Game.carry_slots.is_empty():
		# Waffen aus dem letzten Kapitel mitnehmen
		for wid in Game.carry_slots:
			player.give_weapon(int(wid))
		player.select_weapon(int(Game.carry_slots[0]))
		player.ability_unlocked = Game.carry_ability
	elif chapter == 1:
		var fwd := Vector3(1, 0, 0)
		spawn_pickup("weapon", 0, checkpoint + fwd * 2.2)
		_make_tears()
	elif chapter == 2:
		player.give_weapon(1); player.give_weapon(0)
	else:
		# Kapitelauswahl ohne Mitnahme: die Waffen der letzten Kapitel
		var lw := {1: 9, 2: 3, 3: 7, 4: 8, 5: 6, 6: 4, 7: 1, 9: 5}
		var got: Array = []
		for c in range(chapter - 1, 0, -1):
			if lw.has(c) and not got.has(lw[c]):
				got.append(lw[c])
			if got.size() >= 2:
				break
		got.append(0)
		got.reverse()
		for i in got:
			player.give_weapon(i)
		player.ability_unlocked = true
	_build_secret()
	_make_dust()
	if Game.has_completion_weapon() and not player.slots.has(10) and not ch.get("peaceful", false):
		spawn_pickup("weapon", 10, checkpoint + Vector3(2.5, 0, 2.0))
	# Kassette im Level: im Raum mit dem Splitter
	if Story.TAPES.has("c%d_a" % chapter) and door_cols.size() > 1:
		spawn_pickup("tape", 0, _free_spot(Vector2i(door_cols[1] + 4, 20)))
	# Erinnerung: ein warmer Moment pro Kapitel
	if Story.DIALOG.has("mem_c%d_0" % chapter):
		var mp: Vector3 = _free_spot(Vector2i(door_cols[1] - 5, 6)) if door_cols.size() > 1 else checkpoint + Vector3(6, 0, 3)
		spawn_pickup("memory", 0, mp)
	# neue Waffen liegen irgendwo im Level (zweiter Raum)
	var level_weapon := {1: 9, 2: 3, 3: 7, 4: 8, 5: 6, 6: 4, 7: 1, 9: 5}
	if level_weapon.has(chapter) and door_cols.size() > 1:
		var cx: int = int((door_cols[0] + door_cols[1]) / 2)
		spawn_pickup("weapon", level_weapon[chapter], _free_spot(Vector2i(cx, 8)))
	if Game.continue_game and Game.progress > 0:
		state = "play"
		_apply_progress(Game.progress)

# ---------- Geheimraeume, Kassetten, Easter Eggs ----------
const PropHit = preload("res://scripts3d/prop_hit.gd")
const FigureLib = preload("res://scripts3d/figure.gd")
var secret_pos := Vector3.INF
var secret_found := false
var interactables: Array = []     # [{pos, text, cb}]
const SECRET_WEAPON := {1: 3, 2: 4, 3: 8, 4: 6, 5: 9, 6: 7, 7: 2, 9: 7}

func _build_secret() -> void:
	if secret_pos == Vector3.INF:
		return
	var sp := secret_pos
	# warmes Licht, damit der Raum sich "besonders" anfuehlt
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.85, 0.6)
	l.light_energy = 1.6
	l.omni_range = 9.0
	l.position = sp + Vector3(0, 2.6, 0)
	add_child(l)
	spawn_pickup("tape", 1, sp + Vector3(-1.2, 0, 0))
	if SECRET_WEAPON.has(chapter):
		spawn_pickup("weapon", SECRET_WEAPON[chapter], sp + Vector3(1.4, 0, 0))
	match chapter:
		1:
			# goldene Badeente: anschiessen!
			var duck := PropHit.new()
			duck.collision_layer = 4
			var cs := CollisionShape3D.new()
			var sh := SphereShape3D.new()
			sh.radius = 0.45
			cs.shape = sh
			duck.add_child(cs)
			var body := MeshInstance3D.new()
			body.mesh = _sphere(0.35)
			var gold := StandardMaterial3D.new()
			gold.albedo_color = Color(1, 0.8, 0.2)
			gold.metallic = 1.0
			gold.roughness = 0.2
			body.material_override = gold
			body.scale = Vector3(1.2, 0.9, 1.0)
			duck.add_child(body)
			var hd := MeshInstance3D.new()
			hd.mesh = _sphere(0.2)
			hd.material_override = gold
			hd.position = Vector3(0.3, 0.35, 0)
			duck.add_child(hd)
			var beak := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.18, 0.06, 0.12)
			beak.mesh = bm
			beak.material_override = _mat(Color(1, 0.4, 0.1), 1.0)
			beak.position = Vector3(0.5, 0.33, 0)
			duck.add_child(beak)
			add_child(duck)
			duck.global_position = sp + Vector3(0, 0.4, -1.2)
			duck.on_hit = func():
				Game.sfx("jump", 3.5, 1.0)
				banner("QUACK.", Color(1, 0.85, 0.2))
				for i in 4:
					burst(duck.global_position, Color.from_hsv(randf(), 0.7, 1.0), 20)
				duck.rotation.y += 1.0
		2:
			# Automat aus dem ersten Spiel
			var cab := _crate(sp + Vector3(0, 1.0, -1.6), Vector3(1.0, 2.0, 0.8), Color(0.08, 0.05, 0.15))
			var screen := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.75, 0.55)
			screen.mesh = qm
			screen.material_override = _mat(Color("#ff4df0"), 1.5)
			screen.position = Vector3(0, 0.35, 0.41)
			cab.add_child(screen)
			var t := Label3D.new()
			t.text = "NEON DODGE\nHI-SCORE  ECHO 999999"
			t.font_size = 40
			t.modulate = Color("#38f5c4")
			t.position = Vector3(0, 0.36, 0.43)
			cab.add_child(t)
			interactables.append({"pos": cab.global_position, "text": "[E] PLAY NEON DODGE", "cb": func():
				banner("INSERT COIN. ...you don't have any.", Color("#ff4df0"))})
		3:
			var desk := _crate(sp + Vector3(0, 0.4, -1.4), Vector3(1.6, 0.8, 0.8), Color(0.45, 0.35, 0.2))
			var t := Label3D.new()
			t.text = "MAX WAS HERE"
			t.font_size = 48
			t.modulate = Color(0.15, 0.1, 0.05)
			t.rotation.x = -PI / 2.0
			t.position = Vector3(0, 0.41, 0)
			desk.add_child(t)
			interactables.append({"pos": desk.global_position, "text": "[E] READ THE DESK", "cb": func():
				banner("Someone carved this a long time ago. Before the Reset.", Color(0.9, 0.8, 0.6))})
		4:
			# Miras Versteck: ihre Zeichnung von Echo an der Wand
			var board := _crate(sp + Vector3(0, 1.6, -1.8), Vector3(2.4, 1.4, 0.1), Color(0.1, 0.22, 0.16))
			var t := Label3D.new()
			t.text = "MAX WAS HERE\n\n   :)  <- ECHO\n   (my brother)"
			t.font_size = 36
			t.modulate = Color(0.95, 0.95, 0.9)
			t.position = Vector3(0, 0, 0.06)
			board.add_child(t)
		5:
			# Raum voller Uhren, alle auf 4:40, die rueckwaerts laufen
			for i in 6:
				var t := Label3D.new()
				t.text = "4:40"
				t.font_size = 64
				t.modulate = Color(1, 0.3, 0.3)
				t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				t.position = sp + Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
				add_child(t)
				clocks.append(t)

# Staub, der langsam im Licht schwebt (folgt dem Spieler)
func _make_dust() -> void:
	var dust := CPUParticles3D.new()
	dust.amount = 220
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(12, 3, 12)
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 180.0
	dust.gravity = Vector3(0, -0.02, 0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.12
	var qm := QuadMesh.new()
	qm.size = Vector2(0.025, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var dc: Color = (ch.env.fog as Color).lerp(Color.WHITE, 0.6)
	m.albedo_color = Color(dc, 0.35)
	qm.material = m
	dust.mesh = qm
	dust.position = Vector3(0, 1.5, 0)
	player.add_child(dust)

var clocks: Array = []
var bighead := false
var code_buf := ""

func _sphere(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	return sm

func _crate(pos: Vector3, size: Vector3, col: Color) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.6
	mi.material_override = m
	add_child(mi)
	mi.global_position = pos
	return mi

func _update_secrets(delta: float) -> void:
	if secret_pos != Vector3.INF and not secret_found:
		var c: Vector2i = level.cell_of(player.global_position)
		if level.secret_cells.has(c):
			secret_found = true
			Game.mark("secret_%d" % chapter)
			Game.sfx("swap", 1.2, 1.0)
			banner("SECRET FOUND", Color(1, 0.85, 0.5))
	for t in clocks:
		var sec := 59 - int(play_time * 3.0) % 60
		t.text = "4:%02d" % [40 - (sec % 41)]
	# Interaktionen in der Naehe
	for it in interactables:
		if player.global_position.distance_to(it.pos) < 2.4:
			pickup_hint = it.text
			if Input.is_action_just_pressed("interact"):
				it.cb.call()
				return

# Geheimcode: E-C-H-O tippen = grosse Koepfe fuer alle Geister
func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var ch_s: String = OS.get_keycode_string(e.physical_keycode)
		if ch_s.length() == 1:
			code_buf = (code_buf + ch_s).right(8)
			if code_buf.ends_with("ECHO") and not bighead:
				bighead = true
				banner("BIG HEAD MODE", Color("#ffd23d"))
				for n in get_tree().get_nodes_in_group("npcs"):
					if n.P.has("head"):
						n.P.head.scale = Vector3.ONE * 2.2

# ---------- Die Wiese: ein Hund, sonst nichts ----------
var dog: Node3D
var dog_parts := {}
var dog_path: Array = []
var dog_i := 0
var dog_wait := 0.0
var dog_petted := false
var dog_bark_t := 3.0

func _make_dog() -> void:
	var T: float = level.T
	dog = Node3D.new()
	add_child(dog)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.85, 0.62, 0.32)
	fur.roughness = 0.95
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.08, 0.06)
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(0.95, 0.85, 0.65)
	light.roughness = 0.95
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.8, 0.15, 0.15)
	var body := _part(dog, BoxMesh.new(), Vector3(0.38, 0.36, 0.85), Vector3(0, 0.55, 0), fur)
	_part(dog, BoxMesh.new(), Vector3(0.3, 0.12, 0.6), Vector3(0, 0.4, 0), light)
	var head := Node3D.new()
	head.position = Vector3(0, 0.82, -0.48)
	dog.add_child(head)
	_part(head, BoxMesh.new(), Vector3(0.32, 0.3, 0.32), Vector3.ZERO, fur)
	_part(head, BoxMesh.new(), Vector3(0.2, 0.15, 0.22), Vector3(0, -0.06, -0.24), light)
	_part(head, BoxMesh.new(), Vector3(0.08, 0.06, 0.05), Vector3(0, -0.01, -0.36), dark)
	for sd in [-1, 1]:
		_part(head, BoxMesh.new(), Vector3(0.05, 0.05, 0.02), Vector3(0.08 * sd, 0.06, -0.165), dark)
		var ear := _part(head, BoxMesh.new(), Vector3(0.08, 0.2, 0.12), Vector3(0.17 * sd, 0.0, 0.02), fur)
		ear.rotation.z = 0.25 * sd
	_part(head, BoxMesh.new(), Vector3(0.34, 0.05, 0.08), Vector3(0, -0.14, 0.08), red)
	var tail := Node3D.new()
	tail.position = Vector3(0, 0.68, 0.42)
	dog.add_child(tail)
	var tl := _part(tail, BoxMesh.new(), Vector3(0.07, 0.07, 0.35), Vector3(0, 0.08, 0.15), fur)
	tl.rotation.x = -0.6
	var legs: Array = []
	for lz in [-0.3, 0.3]:
		for lx in [-0.13, 0.13]:
			var lg := Node3D.new()
			lg.position = Vector3(lx, 0.42, lz)
			dog.add_child(lg)
			_part(lg, BoxMesh.new(), Vector3(0.1, 0.42, 0.1), Vector3(0, -0.21, 0), fur)
			legs.append(lg)
	dog_parts = {"head": head, "tail": tail, "legs": legs, "body": body}
	# Weg ueber die Wiese bis zum Ende, wo die Tuer erscheint
	var y := 14.5 * T
	dog_path = [Vector3(10 * T, 0, y), Vector3(22 * T, 0, 9 * T), Vector3(38 * T, 0, 18 * T), Vector3(55 * T, 0, 11 * T), Vector3(70 * T, 0, 17 * T), Vector3(84 * T, 0, y)]
	dog.position = dog_path[0]
	boss_spawn = dog_path[-1] - Vector3(4 * T, 0, 0)

func _part(parent: Node3D, bm: BoxMesh, size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	bm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

func _update_dog(delta: float) -> void:
	if dog == null:
		return
	var t := play_time
	dog_parts.tail.rotation.y = sin(t * 14.0) * 0.7
	if ch.get("afterworld", false):
		_update_dog_free(delta, t)
		return
	var target: Vector3 = dog_path[mini(dog_i, dog_path.size() - 1)]
	var to := target - dog.position
	to.y = 0.0
	var pd: float = dog.position.distance_to(Vector3(player.global_position.x, 0, player.global_position.z))
	var moving := false
	if to.length() > 0.4:
		# laeuft voraus, wartet aber, wenn ECHO zurueckbleibt
		if pd < 9.0 or dog_i == 0:
			dog.position += to.normalized() * 5.0 * delta
			moving = true
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 6.0))
	elif dog_i < dog_path.size() - 1:
		dog_wait += delta
		var tp: Vector3 = player.global_position - dog.position
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-tp.x, -tp.z), minf(1.0, delta * 4.0))
		if pd < 6.0 and dog_wait > 0.6:
			dog_i += 1
			dog_wait = 0.0
			Game.sfx("dog", 1.0, 0.8)
	else:
		var tp: Vector3 = player.global_position - dog.position
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-tp.x, -tp.z), minf(1.0, delta * 4.0))
		objective = ch.objectives[3] if not dog_petted else objective
	for k in 4:
		dog_parts.legs[k].rotation.x = sin(t * 14.0 + k * PI) * (0.6 if moving else 0.0)
	dog_parts.body.position.y = 0.55 + (abs(sin(t * 14.0)) * 0.04 if moving else 0.0)
	dog_parts.head.rotation.x = sin(t * 3.0) * 0.08
	dog_bark_t -= delta
	if dog_bark_t <= 0.0:
		dog_bark_t = randf_range(6.0, 12.0)
		if pd < 25.0:
			Game.sfx("dog", randf_range(0.95, 1.1), 0.6)
	# streicheln
	if not dog_petted and pd < 2.4 and state == "play":
		pickup_hint = "[E]  PET BISCUIT"
		if Input.is_action_just_pressed("interact"):
			pet_dog()

# Welt nach dem Ende: Biscuit laeuft einfach mit
func _update_dog_free(delta: float, t: float) -> void:
	var pp := Vector3(player.global_position.x, 0, player.global_position.z)
	var to := pp - dog.position
	var d := to.length()
	var moving := d > 3.5
	if moving:
		dog.position += to.normalized() * minf(d * 1.5, 7.5) * delta
	if d > 0.1:
		dog.rotation.y = lerp_angle(dog.rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 6.0))
	for k in 4:
		dog_parts.legs[k].rotation.x = sin(t * 14.0 + k * PI) * (0.6 if moving else 0.0)
	dog_parts.head.rotation.x = sin(t * 3.0) * 0.08
	if d < 2.4 and state == "play":
		pickup_hint = "[E]  PET BISCUIT"
		if Input.is_action_just_pressed("interact"):
			Game.unlock("good_boy")
			Game.sfx("dog", 1.15, 0.9)
			burst(dog.position + Vector3(0, 1.2, 0), Color(1, 0.6, 0.7), 12)
			if not dog_petted:
				dog_petted = true
				say("c10_dog", func(): state = "play")

func pet_dog() -> void:
	dog_petted = true
	Game.unlock("good_boy")
	Game.sfx("dog", 1.15, 0.9)
	for i in 3:
		burst(dog.position + Vector3(0, 1.2, 0), Color(1, 0.6, 0.7), 12)
	say(sid("dog"), func():
		state = "play"
		_open_exit())

# ---------- Mini-Mission pro Kapitel (Raum 3): erst danach erscheint der Splitter ----------
const EVENTS := {
	1: {"type": "survive", "title": "THE WATER IS RISING - HOLD ON", "time": 30.0},
	2: {"type": "collect", "title": "FIND HER 3 LOST TOYS", "label": "LOST TOY", "col": Color("#ff8fd0")},
	3: {"type": "collect", "title": "THE POWER IS OUT - FIND 3 SWITCHES", "label": "SWITCH", "col": Color("#ffd23d"), "dark": true},
	4: {"type": "collect", "title": "HIDE AND SEEK - FIND 3 CRYING CHILDREN", "label": "CRYING CHILD", "col": Color("#9fd8ff"), "child": true},
	5: {"type": "collect", "title": "STAY QUIET - FIND 3 PATIENT FILES", "label": "PATIENT FILE", "col": Color("#7dffd0")},
	6: {"type": "doors", "title": "WHICH DOOR IS YOURS?"},
	7: {"type": "survive", "title": "MIND THE GAP - HOLD ON UNTIL THE TRAIN COMES", "time": 35.0},
	9: {"type": "survive", "title": "EVERYONE IS HERE - SURVIVE", "time": 30.0},
}
var event := {}
var event_left := 0
var event_t := 0.0
var event_spawn_t := 0.0
var event_nodes: Array = []
var water: MeshInstance3D

func _room3_cells() -> Array:
	var out: Array = []
	if door_cols.size() < 2:
		return out
	for c in level._floor_cells():
		if c.x > door_cols[1] + 3 and c.x < gate_col - 2 and (c.y < 12 or c.y > 17) and level.grid[c.y][c.x] == ".":
			out.append(c)
	out.shuffle()
	return out

func start_event() -> void:
	if not EVENTS.has(chapter) or not shard_node:
		return
	event = EVENTS[chapter]
	shard_node.visible = false
	banner(event.title, Color("#ffd23d"))
	objective = event.title
	var cells := _room3_cells()
	match event.type:
		"survive":
			event_t = event.time
			if chapter == 1:
				water = MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3((gate_col - door_cols[1]) * level.T, 0.02, level.h * level.T)
				water.mesh = bm
				var wm := StandardMaterial3D.new()
				wm.albedo_color = Color(0.3, 0.6, 0.85, 0.45)
				wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				wm.metallic = 0.6
				wm.roughness = 0.05
				water.material_override = wm
				water.position = Vector3((door_cols[1] + gate_col) / 2.0 * level.T, 0.0, level.h * level.T / 2.0)
				add_child(water)
		"collect":
			event_left = 3
			if event.get("dark", false):
				blackout(999.0)
			for i in 3:
				if i >= cells.size():
					break
				var pos: Vector3 = level.cell_center(cells[i])
				var n: Node3D
				if event.get("child", false):
					n = Node3D.new()
					n.position = pos
					add_child(n)
					var rng := RandomNumberGenerator.new()
					rng.randomize()
					var o := FigureLib.outfit("student", rng)
					o.height = 0.7
					var P := FigureLib.build(n, o, 0.5, 0.4, false)
					P.hips.position.y = 0.45
					P.spine.rotation.x = 0.9
					P.head.rotation.x = 0.5
				else:
					n = Node3D.new()
					n.position = pos
					add_child(n)
					var mi := MeshInstance3D.new()
					var bm := BoxMesh.new()
					bm.size = Vector3(0.4, 0.4, 0.4) if chapter != 3 else Vector3(0.5, 0.8, 0.25)
					mi.mesh = bm
					mi.material_override = _mat(event.col, 1.6)
					mi.position.y = 0.6
					n.add_child(mi)
				var l := OmniLight3D.new()
				l.light_color = event.col
				l.light_energy = 1.4
				l.omni_range = 5.0
				l.position.y = 1.2
				n.add_child(l)
				event_nodes.append(n)
				interactables.append({"pos": pos, "text": "[E]  " + event.label, "node": n, "cb": _event_item.bind(n)})
		"doors":
			event_left = 1
			var good := randi() % 4
			for i in 4:
				if i >= cells.size():
					break
				var pos: Vector3 = level.cell_center(cells[i])
				var d := _exit_door(pos, Color(1, 0.7, 0.4), "440")
				event_nodes.append(d)
				interactables.append({"pos": pos, "text": "[E]  KNOCK", "node": d, "cb": _event_door.bind(d, i == good)})

func _event_item(n: Node3D) -> void:
	if not is_instance_valid(n):
		return
	_drop_interactable(n)
	burst(n.position + Vector3(0, 1, 0), event.col, 30)
	Game.sfx("swap", 1.5, 0.8)
	if event.get("child", false):
		banner("...thank you", Color("#9fd8ff"))
	n.queue_free()
	event_left -= 1
	objective = "%s  (%d left)" % [event.title, event_left]
	# jedes gefundene Teil weckt ein paar Geister
	for i in 2:
		spawn_npc("hostile", n.position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))).awake = true
	if event_left <= 0:
		_finish_event()

func _event_door(d: Node3D, good: bool) -> void:
	if not is_instance_valid(d):
		return
	_drop_interactable(d)
	Game.sfx("land", 0.6, 1.0)
	if good:
		banner("...welcome home", Color(1, 0.8, 0.5))
		for n in event_nodes:
			if is_instance_valid(n) and n != d:
				_drop_interactable(n)
				n.queue_free()
		d.queue_free()
		_finish_event()
	else:
		banner("NOT YOUR DOOR", Color("#ff4d6d"))
		shake(0.3)
		for i in 3:
			spawn_npc("hostile", d.position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))).awake = true
		d.queue_free()

func _drop_interactable(n: Node3D) -> void:
	interactables = interactables.filter(func(it): return it.get("node") != n)

func finish_event() -> void:
	# fuer Tests: Mission sofort abschliessen
	if not event.is_empty():
		for n in event_nodes:
			if is_instance_valid(n):
				_drop_interactable(n)
				n.queue_free()
		_finish_event()

func _finish_event() -> void:
	if event.is_empty():
		return
	event = {}
	blackout_t = 0.0
	if water:
		var tw := water.create_tween()
		tw.tween_property(water, "position:y", -0.2, 2.0)
		tw.tween_callback(water.queue_free)
		water = null
	if shard_node:
		shard_node.visible = true
		burst(shard_node.position, Color("#c77dff"), 60)
	banner("A FRAGMENT APPEARS", Color("#c77dff"))
	objective = ch.objectives[2]

func _update_event(delta: float) -> void:
	if event.is_empty() or event.type != "survive":
		return
	event_t -= delta
	objective = "%s  %ds" % [event.title, int(ceil(event_t))]
	if water:
		water.position.y = lerpf(0.0, 0.55, 1.0 - event_t / float(event.time))
	event_spawn_t -= delta
	if event_spawn_t <= 0.0:
		event_spawn_t = 2.2
		var cells := _room3_cells()
		if cells.size() > 0:
			var pos: Vector3 = level.cell_center(cells[0])
			if pos.distance_to(player.global_position) > 6.0:
				spawn_npc("hostile", pos).awake = true
	if event_t <= 0.0:
		_finish_event()

# ---------- Kampfwellen in Raum 2 ----------
var waves_left := 2

func _spawn_wave(n: int) -> void:
	var T: float = level.T
	banner("WAVE %d / 3" % n, Color("#ff4d6d"))
	Game.sfx("enemy_attack", 0.6, 1.0)
	shake(0.3)
	var cells: Array = []
	for c in level._floor_cells():
		if c.x > door_cols[0] + 2 and c.x < door_cols[1] - 1 and level.grid[c.y][c.x] == ".":
			var p: Vector3 = level.cell_center(c)
			if p.distance_to(player.global_position) > 9.0:
				cells.append(c)
	cells.shuffle()
	var count: int = 3 + n + mini(chapter, 6)
	for i in mini(count, cells.size()):
		var e = spawn_npc("hostile", level.cell_center(cells[i]))
		e.awake = true
		burst(level.cell_center(cells[i]) + Vector3(0, 1, 0), ch.enemy, 16)
	if n == 3 and cells.size() > count:
		spawn_npc("special", level.cell_center(cells[count]))

func enemy_in_cone(from: Vector3, dir: Vector3, min_dot: float, rng: float):
	var best = null
	var bd := rng
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to: Vector3 = e.global_position - from
		var d := to.length()
		if d < bd and to.normalized().dot(dir) > min_dot:
			bd = d
			best = e
	return best

func overload_ring(pos: Vector3, col: Color) -> void:
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9
		tm.outer_radius = 1.0
		ring.mesh = tm
		ring.material_override = _mat(col, 3.0)
		ring.position = pos + Vector3(0, 0.4 + i * 0.5, 0)
		add_child(ring)
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector3.ONE * 16.0, 0.45 + i * 0.1)
		tw.tween_callback(ring.queue_free)

func _carry_weapons(next_ch: int) -> void:
	Game.carry_slots = player.slots.duplicate()
	Game.carry_ability = player.ability_unlocked
	Game.carry_chapter = next_ch

# naechste freie Bodenzelle um eine Wunsch-Zelle
func _free_spot(c: Vector2i) -> Vector3:
	for r in 12:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cc := c + Vector2i(dx, dy)
				if cc.x <= 0 or cc.y <= 0 or cc.x >= level.w - 1 or cc.y >= level.h - 1:
					continue
				var p: Vector3 = level.cell_center(cc)
				if not level.solid(p) and level.grid[cc.y][cc.x] == ".":
					return p
	return level.cell_center(c)

# ---------- Gegenstaende zum Aufheben ----------
func spawn_pickup(kind: String, idx: int, pos: Vector3, cb: Callable = Callable()) -> void:
	var root := Node3D.new()
	root.position = Vector3(pos.x, 0.0, pos.z)
	add_child(root)
	var holder := Node3D.new()
	holder.position.y = 0.6
	root.add_child(holder)
	if kind == "weapon":
		var m: Node3D = player.make_gun_model(idx)
		m.scale = Vector3.ONE * (0.55 if idx < 2 else (0.5 if idx == 2 else 2.6))
		holder.add_child(m)
	elif kind == "tape":
		# Kassette
		var cas := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.32, 0.08)
		cas.mesh = bm
		cas.material_override = _mat(Color(0.12, 0.12, 0.14), 0.3)
		holder.add_child(cas)
		var lab := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.42, 0.14, 0.09)
		lab.mesh = lm
		lab.material_override = _mat(Color(0.95, 0.9, 0.8), 1.2)
		lab.position.y = 0.05
		holder.add_child(lab)
	elif kind == "memory":
		# Erinnerung: ein kleines warmes Licht, wie ein Gluehwuermchen
		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.18
		om.height = 0.36
		orb.mesh = om
		orb.material_override = _mat(Color(1.0, 0.8, 0.5), 4.0)
		holder.add_child(orb)
	else:
		var core := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.6
		core.mesh = sm
		core.material_override = _mat(Color("#c77dff"), 3.0)
		holder.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = player.WEAPONS[idx].col if kind == "weapon" else (Color(1, 0.9, 0.75) if kind == "tape" else (Color(1.0, 0.75, 0.45) if kind == "memory" else Color("#c77dff")))
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.position.y = 1.0
	root.add_child(light)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.75
	tm.outer_radius = 0.8
	ring.mesh = tm
	ring.material_override = _mat(light.light_color, 1.5)
	ring.position.y = 0.05
	root.add_child(ring)
	pickups.append({"n": root, "h": holder, "kind": kind, "idx": idx, "cb": cb})

func _update_pickups(delta: float) -> void:
	pickup_hint = ""
	for pk in pickups:
		pk.h.rotation.y += delta * 1.5
		pk.h.position.y = 0.6 + sin(play_time * 2.5) * 0.08
	if state != "play":
		return
	for pk in pickups:
		var d: float = Vector2(pk.n.position.x - player.global_position.x, pk.n.position.z - player.global_position.z).length()
		if d < 2.2:
			var nm: String = player.WEAPONS[pk.idx].name if pk.kind == "weapon" else ("TAPE" if pk.kind == "tape" else ("MEMORY" if pk.kind == "memory" else "OVERLOAD CORE"))
			pickup_hint = "[E]  PICK UP  " + nm
			if pk.kind == "weapon" and player.slots.size() >= player.MAX_SLOTS and not player.slots.has(pk.idx):
				pickup_hint += "   (replaces " + player.WEAPONS[player.weapon].name + ")"
			if Input.is_action_just_pressed("interact"):
				_take(pk)
				return

func _take(pk: Dictionary) -> void:
	pickups.erase(pk)
	pk.n.queue_free()
	burst(pk.n.position + Vector3(0, 0.6, 0), Color.WHITE, 30)
	Game.sfx("swap", 0.8, 1.0)
	if pk.kind == "weapon":
		player.give_weapon(pk.idx)
		if pk.idx < 3:
			radio(["got_pulse", "scatter", "rail"][pk.idx])
		else:
			banner(player.WEAPONS[pk.idx].name, player.WEAPONS[pk.idx].col)
	elif pk.kind == "tape":
		var key := "c%d_%s" % [chapter, "a" if pk.idx == 0 else "b"]
		tapes_found += 1
		Game.mark("tape_" + key)
		get_tree().create_timer(6.0).timeout.connect(func(): flashback())
		radio_queue.push_front(["HALCYON LOG", Story.TAPES[key], "res://assets/voice/tape_%s.ogg" % key])
		radio_t = 0.0
	elif pk.kind == "memory":
		Game.mark("memory_%d" % chapter)
		_memory_moment()
	else:
		player.ability_unlocked = true
		radio("got_overload")
	if pk.cb.is_valid():
		pk.cb.call()

# ---------- Welt nach dem Ende: offene Wiese mit Orten aus jedem Kapitel ----------
var motes: Array = []
const MOTE_LINES := [
	"The water is warm now. Someone left a towel for you.",
	"The music in the market finally stopped. It's quiet. It's okay.",
	"Every file has been signed: RETURNED TO OWNER.",
	"The school bell rings at four. Nobody is waiting anymore. Everyone got picked up.",
	"Visiting hours never end here.",
	"The light in the kitchen is on. Dinner at six.",
	"The last train goes nowhere. It just goes around. You can ride for free.",
	"Her crown is lying in the grass. She doesn't need it anymore.",
	"A drawing, half buried: three stick figures and a dog.",
	"A swing moving on its own. Higher. Higher.",
	"You can hear her laughing somewhere far away. It doesn't hurt.",
	"MOM: come home whenever you want.",
]

func _abox(pos: Vector3, size: Vector3, col: Color, emit: float = 0.0, solid: bool = true) -> Node3D:
	var root: Node3D
	if solid:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		root = sb
	else:
		root = Node3D.new()
	root.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, emit)
	root.add_child(mi)
	add_child(root)
	return root

func _sign(pos: Vector3, text: String, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 96
	l.pixel_size = 0.012
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	add_child(l)

func _build_afterworld() -> void:
	Game.unlock("stay")
	var c := checkpoint
	var spots := [
		["THE DRAIN", Color(0.85, 0.95, 1.0)], ["THE NEON MARKET", Color("#ff8fd0")], ["THE ARCHIVE", Color("#fff1b0")], ["AFTER SCHOOL", Color("#ffb070")],
		["WARD 4", Color("#c8fff0")], ["HOME", Color("#ffc890")], ["LAST TRAIN", Color("#fff2c0")], ["THE CROWN", Color("#ffffff")],
	]
	for i in spots.size():
		var a := i * TAU / spots.size() + 0.3
		var p := c + Vector3(cos(a), 0, sin(a)) * 34.0
		var col: Color = spots[i][1]
		match i:
			0:  # kleines Becken mit Wasser
				_abox(p + Vector3(0, 0.25, 0), Vector3(6, 0.5, 4), Color(0.95, 0.97, 1.0))
				_abox(p + Vector3(0, 0.52, 0), Vector3(5.4, 0.05, 3.4), Color(0.4, 0.75, 0.95), 0.6, false)
			1:  # Neon-Kiosk
				_abox(p + Vector3(0, 1.2, 0), Vector3(3, 2.4, 2), Color(0.15, 0.1, 0.2))
				_abox(p + Vector3(0, 2.6, 0), Vector3(3.4, 0.3, 2.4), col, 2.5, false)
			2:  # Schreibtisch mit Lampe
				_abox(p + Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 1.2), Color(0.55, 0.45, 0.3))
				_abox(p + Vector3(0.7, 1.3, 0), Vector3(0.2, 0.6, 0.2), col, 3.0, false)
			3:  # Schultuer mit Glocke
				_abox(p + Vector3(0, 1.6, 0), Vector3(2.2, 3.2, 0.3), Color(0.6, 0.3, 0.2))
				_abox(p + Vector3(0, 3.6, 0), Vector3(0.6, 0.6, 0.6), Color(0.9, 0.75, 0.3), 1.0, false)
			4:  # Krankenbett
				_abox(p + Vector3(0, 0.45, 0), Vector3(1.2, 0.3, 2.4), Color(0.9, 0.95, 0.95))
				_abox(p + Vector3(0, 0.8, -1.1), Vector3(1.2, 0.4, 0.2), col, 0.8, false)
			5:  # Haustuer mit Licht im Fenster
				_abox(p + Vector3(0, 2.0, 0), Vector3(4, 4, 3), Color(0.92, 0.88, 0.8))
				_abox(p + Vector3(0, 2.4, -1.52), Vector3(1.0, 0.8, 0.05), Color(1.0, 0.8, 0.45), 3.0, false)
			6:  # U-Bahn-Schild
				_abox(p + Vector3(0, 1.5, 0), Vector3(0.2, 3.0, 0.2), Color(0.3, 0.3, 0.3))
				_abox(p + Vector3(0, 3.2, 0), Vector3(2.4, 0.6, 0.1), Color(0.95, 0.85, 0.2), 1.5, false)
			7:  # Krone im Gras
				for k in 6:
					var ka := k * TAU / 6.0
					_abox(p + Vector3(cos(ka) * 0.9, 0.4, sin(ka) * 0.9), Vector3(0.25, 0.8, 0.25), Color(1.0, 0.85, 0.3), 1.5, false)
		_sign(p + Vector3(0, 4.5, 0), spots[i][0], col)
		_add_mote(i, p + Vector3(2.5, 0, 2.5))
	# versteckte Lichter: weit draussen in den Ecken, hinter Baeumen
	var T: float = level.T
	var corners := [Vector3(6 * T, 0, 6 * T), Vector3((level.w - 6) * T, 0, 6 * T), Vector3(6 * T, 0, (level.h - 6) * T), Vector3((level.w - 6) * T, 0, (level.h - 6) * T)]
	for k in 4:
		_add_mote(8 + k, corners[k])
		for j in 5:
			var ta := j * TAU / 5.0
			var tr := _abox(corners[k] + Vector3(cos(ta) * 3.0, 1.5, sin(ta) * 3.0), Vector3(0.5, 3.0, 0.5), Color(0.4, 0.28, 0.18))
			_abox(tr.position + Vector3(0, 2.4, 0), Vector3(2.2, 2.0, 2.2), Color(0.25, 0.5, 0.2), 0.0, false)
	# Bank am Start, Erfolgs-Tafel
	_abox(c + Vector3(-4, 0.45, -3), Vector3(2.4, 0.15, 0.7), Color(0.55, 0.4, 0.25))
	_abox(c + Vector3(-4, 0.85, -3.3), Vector3(2.4, 0.6, 0.1), Color(0.55, 0.4, 0.25))
	_ach_board(c + Vector3(-8, 0, 0))
	if Game.has_completion_weapon():
		spawn_pickup("weapon", 10, c + Vector3(0, 0, -5))

func _ach_board(p: Vector3) -> void:
	_abox(p + Vector3(0, 2.0, 0), Vector3(0.3, 4.0, 6.0), Color(0.2, 0.16, 0.12))
	var txt := "ACHIEVEMENTS  %d / %d\n\n" % [Game.achievements.size(), Game.ACH.size()]
	for id in Game.ACH:
		txt += ("[x] " if Game.achievements.has(id) else "[ ] ") + Game.ACH[id][0] + "\n"
	var l := Label3D.new()
	l.text = txt
	l.font_size = 48
	l.pixel_size = 0.006
	l.modulate = Color(1, 0.95, 0.8)
	l.position = p + Vector3(0.2, 2.0, 0)
	l.rotation.y = PI / 2
	add_child(l)

func _add_mote(i: int, p: Vector3) -> void:
	if Game.found.has("mote_%d" % i):
		return
	var n := Node3D.new()
	n.position = p + Vector3(0, 1.2, 0)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	mi.mesh = sm
	mi.material_override = _mat(Color(1.0, 0.9, 0.6), 5.0)
	n.add_child(mi)
	var ol := OmniLight3D.new()
	ol.light_color = Color(1.0, 0.85, 0.55)
	ol.light_energy = 1.5
	ol.omni_range = 5.0
	n.add_child(ol)
	add_child(n)
	motes.append({"n": n, "i": i})

func _update_motes(delta: float) -> void:
	for m in motes.duplicate():
		m.n.position.y = 1.2 + sin(play_time * 2.0 + m.i) * 0.2
		if state == "play" and m.n.global_position.distance_to(player.global_position + Vector3(0, 1.0, 0)) < 1.8:
			motes.erase(m)
			burst(m.n.position, Color(1, 0.9, 0.6), 30)
			m.n.queue_free()
			Game.mark("mote_%d" % m.i)
			Game.sfx("swap", 1.5, 0.9)
			var n_found := 0
			for k in Game.found:
				if k.begins_with("mote_"): n_found += 1
			radio_queue.push_front(["LIGHT %d / %d" % [n_found, Game.MOTE_TOTAL], MOTE_LINES[m.i]])
			radio_t = 0.0

# ---------- Erfolge: kleine Meldung oben rechts ----------
var ach_layer: CanvasLayer
func _ach_toast(title: String, desc: String) -> void:
	if not is_inside_tree():
		return
	if ach_layer == null:
		ach_layer = CanvasLayer.new()
		ach_layer.layer = 20
		add_child(ach_layer)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.08, 0.85)
	sb.border_color = Color("#ffd23d")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = "ACHIEVEMENT UNLOCKED\n" + title + "\n" + desc
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	p.add_child(l)
	p.position = Vector2(get_viewport().get_visible_rect().size.x - 380, 20 + ach_layer.get_child_count() * 96)
	p.modulate.a = 0.0
	ach_layer.add_child(p)
	Game.sfx("rail", 1.6, 0.5)
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)

# ---------- Rueckblenden: kurze Erinnerungsfetzen (nach Boss, Kassette, manchmal einfach so) ----------
var flash_layer: CanvasLayer
var flash_cd := 0.0
func flashback(text: String = "") -> void:
	if flash_cd > 0.0 or not is_inside_tree():
		return
	flash_cd = 20.0
	if text == "":
		var pool: Array = ch.memories if not ch.memories.is_empty() else ["you were there", "remember"]
		text = pool[randi() % pool.size()]
	if flash_layer == null:
		flash_layer = CanvasLayer.new()
		flash_layer.layer = 6
		add_child(flash_layer)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(1, 0.96, 0.9, 0.0)
	flash_layer.add_child(r)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text = text
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color(0.25, 0.15, 0.1))
	l.modulate.a = 0.0
	flash_layer.add_child(l)
	glitch_t = 0.5
	Game.sfx("rail", 0.5, 0.6)
	var shot := "res://assets/sfx/%s.ogg" % ["amb_laugh", "amb_musicbox", "amb_phone"][randi() % 3]
	if ResourceLoader.exists(shot):
		var ap := AudioStreamPlayer.new()
		ap.stream = load(shot)
		ap.volume_db = -6.0
		add_child(ap)
		ap.finished.connect(ap.queue_free)
		ap.play()
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.85, 0.12)
	tw.tween_property(r, "color:a", 0.45, 0.6)
	tw.tween_interval(1.8)
	tw.tween_property(r, "color:a", 0.0, 1.2)
	tw.tween_callback(r.queue_free)
	var tl := l.create_tween()
	tl.tween_interval(0.2)
	tl.tween_property(l, "modulate:a", 1.0, 0.5)
	tl.tween_interval(1.7)
	tl.tween_property(l, "modulate:a", 0.0, 1.0)
	tl.tween_callback(l.queue_free)

# ---------- Erinnerungen: kurzer warmer Rueckblick ----------
var memory_rect: ColorRect
func _memory_moment() -> void:
	var prev: String = Game.current_track
	Game.play_music("memory")
	if memory_rect == null:
		var cl := CanvasLayer.new()
		cl.layer = 5
		add_child(cl)
		memory_rect = ColorRect.new()
		memory_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		memory_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		memory_rect.color = Color(1.0, 0.72, 0.4, 0.0)
		cl.add_child(memory_rect)
	var tw := create_tween()
	tw.tween_property(memory_rect, "color:a", 0.28, 1.2)
	slowmo(0.8, 0.3)
	say("mem_c%d" % chapter, func():
		var tw2 := create_tween()
		tw2.tween_property(memory_rect, "color:a", 0.0, 2.5)
		Game.play_music(prev))

# ---------- Atmosphaere: seltene Geraeusche irgendwo hinter dir ----------
var amb_shot_t := 30.0
const AMB_SHOTS := ["amb_laugh", "amb_phone", "amb_steps", "amb_musicbox", "amb_door", "amb_pa"]
func _update_amb_shots(delta: float) -> void:
	if state != "play" or chapter == 8:
		return
	amb_shot_t -= delta
	if amb_shot_t > 0.0:
		return
	amb_shot_t = randf_range(28.0, 60.0)
	var path := "res://assets/sfx/%s.ogg" % AMB_SHOTS[randi() % AMB_SHOTS.size()]
	if not ResourceLoader.exists(path):
		return
	var sp := AudioStreamPlayer3D.new()
	sp.stream = load(path)
	sp.unit_size = 10.0
	sp.volume_db = -4.0
	add_child(sp)
	var back: Vector3 = player.global_basis.z.rotated(Vector3.UP, randf_range(-0.9, 0.9))
	sp.global_position = player.global_position + back * randf_range(8.0, 16.0) + Vector3(0, 1.5, 0)
	sp.finished.connect(sp.queue_free)
	sp.play()

# Traenen / Wasser, das beim Aufwachen ueber das Bild laeuft
func _make_tears() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 14:
		var side := -1.0 if i % 2 == 0 else 1.0
		tears.append({"x": 0.5 + side * rng.randf_range(0.08, 0.3), "y": rng.randf_range(0.3, 0.45), "v": rng.randf_range(0.025, 0.07),
			"delay": rng.randf_range(1.0, 5.5), "w": rng.randf_range(3.0, 9.0), "wob": rng.randf() * 6.0})

# Story-ID fuer das aktuelle Kapitel (Kapitel 2+ haben eigene Texte mit Praefix)
func sid(id: String) -> String:
	var pre := "c%d_%s" % [chapter, id]
	if chapter > 1 and (Story.DIALOG.has(pre) or Story.RADIO.has(pre)):
		return pre
	return id

# Spielstand fortsetzen: Bereiche, die schon geschafft sind, ueberspringen
func _apply_progress(stage: int) -> void:
	var T: float = level.T
	seen["intro"] = true
	seen["intro_done"] = true
	title_t = 0.0
	shards = _shard_no() - (1 if chapter <= 6 or chapter >= 9 else 0)
	if stage >= 1:
		waves_left = 0
		seen["2"] = true
		level.open_doors("D")
		if not player.has_gun():
			player.give_weapon(0)
		for pk in pickups.duplicate():
			if pk.kind == "weapon" and pk.idx == 0:
				pickups.erase(pk); pk.n.queue_free()
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.position.x < door_cols[1] * T:
				e.queue_free()
		checkpoint = Vector3((door_cols[1] + 1.5) * T, 0, 14.5 * T)
		objective = ch.objectives[2]
	if stage >= 2:
		seen["3"] = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.position.x < gate_col * T:
				e.queue_free()
		if shard_node:
			shard_node.queue_free()
			shard_node = null
		shards = _shard_no()
		if chapter == 2:
			player.give_weapon(2)
		level.open_doors("G")
		checkpoint = Vector3((gate_col + 2.5) * T, 0, 14.5 * T)
		objective = ch.objectives[3]
	player.position = checkpoint + Vector3(0, 0.2, 0)
	if chapter == 1 and not player.has_gun():
		pass
	radio("death")

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "dash": [KEY_SHIFT], "shoot": [KEY_J], "interact": [KEY_E, KEY_ENTER],
		"menu": [KEY_M], "slide": [KEY_CTRL, KEY_C], "weapon1": [KEY_1], "weapon2": [KEY_2], "weapon3": [KEY_3], "ability": [KEY_Q], "reload": [KEY_R], "ult": [KEY_F],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shoot", m)
	if not InputMap.has_action("aim"):
		InputMap.add_action("aim")
	var mr := InputEventMouseButton.new()
	mr.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("aim", mr)

var dream_rect: ColorRect
var dream_mat: ShaderMaterial
var glitch_t := 0.0
var wake_t := 0.0
var wake_len := 7.0
var arrive_t := 0.0
var arrive_door: Node3D

func _make_door(pos: Vector3) -> void:
	arrive_door = Node3D.new()
	arrive_door.position = pos
	arrive_door.rotation.y = PI / 2.0
	add_child(arrive_door)
	var white := _mat(Color(1, 0.97, 0.9), 4.0)
	for part in [[Vector3(-0.9, 1.4, 0), Vector3(0.15, 2.8, 0.15)], [Vector3(0.9, 1.4, 0), Vector3(0.15, 2.8, 0.15)], [Vector3(0, 2.8, 0), Vector3(1.95, 0.15, 0.15)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		mi.mesh = bm
		mi.material_override = white
		mi.position = part[0]
		arrive_door.add_child(mi)

func _update_arrive(delta: float) -> void:
	arrive_t += delta
	player.yaw = -PI / 2.0
	player.pitch = lerpf(player.pitch, 0.0, delta * 3.0)
	if arrive_t < 2.6:
		player.global_position.x += delta * 1.6
		player.bob += delta * 9.0
	if arrive_door:
		for c in arrive_door.get_children():
			c.material_override.emission_energy_multiplier = maxf(0.0, 4.0 - arrive_t * 1.2)
	if arrive_t >= 3.2:
		state = "play"
		title_t = 6.0
		if arrive_door:
			arrive_door.queue_free()
			arrive_door = null

# Aufwachen: liegend, Blick nach oben ins Dachfenster, Augen blinzeln, langsam aufrichten
func _update_wake(delta: float) -> void:
	wake_t += delta
	var st := 3.0 if chapter == 1 else 1.2
	var k := clampf((wake_t - st) / (wake_len - st - 0.5), 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	player.head.position.y = lerpf(0.25, 1.6, e)
	player.pitch = lerpf(1.25, 0.0, e)
	player.cam.rotation.z = lerpf(0.5, 0.0, e) + sin(wake_t * 1.3) * 0.03 * (1.0 - e)
	player.gun.visible = wake_t > wake_len - 1.5 and player.has_gun()
	glitch_t = maxf(glitch_t, 0.35 * (1.0 - clampf(wake_t / 4.0, 0.0, 1.0)))
	if wake_t > 1.2 and wake_t < 1.3:
		Game.sfx("land", 0.5, 0.5)
	if wake_t >= wake_len:
		player.cam.rotation.z = 0.0
		state = "play"
		title_t = 6.0

func eyelid() -> float:
	# 0 = Augen zu, 1 = offen
	if state != "wake":
		return 1.0
	var t := wake_t
	if chapter > 1:
		return clampf((t - 0.5) / 1.0, 0.0, 1.0) if t < 1.6 or t > 2.0 else 0.4
	if t < 1.0: return 0.0
	if t < 1.6: return (t - 1.0) / 0.6 * 0.35
	if t < 2.0: return 0.35 - (t - 1.6) / 0.4 * 0.35
	if t < 2.6: return (t - 2.0) / 0.6 * 0.6
	if t < 2.9: return 0.6 - (t - 2.6) / 0.3 * 0.4
	return clampf(0.2 + (t - 2.9) / 1.2, 0.0, 1.0)
var dream_time := 0.0

func _setup_world() -> void:
	# Poolrooms: heller, leicht bewoelkter Nachmittagshimmel, weisser Dunst
	var sky_mat := ProceduralSkyMaterial.new()
	var ev: Dictionary = ch.env
	sky_mat.sky_top_color = ev.sky_top
	sky_mat.sky_horizon_color = ev.sky_hor
	sky_mat.ground_horizon_color = ev.sky_hor
	sky_mat.ground_bottom_color = ev.sky_top
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = ev.amb
	if ch.theme == "meadow":
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.9, 0.75)
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = ev.exp
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = ev.fog
	env.fog_density = ev.fog_d
	env.fog_sky_affect = 0.3
	env.adjustment_enabled = true
	env.adjustment_saturation = ev.sat
	world_env = env
	base_ambient = ev.amb
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = ev.sun
	sun.light_energy = ev.sun_e
	sun.rotation = ev.sun_rot
	sun.shadow_enabled = true
	add_child(sun)
	# niedrige Aufloesung fuer den Retro-Look (UI bleibt scharf)
	if Game.retro:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		get_viewport().scaling_3d_scale = 0.85
	# VHS-Filter ueber dem ganzen Bild
	var post := CanvasLayer.new()
	post.layer = 0
	add_child(post)
	dream_rect = ColorRect.new()
	dream_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dream_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_mat = ShaderMaterial.new()
	dream_mat.shader = load("res://scripts3d/dream.gdshader")
	dream_mat.set_shader_parameter("strength", 0.22 if Game.retro else 0.0)
	dream_rect.material = dream_mat
	dream_rect.visible = Game.retro
	post.add_child(dream_rect)

func _dust() -> void:
	# langsam schwebende Lichtpartikel rund um den Spieler
	var p := CPUParticles3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.5)
	m.emission_enabled = true
	m.emission = Color(1, 1, 0.95)
	m.emission_energy_multiplier = 1.0
	qm.material = m
	p.mesh = qm
	p.amount = 160
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 6, 16)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	p.gravity = Vector3(0, 0.03, 0)
	p.local_coords = false
	p.position = Vector3(0, 3, 0)
	player.add_child(p)

func can_control() -> bool:
	return state == "play"

func say(id: String, done: Callable = Callable()) -> void:
	state = "dialog"
	dialog.start(id, func():
		if state == "dialog":
			state = "play"
		if done.is_valid():
			done.call())

# Funk: laeuft nebenbei, das Spiel pausiert nicht
var radio_queue: Array = []
var radio_line: Array = []
var radio_t := 0.0
const Story = preload("res://scripts/story.gd")

var radio_voice: AudioStreamPlayer

func radio(id: String) -> void:
	var i := 0
	for l in Story.RADIO[id]:
		radio_queue.append([l[0], l[1], "res://assets/voice/radio_%s_%d.ogg" % [id, i]])
		i += 1

func _update_radio(delta: float) -> void:
	radio_t -= delta
	if radio_t <= 0.0:
		if radio_queue.is_empty():
			radio_line = []
		else:
			radio_line = radio_queue.pop_front()
			radio_t = 2.0 + radio_line[1].length() * 0.045
			# vertonter Funkspruch: Text bleibt stehen, bis die Stimme fertig ist
			if radio_voice == null:
				radio_voice = AudioStreamPlayer.new()
				add_child(radio_voice)
			if radio_line.size() > 2 and ResourceLoader.exists(radio_line[2]):
				var st: AudioStream = load(radio_line[2])
				radio_voice.stream = st
				radio_voice.play()
				radio_t = maxf(radio_t, st.get_length() + 0.4)

func banner(text: String, col: Color) -> void:
	banner_text = text
	banner_col = col
	banner_t = 2.5

func shake(t: float) -> void:
	shake_t = maxf(shake_t, t)

func _mat(col: Color, energy: float = 3.0) -> StandardMaterial3D:
	var key := col.to_html() + str(energy)
	if not mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color.BLACK
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		mats[key] = m
	return mats[key]

func spawn_enemy(kind: String, pos: Vector3) -> void:
	# crawler -> feindlicher Bewohner, drone -> Spezialgegner des Ortes
	var role: String = {"crawler": "hostile", "boss_minion": "hostile", "drone": "special"}.get(kind, "hostile")
	spawn_npc(role, pos)

func spawn_npc(role: String, pos: Vector3) -> Node:
	var e := Npc.new()
	e.setup(self, role)
	e.position = Vector3(pos.x, 0.1, pos.z)
	add_child(e)
	if role == "hostile" and boss and boss.active:
		e.awake = true
	return e

func _populate_ghosts() -> void:
	if ch.get("peaceful", false):
		_make_dog()
		if ch.get("afterworld", false):
			dog.position = checkpoint + Vector3(3, 0, 2)
			_build_afterworld()
		return
	# friedliche Geister, die einfach herumlaufen
	var cells: Array = level._floor_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = chapter * 77
	var n := 0
	var tries := 0
	while n < 10 and tries < 400:
		tries += 1
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var pos: Vector3 = level.cell_center(c)
		if pos.distance_to(checkpoint) < 9.0 or c.x >= gate_col:
			continue
		spawn_npc("passive", pos)
		n += 1
	# sitzende Figuren auf Stuehlen in den Seitenraeumen (Klassen, Bueros, Krankenzimmer, Zuhause)
	var seated := 0
	for st in level.seats:
		if seated >= 16 or rng.randf() > 0.45:
			continue
		var cs: Vector2i = level.cell_of(st.pos)
		if cs.x >= gate_col:
			continue
		var e = spawn_npc("passive", st.pos)
		e.sitting = true
		e.collision_layer = 0
		e.position = Vector3(st.pos.x, 0.0, st.pos.z)
		e.visual.rotation.y = st.yaw
		seated += 1

# ---------- Gefahrenzonen (Boss-Angriffe mit Vorwarnung) ----------
var hazards: Array = []

func add_hazard(kind: String, pos: Vector3, size: Vector2, delay: float, yaw: float = 0.0, col: Color = Color(1, 0.15, 0.2)) -> void:
	var mi := MeshInstance3D.new()
	if kind == "circle":
		var cm := CylinderMesh.new()
		cm.top_radius = size.x
		cm.bottom_radius = size.x
		cm.height = 0.04
		mi.mesh = cm
		mi.position = Vector3(pos.x, 0.14, pos.z)
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, 0.04, size.y)
		mi.mesh = bm
		mi.rotation.y = yaw
		mi.position = Vector3(pos.x, 0.14, pos.z) + Vector3(0, 0, -size.y / 2.0).rotated(Vector3.UP, yaw)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col, 0.25)
	mi.material_override = m
	add_child(mi)
	hazards.append({"n": mi, "kind": kind, "pos": pos, "size": size, "t": delay, "max": delay, "yaw": yaw, "col": col})

func _update_hazards(delta: float) -> void:
	for h in hazards:
		h.t -= delta
		var k: float = 1.0 - h.t / h.max
		h.n.material_override.albedo_color.a = 0.15 + 0.5 * k * (0.6 + 0.4 * sin(play_time * 30.0))
		if h.t <= 0.0:
			var pp: Vector3 = player.global_position
			var inside := false
			if h.kind == "circle":
				inside = Vector2(pp.x - h.pos.x, pp.z - h.pos.z).length() < h.size.x
			else:
				var local: Vector3 = (pp - h.pos).rotated(Vector3.UP, -h.yaw)
				inside = absf(local.x) < h.size.x / 2.0 and local.z < 0.0 and local.z > -h.size.y
			if inside and player.global_position.y < 1.2:
				player.hurt(1)
				player.external += Vector3(0, 6, 0)
			burst(h.n.global_position + Vector3(0, 0.3, 0), h.col.lightened(0.3), 20)
			shake(0.2)
			h.n.queue_free()
	hazards = hazards.filter(func(h): return h.t > 0.0)

func clear_hazards() -> void:
	for h in hazards:
		h.n.queue_free()
	hazards.clear()

# ---------- Licht-Effekte ----------
var world_env: Environment
var flicker_t := 0.0
var blackout_t := 0.0
var base_ambient := 0.3

func flicker(dur: float) -> void:
	flicker_t = maxf(flicker_t, dur)

func blackout(dur: float) -> void:
	blackout_t = maxf(blackout_t, dur)

func _update_lights(delta: float) -> void:
	flicker_t = maxf(0.0, flicker_t - delta)
	blackout_t = maxf(0.0, blackout_t - delta)
	var dark := blackout_t > 0.0 or (flicker_t > 0.0 and randf() < 0.6)
	world_env.ambient_light_energy = lerpf(world_env.ambient_light_energy, 0.02 if dark else base_ambient, minf(1.0, delta * 20.0))
	world_env.tonemap_exposure = lerpf(world_env.tonemap_exposure, 0.25 if dark else ch.env.exp, minf(1.0, delta * 20.0))

func spawn_proj(pos: Vector3, vel: Vector3, col: Color, homing: bool = false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = proj_mesh
	mi.material_override = _mat(col, 0.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	add_child(mi)
	if homing:
		mi.scale = Vector3.ONE * 1.6
	projs.append({"n": mi, "v": vel, "life": 6.0, "homing": homing, "r": 0.75})

# grosse Wurfgeschosse (Einkaufswagen, Papierstapel ...)
func spawn_object(mesh: Mesh, m: Material, pos: Vector3, vel: Vector3, r: float, spin: bool = true) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	if spin:
		mi.rotation.y = atan2(-vel.x, -vel.z)
	projs.append({"n": mi, "v": vel, "life": 5.0, "homing": false, "r": r})

func clear_projectiles() -> void:
	for p in projs:
		p.n.queue_free()
	projs.clear()

func player_shoot(origin: Vector3, dir: Vector3, muzzle: Vector3, wd: Dictionary) -> Vector3:
	var rng: float = wd.range
	var end := origin + dir * rng
	var exclude: Array[RID] = []
	var space := get_world_3d().direct_space_state
	# Durchschlagende Waffen treffen mehrere Gegner hintereinander
	for i in (8 if wd.pierce else 1):
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * rng, 1 | 4, exclude)
		var hit := space.intersect_ray(q)
		if not hit:
			break
		end = hit.position
		var c = hit.collider
		if c and c.has_method("hit"):
			# Kopftreffer: oberer Teil einer Figur (nicht bei Bossen)
			var crit: bool = wd.get("crit_always", false)
			if not c.is_in_group("boss") and c.is_in_group("npcs") and end.y - c.global_position.y > 1.42:
				crit = true
			var dmg: int = wd.dmg
			if crit:
				dmg = int(ceil(dmg * float(wd.get("crit", 2.0))))
			c.hit(dmg, dir)
			hit_feedback(end, dmg, crit)
			burst(end, Color.WHITE, 6)
			exclude.append(hit.rid)
			if not wd.pierce:
				break
		else:
			burst(end, wd.col, 5)
			break
	if wd.pierce:
		end = end if end.distance_to(origin) < rng - 0.1 else origin + dir * rng
	_tracer(muzzle, end, wd.col, 0.05 if wd.pierce else 0.012, 0.25 if wd.pierce else 0.06)
	return end

# ---------- Treffer-Rueckmeldung: Zahlen, Marker, Klick ----------
var noise := 0.0   # Laerm (nur gegen die Nachtschwester wichtig)
var killmark_t := 0.0
var tapes_found := 0
var crit_t := 0.0

func hit_feedback(pos: Vector3, dmg: int, crit: bool) -> void:
	hitmark_t = 0.15
	if player.ult_kind < 0:
		player.ult = minf(100.0, player.ult + dmg * 2.0)
	if crit:
		crit_t = 0.2
		Game.sfx("swap", 2.6, 0.55)
	else:
		Game.sfx("swap", 3.2, 0.18)
	var lab := Label3D.new()
	lab.text = str(dmg)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.font_size = 56 if crit else 40
	lab.outline_size = 10
	lab.modulate = Color("#ffd23d") if crit else Color.WHITE
	lab.pixel_size = 0.004
	add_child(lab)
	lab.global_position = pos + Vector3(randf_range(-0.2, 0.2), 0.2, randf_range(-0.2, 0.2))
	var tw := lab.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "global_position:y", lab.global_position.y + 0.9, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lab, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.chain().tween_callback(lab.queue_free)

# Patronenhuelsen fliegen aus der Waffe (rein optisch)
func spawn_casing(pos: Vector3, vel: Vector3, shell: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.025, 0.025, 0.06) if not shell else Vector3(0.04, 0.04, 0.09)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.65, 0.25) if not shell else Color(0.8, 0.15, 0.1)
	m.metallic = 0.9
	m.roughness = 0.3
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	gibs.append({"n": mi, "v": vel, "spin": Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20)), "life": 1.6})

# ---------- Geschosse der Spezialwaffen ----------
var pproj: Array = []

func _proj_mesh(col: Color, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(col, 2.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.2
	l.omni_range = 3.0
	mi.add_child(l)
	return mi

func spawn_bomb(pos: Vector3, vel: Vector3, wd: Dictionary) -> void:
	var mi := _proj_mesh(wd.col, Vector3(0.18, 0.18, 0.18))
	mi.global_position = pos
	pproj.append({"kind": "bomb", "n": mi, "v": vel, "life": 2.5, "wd": wd})

func spawn_knife(pos: Vector3, dir: Vector3, wd: Dictionary) -> void:
	var mi := _proj_mesh(wd.col, Vector3(0.05, 0.05, 0.4))
	mi.global_position = pos
	mi.look_at(pos + dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT)
	pproj.append({"kind": "knife", "n": mi, "v": dir.normalized() * 34.0, "life": 0.8, "wd": wd})

func spawn_disc(pos: Vector3, dir: Vector3, wd: Dictionary) -> void:
	var mi := _proj_mesh(wd.col, Vector3(0.45, 0.04, 0.45))
	mi.global_position = pos
	pproj.append({"kind": "disc", "n": mi, "v": dir.normalized() * 24.0, "life": 3.0, "wd": wd, "hits": [], "left": 5})

func _enemy_near(pos: Vector3, r: float, skip: Array = []):
	var best = null
	var bd := r
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or skip.has(e):
			continue
		var c: Vector3 = e.global_position + Vector3(0, 1.0, 0)
		var d := c.distance_to(pos)
		if d < bd:
			bd = d
			best = e
	return best

func _update_pproj(delta: float) -> void:
	for pr in pproj:
		pr.life -= delta
		var n: MeshInstance3D = pr.n
		if pr.kind == "bomb":
			pr.v.y -= 20.0 * delta
			var np: Vector3 = n.global_position + pr.v * delta
			n.rotation += Vector3(9, 7, 0) * delta
			var hit_e = _enemy_near(np, 1.1)
			if hit_e or level.solid(np) or np.y < 0.1 or pr.life <= 0.0:
				explode(n.global_position, 3.6, pr.wd.dmg, pr.wd.col)
				burst(n.global_position, Color(0.95, 0.95, 0.9), 50)
				pr.life = -1.0
			else:
				n.global_position = np
		elif pr.kind == "knife":
			var np: Vector3 = n.global_position + pr.v * delta
			var e = _enemy_near(np, 1.0)
			if e:
				var dmg: int = pr.wd.dmg * (3 if e.get("awake") == false else 1)
				e.hit(dmg, pr.v)
				hit_feedback(np, dmg, dmg > pr.wd.dmg)
				burst(np, Color.WHITE, 10)
				pr.life = -1.0
			elif level.solid(np):
				burst(n.global_position, Color(0.8, 0.8, 0.85), 6)
				Game.sfx("land", 2.5, 0.4)
				pr.life = -1.0
			else:
				n.global_position = np
		else:
			# Scheibe: sucht naechsten Gegner, prallt von Waenden ab
			n.rotation.y += delta * 30.0
			var tgt = _enemy_near(n.global_position, 14.0, pr.hits)
			if tgt and pr.hits.size() > 0:
				var to: Vector3 = (tgt.global_position + Vector3(0, 1.0, 0) - n.global_position).normalized()
				pr.v = pr.v.lerp(to * 26.0, minf(1.0, delta * 10.0))
			var np: Vector3 = n.global_position + pr.v * delta
			if level.solid(Vector3(np.x, 1, n.global_position.z)):
				pr.v.x = -pr.v.x
				np.x = n.global_position.x
				Game.sfx("land", 2.0, 0.3)
			if level.solid(Vector3(n.global_position.x, 1, np.z)):
				pr.v.z = -pr.v.z
				np.z = n.global_position.z
				Game.sfx("land", 2.0, 0.3)
			n.global_position = np
			var e = _enemy_near(np, 1.2, pr.hits)
			if e:
				pr.hits.append(e)
				e.hit(pr.wd.dmg, pr.v)
				hit_feedback(np, pr.wd.dmg, false)
				burst(np, pr.wd.col, 12)
				pr.left -= 1
				if pr.left <= 0:
					pr.life = -1.0
			if pr.life <= 0.0:
				burst(np, pr.wd.col, 10)
	for pr in pproj:
		if pr.life <= 0.0:
			pr.n.queue_free()
	pproj = pproj.filter(func(pr): return pr.life > 0.0)

# LULLABY: Strahl springt vom Treffer auf Gegner in der Naehe ueber
func chain_from(pos: Vector3, wd: Dictionary, n: int) -> void:
	var done: Array = []
	var from := pos
	for i in n:
		var e = _enemy_near(from, 6.0, done)
		if e == null:
			break
		done.append(e)
		var c: Vector3 = e.global_position + Vector3(0, 1.0, 0)
		if c.distance_to(pos) > 0.3:
			_tracer(from, c, wd.col, 0.02, 0.07)
			e.hit(wd.dmg, c - from)
			hit_feedback(c, wd.dmg, false)
		from = c

# Explosion (Railgun-Aufschlag, letzte Schrot-Patrone): Flaechenschaden + Wegschleudern
func explode(pos: Vector3, radius: float, dmg: int, col: Color) -> void:
	shake(0.3)
	burst(pos, col, 40)
	burst(pos, Color.WHITE, 12)
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	ball.mesh = sm
	ball.material_override = _mat(col, 3.0)
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ball)
	ball.global_position = pos
	var tw := create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE * radius * 2.0, 0.18)
	tw.tween_callback(ball.queue_free)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(pos) < radius + 0.6:
			e.hit(dmg, e.global_position - pos)

func overload(pos: Vector3) -> void:
	# Faehigkeit: Schockwelle um ECHO, schadet, schleudert weg, loescht Projektile
	shake(0.5)
	burst(pos + Vector3(0, 1, 0), Color("#c77dff"), 80)
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9
		tm.outer_radius = 1.0
		ring.mesh = tm
		ring.material_override = _mat(Color("#c77dff"), 3.0)
		ring.position = pos + Vector3(0, 0.4 + i * 0.5, 0)
		add_child(ring)
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector3.ONE * 9.0, 0.35 + i * 0.08)
		tw.tween_callback(ring.queue_free)
	clear_projectiles()
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(pos) < 9.0:
			e.hit(4, e.global_position - pos)

func _tracer(a: Vector3, b: Vector3, col: Color, thick: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len_ab := a.distance_to(b)
	bm.size = Vector3(thick, thick, len_ab)
	mi.mesh = bm
	mi.material_override = _mat(col, 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (a + b) / 2.0
	if len_ab > 0.01:
		mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	tracers.append({"n": mi, "life": life})

func burst(pos: Vector3, col: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radius = 0.06
	m.height = 0.12
	p.mesh = m
	p.material_override = _mat(col, 4.0)
	p.amount = n
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.6
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _make_shard(pos: Vector3) -> void:
	shard_node = Node3D.new()
	shard_node.position = pos + Vector3(0, 1.4, 0)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radial_segments = 4
	sm.rings = 2
	sm.radius = 0.35
	sm.height = 1.0
	mi.mesh = sm
	mi.material_override = _mat(Color("#c77dff"), 5.0)
	shard_node.add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = Color("#c77dff")
	light.light_energy = 2.0
	light.omni_range = 8.0
	shard_node.add_child(light)
	add_child(shard_node)

func _process(delta: float) -> void:
	if state == "play" or state == "dialog":
		play_time += delta
	banner_t = maxf(0.0, banner_t - delta)
	title_t = maxf(0.0, title_t - delta)
	shake_t = maxf(0.0, shake_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	hitmark_t = maxf(0.0, hitmark_t - delta)
	player.cam.h_offset = randf_range(-1, 1) * 0.12 * shake_t if shake_t > 0.0 else 0.0
	player.cam.v_offset = randf_range(-1, 1) * 0.12 * shake_t if shake_t > 0.0 else 0.0
	if Input.is_action_just_pressed("ui_cancel"):
		if state == "play":
			state = "paused"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif state == "paused":
			state = "play"
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if state == "end" and Input.is_action_just_pressed("interact"):
		_carry_weapons(mini(chapter + 1, Chapters.CHAPTERS.size()))
		Game.chapter = mini(chapter + 1, Chapters.CHAPTERS.size())
		Game.progress = 0
		Game.continue_game = false
		Game.write_save()
		get_tree().reload_current_scene()
		return
	if (state == "paused" or state == "end") and Input.is_action_just_pressed("menu"):
		Game.write_save()
		get_tree().change_scene_to_file("res://menu.tscn")
		return
	if state == "play" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if state == "wake":
		_update_wake(delta)
	if state == "arrive":
		_update_arrive(delta)
	if state == "play" and title_t > 0.0 and title_t < 4.5 and not seen.has("intro"):
		seen["intro"] = true
		say(sid("intro"), func(): radio("pickup_hint" if chapter == 1 else sid("controls")))
	_update_radio(delta)
	_update_pickups(delta)
	_update_gibs(delta)
	_update_pproj(delta)
	if state == "play":
		_update_secrets(delta)
		_update_dog(delta)
		_update_event(delta)
	killmark_t = maxf(0.0, killmark_t - delta)
	crit_t = maxf(0.0, crit_t - delta)
	_update_lights(delta)
	if state == "play":
		_update_hazards(delta)
	if state == "play":
		_update_health(delta)
		_update_exit(delta)
	if state == "transition":
		_update_transition(delta)
	dream_time += delta
	_update_amb_shots(delta)
	if not motes.is_empty():
		_update_motes(delta)
	flash_cd = maxf(0.0, flash_cd - delta)
	if state == "play" and not ch.get("peaceful", false) and randf() < delta / 240.0:
		flashback()
	if is_instance_valid(level) and level.is_inside_tree() and player.is_inside_tree():
		level.dream_update(delta, player.global_position, dream_time)
	# seltene kurze Traum-Stoerung (Glitch), staerker bei Erinnerungen
	glitch_t = maxf(0.0, glitch_t - delta)
	if randf() < delta * 0.03:
		glitch_t = 0.25
	dream_mat.set_shader_parameter("glitch", glitch_t * 2.0)
	if state == "dead" and Input.is_action_just_pressed("interact"):
		_respawn()
	if state == "play":
		_check_triggers()
		_check_doors()
		_check_shard()
		_update_projs(delta)
	for tr in tracers:
		tr.life -= delta
		if tr.life <= 0.0:
			tr.n.queue_free()
	tracers = tracers.filter(func(x): return x.life > 0.0)
	if shard_node:
		shard_node.rotation.y += delta * 1.5
		shard_node.position.y = 1.4 + sin(play_time * 3.0) * 0.15

func _update_projs(delta: float) -> void:
	var pc: Vector3 = player.center()
	for p in projs:
		if p.homing:
			var want: Vector3 = (pc - p.n.position).normalized() * p.v.length()
			p.v = p.v.lerp(want, minf(1.0, delta * 1.2))
		p.n.position += p.v * delta
		p.life -= delta
		var pos: Vector3 = p.n.position
		if p.life <= 0.0 or level.solid(pos) or pos.y < -0.2:
			p.life = -1.0
			continue
		if pos.distance_to(pc) < p.get("r", 0.75):
			player.hurt(1)
			p.life = -1.0
	for p in projs:
		if p.life < 0.0:
			p.n.queue_free()
	projs = projs.filter(func(p): return p.life >= 0.0)

func _check_triggers() -> void:
	var c: Vector2i = level.cell_of(player.global_position)
	if not level.triggers.has(c):
		return
	var id: String = level.triggers[c]
	if seen.has(id):
		return
	seen[id] = true
	match id:
		"2":
			radio(sid("scrap"))
			objective = ch.objectives[1]
		"3":
			radio(sid("drones"))
			objective = ch.objectives[2]
			start_event()
		"4":
			checkpoint = player.global_position
			radio(sid("gate"))
			objective = ch.objectives[4]
		"5":
			if boss:
				say(sid("boss"), func():
					Game.play_music("boss")
					boss.active = true
					banner(ch.boss.name, Color("#ff4d6d"))
					shake(0.5))

func _check_doors() -> void:
	var T: float = level.T
	if door_cols.size() < 2:
		return
	if not seen.has("intro_done") and seen.has("intro"):
		seen["intro_done"] = true
		level.open_doors("D", (door_cols[0] + 1) * T)
	if level.doors_of("D").is_empty():
		return
	var alive := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != boss and e.global_position.x < door_cols[1] * T and e.global_position.x > door_cols[0] * T:
			alive = true
	if not alive and player.global_position.x > door_cols[0] * T and waves_left > 0:
		# naechste Welle statt sofort offener Tuer
		waves_left -= 1
		_spawn_wave(3 - waves_left)
		return
	if not alive and player.global_position.x > door_cols[0] * T:
		level.open_doors("D", (door_cols[1] + 1) * T)
		banner("DOOR UNLOCKED", Color("#38f5c4"))
		Game.reach_stage(1)
		checkpoint = player.global_position

func _check_shard() -> void:
	if shard_node and shard_node.visible and player.global_position.distance_to(Vector3(shard_node.position.x, 0, shard_node.position.z)) < 1.6:
		burst(shard_node.position, Color("#c77dff"), 50)
		shard_node.queue_free()
		shard_node = null
		shards = _shard_no()
		checkpoint = player.global_position
		player.hp = player.max_hp
		glitch_t = 1.2
		Game.reach_stage(2)
		var spos: Vector3 = shard_node.position if shard_node else player.global_position
		say(sid("shard"), func():
			if chapter == 2 and not player.unlocked[2]:
				spawn_pickup("weapon", 2, player.global_position + Vector3(2.0, 0, 0))
			level.open_doors("G")
			objective = ch.objectives[3]
			banner("GATE OPEN", Color("#ffd23d")))

func on_player_hurt() -> void:
	shake(0.3)
	hurt_t = 0.6
	if player.hp <= 0:
		state = "dead"
		deaths += 1
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _respawn() -> void:
	player.global_position = checkpoint + Vector3(0, 0.2, 0)
	player.velocity = Vector3.ZERO
	player.hp = player.max_hp
	player.inv = 1.5
	clear_projectiles()
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if boss and is_instance_valid(boss) and boss.active:
		boss.hp = mini(boss.max_hp, boss.hp + 35)
		boss.mode = "idle"
		boss.position = boss.spawn_pos
		clear_hazards()
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss:
				e.queue_free()
	radio("death")

func on_enemy_killed(e) -> void:
	Game.total_kills += 1
	Game.unlock("first_blood")
	if Game.total_kills >= 100:
		Game.unlock("kills100")
	if player.ult_kind < 0:
		player.ult = minf(100.0, player.ult + 12.0)
	shake(0.18)
	# Superhot-Gefuehl: kurzer Zeitlupen-Moment, Kill-Marker, heller "Ping"
	slowmo(0.12, 0.2)
	killmark_t = 0.35
	Game.sfx("swap", 1.9, 0.6)
	burst(e.global_position + Vector3(0, 1.0, 0), Color(1, 1, 1), 24)
	burst(e.global_position + Vector3(0, 1.0, 0), Color(1, 0.2, 0.25), 14)
	if randf() < 0.35:
		_spawn_health(e.global_position)

# ---------- Treffer-Gefuehl ----------
var gibs: Array = []
var health_orbs: Array = []

func slowmo(dur: float, scale: float) -> void:
	Engine.time_scale = scale
	get_tree().create_timer(dur, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func hitstop(dur: float) -> void:
	Engine.time_scale = 0.05
	get_tree().create_timer(dur, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func gibs_from(visual: Node3D, dir: Vector3) -> void:
	# Einzelteile des Gegners fliegen auseinander und bleiben kurz liegen
	var meshes: Array = []
	_collect_meshes(visual, meshes)
	for m in meshes:
		var xf: Transform3D = m.global_transform
		m.get_parent().remove_child(m)
		add_child(m)
		m.global_transform = xf
		var v := Vector3(randf_range(-1, 1), randf_range(0.5, 1.5), randf_range(-1, 1)) * 5.0 + dir.normalized() * 6.0
		gibs.append({"n": m, "v": v, "spin": Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8)), "life": 2.5})

func _collect_meshes(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		_collect_meshes(c, out)

func _update_gibs(delta: float) -> void:
	for g in gibs:
		g.life -= delta
		var n: Node3D = g.n
		g.v.y -= 18.0 * delta
		n.position += g.v * delta
		if n.position.y < 0.08:
			n.position.y = 0.08
			g.v *= 0.5
			g.v.y = absf(g.v.y) * 0.3
			g.spin *= 0.6
		n.rotation += g.spin * delta
		if g.life < 0.5:
			n.scale = n.scale.lerp(Vector3.ZERO, delta * 8.0)
	for g in gibs:
		if g.life <= 0.0:
			g.n.queue_free()
	gibs = gibs.filter(func(g): return g.life > 0.0)

func _spawn_health(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	mi.mesh = sm
	mi.material_override = _mat(Color("#38f5c4"), 2.5)
	mi.position = Vector3(pos.x, 0.6, pos.z)
	add_child(mi)
	health_orbs.append(mi)

func _update_health(delta: float) -> void:
	for o in health_orbs.duplicate():
		o.position.y = 0.6 + sin(play_time * 4.0 + o.get_instance_id()) * 0.12
		var d: float = o.position.distance_to(player.center())
		if d < 6.0:
			o.position = o.position.move_toward(player.center(), delta * (14.0 - d * 1.5))
		if d < 1.0:
			health_orbs.erase(o)
			o.queue_free()
			if player.hp < player.max_hp:
				player.hp += 1
			Game.sfx("swap", 1.6, 0.6)

func on_boss_killed(b) -> void:
	burst(b.global_position, Color("#dfe9ec"), 150)
	burst(b.global_position, Color.WHITE, 80)
	shake(1.0)
	b.queue_free()
	boss = null
	clear_projectiles()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	Game.play_music(ch.music)
	Game.sfx("enemy_die", 0.5, 1.0)
	if Game.best_time <= 0.0 or play_time < Game.best_time:
		Game.best_time = play_time
	Game.reach_stage(3)
	Game.write_save()
	var drop_pos: Vector3 = b.global_position
	var drop := {1: ["weapon", 1], 2: ["ability", 0], 3: ["weapon", 4], 4: ["weapon", 5], 5: ["weapon", 8], 6: ["weapon", 7]}
	Game.unlock(ch.boss.kind)
	say(sid("victory"), func():
		state = "play"
		flashback()
		if drop.has(chapter):
			objective = "Pick up what %s dropped" % ch.boss.name
			radio("drop")
			spawn_pickup(drop[chapter][0], drop[chapter][1], Vector3(drop_pos.x, 0, drop_pos.z), func(): _open_exit())
			return
		_open_exit())

# ---------- Ausgang und Uebergang ins naechste Kapitel ----------
var exit_node: Node3D
var trans_t := 0.0
var trans_lines: Array = []

# Die drei Enden (nur im letzten Kapitel): eine Tuer pro Ende
const ENDINGS := {
	"wake": {"title": "ENDING I: WAKE UP", "col": Color(1, 0.97, 0.9), "label": "WAKE UP",
		"lines": ["You let the Crown go dark.", "One by one, the rooms switch off. The pool. The market. The school.", "Somewhere far below, a real sun comes up.", "You open your eyes. It hurts. It's supposed to."]},
	"forget": {"title": "ENDING II: FORGET", "col": Color(0.6, 0.85, 1.0), "label": "FORGET",
		"lines": ["You choose not to remember.", "HALCYON smiles and turns the lights back on.", "The water is very still.", "You wake up on cold tiles. You don't know why you're here."]},
	"stay": {"title": "ENDING III: STAY", "col": Color(1, 0.75, 0.55), "label": "STAY",
		"lines": ["You sit down next to her.", "Mira takes your hand. Nobody lets go this time.", "Outside the window it is always 4:40.", "For once, nobody is late."]},
}
var ending_doors: Array = []
var ending := ""

func _exit_door(pos: Vector3, col: Color, label: String) -> Node3D:
	var door := Node3D.new()
	door.position = pos
	add_child(door)
	var white := _mat(col, 4.0)
	for part in [[Vector3(-0.9, 1.4, 0), Vector3(0.15, 2.8, 0.15)], [Vector3(0.9, 1.4, 0), Vector3(0.15, 2.8, 0.15)], [Vector3(0, 2.8, 0), Vector3(1.95, 0.15, 0.15)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		mi.mesh = bm
		mi.material_override = white
		mi.position = part[0]
		door.add_child(mi)
	var glow := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.7, 2.7)
	glow.mesh = qm
	var gm := _mat(col.lerp(Color.WHITE, 0.3), 2.0)
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.material_override = gm
	glow.position.y = 1.4
	glow.rotation.y = PI / 2.0
	door.add_child(glow)
	door.rotation.y = PI / 2.0
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 3.0
	l.omni_range = 10.0
	l.position.y = 1.5
	door.add_child(l)
	if label != "":
		var lab := Label3D.new()
		lab.text = label
		lab.font_size = 64
		lab.modulate = col
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position.y = 3.5
		door.add_child(lab)
	return door

func _open_exit() -> void:
	var c: Vector2i = level.cell_of(boss_spawn)
	if chapter == 9:
		objective = "Choose"
		var ids := ["wake", "forget", "stay"]
		for i in 3:
			var cell := Vector2i(mini(c.x + 6, level.w - 3), c.y + (i - 1) * 6)
			var e: Dictionary = ENDINGS[ids[i]]
			var dn := _exit_door(level.cell_center(cell), e.col, e.label)
			ending_doors.append({"node": dn, "id": ids[i]})
		exit_node = ending_doors[0].node
		radio(sid("exit"))
		return
	objective = "Go through the door"
	exit_node = _exit_door(level.cell_center(Vector2i(mini(c.x + 6, level.w - 3), c.y)), Color(1, 0.97, 0.9), "")
	radio(sid("exit"))

func _update_exit(_delta: float) -> void:
	if not ending_doors.is_empty():
		for ed in ending_doors:
			if player.global_position.distance_to(ed.node.position) < 1.6:
				ending = ed.id
				Game.unlock("halcyon")
				for x in ending_doors:
					x.node.queue_free()
				ending_doors.clear()
				exit_node = null
				state = "transition"
				trans_t = 0.0
				trans_lines = ENDINGS[ending].lines
				Game.sfx("land", 0.3, 1.0)
				return
		return
	if exit_node and player.global_position.distance_to(exit_node.position) < 1.6:
		exit_node.queue_free()
		exit_node = null
		state = "transition"
		trans_t = 0.0
		trans_lines = ch.transition
		Game.sfx("land", 0.3, 1.0)

func _update_transition(delta: float) -> void:
	trans_t += delta
	glitch_t = 0.4 if trans_t < 1.5 else 0.0
	var total := 2.0 + trans_lines.size() * 2.6
	if trans_t >= total:
		if chapter < 9:
			_carry_weapons(chapter + 1)
			Game.chapter = chapter + 1
			Game.progress = 0
			Game.continue_game = false
			Game.write_save()
			get_tree().reload_current_scene()
		else:
			state = "end"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
