extends CharacterBody3D
# Gegner:
#  "crawler" -> HOLLOW: grosse, blasse, gesichtslose Gestalt mit zu langen Armen.
#     Bewegt sich ruckartig. Schaust du sie an, schleicht sie nur. Schaust du weg, rennt sie.
#     Ganz nah holt sie aus und springt dich an (kurz vorher zuckt der Kopf).
#  "drone"   -> WATCHER: schwebender Klumpen aus Augen, die dir folgen, mit haengenden Faeden.
#     Blinzelt mit allen Augen, dann schiesst er langsame, verfolgende Kugeln.

var main
var kind := "crawler"
var hp := 4
var radius := 0.6
var col := Color("#d9e6ea")
var flash := 0.0
var knock := Vector3.ZERO
var fire_t := 1.5
var strafe := 1.0
var awake := false
var t := 0.0
var skin := StandardMaterial3D.new()
var dark := StandardMaterial3D.new()
var visual: Node3D
var parts := {}          # Name -> Node3D (fuer Animation)
var eyes: Array = []
var pose_t := 0.0
var lunge_t := 0.0
var lunge_cd := 0.0
var lunge_dir := Vector3.ZERO
var tele_t := 0.0
var blink := 0.0
var watched := false

func setup(m, k: String) -> void:
	main = m
	kind = k
	col = m.ch.enemy
	if kind == "boss_minion":
		kind = "crawler"
		hp = 3
		awake = true
	if kind == "drone":
		hp = 5
		radius = 0.8
		col = m.ch.drone
		fire_t = randf_range(0.8, 1.8)
		strafe = 1.0 if randf() < 0.5 else -1.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	var cs := CollisionShape3D.new()
	if kind == "crawler":
		var cap := CapsuleShape3D.new()
		cap.radius = 0.45
		cap.height = 2.3
		cs.shape = cap
		cs.position.y = 1.15
	else:
		var sh := SphereShape3D.new()
		sh.radius = radius
		cs.shape = sh
	add_child(cs)
	skin.albedo_color = col
	skin.roughness = 0.45
	skin.subsurf_scatter_enabled = false
	skin.emission_enabled = true
	skin.emission = Color("#ff2040")
	skin.emission_energy_multiplier = 0.0
	dark.albedo_color = Color(0.01, 0.01, 0.015)
	dark.roughness = 0.1
	visual = Node3D.new()
	add_child(visual)
	if kind == "crawler":
		_build_hollow()
		visual.scale = Vector3(0.9, 1.2, 0.9)   # noch groesser und duenner
	else:
		_build_watcher()
		position.y = 2.2

func _part(name: String, mesh: Mesh, pos: Vector3, scl: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scl
	mi.material_override = mat
	(parent if parent else visual).add_child(mi)
	parts[name] = mi
	return mi

func _cap(r: float, hgt: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = hgt
	return c

func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s

func _pivot(name: String, pos: Vector3, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	(parent if parent else visual).add_child(n)
	parts[name] = n
	return n

func _build_hollow() -> void:
	# Beine
	for sd in [-1.0, 1.0]:
		var hip := _pivot("hip%d" % sd, Vector3(0.14 * sd, 1.0, 0))
		_part("leg%d" % sd, _cap(0.08, 1.05), Vector3(0, -0.5, 0), Vector3.ONE, skin, hip)
	# Koerper, leicht nach vorn gebeugt
	var spine := _pivot("spine", Vector3(0, 1.0, 0))
	spine.rotation.x = -0.25
	_part("torso", _cap(0.2, 0.95), Vector3(0, 0.45, 0), Vector3(1, 1, 0.75), skin, spine)
	# Rippen-Schatten
	for i in 3:
		_part("rib%d" % i, BoxMesh.new(), Vector3(0, 0.55 + i * 0.1, -0.15), Vector3(0.28, 0.015, 0.02), dark, spine)
	# Kopf: glattes Ei, kein Gesicht, nur ein senkrechter dunkler Spalt
	var neck := _pivot("neck", Vector3(0, 0.95, 0), spine)
	_part("neckm", _cap(0.05, 0.25), Vector3(0, 0.1, 0), Vector3.ONE, skin, neck)
	var head := _pivot("head", Vector3(0, 0.3, 0), neck)
	_part("skull", _sph(0.17), Vector3(0, 0.05, 0), Vector3(1, 1.45, 1.1), skin, head)
	_part("mouth", BoxMesh.new(), Vector3(0, -0.02, -0.17), Vector3(0.025, 0.2, 0.02), dark, head)
	_part("eye_l", _sph(0.025), Vector3(-0.06, 0.12, -0.165), Vector3.ONE, dark, head)
	_part("eye_r", _sph(0.025), Vector3(0.06, 0.12, -0.165), Vector3.ONE, dark, head)
	# Arme: viel zu lang, haengen bis zu den Knien, mit langen Fingern
	for sd in [-1.0, 1.0]:
		var sh := _pivot("sh%d" % sd, Vector3(0.24 * sd, 0.85, 0), spine)
		_part("upper%d" % sd, _cap(0.05, 0.75), Vector3(0, -0.35, 0), Vector3.ONE, skin, sh)
		var el := _pivot("el%d" % sd, Vector3(0, -0.72, 0), sh)
		_part("lower%d" % sd, _cap(0.045, 0.8), Vector3(0, -0.38, 0), Vector3.ONE, skin, el)
		for f in 3:
			var fg := _part("f%d%d" % [sd, f], _cap(0.012, 0.3), Vector3((f - 1) * 0.03, -0.9, 0), Vector3.ONE, skin, el)
			fg.rotation.z = (f - 1) * 0.15

func _build_watcher() -> void:
	_part("core", _sph(0.55), Vector3.ZERO, Vector3(1, 0.9, 1), skin)
	var sclera := StandardMaterial3D.new()
	sclera.albedo_color = Color(0.95, 0.93, 0.88)
	sclera.roughness = 0.15
	var iris := StandardMaterial3D.new()
	iris.albedo_color = Color(0.02, 0.02, 0.02)
	iris.emission_enabled = true
	iris.emission = Color("#ff3030")
	iris.emission_energy_multiplier = 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	for i in 7:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.8), rng.randf_range(-1, -0.2)).normalized()
		var holder := Node3D.new()
		holder.position = dir * 0.5
		visual.add_child(holder)
		var size := rng.randf_range(0.1, 0.22)
		var ball := MeshInstance3D.new()
		ball.mesh = _sph(size)
		ball.material_override = sclera
		holder.add_child(ball)
		var pupil := MeshInstance3D.new()
		pupil.mesh = _sph(size * 0.45)
		pupil.material_override = iris
		pupil.position = Vector3(0, 0, -size * 0.75)
		holder.add_child(pupil)
		eyes.append(holder)
	# haengende Faeden
	for i in 6:
		var a := i * TAU / 6.0
		var p := _pivot("str%d" % i, Vector3(cos(a) * 0.3, -0.35, sin(a) * 0.3))
		_part("strm%d" % i, _cap(0.015, rng.randf_range(0.8, 1.6)), Vector3(0, -0.6, 0), Vector3.ONE, skin, p)

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	blink = maxf(0.0, blink - delta)
	lunge_cd = maxf(0.0, lunge_cd - delta)
	skin.emission_energy_multiplier = 2.0 if flash > 0.0 else 0.0
	if kind == "drone":
		_anim_watcher(delta)
	if not main.can_control():
		return
	var p = main.player
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	if not awake:
		if d < 20.0:
			awake = true
			if kind == "crawler":
				Game.sfx("enemy_hurt", 0.35, 0.5)
		else:
			return
	var dir := to.normalized()
	if kind == "crawler":
		_hollow(delta, p, dir, d)
	else:
		_watcher(delta, p, dir, d)
	knock = knock.lerp(Vector3.ZERO, minf(1.0, delta * 8.0))
	move_and_slide()

func _hollow(delta: float, p, dir: Vector3, d: float) -> void:
	# Wird die Gestalt gerade angeschaut?
	var cam_f: Vector3 = -p.cam.global_basis.z
	var to_me: Vector3 = (global_position + Vector3(0, 1.5, 0) - p.cam.global_position).normalized()
	watched = cam_f.dot(to_me) > 0.82
	var spd := 1.6 if watched else 8.5
	velocity.y -= 20.0 * delta
	if is_on_floor():
		velocity.y = 0.0
	if lunge_t > 0.0:
		lunge_t -= delta
		velocity.x = lunge_dir.x * 15.0
		velocity.z = lunge_dir.z * 15.0
		if global_position.distance_to(p.global_position) < 1.3:
			p.hurt(1)
			p.velocity += lunge_dir * 9.0 + Vector3(0, 3, 0)
			lunge_t = 0.0
		return
	if tele_t > 0.0:
		# Ausholen: steht still, Kopf zuckt, Arme heben sich
		tele_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		parts["head"].rotation.z = sin(t * 60.0) * 0.4
		for sd in [-1.0, 1.0]:
			parts["sh%d" % sd].rotation.x = lerpf(parts["sh%d" % sd].rotation.x, -2.4, delta * 10.0)
		if tele_t <= 0.0:
			lunge_t = 0.35
			lunge_dir = dir
			lunge_cd = 1.6
		return
	if d < 3.2 and lunge_cd <= 0.0:
		tele_t = 0.4
		Game.sfx("enemy_attack", 0.45, 0.8)
		return
	velocity.x = dir.x * spd + knock.x
	velocity.z = dir.z * spd + knock.z
	# Blick zum Spieler
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 10.0))
	# Stop-Motion-Animation: Pose springt nur 10x pro Sekunde
	pose_t -= delta
	if pose_t <= 0.0:
		pose_t = 0.1 if not watched else 0.25
		var ph := t * (14.0 if not watched else 4.0)
		for sd in [-1.0, 1.0]:
			parts["hip%d" % sd].rotation.x = sin(ph + (0.0 if sd > 0 else PI)) * 0.7
			parts["sh%d" % sd].rotation.x = sin(ph + (PI if sd > 0 else 0.0)) * 0.5 + 0.2
			parts["el%d" % sd].rotation.x = -0.3 - randf() * 0.3
		parts["head"].rotation = Vector3(randf_range(-0.3, 0.3), randf_range(-0.6, 0.6), randf_range(-0.5, 0.5)) * (1.0 if randf() < 0.3 else 0.2)
		parts["spine"].rotation.x = -0.25 - (0.35 if not watched else 0.0)

func _watcher(delta: float, p, dir: Vector3, d: float) -> void:
	var side := dir.cross(Vector3.UP) * strafe * 3.0
	var keep := dir * clampf(d - 10.0, -1.0, 1.0) * 4.0
	velocity = side + keep + knock
	velocity.y = (2.3 + sin(t * 1.7) * 0.5 - position.y) * 3.0
	fire_t -= delta
	if fire_t < 0.5 and blink <= 0.0 and fire_t > 0.4:
		blink = 0.3
	if fire_t <= 0.0:
		fire_t = randf_range(1.6, 2.4)
		Game.sfx("enemy_shot", 0.7, 0.4)
		for e in eyes.slice(0, 3):
			var from: Vector3 = e.global_position
			var aim: Vector3 = (p.center() - from).normalized()
			main.spawn_proj(from, aim * 9.0, main.ch.proj, true)
	if randf() < delta * 0.4:
		strafe = -strafe

func _anim_watcher(delta: float) -> void:
	if main.player == null:
		return
	var target: Vector3 = main.player.cam.global_position
	for e in eyes:
		if e.global_position.distance_to(target) > 0.1:
			e.look_at(target, Vector3.UP)
		e.scale.y = lerpf(e.scale.y, 0.1 if blink > 0.0 else 1.0, minf(1.0, delta * 20.0))
	visual.rotation.y += delta * 0.3
	for i in 6:
		if parts.has("str%d" % i):
			parts["str%d" % i].rotation = Vector3(sin(t * 1.3 + i) * 0.3, 0, cos(t * 1.1 + i) * 0.3)

func hit(dmg: int, dir: Vector3) -> void:
	hp -= dmg
	flash = 0.08
	awake = true
	knock = Vector3(dir.x, 0, dir.z).normalized() * 6.0
	if kind == "crawler" and tele_t <= 0.0 and lunge_t <= 0.0:
		parts["head"].rotation.z = randf_range(-0.8, 0.8)
	if hp > 0:
		Game.sfx("enemy_hurt", 0.8 if kind == "crawler" else 1.2, 0.5)
		return
	Game.sfx("enemy_die", 0.6 if kind == "crawler" else 1.0, 0.8)
	main.on_enemy_killed(self)
	main.gibs_from(visual, dir)
	queue_free()
