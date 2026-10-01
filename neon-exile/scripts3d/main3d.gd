extends Node3D
# Kapitel 1 in First-Person: Welt, Licht, Spieler, Gegner, Projektile, Effekte, Story-Ablauf.

const Level = preload("res://scripts3d/level3d.gd")
const Player = preload("res://scripts3d/player3d.gd")
const Enemy = preload("res://scripts3d/enemy3d.gd")
const Boss = preload("res://scripts3d/boss3d.gd")
const Hud = preload("res://scripts3d/hud3d.gd")
const Dialog = preload("res://scripts/dialog.gd")

var level
var player
var boss
var hud
var dialog
var state := "play"          # play | dialog | dead | end
var checkpoint := Vector3.ZERO
var seen := {}
var shards := 0
var objective := ""
var banner_text := ""
var banner_col := Color.WHITE
var banner_t := 0.0
var title_t := 0.0
var shake_t := 0.0
var hurt_t := 0.0
var hitmark_t := 0.0
var play_time := 0.0
var deaths := 0
var shard_node: Node3D
var projs: Array = []        # [{n: MeshInstance3D, v: Vector3, life: float}]
var tracers: Array = []      # [{n: MeshInstance3D, life: float}]
var mats := {}
var proj_mesh := SphereMesh.new()

func _ready() -> void:
	_setup_input()
	_setup_world()
	level = Level.new()
	add_child(level)
	level.load_map("res://data/chapter1.txt")
	proj_mesh.radius = 0.2
	proj_mesh.height = 0.4
	for s in level.spawns:
		match s.c:
			"P":
				checkpoint = s.pos
			"c":
				spawn_enemy("crawler", s.pos)
			"d":
				spawn_enemy("drone", s.pos)
			"S":
				_make_shard(s.pos)
			"B":
				boss = Boss.new()
				boss.main = self
				boss.position = s.pos
				add_child(boss)
	player = Player.new()
	player.main = self
	player.position = checkpoint + Vector3(0, 0.1, 0)
	player.yaw = -PI / 2.0      # Blick nach Osten
	add_child(player)
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	hud.main = self
	ui.add_child(hud)
	dialog = Dialog.new()
	ui.add_child(dialog)
	title_t = 6.0
	objective = "Find a way out of the Sump"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "dash": [KEY_SHIFT], "shoot": [KEY_J], "interact": [KEY_E, KEY_ENTER],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shoot", m)

func _setup_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.008, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.3, 0.55)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.03, 0.14)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.55, 0.45, 1.0)
	sun.light_energy = 0.35
	sun.rotation = Vector3(-1.0, 0.6, 0)
	add_child(sun)

func can_control() -> bool:
	return state == "play"

func say(id: String, done: Callable = Callable()) -> void:
	state = "dialog"
	dialog.start(id, func():
		if state == "dialog":
			state = "play"
		if done.is_valid():
			done.call())

func banner(text: String, col: Color) -> void:
	banner_text = text
	banner_col = col
	banner_t = 2.5

func shake(t: float) -> void:
	shake_t = maxf(shake_t, t)

func _mat(col: Color, energy: float = 3.0) -> StandardMaterial3D:
	var key := col.to_html() + str(energy)
	if not mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color.BLACK
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		mats[key] = m
	return mats[key]

func spawn_enemy(kind: String, pos: Vector3) -> void:
	var e := Enemy.new()
	e.setup(self, kind)
	e.position = Vector3(pos.x, 0.1, pos.z)
	add_child(e)

func spawn_proj(pos: Vector3, vel: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = proj_mesh
	mi.material_override = _mat(col, 4.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	add_child(mi)
	projs.append({"n": mi, "v": vel, "life": 6.0})

func clear_projectiles() -> void:
	for p in projs:
		p.n.queue_free()
	projs.clear()

func player_shoot(origin: Vector3, dir: Vector3, muzzle: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 90.0, 1 | 4)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := origin + dir * 90.0
	if hit:
		end = hit.position
		var c = hit.collider
		if c and c.has_method("hit"):
			c.hit(1, dir)
			hitmark_t = 0.15
			burst(end, Color("#ffffff"), 6)
		else:
			burst(end, Color("#38f5c4"), 5)
	_tracer(muzzle, end)

func _tracer(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len_ab := a.distance_to(b)
	bm.size = Vector3(0.012, 0.012, len_ab)
	mi.mesh = bm
	mi.material_override = _mat(Color("#38f5c4"), 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (a + b) / 2.0
	if len_ab > 0.01:
		mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	tracers.append({"n": mi, "life": 0.06})

func burst(pos: Vector3, col: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radius = 0.06
	m.height = 0.12
	p.mesh = m
	p.material_override = _mat(col, 4.0)
	p.amount = n
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.6
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func _make_shard(pos: Vector3) -> void:
	shard_node = Node3D.new()
	shard_node.position = pos + Vector3(0, 1.4, 0)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radial_segments = 4
	sm.rings = 2
	sm.radius = 0.35
	sm.height = 1.0
	mi.mesh = sm
	mi.material_override = _mat(Color("#c77dff"), 5.0)
	shard_node.add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = Color("#c77dff")
	light.light_energy = 2.0
	light.omni_range = 8.0
	shard_node.add_child(light)
	add_child(shard_node)

func _process(delta: float) -> void:
	if state == "play" or state == "dialog":
		play_time += delta
	banner_t = maxf(0.0, banner_t - delta)
	title_t = maxf(0.0, title_t - delta)
	shake_t = maxf(0.0, shake_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	hitmark_t = maxf(0.0, hitmark_t - delta)
	player.cam.h_offset = randf_range(-1, 1) * 0.12 * shake_t if shake_t > 0.0 else 0.0
	player.cam.v_offset = randf_range(-1, 1) * 0.12 * shake_t if shake_t > 0.0 else 0.0
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if state == "play" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if title_t < 4.5 and not seen.has("intro"):
		seen["intro"] = true
		say("intro")
	if state == "dead" and Input.is_action_just_pressed("interact"):
		_respawn()
	if state == "play":
		_check_triggers()
		_check_doors()
		_check_shard()
		_update_projs(delta)
	for tr in tracers:
		tr.life -= delta
		if tr.life <= 0.0:
			tr.n.queue_free()
	tracers = tracers.filter(func(x): return x.life > 0.0)
	if shard_node:
		shard_node.rotation.y += delta * 1.5
		shard_node.position.y = 1.4 + sin(play_time * 3.0) * 0.15

func _update_projs(delta: float) -> void:
	var pc: Vector3 = player.center()
	for p in projs:
		p.n.position += p.v * delta
		p.life -= delta
		var pos: Vector3 = p.n.position
		if p.life <= 0.0 or level.solid(pos) or pos.y < 0.0:
			p.life = -1.0
			continue
		if pos.distance_to(pc) < 0.75:
			player.hurt(1)
			p.life = -1.0
	for p in projs:
		if p.life < 0.0:
			p.n.queue_free()
	projs = projs.filter(func(p): return p.life >= 0.0)

func _check_triggers() -> void:
	var c: Vector2i = level.cell_of(player.global_position)
	if not level.triggers.has(c):
		return
	var id: String = level.triggers[c]
	if seen.has(id):
		return
	seen[id] = true
	match id:
		"2":
			say("scrap")
			objective = "Get through the scrapyard"
		"3":
			say("drones")
			objective = "Recover the memory shard"
		"4":
			checkpoint = player.global_position
			say("gate")
			objective = "Defeat WARDEN-07"
		"5":
			if boss:
				say("boss", func():
					boss.active = true
					banner("WARDEN-07", Color("#ff2d55"))
					shake(0.5))

func _check_doors() -> void:
	var T: float = level.T
	if not seen.has("intro_done") and seen.has("intro"):
		seen["intro_done"] = true
		level.open_doors("D", 16 * T)
	if level.doors_of("D").is_empty():
		return
	var alive := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != boss and e.global_position.x < 43 * T and e.global_position.x > 15 * T:
			alive = true
	if not alive and level.doors_of("D").size() > 0 and player.global_position.x > 15 * T:
		level.open_doors("D", 44 * T)
		banner("DOOR UNLOCKED", Color("#38f5c4"))
		checkpoint = player.global_position

func _check_shard() -> void:
	if shard_node and player.global_position.distance_to(Vector3(shard_node.position.x, 0, shard_node.position.z)) < 1.6:
		burst(shard_node.position, Color("#c77dff"), 50)
		shard_node.queue_free()
		shard_node = null
		shards += 1
		checkpoint = player.global_position
		player.hp = player.max_hp
		say("shard", func():
			level.open_doors("G")
			objective = "Reach the lift"
			banner("GATE OPEN", Color("#ffd23d")))

func on_player_hurt() -> void:
	shake(0.3)
	hurt_t = 0.6
	if player.hp <= 0:
		state = "dead"
		deaths += 1
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _respawn() -> void:
	player.global_position = checkpoint + Vector3(0, 0.2, 0)
	player.velocity = Vector3.ZERO
	player.hp = player.max_hp
	player.inv = 1.5
	clear_projectiles()
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if boss and is_instance_valid(boss) and boss.active:
		boss.hp = mini(boss.max_hp, boss.hp + 35)
		boss.mode = "idle"
		boss.position = Vector3(86 * level.T + 1.5, 2.8, 14 * level.T + 1.5)
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss:
				e.queue_free()
	say("death")

func on_enemy_killed(_e) -> void:
	shake(0.1)

func on_boss_killed(b) -> void:
	burst(b.global_position, Color("#ff2d55"), 150)
	burst(b.global_position, Color.WHITE, 80)
	shake(1.0)
	b.queue_free()
	boss = null
	clear_projectiles()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	say("victory", func():
		state = "end"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
