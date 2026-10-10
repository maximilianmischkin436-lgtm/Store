extends Node3D
# Nahaufnahmen der Kreaturen fuer die Optik-Kontrolle
const Figure = preload("res://scripts3d/figure.gd")
const XBot = preload("res://scripts3d/xbot.gd")
var bots: Array = []
const Boss = preload("res://scripts3d/boss3d.gd")
var bosses: Array = []
var t := 0.0
var cam: Camera3D

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.25, 0.22, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.85, 0.75)
	env.ambient_light_energy = 0.6
	env.tonemap_exposure = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.8, 0.7)
	env.fog_density = 0.02
	env.fog_light_color = Color(0.35, 0.3, 0.25)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, PI + 0.4, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	fl.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.75, 0.7, 0.6)
	fl.material_override = fm
	add_child(fl)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var cols := [Color(0.9, 0.88, 0.85), Color(0.85, 0.82, 0.8), Color(0.75, 0.8, 0.85), Color(0.95, 0.9, 0.85), Color(0.3, 0.32, 0.4), Color(0.95, 0.95, 0.97)]
	for i in 6:
		var v := Node3D.new()
		v.position = Vector3((i - 2.5) * 1.4, 0, 0)
		add_child(v)
		var b = XBot.new(v, cols[i], 0.6 if i < 3 else 1.0, Color(0.7, 0.9, 1.0) if i < 4 else Color(1.0, 0.8, 0.3), 1.0, 1.0, 1.0 if i < 5 else 1.4)
		b.head_tilt = 0.45 * (1 if i % 2 == 0 else -1)
		b.stretch = 1.3
		b.step = 1.0 / 12.0 if i % 2 == 0 else 0.0
		if i >= 3: b.bandage_head()
		b.hunch = 0.4
		b.twitch = 2.0
		v.set_meta("spd", [0.0, 1.2, 0.0, 6.0, 1.2, 0.0][i])
		if i == 0 or i == 2: b.sit()
		b.set_clothes({"skin": Color(0.85, 0.7, 0.6), "shirt": [Color(0.8,0.3,0.3), Color(0.3,0.4,0.7), Color(0.9,0.9,0.85)][i % 3], "pants": Color(0.2,0.22,0.35), "hair": Color(0.3,0.2,0.1)})
		bots.append(b)
	var bk := ["lifeguard", "mannequin", "headmaster", "nurse", "mirror", "conductor", "halcyon"]
	for i in bk.size():
		var b = Boss.new()
		b.cfg = {"kind": bk[i], "hp": 100}
		b.main = self
		b.position = Vector3((i - 3) * 5.0, 0, 14.0)
		add_child(b)
		b.set_physics_process(false)
		b.set_process(false)
		b.rotation.y = PI
		bosses.append(b)
	var kinds := []
	for i in kinds.size():
		var v := Node3D.new()
		v.position = Vector3((i - 2.5) * 1.3, 0, 0)
		v.rotation.y = PI + (i - 2.5) * 0.15
		add_child(v)
		var o := Figure.outfit(kinds[i], rng)
		var P := Figure.build(v, o, 0.55 if i < 4 else 1.0, 0.25, true)
		v.scale *= Vector3(0.9, 1.12, 0.9)
		P.neck.scale = Vector3(0.8, 1.6, 0.8)
		P.head.rotation.z = 0.4 * (1 if i % 2 == 0 else -1)
		for sd in [-1, 1]:
			P["el%d" % sd].scale = Vector3(0.85, 1.35, 0.85)
		Figure.liminal(v, Color(0.7, 0.9, 1.0) if i < 4 else Color(1.0, 0.85, 0.3), 1.0 if i < 4 else 1.3, 1.0)
	cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.4, -5.0)
	cam.look_at(Vector3(0, 1.1, 0))

func _process(delta: float) -> void:
	t += delta
	for b in bots:
		b.update(delta, b.root.get_parent().get_meta("spd"))
	for b in bosses:
		if b.xb: b.xb.update(delta, 0.0)
	if t > 1.5 and t - delta <= 1.5:
		_snap("creatures_a")
	if t > 2.3 and t - delta <= 2.3:
		cam.position = Vector3(-0.7, 1.5, -2.2)
		cam.look_at(Vector3(-0.7, 1.2, 0))
	if t > 3.0 and t - delta <= 3.0:
		_snap("creatures_close")
	if t > 3.6 and t - delta <= 3.6:
		cam.position = Vector3(0, 4.0, -6.0)
		cam.look_at(Vector3(0, 3.0, 14.0))
	if t > 4.3 and t - delta <= 4.3:
		_snap("bosses")
	if t > 4.4 and t - delta <= 4.4:
		cam.position = Vector3(-3.5 + 2.6, 1.0, -0.8)
		cam.look_at(Vector3(-3.5, 0.7, 0))
	if t > 4.8 and t - delta <= 4.8:
		_snap("sit")
	if t > 5.2:
		get_tree().quit()

func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/%s.png" % n)
	print("shot ", n)
