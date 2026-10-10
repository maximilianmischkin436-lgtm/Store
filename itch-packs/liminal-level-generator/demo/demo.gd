extends Node3D
## Demo: R = new seed, 1/2/3 = style (rooms / halls / pool). Walk with WASD + mouse.
var builder: LiminalLevelBuilder
var player
var env: Environment
var style := "rooms"
var seed_v := 1
var label: Label

func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.35, 0.25, 0.45)
	sm.sky_horizon_color = Color(1.0, 0.6, 0.35)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.82, 0.72)
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color(0.9, 0.7, 0.55)
	env.fog_density = 0.01
	env.glow_enabled = true
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.35, 1.2, 0)
	sun.light_color = Color(1.0, 0.7, 0.45)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	builder = LiminalLevelBuilder.new()
	add_child(builder)
	builder.fell_into_pit.connect(func(b): if b == player: _respawn())
	builder.reached_exit.connect(func(b): if b == player: seed_v += 1; _generate())
	player = preload("res://demo/fps_player.gd").new()
	player.add_to_group("door_openers")
	add_child(player)
	var cl := CanvasLayer.new()
	label = Label.new()
	label.position = Vector2(16, 12)
	cl.add_child(label)
	add_child(cl)
	_generate()
	if OS.get_cmdline_user_args().size() > 0 and OS.get_cmdline_user_args()[0] == "shot":
		label.visible = false
		var sh = preload("res://demo/shot.gd").new()
		sh.actions = [
			[1.0, func(): _look(builder.start_position + Vector3(12, 0, 1.5), -PI / 2.0, 0.0), ""], [1.6, null, "corridor"],
			[1.8, func(): _look_room(), ""], [2.4, null, "classroom"],
			[2.6, func(): style = "pool"; _generate(); _look(builder.start_position + Vector3(30, 0, 1.5), -PI / 2.0, -0.25), ""], [3.4, null, "pool"],
			[3.6, func(): style = "halls"; seed_v = 4; _generate(); _look(builder.start_position + Vector3(25, 0, 1.5), -PI / 2.0 + 0.3, 0.0), ""], [4.4, null, "halls"]]
		add_child(sh)

func _look(p: Vector3, yaw: float, pitch: float) -> void:
	player.global_position = p + Vector3(0, 0.2, 0)
	player.rotation.y = yaw
	player.pitch = pitch
	player.cam.rotation.x = pitch
	player.set_physics_process(false)

func _look_room() -> void:
	var r = builder.side_rooms[2]
	_look(r.pos + Vector3(2.0, 0, r.dir * 4.0), 0.0 if r.dir > 0 else PI, 0.0)

func _generate() -> void:
	var cols := {"rooms": [Color(0.86, 0.8, 0.68), Color(0.6, 0.35, 0.3)], "halls": [Color(0.82, 0.78, 0.55), Color(0.55, 0.5, 0.35)], "pool": [Color(0.86, 0.93, 0.95), Color(0.8, 0.9, 0.93)]}
	var wm := StandardMaterial3D.new()
	wm.albedo_color = cols[style][0]
	wm.roughness = 0.35 if style == "pool" else 0.8
	var fm := StandardMaterial3D.new()
	fm.albedo_color = cols[style][1]
	fm.roughness = 0.3 if style == "pool" else 0.9
	builder.wall_material = wm
	builder.floor_material = fm
	builder.ceiling_material = wm
	builder.build(LiminalLevelGen.generate(seed_v, style, 3, style == "rooms"))
	_respawn()
	label.text = "style: %s   seed: %d      R new seed   1 rooms   2 halls   3 pool" % [style, seed_v]

func _respawn() -> void:
	player.global_position = builder.start_position + Vector3(0, 0.2, 0)
	player.velocity = Vector3.ZERO
	player.rotation.y = -PI / 2.0

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_R: seed_v += 1; _generate()
			KEY_1: style = "rooms"; _generate()
			KEY_2: style = "halls"; _generate()
			KEY_3: style = "pool"; _generate()
