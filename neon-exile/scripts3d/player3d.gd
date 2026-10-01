extends CharacterBody3D
# ECHO in First-Person: Maus-Blick, laufen, springen, Dash, Laser-Gewehr.

var main
var max_hp := 6
var hp := 6
var head: Node3D
var cam: Camera3D
var gun: Node3D
var muzzle: Node3D
var yaw := 0.0
var pitch := 0.0
var sens := 0.0025   # wird mit Game.sensitivity multipliert
const SPEED := 7.5
const ACCEL := 70.0
const AIR_ACCEL := 25.0
const JUMP := 7.0
const GRAV := 20.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.ZERO
var inv := 0.0
var shoot_cd := 0.0
var bob := 0.0
var recoil := 0.0
var gun_base := Vector3(0.17, -0.15, -0.3)
# Waffen: Name, Farbe, Feuerrate, Schaden, Kugeln pro Schuss, Streuung, Reichweite, durchschlagend, automatisch
# mag = Magazin, reload = Nachladezeit (kurz!). Besonderheiten:
#  PULSE: dreht beim Dauerfeuer hoch (schneller), die letzten 5 Schuss sind "Overdrive" (2 Schaden)
#  SCATTER: im Rutschen/Dash doppelter Schaden, letzte Patrone = Brandladung mit Explosion
#  RAIL: Schuss gedrueckt halten zum Aufladen (bis 3x Schaden + Explosion beim Einschlag)
# Aktives Nachladen: nochmal R im leuchtenden Fenster = sofort fertig + naechstes Magazin +1 Schaden
const WEAPONS := [
	{"name": "PULSE RIFLE", "col": Color("#38f5c4"), "rate": 0.12, "dmg": 1, "pellets": 1, "spread": 0.008, "range": 90.0, "pierce": false, "auto": true, "mag": 32, "reload": 0.9},
	{"name": "SCATTER GUN", "col": Color("#ff9f3d"), "rate": 0.5, "dmg": 1, "pellets": 9, "spread": 0.075, "range": 26.0, "pierce": false, "auto": false, "mag": 6, "reload": 1.0},
	{"name": "RAIL CANNON", "col": Color("#c77dff"), "rate": 0.55, "dmg": 6, "pellets": 1, "spread": 0.0, "range": 120.0, "pierce": true, "auto": false, "mag": 4, "reload": 1.1},
]
var ammo := [32, 6, 4]
var reload_t := 0.0          # >0 waehrend des Nachladens
var reload_len := 1.0
var reload_tried := false    # aktives Nachladen nur ein Versuch
var perfect := [false, false, false]   # Bonus-Magazin nach perfektem Nachladen
var spin := 0.0              # PULSE: Hochdrehen 0..1
var charge := 0.0            # RAIL: Aufladung 0..1
const SWEET_A := 0.45        # Anteil des Nachladebalkens, in dem "perfekt" moeglich ist
const SWEET_B := 0.62
var unlocked := [false, false, false]
var weapon := 0
var ability_unlocked := false
var ability_cd := 0.0
const ABILITY_CD := 8.0
var glow_mat: StandardMaterial3D
var swap_t := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 85
	cam.near = 0.05
	head.add_child(cam)
	_build_gun()

var models: Array = []
var was_on_floor := true
const GUN_MODELS := ["res://assets/kenney/models/blaster-repeater.glb", "res://assets/kenney/models/blaster.glb", "res://assets/kenney/models/blaster-repeater.glb"]

func _build_gun() -> void:
	gun = Node3D.new()
	gun.position = gun_base
	cam.add_child(gun)
	for i in 3:
		var m: Node3D = load(GUN_MODELS[i]).instantiate()
		m.rotation_degrees.y = 180.0
		m.scale = Vector3.ONE * 0.13 if i < 2 else Vector3(0.12, 0.12, 0.18)
		m.visible = i == 0
		gun.add_child(m)
		_no_shadow(m)
		if i == 2:
			_tint(m, Color("#c77dff"))   # Railgun: lila Leuchten
		models.append(m)
	glow_mat = StandardMaterial3D.new()
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.03, -0.22)
	gun.add_child(muzzle)
	# schwaches Licht am Spieler, damit Waffe und nahe Waende sichtbar sind
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("#9fe8ff")
	lamp.light_energy = 0.5
	lamp.omni_range = 9.0
	lamp.position = Vector3(0, 0.6, -2.5)
	cam.add_child(lamp)

func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadow(c)

func _tint(n: Node, col: Color) -> void:
	if n is MeshInstance3D:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(col, 0.35)
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.6
		n.material_overlay = m
	for c in n.get_children():
		_tint(c, col)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= e.relative.x * sens * Game.sensitivity
		pitch = clampf(pitch - e.relative.y * sens * Game.sensitivity, -1.45, 1.45)
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var dir := 1 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		for i in range(1, 4):
			var n := posmod(weapon + dir * i, 3)
			if unlocked[n]:
				select_weapon(n)
				break

func give_weapon(n: int) -> void:
	var first := not unlocked.has(true)
	unlocked[n] = true
	if first:
		weapon = -1
	select_weapon(n)

func has_gun() -> bool:
	return unlocked.has(true)

func select_weapon(n: int) -> void:
	if not unlocked[n] or n == weapon:
		return
	weapon = n
	reload_t = 0.0
	charge = 0.0
	spin = 0.0
	swap_t = 0.25
	shoot_cd = maxf(shoot_cd, 0.2)
	for i in 3:
		models[i].visible = i == n
	gun.visible = true
	Game.sfx("swap")

var jumps := 1
var external := Vector3.ZERO     # Stoss/Sog von aussen
var freeze_t := 0.0              # "Nachsitzen": kann sich nicht bewegen
var invert_t := 0.0              # MNEMOS: Steuerung vertauscht

func freeze(dur: float) -> void:
	freeze_t = maxf(freeze_t, dur)
var slide_t := 0.0
var slide_dir := Vector3.ZERO
var land_dip := 0.0
var kick := 0.0
var tilt := 0.0
var flash_light: OmniLight3D
var flash_t := 0.0

func _physics_process(delta: float) -> void:
	inv = maxf(0.0, inv - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	shoot_cd = maxf(0.0, shoot_cd - delta)
	rotation.y = yaw
	kick = lerpf(kick, 0.0, minf(1.0, delta * 9.0))
	head.rotation.x = pitch + kick
	recoil = lerpf(recoil, 0.0, minf(1.0, delta * 14.0))
	land_dip = lerpf(land_dip, 0.0, minf(1.0, delta * 8.0))
	flash_t = maxf(0.0, flash_t - delta)
	if flash_light == null:
		flash_light = OmniLight3D.new()
		flash_light.light_color = Color(1, 0.95, 0.8)
		flash_light.omni_range = 9.0
		muzzle.add_child(flash_light)
	flash_light.light_energy = 4.0 if flash_t > 0.0 else 0.0
	if not is_on_floor():
		velocity.y -= GRAV * delta
	if not main.can_control():
		Game.set_walking(false)
		velocity.x = 0.0
		velocity.z = 0.0
		slide_t = 0.0
		move_and_slide()
		return
	freeze_t = maxf(0.0, freeze_t - delta)
	invert_t = maxf(0.0, invert_t - delta)
	var inp := Input.get_vector("left", "right", "up", "down")
	if invert_t > 0.0:
		inp = -inp
	if freeze_t > 0.0:
		inp = Vector2.ZERO
	var dir := (transform.basis * Vector3(inp.x, 0, inp.y)).normalized()
	var acc := ACCEL if is_on_floor() else AIR_ACCEL
	var hspeed := Vector2(velocity.x, velocity.z).length()
	# Rutschen: Strg/C beim Laufen, schnell und tief, Sprung aus dem Rutschen behaelt den Schwung
	if Input.is_action_just_pressed("slide") and is_on_floor() and slide_t <= 0.0 and dir != Vector3.ZERO:
		slide_t = 0.75
		slide_dir = dir
		Game.sfx("land", 0.7, 0.5)
	if slide_t > 0.0:
		slide_t -= delta
		var sp := lerpf(SPEED, 17.0, slide_t / 0.75)
		velocity.x = slide_dir.x * sp
		velocity.z = slide_dir.z * sp
		if not is_on_floor():
			slide_t = 0.0
	elif is_on_floor() or hspeed <= SPEED + 0.5 or dir.dot(Vector3(velocity.x, 0, velocity.z).normalized()) < 0.3:
		velocity.x = move_toward(velocity.x, dir.x * SPEED, acc * delta)
		velocity.z = move_toward(velocity.z, dir.z * SPEED, acc * delta)
	else:
		# in der Luft mit viel Schwung: nur lenken, nicht abbremsen
		var v2 := Vector2(velocity.x, velocity.z)
		v2 = v2.rotated(clampf(Vector2(dir.x, dir.z).angle_to(v2) * -1.0, -1.5, 1.5) * delta * 2.0) if dir != Vector3.ZERO else v2
		v2 = v2.move_toward(v2.normalized() * SPEED, 4.0 * delta)
		velocity.x = v2.x
		velocity.z = v2.y
	if is_on_floor():
		jumps = 1
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or slide_t > 0.0:
			velocity.y = JUMP
			slide_t = 0.0
			Game.sfx("jump", 1.0, 0.6)
		elif jumps > 0:
			jumps -= 1
			velocity.y = JUMP * 0.9
			main.burst(global_position, Color(0.8, 0.9, 1.0), 8)
			Game.sfx("jump", 1.3, 0.5)
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		dash_dir = dir if dir != Vector3.ZERO else -transform.basis.z
		dash_t = 0.18
		dash_cd = 0.7
	if dash_t > 0.0:
		dash_t -= delta
		velocity.x = dash_dir.x * 24.0
		velocity.z = dash_dir.z * 24.0
	var fall := velocity.y
	velocity += external
	move_and_slide()
	velocity -= external
	external = external.lerp(Vector3.ZERO, minf(1.0, delta * 5.0))
	if is_on_floor() and not was_on_floor:
		Game.sfx("land", 1.0, 0.6)
		land_dip = clampf(-fall * 0.02, 0.03, 0.25)
	was_on_floor = is_on_floor()
	Game.set_walking(is_on_floor() and Vector2(velocity.x, velocity.z).length() > 2.0 and dash_t <= 0.0 and slide_t <= 0.0)
	hspeed = Vector2(velocity.x, velocity.z).length()
	cam.fov = lerpf(cam.fov, 85.0 + clampf(hspeed - SPEED, 0.0, 12.0) * 1.2 + (8.0 if dash_t > 0.0 else 0.0), minf(1.0, delta * 8.0))
	tilt = lerpf(tilt, -inp.x * 0.035 + (0.08 if slide_t > 0.0 else 0.0), minf(1.0, delta * 8.0))
	cam.rotation.z = tilt
	var moving := hspeed > 1.0 and is_on_floor() and slide_t <= 0.0
	if moving:
		bob += delta * (11.0 + hspeed * 0.3)
	var target_h := 0.85 if slide_t > 0.0 else 1.6
	head.position.y = lerpf(head.position.y, target_h + (sin(bob) * 0.06 if moving else 0.0) - land_dip, minf(1.0, delta * 14.0))
	swap_t = maxf(0.0, swap_t - delta)
	ability_cd = maxf(0.0, ability_cd - delta)
	for i in 3:
		if Input.is_action_just_pressed("weapon%d" % (i + 1)):
			select_weapon(i)
	if ability_unlocked and Input.is_action_just_pressed("ability") and ability_cd <= 0.0:
		ability_cd = ABILITY_CD
		main.overload(global_position)
	# Nachlade-Animation: Waffe kippt weg und dreht sich, schnappt zurueck
	var rl := 0.0
	if reload_t > 0.0:
		rl = sin((1.0 - reload_t / reload_len) * PI)
	var shake_c := charge * 0.006 * sin(Time.get_ticks_msec() * 0.08)
	gun.position = gun_base + Vector3(sin(bob * 0.5) * 0.015 + shake_c, abs(sin(bob * 0.5)) * -0.015 - swap_t * 0.6 - land_dip * 0.2 - rl * 0.12, recoil * 0.08 + charge * 0.03)
	gun.rotation.x = recoil * 0.15 + rl * 0.7
	gun.rotation.z = -tilt * 2.0 + rl * 0.9
	gun.visible = has_gun() and gun.visible
	if not has_gun() or weapon < 0:
		return
	var wd: Dictionary = WEAPONS[weapon]
	_update_reload(delta, wd)
	if reload_t > 0.0:
		return
	if freeze_t > 0.0:
		charge = 0.0
		return
	if weapon == 2:
		# RAIL: halten = aufladen, loslassen = feuern
		if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
			if charge == 0.0:
				Game.sfx("swap", 0.6, 0.4)
			charge = minf(1.0, charge + delta * 1.4)
			if charge >= 1.0 and int(Time.get_ticks_msec() / 120) % 2 == 0:
				main.burst(muzzle.global_position, wd.col, 1)
		elif charge > 0.0:
			_fire(wd)
			charge = 0.0
		return
	var trigger := Input.is_action_pressed("shoot") if wd.auto else Input.is_action_just_pressed("shoot")
	if weapon == 0:
		spin = minf(1.0, spin + delta * 0.8) if trigger else maxf(0.0, spin - delta * 2.0)
	if trigger and shoot_cd <= 0.0:
		_fire(wd)

func _update_reload(delta: float, wd: Dictionary) -> void:
	if reload_t > 0.0:
		var prog := 1.0 - reload_t / reload_len
		if Input.is_action_just_pressed("reload") and not reload_tried:
			reload_tried = true
			if prog >= SWEET_A and prog <= SWEET_B:
				perfect[weapon] = true
				reload_t = 0.0
				_finish_reload(wd)
				main.burst(muzzle.global_position, Color.WHITE, 14)
				Game.sfx("swap", 1.6, 0.9)
				return
			else:
				reload_t += 0.35   # verpatzt: etwas laenger
				reload_len += 0.35
				Game.sfx("land", 0.5, 0.5)
		reload_t -= delta
		if reload_t <= 0.0:
			reload_t = 0.0
			_finish_reload(wd)
		return
	var empty: bool = ammo[weapon] <= 0
	if (Input.is_action_just_pressed("reload") and ammo[weapon] < wd.mag) or (empty and shoot_cd <= 0.0):
		reload_len = wd.reload
		reload_t = reload_len
		reload_tried = false
		perfect[weapon] = false
		charge = 0.0
		spin = 0.0
		Game.sfx("swap", 0.75, 0.7)

func _finish_reload(wd: Dictionary) -> void:
	ammo[weapon] = wd.mag
	Game.sfx("land", 1.6, 0.6)
	recoil = 0.6

func reload_progress() -> float:
	return 0.0 if reload_t <= 0.0 else 1.0 - reload_t / reload_len

func _fire(wd: Dictionary) -> void:
	var w := weapon
	var shot := wd.duplicate()
	var bonus := 1 if perfect[w] else 0
	var last: bool = ammo[w] == 1
	ammo[w] -= 1
	shoot_cd = wd.rate
	if w == 0:
		shoot_cd = lerpf(wd.rate, 0.065, spin)
		shot.dmg = (2 if ammo[w] < 5 else 1) + bonus
		shot.spread = wd.spread + spin * 0.012
		if ammo[w] < 5:
			shot.col = Color("#eaffff")
	elif w == 1:
		shot.dmg = (2 if slide_t > 0.0 or dash_t > 0.0 else 1) + bonus
		if last:
			shot.pellets = 14
			shot.col = Color("#ff4d2e")
	else:
		shot.dmg = int(round(wd.dmg * lerpf(0.6, 3.0, charge))) + bonus * 2
	Game.sfx(["pulse", "scatter", "rail"][w], [1.25 + spin * 0.25, 0.85 if not last else 0.6, 0.7 - charge * 0.25][w], [0.5, 0.9, 1.0][w])
	recoil = [1.0, 2.2, 1.5 + charge * 1.5][w]
	kick += [0.012 + spin * 0.006, 0.05, 0.04 + charge * 0.06][w]
	flash_t = 0.05
	flash_light.light_color = shot.col.lerp(Color.WHITE, 0.5)
	for i in shot.pellets:
		var spread: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * float(shot.spread)
		var fwd: Vector3 = (-cam.global_basis.z + cam.global_basis * spread).normalized()
		var end: Vector3 = main.player_shoot(cam.global_position, fwd, muzzle.global_position, shot)
		if w == 1 and last and i == 0:
			main.explode(end, 3.0, 3, shot.col)
		if w == 2 and charge >= 0.95:
			main.explode(end, 3.5, 4, wd.col)
	if w > 0:
		main.shake(0.15 if w == 1 else 0.15 + charge * 0.25)
		velocity -= -cam.global_basis.z * (5.0 if w == 1 else 2.0 + charge * 8.0)

func center() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)

func is_dashing() -> bool:
	return dash_t > 0.0

func hurt(d: int) -> void:
	if inv > 0.0 or dash_t > 0.0 or hp <= 0:
		return
	hp -= d
	inv = 0.8
	main.on_player_hurt()
