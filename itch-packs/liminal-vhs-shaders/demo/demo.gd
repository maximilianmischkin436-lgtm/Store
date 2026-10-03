extends Node3D
## Demo: walk around (WASD/mouse). 1 = VHS on/off, 2 = flashback, 3 = hallucination, 4 = glitch, 5/6 = VHS strength.
var fx: LiminalFX
var env: Environment
var lines := ["you were there", "it's always 4 PM here", "don't run near the pool", "who is picking you up?", "she waited by the window"]

func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.85, 0.9, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.92, 0.95)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.92, 0.95)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-1.0, 0.5, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	add_child(sun)
	# pool-like room: tiled floor/walls, columns
	var tile := StandardMaterial3D.new()
	tile.albedo_color = Color(0.86, 0.92, 0.94)
	tile.roughness = 0.3
	_box(Vector3(0, -0.25, 0), Vector3(40, 0.5, 40), tile)
	_box(Vector3(0, 6.25, 0), Vector3(40, 0.5, 40), tile)
	for s in [-1, 1]:
		_box(Vector3(20 * s, 3, 0), Vector3(0.5, 6, 40), tile)
		_box(Vector3(0, 3, 20 * s), Vector3(40, 6, 0.5), tile)
	for x in range(-12, 13, 8):
		for z in range(-12, 13, 8):
			var c := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.5
			cm.bottom_radius = 0.5
			cm.height = 6
			c.mesh = cm
			c.material_override = tile
			c.position = Vector3(x, 3, z)
			add_child(c)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.4, 0.75, 0.9, 0.35)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.05
	water.material_override = wm
	water.position.y = 0.1
	add_child(water)
	# figures with the liminal shell (in group "liminal_hide": they vanish during hallucinations)
	for i in 5:
		var fig := Node3D.new()
		fig.position = Vector3(-4 + i * 2, 0, 2.5 - absf(i - 2) * 0.8)
		add_child(fig)
		fig.add_to_group("liminal_hide")
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.8
		body.mesh = cap
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color(0.9, 0.88, 0.86)
		body.material_override = bm
		body.position.y = 0.9
		fig.add_child(body)
		LiminalFX.apply_shell(fig, [Color(0.7, 0.9, 1), Color(1, 0.6, 0.8), Color(1, 0.85, 0.3), Color(0.5, 1, 0.8), Color(1, 1, 1)][i])
	var p = preload("res://demo/fps_player.gd").new()
	p.position = Vector3(0, 0.1, 8)
	add_child(p)
	fx = LiminalFX.new()
	add_child(fx)
	var help := Label.new()
	help.text = "1 VHS on/off   2 flashback   3 hallucination   4 glitch   5/6 VHS strength"
	help.position = Vector2(16, 12)
	var cl := CanvasLayer.new()
	cl.layer = 60
	cl.add_child(help)
	add_child(cl)
	if OS.get_cmdline_user_args().size() > 0 and OS.get_cmdline_user_args()[0] == "shot":
		help.visible = false
		var sh = preload("res://demo/shot.gd").new()
		sh.actions = [[1.5, null, "cover"], [2.2, func(): fx.flashback("you were there"), ""], [2.9, null, "flashback"], [4.5, func(): fx.hallucinate(env, 3.0), ""], [5.0, null, "hallucination"]]
		add_child(sh)

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

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_1: fx.set_vhs(not fx.vhs_on)
			KEY_2: fx.flashback(lines[randi() % lines.size()])
			KEY_3: fx.hallucinate(env, 4.0)
			KEY_4: fx.glitch(0.6)
			KEY_5: fx.set_vhs(true, maxf(0.0, fx.vhs_strength - 0.1))
			KEY_6: fx.set_vhs(true, minf(1.0, fx.vhs_strength + 0.1))
