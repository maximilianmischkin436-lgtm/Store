extends CharacterBody3D
# Die vier Bosse. Jeder hat eigenes Aussehen und eigene Angriffe:
#  lifeguard  THE LIFEGUARD (Pool): Pfeifen-Schockwellen (springen!), Sprung auf dich, Sog, ruft Ertrunkene
#  mannequin  LOST & FOUND (Mall): bewegt sich nur, wenn du wegschaust, Einkaufswagen, Muenzregen, Kaeufer
#  mnemos     MNEMOS (Archiv): Stromausfall + Teleport, Papiersturm, Schubladen-Schlaege, vertauscht deine Steuerung
#  halcyon    HALCYON (Krone, Finale): Mutter-Gestalt mit Krone, nutzt die Angriffe aller vier Bosse
#  headmaster THE HEADMASTER (Schule): Nachsitz-Blick (Deckung suchen!), Kreide, Lineal-Schlag, Schulglocke

const Figure = preload("res://scripts3d/figure.gd")

var main
var cfg: Dictionary = {}
var kind := "lifeguard"
var spawn_pos := Vector3.ZERO
var max_hp := 160
var hp := 160
var active := false
var phase := 0
var t := 0.0
var flash := 0.0
var cd := 2.5
var mode := "idle"
var mode_t := 0.0
var pat := 0
var P := {}
var mats: Array = []
var visual: Node3D
var radius := 1.4
var walk_ph := 0.0
var jump_from := Vector3.ZERO
var jump_to := Vector3.ZERO
var gaze := 0.0
var beam: MeshInstance3D
var eye: MeshInstance3D
var drawers: Array = []
var tp_t := 0.0
var COL := Color("#0e2a44")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1
	kind = cfg.get("kind", "lifeguard")
	max_hp = cfg.get("hp", 160)
	hp = max_hp
	COL = cfg.get("proj", COL)
	spawn_pos = position
	visual = Node3D.new()
	add_child(visual)
	var cs := CollisionShape3D.new()
	if kind == "mnemos":
		var sh := SphereShape3D.new()
		sh.radius = 2.2
		cs.shape = sh
		position.y = 3.2
		spawn_pos = position
		_build_mnemos()
	else:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.9
		cap.height = 5.0
		cs.shape = cap
		cs.position.y = 2.5
		_build_giant()
	add_child(cs)

func _build_giant() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var o := Figure.outfit({"lifeguard": "lifeguard", "mannequin": "mannequin", "headmaster": "teacher", "halcyon": "shopper", "nurse": "nurse", "mirror": "worker", "conductor": "inspector"}[kind], rng)
	o.height = 2.6
	if kind == "lifeguard":
		o.width = 0.85
	if kind == "conductor":
		o.height = 3.0
		o.width = 1.1
	if kind == "nurse":
		o.height = 3.1
		o.width = 0.75
	if kind == "mirror":
		# sieht aus wie ECHO: dunkel, mit tuerkisem Leuchten, nur etwas groesser
		o.height = 1.6
		o.shirt = Color(0.08, 0.1, 0.12)
		o.pants = Color(0.05, 0.06, 0.08)
		o.extras = ["collar"]
	if kind == "halcyon":
		o.height = 3.2
		o.shirt = Color(0.96, 0.95, 0.98)
		o.pants = Color(0.92, 0.9, 0.95)
	if kind == "headmaster":
		o.height = 2.9
		o.shirt = Color(0.18, 0.16, 0.15)
		o.pants = Color(0.14, 0.13, 0.12)
	P = Figure.build(visual, o, 1.0, 0.0, true)
	mats = P.mats
	# alle zu lange Arme
	for sd in [-1, 1]:
		P["el%d" % sd].scale = Vector3(1, 1.6, 1)
	if kind == "halcyon":
		# Krone aus leuchtenden Erinnerungs-Splittern + langer Schleier
		var crown_m := Figure.mat(Color(1, 0.95, 0.8), 1.0, 0.2)
		crown_m.emission_enabled = true
		crown_m.emission = Color(1, 0.9, 0.7)
		crown_m.emission_energy_multiplier = 2.5
		for i in 9:
			var a := i * TAU / 9.0
			var sp := MeshInstance3D.new()
			sp.mesh = Figure.box(0.05, 0.28 + (i % 2) * 0.14, 0.05)
			sp.material_override = crown_m
			sp.position = Vector3(cos(a) * 0.15, 0.3, sin(a) * 0.15)
			sp.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
			P.head.add_child(sp)
		var veil := MeshInstance3D.new()
		veil.mesh = Figure.box(0.5, 1.4, 0.02)
		var vm := Figure.mat(Color(1, 1, 1), 0.35)
		veil.material_override = vm
		veil.position = Vector3(0, -0.5, 0.18)
		P.head.add_child(veil)
		var halo := OmniLight3D.new()
		halo.light_color = Color(1, 0.92, 0.8)
		halo.light_energy = 1.5
		halo.omni_range = 8.0
		P.head.add_child(halo)
	if kind == "nurse":
		# viel zu lange Arme, Spritze in der Hand
		for sd in [-1, 1]:
			P["el%d" % sd].scale = Vector3(1, 2.2, 1)
		var syr := MeshInstance3D.new()
		syr.mesh = Figure.box(0.06, 0.4, 0.06)
		syr.material_override = Figure.mat(Color(0.8, 0.95, 1.0), 0.7, 0.1)
		syr.position = Vector3(0, -0.6, 0)
		P.el1.add_child(syr)
	if kind == "mirror":
		for m in mats:
			m.emission = Color("#38f5c4")
		var glow := Figure.mat(Color("#38f5c4"), 1.0, 0.2)
		glow.emission_enabled = true
		glow.emission = Color("#38f5c4")
		glow.emission_energy_multiplier = 3.0
		for sd in [-1, 1]:
			var eye_m := MeshInstance3D.new()
			eye_m.mesh = Figure.box(0.04, 0.015, 0.01)
			eye_m.material_override = glow
			eye_m.position = Vector3(0.045 * sd, 0.03, -0.125)
			P.head.add_child(eye_m)
		var gun_m := MeshInstance3D.new()
		gun_m.mesh = Figure.box(0.08, 0.1, 0.5)
		gun_m.material_override = glow
		gun_m.position = Vector3(0, -0.5, -0.2)
		P.el1.add_child(gun_m)
	if kind == "headmaster" or kind == "halcyon":
		beam = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.06, 1.0)
		beam.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1, 0.05, 0.05, 0.0)
		beam.material_override = m
		main.add_child(beam)
	if kind == "mannequin":
		# Preisschilder und eine Krone aus verlorenen Dingen
		for i in 6:
			var tag := MeshInstance3D.new()
			tag.mesh = Figure.box(0.12, 0.08, 0.01)
			tag.material_override = Figure.mat(Color(1, 1, 0.95))
			tag.position = Vector3(randf_range(-0.2, 0.2), randf_range(0.1, 0.5), -0.16)
			tag.rotation.z = randf_range(-0.6, 0.6)
			P.spine.add_child(tag)

func _build_mnemos() -> void:
	# Turm aus Aktenschubladen um ein riesiges Auge
	var metal := Figure.mat(Color(0.55, 0.55, 0.5), 1.0, 0.35)
	metal.metallic = 0.7
	mats.append(metal)
	for ring in 3:
		var n := 7 + ring * 2
		for i in n:
			var a := i * TAU / n + ring * 0.4
			var d := MeshInstance3D.new()
			d.mesh = Figure.box(0.9, 0.55, 1.3)
			d.material_override = metal
			d.position = Vector3(cos(a), (ring - 1) * 1.1, sin(a)) * Vector3(2.2, 1.0, 2.2)
			d.rotation.y = -a
			visual.add_child(d)
			var handle := MeshInstance3D.new()
			handle.mesh = Figure.box(0.3, 0.06, 0.06)
			handle.material_override = Figure.mat(Color(0.2, 0.2, 0.2))
			handle.position = Vector3(0, 0, 0.66)
			d.add_child(handle)
			drawers.append(d)
	var ball := MeshInstance3D.new()
	ball.mesh = Figure.sph(1.3)
	ball.material_override = Figure.mat(Color(0.95, 0.93, 0.88), 1.0, 0.15)
	visual.add_child(ball)
	eye = MeshInstance3D.new()
	eye.mesh = Figure.sph(0.55)
	var em := Figure.mat(Color(0.05, 0.0, 0.0), 1.0, 0.1, 0.0)
	em.emission = Color("#ff2020")
	em.emission_energy_multiplier = 2.5
	eye.material_override = em
	eye.position = Vector3(0, 0, -1.0)
	visual.add_child(eye)
	for i in 10:
		var sheet := MeshInstance3D.new()
		sheet.mesh = Figure.box(0.4, 0.01, 0.55)
		sheet.material_override = Figure.mat(Color(0.95, 0.94, 0.88))
		sheet.position = Vector3(randf_range(-3, 3), randf_range(-2, 2), randf_range(-3, 3))
		visual.add_child(sheet)
		drawers.append(sheet)

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	for m in mats:
		m.emission_energy_multiplier = 1.5 if flash > 0.0 else (0.3 * (0.5 + 0.5 * sin(t * 8.0)) if phase >= 2 else 0.0)
	if kind == "mnemos":
		visual.rotation.y += delta * (0.2 + phase * 0.2)
		for i in drawers.size():
			drawers[i].position.y += sin(t * 2.0 + i) * delta * 0.2
	if not active or not main.can_control():
		return
	var p = main.player
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	var np := 2 if hp < max_hp * 0.34 else (1 if hp < max_hp * 0.67 else 0)
	if np > phase:
		phase = np
		mode = "idle"
		cd = 1.6
		main.shake(0.6)
		main.burst(global_position + Vector3(0, 2, 0), Color.WHITE, 60)
		main.banner(cfg.get("phase%d" % phase, "PHASE %d" % (phase + 1)), Color("#ff4d6d"))
		main.clear_projectiles()
		main.clear_hazards()
		if phase == 1:
			main.radio("halfway")
	if kind != "mnemos" and d < 1.8 and global_position.y < 1.5:
		p.hurt(1)
		p.external += to.normalized() * 8.0
	velocity = Vector3.ZERO
	match kind:
		"lifeguard": _lifeguard(delta, p, to, d)
		"mannequin": _mannequin(delta, p, to, d)
		"mnemos": _mnemos(delta, p, to, d)
		"headmaster": _headmaster(delta, p, to, d)
		"halcyon": _halcyon(delta, p, to, d)
		"nurse": _nurse(delta, p, to, d)
		"conductor": _conductor(delta, p, to, d)
		"mirror": _mirror(delta, p, to, d)
	if kind != "mnemos":
		velocity.y = 0.0 if mode != "jump" else velocity.y
	move_and_slide()

func _face(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 5.0))

func _walk(delta: float, dir: Vector3, spd: float) -> void:
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	walk_ph += delta * spd * 1.2
	Figure.walk(P, walk_ph, 1.0)

func _next(list: Array) -> String:
	var a: String = list[pat % list.size()]
	pat += 1
	return a

func _rate() -> float:
	return 1.0 - phase * 0.22

# ---------------- THE LIFEGUARD ----------------
func _lifeguard(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	match mode:
		"idle":
			_face(dir, delta)
			_walk(delta, dir, 2.4 + phase * 0.6)
			cd -= delta
			if cd <= 0.0:
				match _next(["whistle", "dive", "undertow", "whistle", "drowned"]):
					"whistle":
						Game.sfx("enemy_attack", 2.0, 1.0)
						P.sh1.rotation.x = -2.8
						_ring(16 + phase * 6, 8.0, 0.5)
						if phase >= 1:
							get_tree().create_timer(0.7).timeout.connect(func(): if active: _ring(14, 6.5, 0.5))
						cd = 2.2 * _rate()
					"dive":
						mode = "crouch"
						mode_t = 0.6
					"undertow":
						mode = "undertow"
						mode_t = 3.0
						main.banner("UNDERTOW", Color("#4db8ff"))
					"drowned":
						for i in 2 + phase:
							main.spawn_npc("hostile", global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
						cd = 1.5
		"crouch":
			mode_t -= delta
			P.hips.position.y = lerpf(P.hips.position.y, 0.6, delta * 8.0)
			if mode_t <= 0.0:
				jump_from = global_position
				jump_to = Vector3(p.global_position.x, 0, p.global_position.z)
				main.add_hazard("circle", jump_to, Vector2(4.0, 0), 1.0, 0.0, Color(0.3, 0.7, 1.0))
				mode = "jump"
				mode_t = 0.0
		"jump":
			mode_t += delta
			var k := clampf(mode_t / 1.0, 0.0, 1.0)
			global_position = jump_from.lerp(jump_to, k) + Vector3(0, sin(k * PI) * 9.0, 0)
			if k >= 1.0:
				global_position.y = 0.0
				main.shake(0.6)
				_ring(10, 7.0, 0.5)
				mode = "idle"
				cd = 1.4 * _rate()
		"undertow":
			mode_t -= delta
			_face(dir, delta)
			p.external += -dir * delta * 40.0
			if randf() < delta * 10.0:
				main.burst(p.global_position + Vector3(randf_range(-3, 3), 0.2, randf_range(-3, 3)), Color(0.6, 0.85, 1.0), 4)
			if mode_t <= 0.0:
				mode = "idle"
				cd = 1.0

# ---------------- LOST & FOUND ----------------
func _mannequin(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	var f: Vector3 = -p.cam.global_basis.z
	var to_me: Vector3 = (global_position + Vector3(0, 3, 0) - p.cam.global_position).normalized()
	var watched: bool = f.dot(to_me) > 0.75
	cd -= delta
	if not watched:
		# niemand schaut: schnell naeher kommen, Pose wechselt ruckartig
		_face(dir, delta * 4.0)
		_walk(delta, dir, 6.5 + phase * 2.0)
		if randf() < delta * 5.0:
			P.head.rotation = Vector3(randf_range(-0.5, 0.5), randf_range(-1, 1), randf_range(-0.5, 0.5))
	else:
		Figure.walk(P, walk_ph, 0.0)
	if cd <= 0.0:
		match _next(["carts", "sale", "carts", "lost"]):
			"carts":
				Game.sfx("land", 0.5, 1.0)
				var cart_m := Figure.mat(Color(0.75, 0.75, 0.78), 1.0, 0.3)
				cart_m.metallic = 0.8
				for s in ([-0.35, 0.0, 0.35] if phase == 0 else [-0.5, -0.25, 0.0, 0.25, 0.5]):
					var v: Vector3 = dir.rotated(Vector3.UP, s) * (11.0 + phase * 2.0)
					main.spawn_object(Figure.box(0.9, 0.9, 1.3), cart_m, global_position + Vector3(0, 0.5, 0) + dir * 2.0, v, 1.0)
				cd = 2.4 * _rate()
			"sale":
				main.banner("EVERYTHING MUST GO", Color("#ffd27a"))
				for i in 5 + phase * 2:
					var off := Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)) if i > 0 else Vector3.ZERO
					main.add_hazard("circle", p.global_position + off, Vector2(2.2, 0), 1.2 + i * 0.1, 0.0, Color(1, 0.8, 0.2))
				cd = 2.6 * _rate()
			"lost":
				main.banner("LOST CHILD, PLEASE COME TO THE INFO DESK", Color("#ff4fa3"))
				for i in 3 + phase:
					main.spawn_npc("hostile", global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)))
				cd = 3.0

# ---------------- MNEMOS ----------------
func _mnemos(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	if eye and global_position.distance_to(p.cam.global_position) > 0.5:
		visual.look_at(p.cam.global_position, Vector3.UP)
	match mode:
		"idle":
			var home: Vector3 = spawn_pos + Vector3(sin(t * 0.5) * 6.0, sin(t * 1.3) * 0.6, cos(t * 0.4) * 5.0)
			global_position = global_position.lerp(home, minf(1.0, delta))
			cd -= delta
			if cd <= 0.0:
				match _next(["papers", "slam", "blackout", "papers", "forget"]):
					"papers":
						mode = "papers"
						mode_t = 0.0
						pat += 0
						tp_t = 3
					"slam":
						for s in ([-0.5, 0.0, 0.5] if phase < 2 else [-0.9, -0.45, 0.0, 0.45, 0.9]):
							var yaw: float = atan2(-dir.x, -dir.z) + s
							main.add_hazard("line", Vector3(global_position.x, 0, global_position.z), Vector2(3.0, 34.0), 1.0, yaw, Color(0.9, 0.85, 0.6))
						cd = 2.0 * _rate()
					"blackout":
						main.blackout(5.0 + phase)
						main.banner("WHERE DID THE LIGHT GO?", Color("#ff2020"))
						mode = "dark"
						mode_t = 5.0 + phase
						tp_t = 0.0
					"forget":
						p.invert_t = 4.0
						main.banner("WHICH WAY IS LEFT?", Color("#ff2020"))
						main.glitch_t = 1.0
						cd = 2.0
		"papers":
			mode_t -= delta
			if mode_t <= 0.0:
				mode_t = 0.45
				tp_t -= 1
				var sheet_m := Figure.mat(Color(0.96, 0.95, 0.9))
				for i in 9:
					var a := (i - 4) * 0.13
					var aim: Vector3 = (p.center() - global_position).normalized().rotated(Vector3.UP, a)
					main.spawn_object(Figure.box(0.5, 0.02, 0.7), sheet_m, global_position + aim * 2.5, aim * 13.0, 0.7)
				if tp_t <= 0:
					mode = "idle"
					cd = 1.6 * _rate()
		"dark":
			mode_t -= delta
			tp_t -= delta
			if tp_t <= 0.0:
				tp_t = 1.3
				var a := randf() * TAU
				global_position = p.global_position + Vector3(cos(a) * 11.0, 3.5, sin(a) * 11.0)
				Game.sfx("enemy_hurt", 0.3, 0.6)
				main.spawn_proj(global_position, (p.center() - global_position).normalized() * 8.0, Color(0.9, 0.1, 0.1), true)
			if mode_t <= 0.0:
				mode = "idle"
				cd = 1.5

# ---------------- THE HEADMASTER ----------------
# Neu: Lineal-Rundumschlag (springen!), Papierflieger-Schwarm, Pop-Quiz (richtige Antwort-Flaeche finden),
# Flurausweis (verschwindet, taucht hinter dir auf), Nachsitzen (Tafeln als Deckung), Schulglocke (Geister)
const QUIZ := [
	["WHEN DOES SCHOOL END?", ["4:00", "4:40", "5:00", "NEVER"], 0],
	["WHO WAITED IN ROOM 2B?", ["NOBODY", "MIRA", "ECHO", "MOM"], 1],
	["HOW LATE WERE YOU?", ["1 MIN", "10 MIN", "40 MIN", "NOT LATE"], 2],
	["WHAT DID YOU PROTECT INSTEAD?", ["HER", "SERVER 7", "THE SCHOOL", "YOURSELF"], 1],
]
var ruler: MeshInstance3D
var ruler_ang := 0.0
var quiz_nodes: Array = []
var quiz_ok := Vector3.ZERO

func _headmaster(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	if mode != "hallpass":
		_face(dir, delta)
	var head_pos: Vector3 = global_position + Vector3(0, 4.7, 0)
	match mode:
		"idle":
			if d > 6.0:
				_walk(delta, dir, 1.8 + phase * 0.5)
			else:
				Figure.walk(P, walk_ph, 0.0)
			cd -= delta
			if cd <= 0.0:
				var lists := [["ruler", "planes", "quiz", "chalk"], ["ruler", "detention", "planes", "hallpass", "quiz"], ["ruler", "hallpass", "detention", "planes", "bell", "quiz", "ruler"]]
				match _next(lists[phase]):
					"detention":
						mode = "gaze"
						mode_t = 4.0
						gaze = 0.0
						_raise_boards(p, dir)
						main.banner("LOOK AT ME WHEN I'M TALKING TO YOU", Color("#ff3030"))
					"chalk":
						mode = "chalk"
						mode_t = 0.0
						tp_t = 3 + phase
					"ruler":
						main.banner("STAND UP STRAIGHT", Color("#ffcc33"))
						mode = "ruler_wind"
						mode_t = 0.8
						_make_ruler()
						ruler_ang = atan2(dir.x, dir.z) + PI * 0.5
					"planes":
						main.banner("PASS IT TO THE FRONT", Color("#f4f1e8"))
						for i in 5 + phase * 2:
							var a := (i - 3) * 0.35
							var v: Vector3 = (Vector3(dir.x, 0.35, dir.z).rotated(Vector3.UP, a)).normalized() * 7.0
							main.spawn_proj(head_pos, v, Color(0.97, 0.97, 0.94), true)
						cd = 2.2 * _rate()
					"quiz":
						_start_quiz(p)
					"hallpass":
						main.banner("WHERE IS YOUR HALL PASS?", Color("#ffcc33"))
						mode = "hallpass"
						mode_t = 1.2
						visual.visible = false
						main.burst(global_position + Vector3(0, 2.5, 0), Color(0.95, 0.95, 0.9), 50)
					"bell":
						Game.sfx("enemy_attack", 3.0, 1.0)
						main.banner("*RIIIIING*", Color("#ffcc33"))
						for i in 3 + phase:
							main.spawn_npc("hostile", global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
						cd = 2.5
		"ruler_wind":
			mode_t -= delta
			P.sh1.rotation.x = lerpf(P.sh1.rotation.x, -2.6, delta * 8.0)
			_place_ruler(0.9)
			if mode_t <= 0.0:
				mode = "ruler"
				mode_t = 2.6 - phase * 0.4
				Game.sfx("jump", 0.4, 1.0)
		"ruler":
			mode_t -= delta
			ruler_ang += delta * TAU / (2.6 - phase * 0.4)
			_place_ruler(0.35)
			# Treffer: Spieler am Boden und auf Hoehe des Lineals
			var rel: Vector3 = p.global_position - global_position
			rel.y = 0.0
			var pa: float = atan2(rel.x, rel.z)
			if rel.length() < 13.0 and absf(angle_difference(pa, ruler_ang)) < 0.14 and p.global_position.y < 0.7:
				p.hurt(1)
				p.external += Vector3(cos(ruler_ang), 0, -sin(ruler_ang)) * 10.0
			if mode_t <= 0.0:
				if ruler:
					ruler.queue_free()
					ruler = null
				mode = "idle"
				cd = 1.4 * _rate()
		"quiz":
			mode_t -= delta
			Figure.walk(P, walk_ph, 0.0)
			if mode_t <= 0.0:
				var pp: Vector3 = p.global_position
				pp.y = 0.0
				if pp.distance_to(quiz_ok) > 3.0:
					p.hurt(2)
					main.shake(0.6)
					main.banner("WRONG", Color("#ff3030"))
				else:
					main.banner("...CORRECT", Color("#7dffb0"))
				for n in quiz_nodes:
					main.burst(n.global_position + Vector3(0, 0.3, 0), Color(1, 0.3, 0.2) if n.global_position.distance_to(quiz_ok) > 0.5 else Color(0.5, 1, 0.6), 30)
					n.queue_free()
				quiz_nodes.clear()
				mode = "idle"
				cd = 1.2
		"hallpass":
			mode_t -= delta
			if mode_t <= 0.0:
				var back: Vector3 = p.global_basis.z
				var tp: Vector3 = p.global_position + Vector3(back.x, 0, back.z).normalized() * 4.5
				if main.level.solid(tp):
					tp = p.global_position - dir * 5.0
				global_position = Vector3(tp.x, 0, tp.z)
				visual.visible = true
				main.burst(global_position + Vector3(0, 2.5, 0), Color(0.95, 0.95, 0.9), 50)
				main.add_hazard("circle", Vector3(p.global_position.x, 0, p.global_position.z), Vector2(2.8, 0), 0.7, 0.0, Color(1, 0.8, 0.3))
				Game.sfx("enemy_hurt", 0.3, 1.0)
				mode = "idle"
				cd = 1.5 * _rate()
		"gaze":
			mode_t -= delta
			detention_cd = maxf(0.0, detention_cd - delta)
			Figure.walk(P, walk_ph, 0.0)
			var q := PhysicsRayQueryParameters3D.create(head_pos, p.cam.global_position, 1)
			var sees: bool = get_world_3d().direct_space_state.intersect_ray(q).is_empty()
			# Wegschauen (Blick senken) laedt den Blick nur langsam auf, Deckung stoppt ihn ganz
			var look: Vector3 = -p.cam.global_basis.z
			var facing: bool = look.dot((head_pos - p.cam.global_position).normalized()) > 0.3
			var rate: float = 1.0 if facing else 0.3
			if detention_cd > 0.0:
				sees = false
			gaze = minf(GAZE_MAX, gaze + delta * rate) if sees else maxf(0.0, gaze - delta * 2.5)
			beam.global_position = (head_pos + p.cam.global_position) / 2.0
			beam.scale.z = head_pos.distance_to(p.cam.global_position)
			beam.look_at(p.cam.global_position, Vector3.UP)
			beam.material_override.albedo_color.a = (gaze / GAZE_MAX) * 0.8 if sees else 0.05
			if gaze >= GAZE_MAX:
				gaze = 0.0
				detention_cd = 2.5   # danach kurz Ruhe, kein Dauer-Festhalten
				p.freeze(0.7)
				p.hurt(1)
				main.banner("DETENTION", Color("#ff3030"))
			if mode_t <= 0.0:
				beam.material_override.albedo_color.a = 0.0
				mode = "idle"
				cd = 1.6
				_lower_boards()
		"chalk":
			mode_t -= delta
			if mode_t <= 0.0:
				mode_t = 0.35
				tp_t -= 1
				for s in [-0.2, -0.1, 0.0, 0.1, 0.2]:
					var aim: Vector3 = (p.center() - head_pos).normalized().rotated(Vector3.UP, s)
					main.spawn_proj(head_pos, aim * 17.0, Color(0.95, 0.95, 0.92))
				if tp_t <= 0:
					mode = "idle"
					cd = 1.4 * _rate()


func _make_ruler() -> void:
	if ruler:
		ruler.queue_free()
	ruler = MeshInstance3D.new()
	ruler.mesh = Figure.box(0.5, 0.12, 13.0)
	var m := Figure.mat(Color(0.85, 0.65, 0.3), 1.0, 0.5)
	m.emission_enabled = true
	m.emission = Color(1, 0.6, 0.2)
	m.emission_energy_multiplier = 0.6
	ruler.material_override = m
	main.add_child(ruler)
	for k in 12:
		var tick := MeshInstance3D.new()
		tick.mesh = Figure.box(0.3, 0.13, 0.04)
		tick.material_override = Figure.mat(Color(0.2, 0.15, 0.1))
		tick.position = Vector3(-0.1, 0.0, -6.0 + k)
		ruler.add_child(tick)

func _place_ruler(h: float) -> void:
	if not ruler:
		return
	var d := Vector3(sin(ruler_ang), 0, cos(ruler_ang))
	ruler.global_position = global_position + d * 6.8 + Vector3(0, h, 0)
	ruler.rotation = Vector3(0, ruler_ang, 0)

func _start_quiz(p) -> void:
	var q: Array = QUIZ[randi() % QUIZ.size()]
	main.banner("POP QUIZ: " + q[0], Color("#ffcc33"))
	mode = "quiz"
	mode_t = 4.5 - phase * 0.5
	var center: Vector3 = p.global_position
	center.y = 0.0
	var cols := [Color(1, 0.4, 0.4), Color(0.4, 0.7, 1), Color(1, 0.85, 0.3), Color(0.5, 1, 0.6)]
	var start := randf() * TAU
	for i in 4:
		var a := start + i * TAU / 4.0
		var pos: Vector3 = center + Vector3(cos(a), 0, sin(a)) * 6.0
		for k in 6:
			if not main.level.solid(pos):
				break
			pos = pos.lerp(center, 0.3)
		var n := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 2.6
		cm.bottom_radius = 2.6
		cm.height = 0.05
		n.mesh = cm
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(cols[i], 0.4)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.emission_enabled = true
		mm.emission = cols[i]
		mm.emission_energy_multiplier = 1.2
		n.material_override = mm
		main.add_child(n)
		n.global_position = pos + Vector3(0, 0.04, 0)
		var lab := Label3D.new()
		lab.text = q[1][i]
		lab.font_size = 96
		lab.outline_size = 16
		lab.modulate = cols[i]
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position.y = 2.2
		n.add_child(lab)
		quiz_nodes.append(n)
		if i == q[2]:
			quiz_ok = n.global_position
			quiz_ok.y = 0.0

# ---------------- THE NIGHT NURSE ----------------
# Laerm lockt sie an (Schiessen/Dashen fuellt die Laerm-Anzeige), EKG-Linien im Herzschlag,
# Spritzen-Faecher, und ab Phase 2 "CODE BLUE": Licht aus, Patienten stehen auf.
var beats := 0
func _nurse(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	_face(dir, delta)
	main.noise = maxf(0.0, main.noise - delta * 0.12)
	if main.noise >= 1.0 and mode == "idle":
		main.noise = 0.0
		main.banner("SHHHHHHH", Color("#7dffd0"))
		Game.sfx("enemy_hurt", 0.4, 1.0)
		var back: Vector3 = p.global_basis.z
		var tp: Vector3 = p.global_position + Vector3(back.x, 0, back.z).normalized() * 3.5
		if not main.level.solid(tp):
			global_position = Vector3(tp.x, 0, tp.z)
		main.burst(global_position + Vector3(0, 2, 0), Color(0.8, 1, 0.95), 40)
		main.add_hazard("circle", Vector3(p.global_position.x, 0, p.global_position.z), Vector2(3.0, 0), 0.6, 0.0, Color(0.4, 1, 0.8))
		cd = 1.4
		return
	match mode:
		"idle":
			if d > 5.0:
				_walk(delta, dir, 1.5 + phase * 0.6)
			else:
				Figure.walk(P, walk_ph, 0.0)
			cd -= delta
			if cd <= 0.0:
				var lists := [["ecg", "syringes", "ecg", "syringes"], ["ecg", "syringes", "codeblue", "ecg"], ["ecg", "syringes", "codeblue", "ecg", "syringes"]]
				match _next(lists[phase]):
					"ecg":
						main.banner("BEEP... BEEP...", Color("#7dffd0"))
						mode = "ecg"
						mode_t = 0.0
						beats = 4 + phase * 2
					"syringes":
						mode = "syringes"
						mode_t = 0.0
						tp_t = 3 + phase
					"codeblue":
						main.banner("CODE BLUE", Color("#ff3030"))
						main.blackout(3.0 + phase)
						for i in 2 + phase:
							main.spawn_npc("hostile", global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
						cd = 2.5
		"ecg":
			# EKG: im Herzschlag schlagen Linien quer durch den Raum ein, abwechselnd laengs und quer
			mode_t -= delta
			if mode_t <= 0.0:
				mode_t = 0.55 - phase * 0.08
				beats -= 1
				Game.sfx("swap", 2.8, 0.7)
				var yaw: float = atan2(-dir.x, -dir.z) + (PI / 2.0 if beats % 2 == 0 else 0.0)
				main.add_hazard("line", Vector3(p.global_position.x, 0, p.global_position.z), Vector2(2.2, 34.0), 0.6, yaw, Color(0.3, 1.0, 0.6))
				if beats <= 0:
					mode = "idle"
					cd = 1.6 * _rate()
		"syringes":
			mode_t -= delta
			if mode_t <= 0.0:
				mode_t = 0.4
				tp_t -= 1
				var hp_: Vector3 = global_position + Vector3(0, 3.8, 0)
				for s_ in [-0.24, -0.12, 0.0, 0.12, 0.24]:
					var aim: Vector3 = (p.center() - hp_).normalized().rotated(Vector3.UP, s_)
					main.spawn_proj(hp_, aim * 19.0, Color(0.8, 0.95, 1.0))
				if tp_t <= 0:
					mode = "idle"
					cd = 1.3 * _rate()

# ---------------- THE CONDUCTOR ----------------
# Zuege rasen durch Fahrspuren (rote Spur = gleich kommt einer), zielsuchende Fahrkarten,
# "MIND THE GAP": Loecher oeffnen sich unter dir, "DOORS CLOSING": zwei Waende schliessen von den Seiten,
# ab Phase 2 Expresszuege in mehreren Spuren mit nur einer Luecke.
var trains: Array = []
func _conductor(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	_face(dir, delta)
	_update_trains(delta, p)
	match mode:
		"idle":
			if d > 7.0:
				_walk(delta, dir, 2.0 + phase * 0.6)
			else:
				Figure.walk(P, walk_ph, 0.0)
			cd -= delta
			if cd <= 0.0:
				var lists := [["train", "tickets", "gap", "train"], ["train", "doors", "tickets", "gap", "express"], ["express", "tickets", "doors", "gap", "train", "passengers"]]
				match _next(lists[phase]):
					"train":
						main.banner("TRAIN APPROACHING", Color("#ffd23d"))
						_send_train(p.global_position, randf() < 0.5, 0.9)
						cd = 1.4 * _rate()
					"express":
						main.banner("EXPRESS - DOES NOT STOP", Color("#ff4d6d"))
						var horizontal := randf() < 0.5
						var safe := randi() % 4
						for k in 4:
							if k == safe:
								continue
							var off := Vector3((k - 1.5) * 4.0, 0, 0) if not horizontal else Vector3(0, 0, (k - 1.5) * 4.0)
							_send_train(p.global_position + off, horizontal, 1.1)
						cd = 2.2 * _rate()
					"tickets":
						mode = "tickets"
						mode_t = 0.0
						tp_t = 4 + phase * 2
					"gap":
						main.banner("MIND THE GAP", Color("#ffd23d"))
						for k in 5 + phase * 2:
							var off := Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)) if k > 0 else Vector3.ZERO
							main.add_hazard("circle", Vector3(p.global_position.x, 0, p.global_position.z) + off, Vector2(1.8, 0), 0.8 + k * 0.25, 0.0, Color(0.1, 0.1, 0.1))
						cd = 2.0 * _rate()
					"doors":
						main.banner("DOORS CLOSING", Color("#ff4d6d"))
						for sd in [-1.0, 1.0]:
							var yaw: float = atan2(-dir.x, -dir.z) + PI / 2.0
							var side: Vector3 = dir.cross(Vector3.UP) * sd * 3.2
							main.add_hazard("line", Vector3(p.global_position.x, 0, p.global_position.z) + side, Vector2(3.2, 30.0), 1.0, yaw - PI / 2.0, Color(1, 0.4, 0.2))
						cd = 1.8 * _rate()
					"passengers":
						main.banner("PLEASE BOARD THE TRAIN", Color("#ffd23d"))
						for i in 3 + phase:
							main.spawn_npc("hostile", global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))).awake = true
						cd = 2.5
		"tickets":
			mode_t -= delta
			if mode_t <= 0.0:
				mode_t = 0.3
				tp_t -= 1
				var src: Vector3 = global_position + Vector3(0, 3.5, 0)
				var v: Vector3 = (p.center() - src).normalized().rotated(Vector3.UP, randf_range(-0.6, 0.6)) * 8.0
				main.spawn_proj(src, v, Color(1, 0.85, 0.2), true)
				Game.sfx("swap", 2.2, 0.5)
				if tp_t <= 0:
					mode = "idle"
					cd = 1.2 * _rate()

# Ein Zug: rote Spur als Warnung, dann rast ein Wagen durch die Spur
func _send_train(at: Vector3, horizontal: bool, warn: float) -> void:
	var yaw := PI / 2.0 if horizontal else 0.0
	var lane := Vector3(at.x, 0, at.z)
	main.add_hazard("line", lane, Vector2(3.0, 80.0), warn, yaw, Color(1, 0.85, 0.2))
	var car := MeshInstance3D.new()
	car.mesh = Figure.box(2.8, 3.0, 12.0)
	var cm := Figure.mat(Color(0.75, 0.78, 0.82), 1.0, 0.3)
	cm.emission_enabled = true
	cm.emission = Color(1, 0.9, 0.6)
	cm.emission_energy_multiplier = 0.4
	car.material_override = cm
	car.visible = false
	main.add_child(car)
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	trains.append({"n": car, "from": lane - fwd * 45.0, "to": lane + fwd * 45.0, "t": -warn, "yaw": yaw})
	Game.sfx("enemy_attack", 0.4, 0.6)

func _update_trains(delta: float, p) -> void:
	for tr in trains:
		tr.t += delta
		var n: MeshInstance3D = tr.n
		if tr.t < 0.0:
			continue
		n.visible = true
		var k: float = tr.t / 0.7
		n.global_position = tr.from.lerp(tr.to, k) + Vector3(0, 1.5, 0)
		n.rotation.y = tr.yaw
		if k > 0.0 and k < 1.0 and int(tr.t * 30.0) % 4 == 0:
			main.shake(0.15)
	for tr in trains:
		if tr.t > 0.7:
			tr.n.queue_free()
	trains = trains.filter(func(x): return x.t <= 0.7)

# ---------------- ECHO (das Spiegelbild) ----------------
# Kaempft wie du: kreist um dich, Dash-Schnitt, Pulse-Salven, Schrot aus der Naehe,
# Katana-Wirbel, und ab Phase 2 Zeitsprung zurueck und Schattenkopien.
var history: Array = []
var circle_dir := 1.0
func _mirror(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	_face(dir, delta * 2.0)
	history.append(global_position)
	if history.size() > 180:
		history.pop_front()
	match mode:
		"idle":
			# seitlich um den Spieler kreisen, Abstand halten
			var side := dir.cross(Vector3.UP) * circle_dir
			var want := side * 5.0 + dir * (d - 8.0) * 0.8
			velocity.x = want.x
			velocity.z = want.z
			walk_ph += delta * 8.0
			Figure.walk(P, walk_ph, 1.0)
			if randf() < delta * 0.4:
				circle_dir = -circle_dir
			cd -= delta
			if cd <= 0.0:
				var lists := [["pulse", "dash", "pulse", "scatter"], ["dash", "pulse", "katana", "rewind", "scatter"], ["dash", "pulse", "shadows", "katana", "rewind", "dash"]]
				var a := _next(lists[phase])
				if a == "scatter" and d > 9.0:
					a = "dash"
				match a:
					"pulse":
						mode = "pulse"
						mode_t = 0.0
						tp_t = 10 + phase * 4
					"scatter":
						Game.sfx("scatter", 0.8, 1.0)
						for i in 9:
							var aim: Vector3 = (p.center() - global_position - Vector3(0, 1.2, 0)).normalized().rotated(Vector3.UP, randf_range(-0.3, 0.3))
							main.spawn_proj(global_position + Vector3(0, 1.2, 0), aim * 22.0, Color("#ff9f3d"))
						cd = 1.0 * _rate()
					"dash":
						mode = "dash_wind"
						mode_t = 0.45
						jump_to = Vector3(p.global_position.x, 0, p.global_position.z) + dir * 3.0
						var yaw: float = atan2(-dir.x, -dir.z)
						main.add_hazard("line", (global_position + jump_to) / 2.0, Vector2(1.8, global_position.distance_to(jump_to) + 2.0), 0.45, yaw, Color("#38f5c4"))
					"katana":
						main.banner("TOO SLOW", Color("#38f5c4"))
						_ring(18 + phase * 4, 9.0, 0.5)
						Game.sfx("jump", 2.4, 1.0)
						cd = 1.2 * _rate()
					"rewind":
						if history.size() > 10:
							main.burst(global_position + Vector3(0, 1, 0), Color("#38f5c4"), 40)
							global_position = history[0]
							main.burst(global_position + Vector3(0, 1, 0), Color("#38f5c4"), 40)
							main.glitch_t = 0.6
							Game.sfx("swap", 0.5, 1.0)
						cd = 0.6
					"shadows":
						main.banner("WE WERE ALL LATE", Color("#ff4d6d"))
						for i in 3:
							main.spawn_npc("hostile", global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
						cd = 2.0
		"pulse":
			mode_t -= delta
			Figure.walk(P, walk_ph, 0.0)
			if mode_t <= 0.0:
				mode_t = 0.09
				tp_t -= 1
				var src: Vector3 = global_position + Vector3(0, 1.2, 0)
				var aim: Vector3 = (p.center() - src).normalized().rotated(Vector3.UP, randf_range(-0.05, 0.05))
				main.spawn_proj(src, aim * 26.0, Color("#38f5c4"))
				if int(tp_t) % 3 == 0:
					Game.sfx("pulse", 1.1, 0.4)
				if tp_t <= 0:
					mode = "idle"
					cd = 1.0 * _rate()
		"dash_wind":
			mode_t -= delta
			if mode_t <= 0.0:
				mode = "dash"
				mode_t = 0.25
				Game.sfx("jump", 1.5, 1.0)
		"dash":
			mode_t -= delta
			var dd: Vector3 = jump_to - global_position
			dd.y = 0.0
			velocity = dd.normalized() * 34.0 if dd.length() > 0.5 else Vector3.ZERO
			if (p.global_position - global_position).length() < 1.6:
				p.hurt(1)
			if mode_t <= 0.0 or dd.length() < 0.5:
				mode = "idle"
				cd = 0.9 * _rate()

# ---------------- HALCYON ----------------
# Benutzt die Angriffe der anderen: Pfeife (springen), Sprung, Ausverkauf-Kreise, Akten-Schlaege,
# Vergessen (Steuerung vertauscht), Nachsitz-Blick (Tafeln), Kreide, und ruft Geister aller Orte.
func _halcyon(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	if mode in ["gaze", "chalk"]:
		_headmaster(delta, p, to, d)
		return
	if mode in ["crouch", "jump", "undertow"]:
		_lifeguard(delta, p, to, d)
		return
	_face(dir, delta)
	if d > 7.0:
		_walk(delta, dir, 2.2 + phase * 0.8)
	else:
		Figure.walk(P, walk_ph, 0.0)
	# schwebt leicht, Schleier weht
	visual.position.y = 0.25 + sin(t * 1.5) * 0.15
	cd -= delta
	if cd > 0.0:
		return
	var lists := [
		["whistle", "sale", "chalk", "dive", "whistle", "ghosts"],
		["slam", "detention", "whistle", "forget", "sale", "dive", "ghosts"],
		["whistle", "slam", "detention", "undertow", "chalk", "forget", "sale", "ghosts"],
	]
	match _next(lists[phase]):
		"whistle":
			Game.sfx("enemy_attack", 2.0, 1.0)
			P.sh1.rotation.x = -2.8
			_ring(16 + phase * 6, 8.0, 0.5)
			if phase >= 1:
				get_tree().create_timer(0.7).timeout.connect(func(): if active: _ring(14, 6.5, 0.5))
			cd = 2.0 * _rate()
		"dive":
			mode = "crouch"
			mode_t = 0.6
		"undertow":
			mode = "undertow"
			mode_t = 2.5
			main.banner("DON'T GO", Color("#4db8ff"))
		"sale":
			main.banner("EVERYTHING YOU LOST", Color("#ffd27a"))
			for i in 5 + phase * 2:
				var off := Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)) if i > 0 else Vector3.ZERO
				main.add_hazard("circle", p.global_position + off, Vector2(2.2, 0), 1.2 + i * 0.1, 0.0, Color(1, 0.8, 0.2))
			cd = 2.4 * _rate()
		"slam":
			for s in ([-0.5, 0.0, 0.5] if phase < 2 else [-0.9, -0.45, 0.0, 0.45, 0.9]):
				var yaw: float = atan2(-dir.x, -dir.z) + s
				main.add_hazard("line", Vector3(global_position.x, 0, global_position.z), Vector2(3.0, 34.0), 1.0, yaw, Color(0.9, 0.85, 0.6))
			cd = 2.0 * _rate()
		"forget":
			p.invert_t = 3.0
			main.banner("FORGET, SWEETHEART", Color("#ffffff"))
			main.glitch_t = 1.0
			cd = 1.8
		"detention":
			mode = "gaze"
			mode_t = 3.5
			gaze = 0.0
			_raise_boards(p, dir)
			main.banner("LOOK AT ME", Color("#ff3030"))
		"chalk":
			mode = "chalk"
			mode_t = 0.0
			tp_t = 3 + phase
		"ghosts":
			main.banner("EVERYONE IS HERE, ECHO", Color("#9fd8ff"))
			for i in 2 + phase:
				main.spawn_npc("hostile", global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
			cd = 2.5

# Nachsitzen: Tafeln fahren aus dem Boden hoch, hinter denen man sich verstecken kann
const GAZE_MAX := 1.8
var detention_cd := 0.0
var boards: Array = []

func _raise_boards(p, dir: Vector3) -> void:
	_lower_boards()
	var side := dir.cross(Vector3.UP).normalized()
	var base: Vector3 = p.global_position - dir * 2.5
	for o in [-4.0, 0.0, 4.0]:
		var pos: Vector3 = base + side * o + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		if main.level.solid(pos):
			continue
		var b := StaticBody3D.new()
		b.collision_layer = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(2.6, 3.2, 0.25)
		cs.shape = sh
		cs.position.y = 1.6
		b.add_child(cs)
		var board := MeshInstance3D.new()
		board.mesh = Figure.box(2.6, 1.9, 0.12)
		board.material_override = Figure.mat(Color(0.1, 0.22, 0.16), 1.0, 0.8)
		board.position.y = 2.1
		b.add_child(board)
		var frame := MeshInstance3D.new()
		frame.mesh = Figure.box(2.75, 3.2, 0.08)
		frame.material_override = Figure.mat(Color(0.45, 0.3, 0.18), 1.0, 0.6)
		frame.position = Vector3(0, 1.6, 0.06)
		b.add_child(frame)
		var lab := Label3D.new()
		lab.text = ["I WILL NOT BE LATE", "STAY AFTER CLASS", "PAY ATTENTION"][randi() % 3]
		lab.modulate = Color(0.95, 0.95, 0.9, 0.8)
		lab.font_size = 40
		lab.position = Vector3(0, 2.3, -0.07)
		lab.rotation.y = PI
		b.add_child(lab)
		main.add_child(b)
		b.global_position = pos - Vector3(0, 3.3, 0)
		b.look_at(b.global_position + dir, Vector3.UP)
		var tw := b.create_tween()
		tw.tween_property(b, "global_position:y", 0.0, 0.45).set_trans(Tween.TRANS_BACK)
		boards.append(b)
	Game.sfx("land", 0.4, 0.9)

func _lower_boards() -> void:
	for b in boards:
		if is_instance_valid(b):
			var tw: Tween = b.create_tween()
			tw.tween_property(b, "global_position:y", -3.4, 0.5)
			tw.tween_callback(b.queue_free)
	boards.clear()

# Ring aus Kugeln knapp ueber dem Boden (man muss springen)
func _ring(n: int, sp: float, y: float) -> void:
	var off := randf() * TAU
	var base := Vector3(global_position.x, y, global_position.z)
	for i in n:
		var a := off + i * TAU / n
		var dd := Vector3(cos(a), 0, sin(a))
		main.spawn_proj(base + dd * 1.5, dd * sp, COL.lightened(0.2))

func hit(dmg: int, _dir: Vector3) -> void:
	if not active:
		return
	hp -= dmg
	flash = 0.06
	if randf() < 0.3:
		Game.sfx("enemy_hurt", 0.5, 0.5)
	if hp <= 0:
		if beam:
			beam.queue_free()
			_lower_boards()
		if ruler:
			ruler.queue_free()
		for tr in trains:
			if is_instance_valid(tr.n):
				tr.n.queue_free()
		trains.clear()
		for n in quiz_nodes:
			n.queue_free()
		main.blackout_t = 0.0
		main.player.invert_t = 0.0
		main.clear_hazards()
		main.on_boss_killed(self)
