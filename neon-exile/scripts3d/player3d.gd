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
# Waffen. Man traegt hoechstens 3 gleichzeitig (slots). Eine neue Waffe ersetzt die aktuelle,
# die alte faellt auf den Boden. Typen: hitscan, lob (Granate), beam (Kette), disc (springt zwischen Gegnern)
#  PULSE: dreht beim Dauerfeuer hoch, die letzten 5 Schuss machen doppelten Schaden
#  SCATTER: im Rutschen/Dash doppelter Schaden, letzte Patrone = Brandladung mit Explosion
#  RAIL: halten zum Aufladen (bis 3x Schaden + Explosion beim Einschlag)
#  HUMMINGBIRD: sehr schnelle MP, beim Zielen extrem praezise
#  LAST WORD: Revolver, Kopftreffer x2.5, der letzte Schuss im Lauf trifft immer kritisch
#  CHALK BOMB: Granatwerfer, Kreidebomben explodieren beim Aufprall
#  LULLABY: Strahl, springt auf bis zu 3 Gegner in der Naehe ueber
#  TIDE: Scheibe, die von Gegner zu Gegner und von Waenden abprallt
#  KATANA: Hieb im Bogen, zerschlaegt gegnerische Geschosse, rechte Maustaste = Sprung-Schnitt nach vorn
#  KNIFE: schnelle Stiche, 3x Schaden gegen Gegner, die dich noch nicht bemerkt haben, rechte Maustaste = werfen
# Aktives Nachladen: nochmal R im leuchtenden Fenster = sofort fertig + naechstes Magazin mehr Schaden
const WEAPONS := [
	{"name": "PULSE RIFLE", "col": Color("#38f5c4"), "type": "hitscan", "rate": 0.1, "dmg": 1, "pellets": 1, "spread": 0.008, "range": 90.0, "pierce": false, "auto": true, "mag": 32, "reload": 0.9, "crit": 2.0},
	{"name": "SCATTER GUN", "col": Color("#ff9f3d"), "type": "hitscan", "rate": 0.5, "dmg": 1, "pellets": 8, "spread": 0.075, "range": 26.0, "pierce": false, "auto": false, "mag": 6, "reload": 1.0, "crit": 1.5},
	{"name": "RAIL CANNON", "col": Color("#c77dff"), "type": "hitscan", "rate": 0.6, "dmg": 6, "pellets": 1, "spread": 0.0, "range": 120.0, "pierce": true, "auto": false, "mag": 4, "reload": 1.1, "crit": 2.0},
	{"name": "HUMMINGBIRD", "col": Color("#7dffb0"), "type": "hitscan", "rate": 0.08, "dmg": 1, "pellets": 1, "spread": 0.03, "range": 60.0, "pierce": false, "auto": true, "mag": 48, "reload": 0.8, "crit": 2.0},
	{"name": "LAST WORD", "col": Color("#ffe066"), "type": "hitscan", "rate": 0.3, "dmg": 4, "pellets": 1, "spread": 0.0, "range": 100.0, "pierce": false, "auto": false, "mag": 6, "reload": 0.95, "crit": 2.5},
	{"name": "CHALK BOMB", "col": Color("#f4f1e8"), "type": "lob", "rate": 0.65, "dmg": 6, "pellets": 1, "spread": 0.0, "range": 0.0, "pierce": false, "auto": false, "mag": 4, "reload": 1.1, "crit": 1.0},
	{"name": "LULLABY", "col": Color("#9fd8ff"), "type": "beam", "rate": 0.08, "dmg": 1, "pellets": 1, "spread": 0.0, "range": 16.0, "pierce": false, "auto": true, "mag": 70, "reload": 1.0, "crit": 1.0},
	{"name": "TIDE", "col": Color("#4db8ff"), "type": "disc", "rate": 0.45, "dmg": 4, "pellets": 1, "spread": 0.0, "range": 0.0, "pierce": false, "auto": false, "mag": 3, "reload": 0.9, "crit": 1.0},
	{"name": "KATANA", "col": Color("#ff4d6d"), "type": "melee", "rate": 0.38, "dmg": 5, "pellets": 1, "spread": 0.0, "range": 3.3, "arc": 0.45, "pierce": false, "auto": true, "mag": 0, "reload": 0.0, "crit": 1.0},
	{"name": "KNIFE", "col": Color("#e0e6ee"), "type": "melee", "rate": 0.16, "dmg": 2, "pellets": 1, "spread": 0.0, "range": 2.2, "arc": 0.65, "pierce": false, "auto": true, "mag": 0, "reload": 0.0, "crit": 3.0},
	# Belohnung fuer 100%: alle Geheimraeume, Kassetten und Erinnerungen
	{"name": "HALO", "col": Color("#ffd23d"), "type": "hitscan", "rate": 0.1, "dmg": 2, "pellets": 1, "spread": 0.004, "range": 140.0, "pierce": true, "auto": true, "mag": 40, "reload": 0.7, "crit": 2.5},
]
var ammo: Array = []
var reload_t := 0.0          # >0 waehrend des Nachladens
var reload_len := 1.0
var reload_tried := false    # aktives Nachladen nur ein Versuch
var perfect: Array = []      # Bonus-Magazin nach perfektem Nachladen
var spin := 0.0              # PULSE: Hochdrehen 0..1
var charge := 0.0            # RAIL: Aufladung 0..1
const SWEET_A := 0.45        # Anteil des Nachladebalkens, in dem "perfekt" moeglich ist
const SWEET_B := 0.62
const MAX_SLOTS := 3
var slots: Array = []        # Waffen-IDs, die man gerade traegt (max 3)
var unlocked: Array = []     # unlocked[id] = gerade im Inventar
var weapon := 0
var aim := 0.0
# Ult: laedt sich durch Treffer und Kills, [F] loest die Ult der aktuellen Waffe aus
var ult := 0.0
var _f_down := false
var ult_t := 0.0          # Dauer laufender Ults (PULSE / HUMMINGBIRD)
var ult_kind := -1
const ULT_NAMES := ["OVERDRIVE", "DRAGON BREATH", "JUDGEMENT", "SWARM", "DEADEYE", "CLUSTER", "SLEEP", "TSUNAMI", "THOUSAND CUTS", "SHADOW STEP", "REMEMBRANCE"]               # 0..1 Zielen mit rechter Maustaste
var sway := Vector2.ZERO     # Waffe zieht der Mausbewegung nach
var ability_unlocked := false
var ability_cd := 0.0
const ABILITY_CD := 8.0
var glow_mat: StandardMaterial3D
var swap_t := 0.0

func _ready() -> void:
	for wd in WEAPONS:
		ammo.append(wd.mag)
		perfect.append(false)
		unlocked.append(false)
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

# Waffenmodell bauen (0-2 Kenney-Modelle, die anderen aus Formen zusammengesetzt)
func make_gun_model(id: int) -> Node3D:
	if id < 3:
		var m: Node3D = load(GUN_MODELS[id]).instantiate()
		if id == 2:
			_tint(m, Color("#c77dff"))
		return m
	var root := Node3D.new()
	var col: Color = WEAPONS[id].col
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.13, 0.13, 0.16)
	dark.metallic = 0.6
	dark.roughness = 0.35
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(0.75, 0.76, 0.8)
	light.metallic = 0.8
	light.roughness = 0.25
	var glow := StandardMaterial3D.new()
	glow.albedo_color = col
	glow.emission_enabled = true
	glow.emission = col
	glow.emission_energy_multiplier = 2.5
	var parts: Array = []
	match id:
		10:  # HALO: goldener Ring um einen langen Lauf
			parts = [[Vector3(0, 0, 0), Vector3(0.8, 0.8, 2.2), light], [Vector3(0, 0.1, -1.9), Vector3(0.3, 0.3, 2.0), glow],
				[Vector3(0, 0.75, 0.2), Vector3(1.4, 0.12, 1.4), glow], [Vector3(0, -0.9, 0.6), Vector3(0.5, 1.2, 0.6), dark],
				[Vector3(0.45, 0, 0), Vector3(0.06, 0.5, 2.0), glow], [Vector3(-0.45, 0, 0), Vector3(0.06, 0.5, 2.0), glow]]
		3:  # HUMMINGBIRD: kompakte MP mit langem Magazin
			parts = [[Vector3(0, 0, 0), Vector3(0.9, 0.9, 2.6), dark], [Vector3(0, 0.3, -1.9), Vector3(0.45, 0.45, 1.6), light],
				[Vector3(0, -1.1, -0.3), Vector3(0.5, 1.6, 0.6), dark], [Vector3(0, -0.8, 1.0), Vector3(0.6, 1.2, 0.6), dark],
				[Vector3(0.48, 0.15, 0), Vector3(0.05, 0.25, 2.0), glow], [Vector3(-0.48, 0.15, 0), Vector3(0.05, 0.25, 2.0), glow]]
		4:  # LAST WORD: Revolver mit Trommel
			parts = [[Vector3(0, 0.25, -1.4), Vector3(0.45, 0.45, 2.6), light], [Vector3(0, 0.05, 0), Vector3(0.9, 0.9, 0.9), dark],
				[Vector3(0, -0.8, 0.8), Vector3(0.6, 1.5, 0.7), Color(0.35, 0.2, 0.12)], [Vector3(0, 0.55, -2.6), Vector3(0.12, 0.2, 0.12), glow],
				[Vector3(0, 0.05, 0), Vector3(0.95, 0.3, 0.3), glow]]
		5:  # CHALK BOMB: dicker Werfer mit Trommel
			parts = [[Vector3(0, 0.1, -0.6), Vector3(1.1, 1.1, 3.0), Color(0.3, 0.42, 0.34)], [Vector3(0, 0.1, -2.2), Vector3(1.3, 1.3, 0.3), dark],
				[Vector3(0, -0.9, 0.6), Vector3(0.6, 1.4, 0.7), dark], [Vector3(0, 0.1, 0.4), Vector3(1.4, 1.4, 1.0), dark],
				[Vector3(0, 0.1, -2.38), Vector3(0.7, 0.7, 0.05), glow]]
		6:  # LULLABY: Spulen um eine Glasroehre
			parts = [[Vector3(0, 0, 0), Vector3(0.8, 0.9, 2.4), light], [Vector3(0, 0.1, -1.6), Vector3(0.35, 0.35, 1.6), glow],
				[Vector3(0, -0.9, 0.6), Vector3(0.55, 1.3, 0.6), dark]]
			for k in 3:
				parts.append([Vector3(0, 0.1, -1.0 - k * 0.5), Vector3(0.8, 0.8, 0.12), dark])
		7:  # TIDE: Werfer mit sichtbarer Scheibe vorne
			parts = [[Vector3(0, 0, 0.2), Vector3(0.8, 0.8, 2.2), dark], [Vector3(0, -0.85, 0.7), Vector3(0.55, 1.3, 0.6), dark],
				[Vector3(0, 0.25, -1.3), Vector3(1.6, 0.12, 1.6), glow], [Vector3(0, 0.1, -0.9), Vector3(0.3, 0.3, 0.8), light]]
		8:  # KATANA: lange, leicht gebogene Klinge mit Tsuba und umwickeltem Griff
			for k in 6:
				parts.append([Vector3(0, 0.6 + k * 0.05 * k * 0.15, -1.2 - k * 1.5), Vector3(0.12, 0.42, 1.55), light])
			parts.append([Vector3(0, 0.62, -0.1), Vector3(0.9, 0.9, 0.15), Color(0.7, 0.55, 0.2)])
			parts.append([Vector3(0, 0.6, 1.3), Vector3(0.32, 0.36, 2.6), Color(0.12, 0.05, 0.06)])
			parts.append([Vector3(0.07, 0.75, -4.5), Vector3(0.02, 0.1, 8.4), glow])
		9:  # KNIFE: kurze Klinge
			parts = [[Vector3(0, 0.3, -1.3), Vector3(0.1, 0.55, 2.2), light], [Vector3(0, 0.3, 0.0), Vector3(0.5, 0.75, 0.2), dark],
				[Vector3(0, 0.25, 1.0), Vector3(0.35, 0.45, 1.8), Color(0.15, 0.12, 0.1)], [Vector3(0.06, 0.48, -1.3), Vector3(0.02, 0.08, 2.0), glow]]
	for pr in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pr[1]
		mi.mesh = bm
		if pr[2] is Color:
			var cm := StandardMaterial3D.new()
			cm.albedo_color = pr[2]
			cm.roughness = 0.6
			mi.material_override = cm
		else:
			mi.material_override = pr[2]
		mi.position = pr[0]
		root.add_child(mi)
	# Formen sind in "Einheiten" gebaut: auf die Groesse der Kenney-Modelle bringen
	root.scale = Vector3.ONE * 0.045
	var outer := Node3D.new()
	outer.add_child(root)
	return outer

func _build_gun() -> void:
	gun = Node3D.new()
	gun.position = gun_base
	cam.add_child(gun)
	for i in WEAPONS.size():
		var m: Node3D = make_gun_model(i)
		if i < 3:
			m.rotation_degrees.y = 180.0
			m.scale = Vector3.ONE * 0.13 if i < 2 else Vector3(0.12, 0.12, 0.18)
		else:
			m.scale = Vector3.ONE * 0.95
		m.visible = false
		gun.add_child(m)
		_no_shadow(m)
		models.append(m)
	glow_mat = StandardMaterial3D.new()
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.03, -0.22)
	gun.add_child(muzzle)
	# Muendungsfeuer: kurz aufleuchtender Stern
	flash_mesh = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.16, 0.16)
	flash_mesh.mesh = qm
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.albedo_texture = _star_tex()
	flash_mesh.material_override = fm
	flash_mesh.visible = false
	muzzle.add_child(flash_mesh)
	# schwaches Licht am Spieler, damit Waffe und nahe Waende sichtbar sind
	var lamp := OmniLight3D.new()
	lamp.light_color = Color("#9fe8ff")
	lamp.light_energy = 0.5
	lamp.omni_range = 9.0
	lamp.position = Vector3(0, 0.6, -2.5)
	cam.add_child(lamp)

var flash_mesh: MeshInstance3D

func _star_tex() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5)
			var a := maxf(0.0, 1.0 - d.length() / 16.0)
			var spike := maxf(maxf(0.0, 1.0 - absf(d.x) / 2.5), maxf(0.0, 1.0 - absf(d.y) / 2.5)) * maxf(0.0, 1.0 - d.length() / 16.0)
			var v := clampf(a * a * 1.5 + spike, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, v))
	return ImageTexture.create_from_image(img)

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
		var sm := sens * Game.sensitivity * (1.0 - aim * 0.35)
		yaw -= e.relative.x * sm
		pitch = clampf(pitch - e.relative.y * sm, -1.45, 1.45)
		sway += Vector2(e.relative.x, e.relative.y) * 0.0006
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and slots.size() > 1:
		var dir := 1 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		var i := slots.find(weapon)
		select_weapon(slots[posmod(i + dir, slots.size())])

# Waffe aufnehmen. Volle Slots: die aktuelle Waffe wird ersetzt und faellt zu Boden.
func give_weapon(n: int) -> void:
	if slots.has(n):
		select_weapon(n)
		return
	if slots.size() >= MAX_SLOTS:
		var i := slots.find(weapon)
		if i < 0:
			i = 0
		var old: int = slots[i]
		slots[i] = n
		unlocked[old] = false
		if main and main.has_method("spawn_pickup") and is_inside_tree():
			var fwd: Vector3 = -global_basis.z
			main.spawn_pickup("weapon", old, global_position + fwd * 1.6)
	else:
		slots.append(n)
	unlocked[n] = true
	ammo[n] = WEAPONS[n].mag
	weapon = -1
	select_weapon(n)
	_check_arsenal()

func has_gun() -> bool:
	return not slots.is_empty()

func _check_arsenal() -> void:
	if slots.size() >= MAX_SLOTS:
		Game.unlock("arsenal")

func select_weapon(n: int) -> void:
	if not slots.has(n) or n == weapon:
		return
	weapon = n
	reload_t = 0.0
	charge = 0.0
	spin = 0.0
	swap_t = 0.25
	shoot_cd = maxf(shoot_cd, 0.2)
	for i in models.size():
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
	for i in slots.size():
		if Input.is_action_just_pressed("weapon%d" % (i + 1)):
			select_weapon(slots[i])
	# Zielen (rechte Maustaste): reinzoomen, Waffe in die Mitte, weniger Streuung
	var aiming: bool = Input.is_action_pressed("aim") and has_gun() and WEAPONS[maxi(weapon, 0)].type != "melee" and reload_t <= 0.0 and slide_t <= 0.0
	aim = move_toward(aim, 1.0 if aiming else 0.0, delta * 7.0)
	sway = sway.lerp(Vector2.ZERO, minf(1.0, delta * 9.0))
	flash_mesh.visible = flash_t > 0.0
	if flash_t > 0.0:
		flash_mesh.rotation.z = randf() * TAU
		flash_mesh.scale = Vector3.ONE * randf_range(0.8, 1.4)
	if ult_t > 0.0:
		ult_t -= delta
		if ult_t <= 0.0:
			ult_kind = -1
	if has_gun():
		ult = minf(100.0, ult + delta * 2.5)   # laedt auch langsam von selbst
	if Input.is_action_just_pressed("ult") or Input.is_physical_key_pressed(KEY_F) and not _f_down:
		if not has_gun() or weapon < 0:
			main.banner("NO WEAPON", Color("#888888"))
		elif ult >= 100.0:
			ult = 0.0
			_do_ult(weapon)
		else:
			main.banner("ULT %d%%" % int(ult), Color("#aaaaaa"))
			Game.sfx("swap", 0.6, 0.5)
	_f_down = Input.is_physical_key_pressed(KEY_F)
	if ability_unlocked and Input.is_action_just_pressed("ability") and ability_cd <= 0.0:
		ability_cd = ABILITY_CD
		main.overload(global_position)
	# Nachlade-Animation: Waffe kippt weg und dreht sich, schnappt zurueck
	var rl := 0.0
	if reload_t > 0.0:
		rl = sin((1.0 - reload_t / reload_len) * PI)
	var shake_c := charge * 0.006 * sin(Time.get_ticks_msec() * 0.08)
	var base: Vector3 = gun_base.lerp(Vector3(0.0, -0.11, -0.26), aim)
	var bobk := 1.0 - aim * 0.8
	gun.position = base + Vector3((sin(bob * 0.5) * 0.015 + shake_c) * bobk - sway.x * 0.5, (abs(sin(bob * 0.5)) * -0.015) * bobk - swap_t * 0.6 - land_dip * 0.2 - rl * 0.12 + sway.y * 0.5, recoil * 0.08 + charge * 0.03)
	gun.rotation.x = recoil * 0.15 + rl * 0.7 + sway.y * 2.0
	gun.rotation.y = -sway.x * 2.0 + (sin(swing_t / 0.22 * PI) * 1.2 * swing_dir if swing_t > 0.0 else 0.0)
	gun.rotation.z = -tilt * 2.0 + rl * 0.9 - sway.x * 1.5
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
	if wd.type == "melee":
		swing_t = maxf(0.0, swing_t - delta)
		if Input.is_action_just_pressed("aim") and special_cd <= 0.0:
			_melee_special(weapon)
		if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
			_slash(wd)
		special_cd = maxf(0.0, special_cd - delta)
		return
	if wd.type == "beam":
		beam_on = Input.is_action_pressed("shoot") and ammo[weapon] > 0
	var trigger := Input.is_action_pressed("shoot") if wd.auto else Input.is_action_just_pressed("shoot")
	if weapon == 0:
		spin = minf(1.0, spin + delta * 0.8) if trigger else maxf(0.0, spin - delta * 2.0)
	if trigger and shoot_cd <= 0.0:
		_fire(wd)

var beam_on := false

var swing_t := 0.0
var swing_dir := 1.0
var special_cd := 0.0

# Nahkampf: alles im Bogen vor dir treffen, Klinge zerschlaegt Geschosse
func _slash(wd: Dictionary) -> void:
	shoot_cd = wd.rate
	swing_t = 0.22
	swing_dir = -swing_dir
	var fwd: Vector3 = -cam.global_basis.z
	var origin: Vector3 = cam.global_position
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var c: Vector3 = e.global_position + Vector3(0, 1.0, 0)
		var to: Vector3 = c - origin
		var reach: float = wd.range + (1.5 if e.is_in_group("boss") else 0.0)
		if to.length() < reach and fwd.dot(to.normalized()) > float(wd.arc):
			var dmg: int = wd.dmg + (1 if perfect[weapon] else 0)
			var crit := false
			if weapon == 9 and e.get("awake") == false:
				dmg = int(dmg * wd.crit)
				crit = true
			e.hit(dmg, to)
			main.hit_feedback(c, dmg, crit)
			main.burst(c, wd.col, 10)
			hit_any = true
	# Katana: Geschosse vor dir werden zerschlagen
	if weapon == 8:
		for pr in main.projs:
			var to2: Vector3 = pr.n.global_position - origin
			if to2.length() < wd.range + 0.8 and fwd.dot(to2.normalized()) > 0.3:
				pr.life = 0.0
				main.burst(pr.n.global_position, Color.WHITE, 8)
				hit_any = true
	main._tracer(origin + fwd * 0.6 + cam.global_basis.x * swing_dir * 0.8, origin + fwd * 1.4 - cam.global_basis.x * swing_dir * 0.8, wd.col, 0.02, 0.08)
	Game.sfx("jump", 2.4 if weapon == 8 else 3.0, 0.4)
	if hit_any:
		main.shake(0.12)
		Game.sfx("land", 1.8, 0.7)
	kick += 0.015

func _melee_special(w: int) -> void:
	var fwd: Vector3 = -cam.global_basis.z
	if w == 8:
		# Sprung-Schnitt: nach vorn schnellen und alles auf dem Weg treffen
		special_cd = 1.0
		velocity = Vector3(fwd.x, 0.15, fwd.z).normalized() * 22.0
		inv = maxf(inv, 0.3)
		shoot_cd = 0.0
		_slash(WEAPONS[8])
		main.shake(0.2)
	else:
		# Messer werfen: fliegt gerade, kommt nach kurzer Zeit zurueck in die Hand
		special_cd = 0.9
		var shot: Dictionary = WEAPONS[9].duplicate()
		shot.dmg = 4
		main.spawn_knife(muzzle.global_position, fwd, shot)
		models[9].visible = false
		get_tree().create_timer(0.9).timeout.connect(func(): if weapon == 9: models[9].visible = true)
		Game.sfx("jump", 3.0, 0.5)

func _do_ult(w: int) -> void:
	Game.unlock("ult")
	var col: Color = WEAPONS[w].col
	main.banner(ULT_NAMES[w], col)
	main.shake(0.5)
	Game.sfx("rail", 0.4, 1.0)
	main.burst(global_position + Vector3(0, 1, 0), col, 60)
	var fwd: Vector3 = -cam.global_basis.z
	match w:
		10:
			# REMEMBRANCE: Zeit steht still, jeder Gegner in der Naehe wird getroffen
			main.slowmo(1.5, 0.15)
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(global_position) < 45.0:
					main._tracer(muzzle.global_position, e.global_position + Vector3(0, 1.4, 0), col, 0.05, 0.4)
					e.hit(35, (e.global_position - global_position).normalized())
					main.hit_feedback(e.global_position + Vector3(0, 1.6, 0), 35, true)
		0, 3:
			ult_kind = w
			ult_t = 6.0
			ammo[w] = WEAPONS[w].mag
		1:
			# DRAGON BREATH: drei Feuerwellen nach vorn
			for k in 3:
				main.get_tree().create_timer(k * 0.25).timeout.connect(func():
					for j in 5:
						var dirj: Vector3 = fwd.rotated(Vector3.UP, (j - 2) * 0.22)
						main.explode(global_position + Vector3(0, 0.8, 0) + dirj * (4.0 + k * 3.5), 2.8, 4, Color("#ff6a2e")))
		2:
			# JUDGEMENT: ein Strahl, der durch alles geht
			var a: Vector3 = cam.global_position
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e):
					continue
				var to: Vector3 = e.global_position + Vector3(0, 1.2, 0) - a
				var along := to.dot(fwd)
				if along > 0.0 and (to - fwd * along).length() < 2.2:
					e.hit(40, fwd)
					main.hit_feedback(e.global_position + Vector3(0, 1.5, 0), 40, true)
			main._tracer(muzzle.global_position, a + fwd * 150.0, Color("#c77dff"), 0.35, 0.6)
			velocity -= fwd * 14.0
		4:
			# DEADEYE: Zeitlupe, dann trifft jeder Gegner in Sicht kritisch
			main.slowmo(1.2, 0.25)
			main.get_tree().create_timer(1.0, true, false, true).timeout.connect(func():
				for e in main.get_tree().get_nodes_in_group("enemies"):
					if is_instance_valid(e) and e.global_position.distance_to(global_position) < 40.0:
						var to: Vector3 = (e.global_position - global_position).normalized()
						if to.dot(fwd) > 0.3:
							main._tracer(muzzle.global_position, e.global_position + Vector3(0, 1.5, 0), Color("#ffe066"), 0.03, 0.2)
							e.hit(18, to)
							main.hit_feedback(e.global_position + Vector3(0, 1.6, 0), 18, true)
				Game.sfx("rail", 1.2, 1.0))
		5:
			# CLUSTER: 8 Bomben ringsum
			for j in 8:
				var dj: Vector3 = Vector3(cos(j * TAU / 8.0), 0, sin(j * TAU / 8.0))
				main.spawn_bomb(global_position + Vector3(0, 1.5, 0), dj * 10.0 + Vector3(0, 7.0, 0), WEAPONS[5].duplicate())
		6:
			# SLEEP: alle in der Naehe schlafen ein
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(global_position) < 20.0 and e.get("stun_t") != null:
					e.stun_t = 5.0
					e.hit(3, Vector3.UP)
			main.burst(global_position + Vector3(0, 1, 0), Color("#9fd8ff"), 120)
		7:
			# TSUNAMI: Welle, die alles wegschleudert
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(global_position) < 16.0:
					var away: Vector3 = (e.global_position - global_position).normalized()
					e.hit(10, away)
					if e.get("knock") != null:
						e.knock = away * 30.0
			main.overload_ring(global_position, Color("#4db8ff"))
		8:
			# THOUSAND CUTS: springt zu bis zu 6 Gegnern und schneidet
			inv = maxf(inv, 2.5)
			var targets: Array = []
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and e.global_position.distance_to(global_position) < 25.0:
					targets.append(e)
			targets.sort_custom(func(x, y): return x.global_position.distance_to(global_position) < y.global_position.distance_to(global_position))
			main.slowmo(1.5, 0.35)
			var k := 0
			for e in targets.slice(0, 6):
				main.get_tree().create_timer(k * 0.12, true, false, true).timeout.connect(func():
					if is_instance_valid(e):
						var from: Vector3 = global_position + Vector3(0, 1, 0)
						global_position = e.global_position - (e.global_position - global_position).normalized() * 1.2
						main._tracer(from, global_position + Vector3(0, 1, 0), Color("#ff4d6d"), 0.05, 0.3)
						e.hit(20, Vector3.UP)
						main.hit_feedback(e.global_position + Vector3(0, 1.5, 0), 20, true))
				k += 1
		9:
			# SHADOW STEP: hinter den naechsten Gegner, sofortiger Kill (dreimal)
			for k in 3:
				main.get_tree().create_timer(k * 0.35).timeout.connect(func():
					var best = main.enemy_in_cone(global_position, fwd, -1.0, 30.0)
					if best:
						var back: Vector3 = best.global_basis.z if best.get("visual") == null else best.visual.global_basis.z
						global_position = best.global_position + back.normalized() * 1.2
						yaw = atan2(best.global_position.x - global_position.x, best.global_position.z - global_position.z) + PI
						best.hit(30, Vector3.UP)
						main.hit_feedback(best.global_position + Vector3(0, 1.5, 0), 30, true)
						Game.sfx("jump", 3.0, 0.8))

func _update_reload(delta: float, wd: Dictionary) -> void:
	if int(wd.mag) == 0:
		return
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
	main.noise += [0.06, 0.14, 0.2, 0.03, 0.15, 0.18, 0.02, 0.08, 0.0, 0.0, 0.05][w]
	var shot := wd.duplicate()
	var bonus := 1 if perfect[w] else 0
	var last: bool = ammo[w] == 1
	if ult_kind == w and w in [0, 3]:
		ammo[w] += 1   # Ult: unendlich Munition
	ammo[w] -= 1
	shoot_cd = wd.rate
	shot.spread = float(wd.spread) * lerpf(1.0, 0.3, aim)
	shot.crit_always = false
	match w:
		0:
			shoot_cd = lerpf(wd.rate, 0.065, spin)
			shot.dmg = (2 if ammo[w] < 5 else 1) + bonus
			shot.spread = shot.spread + spin * 0.012 * (1.0 - aim * 0.7)
			if ammo[w] < 5:
				shot.col = Color("#eaffff")
		1:
			shot.dmg = (2 if slide_t > 0.0 or dash_t > 0.0 else 1) + bonus
			if last:
				shot.pellets = 14
				shot.col = Color("#ff4d2e")
		2:
			shot.dmg = int(round(wd.dmg * lerpf(0.6, 3.0, charge))) + bonus * 2
		3:
			shot.dmg = 1 + bonus
			shot.spread = float(wd.spread) * lerpf(1.0, 0.15, aim)
			if ult_kind == 3:
				shot.spread = 0.0
				shot.dmg = 2
		4:
			shot.dmg = wd.dmg + bonus * 2
			shot.crit_always = last
		_:
			shot.dmg = wd.dmg + bonus
	var snd: String = ["pulse", "scatter", "rail", "pulse", "rail", "scatter", "pulse", "scatter"][w]
	var pitch: float = [1.25 + spin * 0.25, 0.85 if not last else 0.6, 0.7 - charge * 0.25, 1.7, 0.95, 0.55, 2.2, 1.4][w]
	var vol: float = [0.5, 0.9, 1.0, 0.35, 1.0, 0.8, 0.15, 0.7][w]
	Game.sfx(snd, pitch * randf_range(0.96, 1.04), vol)
	if w == 4:
		Game.sfx("scatter", 0.5, 0.6)   # tiefer Knall unter dem Revolver
	recoil = [1.0, 2.2, 1.5 + charge * 1.5, 0.5, 2.6, 2.0, 0.15, 1.2][w] * lerpf(1.0, 0.6, aim)
	kick += [0.012 + spin * 0.006, 0.05, 0.04 + charge * 0.06, 0.006, 0.07, 0.04, 0.0, 0.02][w] * lerpf(1.0, 0.6, aim)
	flash_t = 0.05 if w != 6 else 0.0
	flash_light.light_color = shot.col.lerp(Color.WHITE, 0.5)
	if flash_mesh:
		flash_mesh.material_override.albedo_color = shot.col.lerp(Color.WHITE, 0.4)
	var fwd0: Vector3 = -cam.global_basis.z
	match wd.type:
		"lob":
			main.spawn_bomb(muzzle.global_position, fwd0 * 22.0 + Vector3(0, 4.0, 0) + velocity * 0.5, shot)
		"disc":
			main.spawn_disc(muzzle.global_position, fwd0, shot)
		"beam":
			var end: Vector3 = main.player_shoot(cam.global_position, fwd0, muzzle.global_position, shot)
			main.chain_from(end, shot, 3)
		_:
			if ult_kind == 0 and w == 0:
				shoot_cd = 0.045
				shot.pierce = true
				shot.dmg = 2
				shot.col = Color("#eaffff")
			for i in shot.pellets:
				var spread: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * float(shot.spread)
				var fwd: Vector3 = (fwd0 + cam.global_basis * spread).normalized()
				if ult_kind == 3 and w == 3:
					# SWARM: Kugeln suchen sich den naechsten Gegner im Blickfeld
					var tgt = main.enemy_in_cone(cam.global_position, fwd0, 0.8, 40.0)
					if tgt:
						fwd = (tgt.global_position + Vector3(0, 1.2, 0) - cam.global_position).normalized()
				var end: Vector3 = main.player_shoot(cam.global_position, fwd, muzzle.global_position, shot)
				if w == 1 and last and i == 0:
					main.explode(end, 3.0, 3, shot.col)
				if w == 2 and charge >= 0.95:
					main.explode(end, 3.5, 4, wd.col)
			if w != 2:
				main.spawn_casing(muzzle.global_position - cam.global_basis.z * -0.1, cam.global_basis.x * randf_range(2.0, 3.0) + Vector3(0, 2.5, 0), w == 1)
	if w in [1, 2, 4, 5]:
		main.shake([0, 0.15, 0.15 + charge * 0.25, 0, 0.12, 0.18][w])
	if w == 1:
		velocity -= fwd0 * 5.0
	elif w == 2:
		velocity -= fwd0 * (2.0 + charge * 8.0)

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
