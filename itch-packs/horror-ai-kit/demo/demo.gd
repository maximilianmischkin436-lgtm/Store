extends Node3D
## Demo: 1 = stealth room with watchers (stay out of the light cones), 2 = the stretching corridor chase.
var player
var label: Label
var mode := "stealth"
var corridor: StretchingCorridor
var chaser: HorrorChaser
var start_stealth := Vector3(-8, 0.2, 8)

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.45, 0.4)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.06, 0.05)
	env.fog_density = 0.03
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# stealth room
	var wall := StandardMaterial3D.new()
	wall.albedo_color = Color(0.7, 0.62, 0.5)
	var fl := StandardMaterial3D.new()
	fl.albedo_color = Color(0.35, 0.3, 0.28)
	_box(Vector3(0, -0.25, 0), Vector3(24, 0.5, 24), fl)
	_box(Vector3(0, 3.75, 0), Vector3(24, 0.5, 24), wall)
	for s in [-1, 1]:
		_box(Vector3(12 * s, 1.75, 0), Vector3(0.5, 3.5, 24), wall)
		_box(Vector3(0, 1.75, 12 * s), Vector3(24, 3.5, 0.5), wall)
	for p in [Vector3(-4, 1.75, 2), Vector3(4, 1.75, -2), Vector3(0, 1.75, 6), Vector3(-6, 1.75, -6), Vector3(6, 1.75, 5)]:
		_box(p, Vector3(1.6, 3.5, 1.6), wall)
	_box(Vector3(8, 1.2, -9), Vector3(1.6, 2.4, 0.2), _glow())
	player = preload("res://demo/fps_player.gd").new()
	add_child(player)
	for pts in [[Vector3(-9, 0, -3), Vector3(9, 0, -3)], [Vector3(2, 0, 9), Vector3(2, 0, -9), Vector3(-8, 0, 0)]]:
		var w := HorrorWatcher.new()
		w.patrol = pts
		w.target = player
		w.spotted.connect(func(_t): _fail("THEY SAW YOU"))
		add_child(w)
	# corridor + chaser (far away)
	corridor = StretchingCorridor.new()
	corridor.position = Vector3(0, 0, 100)
	corridor.target = player
	corridor.door_reached.connect(func(): _win())
	add_child(corridor)
	chaser = HorrorChaser.new()
	chaser.target = player
	chaser.caught.connect(func(_t): _fail("IT CAUGHT YOU"))
	add_child(chaser)
	var cl := CanvasLayer.new()
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 20)
	cl.add_child(label)
	add_child(cl)
	_stealth()
	if OS.get_cmdline_user_args().size() > 0 and OS.get_cmdline_user_args()[0] == "shot":
		label.visible = false
		var sh = preload("res://demo/shot.gd").new()
		sh.actions = [[2.0, null, "stealth"], [2.2, func(): _chase(), ""], [6.5, func(): player.rotation.y = PI / 2.0, ""], [6.8, null, "chase"]]
		add_child(sh)

func _glow() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.emission_enabled = true
	m.emission = Color(1, 0.95, 0.8)
	m.emission_energy_multiplier = 3.0
	return m

func _box(pos: Vector3, size: Vector3, m: Material) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	sb.add_child(mi)
	sb.position = pos
	add_child(sb)

func _stealth() -> void:
	mode = "stealth"
	chaser.stop()
	chaser.position = Vector3(0, -50, 0)
	player.global_position = start_stealth
	player.rotation.y = -PI * 0.25
	label.text = "STEALTH: reach the glowing door without being seen.   2 = corridor chase"

func _chase() -> void:
	mode = "chase"
	player.global_position = corridor.global_position + Vector3(2, 0.2, 0)
	player.rotation.y = -PI / 2.0
	corridor.start()
	chaser.start()
	label.text = "RUN (hold Shift). The door keeps running away...   1 = stealth room"

func _fail(t: String) -> void:
	label.text = t + " - try again"
	if mode == "stealth":
		_stealth()
	else:
		_chase()

func _win() -> void:
	chaser.stop()
	label.text = "YOU MADE IT.   1 = stealth room   2 = chase again"

func _physics_process(_d: float) -> void:
	if mode == "stealth" and player.global_position.distance_to(Vector3(8, 0, -9)) < 1.8:
		label.text = "YOU MADE IT.   2 = try the corridor chase"

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_1: _stealth()
		if e.keycode == KEY_2: _chase()
