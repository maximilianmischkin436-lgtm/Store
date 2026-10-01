extends CharacterBody3D
# Bewohner der Erinnerungsorte.
#  role "passive": Geist, geht herum und ignoriert dich. Schiesst du auf ihn, wird er feindlich.
#  role "hostile": sieht fast gleich aus (Kopf schief, dunkle Augenhoehlen). Rennt los, wenn du nah bist.
#  role "special": eigene Mechanik je Ort:
#     pool   LIFEGUARD  - pfeift, dann werden alle Schwimmer in der Naehe feindlich
#     mall   MANNEQUIN  - bewegt sich nur, wenn du nicht hinschaust
#     office MANAGER    - Licht flackert, er steht ploetzlich hinter dir
#     school TEACHER    - wirft Kreide, sein Blick gibt dir "Nachsitzen" (du erstarrst)

const Figure = preload("res://scripts3d/figure.gd")
const KIND := {
	"pool": ["swimmer", "lifeguard"], "mall": ["shopper", "mannequin"],
	"office": ["worker", "manager"], "school": ["student", "teacher"],
	"hospital": ["patient", "nurse"], "home": ["resident", "parent"],
}

var main
var role := "passive"
var theme := "pool"
var hp := 3
var variant := "normal"   # normal / runner (schnell, schwach) / brute (gross, rammt) / spitter (wirft aus der Ferne)
var charge_t := 0.0
var charge_dir := Vector3.ZERO
var spit_t := 2.0
var radius := 0.45
var awake := false
var visual: Node3D
var P := {}
var mats: Array = []
var t := 0.0
var flash := 0.0
var knock := Vector3.ZERO
var target := Vector3.ZERO
var wait := 0.0
var wind := 0.0
var hit_cd := 0.0
var ability_t := 0.0
var gaze := 0.0
var beam: MeshInstance3D
var base_alpha := 0.45
var rng := RandomNumberGenerator.new()
var walk_ph := 0.0
var tilt := 0.0

func setup(m, r: String) -> void:
	main = m
	role = r
	theme = m.ch.theme
	if theme == "crown":
		theme = ["pool", "mall", "office", "school"][randi() % 4]
	rng.seed = randi()
	if role == "hostile":
		hp = 4
		# Varianten, damit nicht jeder Gegner gleich kaempft (spaetere Kapitel: mehr Abwechslung)
		var chn: int = m.chapter
		var r := rng.randf()
		if r < 0.22:
			variant = "runner"
			hp = 2
		elif r < 0.22 + minf(0.06 * chn, 0.2):
			variant = "brute"
			hp = 12
		elif r < 0.42 + minf(0.06 * chn, 0.2) and chn >= 2:
			variant = "spitter"
			hp = 3
	elif role == "special":
		hp = 9

func _ready() -> void:
	if role != "passive":
		add_to_group("enemies")
	add_to_group("npcs")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	var kind: String = KIND[theme][1 if role == "special" else 0]
	var o := Figure.outfit(kind, rng)
	var solid := kind == "mannequin"
	base_alpha = 1.0 if solid else (0.42 if role == "passive" else 0.55)
	P = Figure.build(visual, o, base_alpha, 0.25 if not solid else 0.0, role == "hostile")
	mats = P.mats
	match variant:
		"runner":
			visual.scale = Vector3.ONE * 0.85
			P.spine.rotation.x = 0.45
		"brute":
			visual.scale = Vector3(1.45, 1.3, 1.45)
			cs.scale = Vector3(1.4, 1.3, 1.4)
		"spitter":
			P.head.scale = Vector3(1.1, 1.3, 1.1)
	if role == "hostile":
		tilt = rng.randf_range(0.35, 0.6) * (1 if rng.randf() < 0.5 else -1)
		for m in mats:
			m.albedo_color = Color(m.albedo_color.darkened(0.25), m.albedo_color.a)
	if kind == "teacher":
		beam = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.03, 0.03, 1.0)
		beam.mesh = bm
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.albedo_color = Color(1, 0.1, 0.1, 0.6)
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam.material_override = bmat
		beam.visible = false
		main.add_child(beam)
	target = global_position
	wait = rng.randf_range(0.0, 2.0)
	walk_ph = rng.randf() * TAU

func _exit_tree() -> void:
	if beam and is_instance_valid(beam):
		beam.queue_free()

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	hit_cd = maxf(0.0, hit_cd - delta)
	for m in mats:
		m.emission_energy_multiplier = 2.5 if flash > 0.0 else 0.25
	# Geister flackern manchmal
	if base_alpha < 1.0 and rng.randf() < delta * 0.6:
		visual.visible = false
	elif not visual.visible and rng.randf() < delta * 12.0:
		visual.visible = true
	if not main.can_control():
		return
	var p = main.player
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	if role == "passive":
		_wander(delta)
		# manche drehen den Kopf zu dir, wenn du vorbeigehst
		if d < 4.0:
			P.head.rotation.y = lerp_angle(P.head.rotation.y, clampf(atan2(-to.x, -to.z) - visual.rotation.y, -1.2, 1.2), delta * 3.0)
	elif role == "hostile":
		P.head.rotation.z = tilt + (sin(t * 30.0) * 0.08 if awake else 0.0)
		if not awake:
			_wander(delta)
			if d < 9.0 and _sees(p):
				awake = true
				Game.sfx("enemy_hurt", 0.4, 0.5)
		else:
			match variant:
				"runner":
					_chase(delta, p, to, d, 9.0)
				"brute":
					_brute(delta, p, to, d)
				"spitter":
					_spitter(delta, p, to, d)
				_:
					_chase(delta, p, to, d, 5.8)
	else:
		_special(delta, p, to, d)
	knock = knock.lerp(Vector3.ZERO, minf(1.0, delta * 8.0))
	velocity.x += knock.x
	velocity.z += knock.z
	move_and_slide()

# Brocken: langsam, holt aus und rammt dich (rote Linie warnt vorher)
func _brute(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	if charge_t > 0.0:
		charge_t -= delta
		if charge_t > 0.6:
			# ausholen
			velocity.x = 0.0
			velocity.z = 0.0
			visual.position.x = sin(t * 60.0) * 0.04
		else:
			velocity.x = charge_dir.x * 15.0
			velocity.z = charge_dir.z * 15.0
			walk_ph += delta * 30.0
			Figure.walk(P, walk_ph, 1.0)
			if d < 1.8 and hit_cd <= 0.0:
				p.hurt(2)
				p.external += charge_dir * 14.0
				main.shake(0.4)
				hit_cd = 1.0
		return
	if d > 4.0 and d < 12.0 and hit_cd <= 0.0 and rng.randf() < delta * 0.8:
		charge_t = 1.2
		charge_dir = dir
		main.add_hazard("line", global_position + dir * 6.0, Vector2(1.6, 12.0), 0.6, atan2(-dir.x, -dir.z), Color(1, 0.3, 0.2))
		Game.sfx("enemy_attack", 0.5, 0.8)
		return
	_chase(delta, p, to, d, 3.2)

# Spucker: haelt Abstand und wirft dunkle Kugeln
func _spitter(delta: float, p, to: Vector3, d: float) -> void:
	var dir := to.normalized()
	_face(dir, delta, 8.0)
	var want := 0.0
	if d < 7.0:
		want = -3.5
	elif d > 13.0:
		want = 4.0
	var side := dir.cross(Vector3.UP) * sin(t * 0.8) * 2.0
	velocity.x = dir.x * want + side.x
	velocity.z = dir.z * want + side.z
	walk_ph += delta * 6.0
	Figure.walk(P, walk_ph, 0.6)
	spit_t -= delta
	if spit_t <= 0.0 and _sees(p):
		spit_t = rng.randf_range(1.6, 2.4)
		var src: Vector3 = global_position + Vector3(0, 1.6, 0)
		P.head.rotation.x = -0.6
		main.spawn_proj(src, (p.center() - src).normalized() * 12.0, main.ch.proj)
		Game.sfx("enemy_shot", 1.2, 0.5)

func _face(dir: Vector3, delta: float, spd: float = 6.0) -> void:
	if dir.length() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * spd))

func _wander(delta: float) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.6 or wait > 0.0:
		wait -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		Figure.walk(P, walk_ph, 0.0)
		if wait <= 0.0 and to.length() < 0.6:
			var cell: Vector2i = main.level.cell_of(global_position) + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
			var c: Vector3 = main.level.cell_center(cell)
			if not main.level.solid(c + Vector3(0, 0.5, 0)):
				target = c
			wait = rng.randf_range(1.0, 4.0)
		return
	var dir := to.normalized()
	velocity.x = dir.x * 1.1
	velocity.z = dir.z * 1.1
	walk_ph += delta * 4.5
	Figure.walk(P, walk_ph, 0.8)
	_face(dir, delta, 3.0)
	if get_slide_collision_count() > 0 and rng.randf() < 0.05:
		target = global_position

func _sees(p) -> bool:
	var from := global_position + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(from, p.cam.global_position, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _watched_by(p) -> bool:
	var f: Vector3 = -p.cam.global_basis.z
	var to_me: Vector3 = (global_position + Vector3(0, 1.2, 0) - p.cam.global_position).normalized()
	return f.dot(to_me) > 0.8 and _sees(p)

func _chase(delta: float, p, to: Vector3, d: float, spd: float) -> void:
	var dir := to.normalized()
	_face(dir, delta, 10.0)
	if wind > 0.0:
		wind -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		for sd in [-1, 1]:
			P["sh%d" % sd].rotation.x = lerpf(P["sh%d" % sd].rotation.x, -2.3, delta * 12.0)
		if wind <= 0.0:
			if d < 2.0:
				p.hurt(1)
				p.external += dir * 7.0
			hit_cd = 0.9
		return
	if d < 1.5 and hit_cd <= 0.0:
		wind = 0.35
		return
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	walk_ph += delta * (spd * 2.2)
	Figure.walk(P, walk_ph, 1.0)
	# ruckelige Bewegung
	if rng.randf() < delta * 6.0:
		P.head.rotation.x = rng.randf_range(-0.4, 0.4)

func _special(delta: float, p, to: Vector3, d: float) -> void:
	ability_t -= delta
	# neue Orte nutzen die Mechaniken der alten: Krankenschwester = Alarm wie der Bademeister,
	# Eltern auf den Familienfotos = bewegen sich nur, wenn man wegschaut
	var beh: String = {"hospital": "pool", "home": "mall"}.get(theme, theme)
	match beh:
		"pool":
			# Bademeister: pfeift, alle Schwimmer in der Naehe werden feindlich
			if not awake and d < 18.0 and _sees(p):
				awake = true
			if not awake:
				_wander(delta)
				return
			if ability_t <= 0.0 and _sees(p):
				ability_t = 9.0
				Game.sfx("enemy_attack", 2.2, 1.0)
				main.banner("*SHHHHH*" if theme == "hospital" else "*WHISTLE*", Color("#ff4d4d"))
				P.sh1.rotation.x = -2.6
				for n in get_tree().get_nodes_in_group("npcs"):
					if n.role == "passive" and n.global_position.distance_to(global_position) < 26.0:
						n.turn_hostile()
			_chase(delta, p, to, d, 3.2)
		"mall":
			# Schaufensterpuppe: friert ein, wenn du hinschaust
			if not awake and d < 22.0:
				awake = true
			if _watched_by(p):
				velocity.x = 0.0
				velocity.z = 0.0
				return
			_chase(delta, p, to, d, 9.0)
			if rng.randf() < delta * 4.0:
				P.head.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6))
		"office":
			# Manager: taucht hinter dir auf, wenn das Licht flackert
			if not awake and d < 20.0:
				awake = true
				ability_t = 2.0
			if not awake:
				_wander(delta)
				return
			if ability_t <= 0.0:
				ability_t = 6.5
				main.flicker(0.5)
				var behind: Vector3 = p.global_position + p.cam.global_basis.z * 2.6
				behind.y = 0.0
				if not main.level.solid(behind + Vector3(0, 0.5, 0)):
					global_position = behind
				Game.sfx("enemy_hurt", 0.3, 0.8)
			_chase(delta, p, to, d, 2.6)
		"school":
			# Lehrer: wirft Kreide, Blick laesst dich erstarren
			if not awake and d < 20.0 and _sees(p):
				awake = true
			if not awake:
				_wander(delta)
				return
			var sees := _sees(p) and d < 15.0
			gaze = minf(1.5, gaze + delta) if sees else maxf(0.0, gaze - delta * 2.0)
			beam.visible = gaze > 0.2
			if beam.visible:
				var a: Vector3 = global_position + Vector3(0, 1.75, 0)
				var b: Vector3 = p.cam.global_position - Vector3(0, 0.15, 0)
				beam.global_position = (a + b) / 2.0
				beam.scale.z = a.distance_to(b)
				beam.look_at(b, Vector3.UP)
				beam.material_override.albedo_color.a = gaze / 1.5 * 0.7
			if gaze >= 1.5:
				gaze = 0.0
				p.freeze(1.2)
				p.hurt(1)
				main.banner("DETENTION", Color("#ff3030"))
			if ability_t <= 0.0 and sees:
				ability_t = 2.2
				for s in [-0.12, 0.0, 0.12]:
					var from := global_position + Vector3(0, 1.5, 0)
					var aim: Vector3 = (p.center() - from).normalized().rotated(Vector3.UP, s)
					main.spawn_proj(from, aim * 14.0, Color(0.95, 0.95, 0.92))
			_face(to.normalized(), delta, 4.0)
			if d > 7.0:
				velocity.x = to.normalized().x * 1.6
				velocity.z = to.normalized().z * 1.6
				walk_ph += delta * 4.0
				Figure.walk(P, walk_ph, 0.6)
			else:
				velocity.x = 0.0
				velocity.z = 0.0

func turn_hostile() -> void:
	if role != "passive":
		return
	role = "hostile"
	hp = 3
	awake = true
	tilt = rng.randf_range(0.3, 0.6)
	add_to_group("enemies")
	for m in mats:
		m.albedo_color = Color(m.albedo_color.darkened(0.3), 0.55)

func hit(dmg: int, dir: Vector3) -> void:
	hp -= dmg
	flash = 0.08
	knock = Vector3(dir.x, 0, dir.z).normalized() * 5.0
	if role == "passive":
		turn_hostile()
	awake = true
	if hp > 0:
		Game.sfx("enemy_hurt", 0.9, 0.5)
		return
	Game.sfx("enemy_die", 0.7, 0.8)
	main.on_enemy_killed(self)
	main.gibs_from(visual, dir)
	queue_free()
