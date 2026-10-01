extends CharacterBody3D
# WARDEN-07 in 3D. Tiefe Schockwellen-Ringe muss man ueberspringen.

var main
var max_hp := 160
var hp := 160
var radius := 2.2
var active := false
var phase := 0
var t := 0.0
var flash := 0.0
var cd := 2.0
var mode := "idle"
var mode_t := 0.0
var charge_dir := Vector3.ZERO
var volley_n := 0
var spin := 0.0
var spin_acc := 0.0
var pat := 0
const COL := Color("#ff2d55")
var mat := StandardMaterial3D.new()
var plates: Node3D
var eye: Node3D
var visual: Node3D

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
	position.y = 2.8
	mat.albedo_color = Color(0.05, 0.02, 0.04)
	mat.emission_enabled = true
	mat.emission = COL
	mat.emission_energy_multiplier = 1.2
	visual = Node3D.new()
	add_child(visual)
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	body.mesh = sm
	body.material_override = mat
	visual.add_child(body)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.01, 0.01, 0.02)
	var socket := MeshInstance3D.new()
	var ss := SphereMesh.new()
	ss.radius = 1.1
	ss.height = 2.2
	socket.mesh = ss
	socket.material_override = dark
	socket.position = Vector3(0, 0, -1.4)
	visual.add_child(socket)
	eye = MeshInstance3D.new()
	var es := SphereMesh.new()
	es.radius = 0.55
	es.height = 1.1
	eye.mesh = es
	var em := StandardMaterial3D.new()
	em.emission_enabled = true
	em.emission = Color.WHITE
	em.emission_energy_multiplier = 2.5
	eye.material_override = em
	eye.position = Vector3(0, 0, -2.2)
	visual.add_child(eye)
	plates = Node3D.new()
	add_child(plates)
	for i in 8:
		var p := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 1.6, 0.3)
		p.mesh = bm
		p.material_override = mat
		var a := i * TAU / 8.0
		p.position = Vector3(cos(a), 0, sin(a)) * 3.2
		p.rotation.y = -a
		plates.add_child(p)

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	mat.emission = Color.WHITE if flash > 0.0 else (COL.lerp(Color("#ffd23d"), 0.4 * (0.5 + 0.5 * sin(t * 10.0))) if phase >= 2 else COL)
	plates.rotation.y += delta * (0.8 + phase * 0.7)
	plates.rotation.x = sin(t) * 0.2
	if not active or not main.can_control():
		return
	var p = main.player
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	visual.look_at(global_position + to.normalized() + Vector3(0, (p.center().y - global_position.y) * 0.1, 0), Vector3.UP)
	var np := 2 if hp < max_hp * 0.34 else (1 if hp < max_hp * 0.67 else 0)
	if np > phase:
		phase = np
		mode = "idle"
		cd = 1.5
		main.shake(0.6)
		main.burst(global_position, COL, 60)
		main.banner("PHASE 2" if phase == 1 else "WARDEN-07 OVERLOAD", COL)
		main.clear_projectiles()
		if phase == 1:
			main.radio("halfway")
	if global_position.distance_to(p.center()) < radius + 0.6:
		p.hurt(1)
	velocity = Vector3.ZERO
	match mode:
		"idle":
			velocity = to.normalized() * (2.0 + phase * 1.0)
			cd -= delta
			if cd <= 0.0:
				_attack()
		"tele":
			mode_t -= delta
			flash = 0.05 if int(mode_t * 16.0) % 2 == 0 else 0.0
			if mode_t <= 0.0:
				charge_dir = to.normalized()
				mode = "charge"
				mode_t = 1.0
		"charge":
			velocity = charge_dir * (20.0 + phase * 4.0)
			mode_t -= delta
			if get_slide_collision_count() > 0 or mode_t <= 0.0:
				main.shake(0.4)
				_ring(16 + phase * 4, 9.0, 0.6)
				mode = "idle"
				cd = 1.3
		"volley":
			mode_t -= delta
			if mode_t <= 0.0:
				var aim: Vector3 = (p.center() - global_position).normalized()
				for s in ([-0.12, 0.0, 0.12] if phase > 0 else [0.0]):
					main.spawn_proj(global_position + aim * radius, aim.rotated(Vector3.UP, s) * 18.0, COL)
				volley_n -= 1
				mode_t = 0.18
				if volley_n <= 0:
					mode = "idle"
					cd = 1.0
		"spiral":
			mode_t -= delta
			spin += delta * 3.0
			spin_acc += delta
			if spin_acc > 0.09:
				spin_acc = 0.0
				for k in 4:
					var a := spin + k * TAU / 4.0
					main.spawn_proj(global_position + Vector3(0, -1.6, 0), Vector3(cos(a), 0, sin(a)) * 10.0, Color("#ffd23d"))
			if mode_t <= 0.0:
				mode = "idle"
				cd = 1.2
	position.y = lerpf(position.y, 2.8 + sin(t * 1.5) * 0.3, minf(1.0, delta * 3.0))
	move_and_slide()

func _attack() -> void:
	var list := ["ring", "volley", "charge"]
	if phase >= 1:
		list.append("summon")
	if phase >= 2:
		list.append("spiral")
	var a: String = list[pat % list.size()]
	pat += 1
	match a:
		"ring":
			_ring(18 + phase * 6, 8.0, 0.6)
			if phase >= 1:
				_ring(12, 6.0, 1.6)
			cd = 1.8 - phase * 0.3
		"volley":
			mode = "volley"
			volley_n = 5 + phase * 2
			mode_t = 0.3
		"charge":
			mode = "tele"
			mode_t = 0.8
		"summon":
			for i in 2:
				main.spawn_enemy("boss_minion", global_position + Vector3(randf_range(-4, 4), -2.8, randf_range(-4, 4)))
			cd = 1.5
		"spiral":
			mode = "spiral"
			mode_t = 2.8

# Ring auf Hoehe y (0.6 = knapp ueber dem Boden, man muss drueberspringen)
func _ring(n: int, sp: float, y: float) -> void:
	var off := randf() * TAU
	var base := Vector3(global_position.x, y, global_position.z)
	for i in n:
		var a := off + i * TAU / n
		var d := Vector3(cos(a), 0, sin(a))
		main.spawn_proj(base + d * radius, d * sp, COL)

func hit(dmg: int, _dir: Vector3) -> void:
	if not active:
		return
	hp -= dmg
	flash = 0.06
	if hp <= 0:
		main.on_boss_killed(self)
