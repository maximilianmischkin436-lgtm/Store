extends Node3D
# Kapitel 1 in First-Person: Welt, Licht, Spieler, Gegner, Projektile, Effekte, Story-Ablauf.

const Level = preload("res://scripts3d/level3d.gd")
const Player = preload("res://scripts3d/player3d.gd")
const Enemy = preload("res://scripts3d/enemy3d.gd")
const Boss = preload("res://scripts3d/boss3d.gd")
const Hud = preload("res://scripts3d/hud3d.gd")
const Dialog = preload("res://scripts/dialog.gd")
const Chapters = preload("res://scripts3d/chapters.gd")
var ch: Dictionary
var chapter := 1
var door_cols: Array = []     # x-Spalten der beiden Tueren D
var gate_col := 0

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
	chapter = clampi(Game.chapter, 1, Chapters.CHAPTERS.size())
	ch = Chapters.CHAPTERS[chapter - 1]
	_setup_input()
	_setup_world()
	level = Level.new()
	level.setup(ch)
	add_child(level)
	level.load_map(ch.map)
	var xs := {}
	for c in level.doors_of("D"):
		xs[c.x] = true
	door_cols = xs.keys()
	door_cols.sort()
	for c in level.doors_of("G"):
		gate_col = c.x
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
				boss.cfg = ch.boss
				boss.position = s.pos
				add_child(boss)
	player = Player.new()
	player.main = self
	player.position = checkpoint + Vector3(0, 0.1, 0)
	player.yaw = -PI / 2.0      # Blick nach Osten
	add_child(player)
	_dust()
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	hud.main = self
	ui.add_child(hud)
	dialog = Dialog.new()
	ui.add_child(dialog)
	objective = ch.objectives[0]
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Game.play_music(ch.music)
	if chapter == 1:
		state = "wake"
		wake_t = 0.0
	else:
		state = "play"
		title_t = 6.0
		player.unlocked = [true, true, true]
		player.ability_unlocked = true
	if Game.continue_game and Game.progress > 0:
		state = "play"
		_apply_progress(Game.progress)

# Story-ID fuer das aktuelle Kapitel (Kapitel 2+ haben eigene Texte mit Praefix)
func sid(id: String) -> String:
	var pre := "c%d_%s" % [chapter, id]
	if chapter > 1 and (Story.DIALOG.has(pre) or Story.RADIO.has(pre)):
		return pre
	return id

# Spielstand fortsetzen: Bereiche, die schon geschafft sind, ueberspringen
func _apply_progress(stage: int) -> void:
	var T: float = level.T
	seen["intro"] = true
	seen["intro_done"] = true
	title_t = 0.0
	shards = chapter - 1
	if stage >= 1:
		seen["2"] = true
		level.open_doors("D")
		player.unlocked[1] = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.position.x < door_cols[1] * T:
				e.queue_free()
		checkpoint = Vector3((door_cols[1] + 1.5) * T, 0, 14.5 * T)
		objective = ch.objectives[2]
	if stage >= 2:
		seen["3"] = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.position.x < gate_col * T:
				e.queue_free()
		if shard_node:
			shard_node.queue_free()
			shard_node = null
		shards = chapter
		player.unlocked[2] = true
		player.ability_unlocked = true
		level.open_doors("G")
		checkpoint = Vector3((gate_col + 2.5) * T, 0, 14.5 * T)
		objective = ch.objectives[3]
	player.position = checkpoint + Vector3(0, 0.2, 0)
	radio("death")

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "dash": [KEY_SHIFT], "shoot": [KEY_J], "interact": [KEY_E, KEY_ENTER],
		"menu": [KEY_M], "weapon1": [KEY_1], "weapon2": [KEY_2], "weapon3": [KEY_3], "ability": [KEY_Q],
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

var dream_rect: ColorRect
var dream_mat: ShaderMaterial
var glitch_t := 0.0
var wake_t := 0.0
const WAKE_LEN := 7.0

# Aufwachen: liegend, Blick nach oben ins Dachfenster, Augen blinzeln, langsam aufrichten
func _update_wake(delta: float) -> void:
	wake_t += delta
	var k := clampf((wake_t - 3.0) / 3.5, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	player.head.position.y = lerpf(0.25, 1.6, e)
	player.pitch = lerpf(1.25, 0.0, e)
	player.cam.rotation.z = lerpf(0.5, 0.0, e) + sin(wake_t * 1.3) * 0.03 * (1.0 - e)
	player.gun.visible = wake_t > 5.5
	glitch_t = maxf(glitch_t, 0.35 * (1.0 - clampf(wake_t / 4.0, 0.0, 1.0)))
	if wake_t > 1.2 and wake_t < 1.3:
		Game.sfx("land", 0.5, 0.5)
	if wake_t >= WAKE_LEN:
		player.cam.rotation.z = 0.0
		state = "play"
		title_t = 6.0

func eyelid() -> float:
	# 0 = Augen zu, 1 = offen
	if state != "wake":
		return 1.0
	var t := wake_t
	if t < 1.0: return 0.0
	if t < 1.6: return (t - 1.0) / 0.6 * 0.35
	if t < 2.0: return 0.35 - (t - 1.6) / 0.4 * 0.35
	if t < 2.6: return (t - 2.0) / 0.6 * 0.6
	if t < 2.9: return 0.6 - (t - 2.6) / 0.3 * 0.4
	return clampf(0.2 + (t - 2.9) / 1.2, 0.0, 1.0)
var dream_time := 0.0

func _setup_world() -> void:
	# Poolrooms: heller, leicht bewoelkter Nachmittagshimmel, weisser Dunst
	var sky_mat := ProceduralSkyMaterial.new()
	var ev: Dictionary = ch.env
	sky_mat.sky_top_color = ev.sky_top
	sky_mat.sky_horizon_color = ev.sky_hor
	sky_mat.ground_horizon_color = ev.sky_hor
	sky_mat.ground_bottom_color = ev.sky_top
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = ev.amb
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = ev.exp
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = ev.fog
	env.fog_density = ev.fog_d
	env.fog_sky_affect = 0.3
	env.adjustment_enabled = true
	env.adjustment_saturation = ev.sat
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = ev.sun
	sun.light_energy = ev.sun_e
	sun.rotation = ev.sun_rot
	sun.shadow_enabled = true
	add_child(sun)
	# niedrige Aufloesung fuer den Retro-Look (UI bleibt scharf)
	if Game.retro:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		get_viewport().scaling_3d_scale = 0.66
	# VHS-Filter ueber dem ganzen Bild
	var post := CanvasLayer.new()
	post.layer = 0
	add_child(post)
	dream_rect = ColorRect.new()
	dream_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dream_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dream_mat = ShaderMaterial.new()
	dream_mat.shader = load("res://scripts3d/dream.gdshader")
	dream_mat.set_shader_parameter("strength", 0.45 if Game.retro else 0.0)
	dream_rect.material = dream_mat
	dream_rect.visible = Game.retro
	post.add_child(dream_rect)

func _dust() -> void:
	# langsam schwebende Lichtpartikel rund um den Spieler
	var p := CPUParticles3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.5)
	m.emission_enabled = true
	m.emission = Color(1, 1, 0.95)
	m.emission_energy_multiplier = 1.0
	qm.material = m
	p.mesh = qm
	p.amount = 160
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(16, 6, 16)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	p.gravity = Vector3(0, 0.03, 0)
	p.local_coords = false
	p.position = Vector3(0, 3, 0)
	player.add_child(p)

func can_control() -> bool:
	return state == "play"

func say(id: String, done: Callable = Callable()) -> void:
	state = "dialog"
	dialog.start(id, func():
		if state == "dialog":
			state = "play"
		if done.is_valid():
			done.call())

# Funk: laeuft nebenbei, das Spiel pausiert nicht
var radio_queue: Array = []
var radio_line: Array = []
var radio_t := 0.0
const Story = preload("res://scripts/story.gd")

func radio(id: String) -> void:
	for l in Story.RADIO[id]:
		radio_queue.append(l)

func _update_radio(delta: float) -> void:
	radio_t -= delta
	if radio_t <= 0.0:
		if radio_queue.is_empty():
			radio_line = []
		else:
			radio_line = radio_queue.pop_front()
			radio_t = 2.0 + radio_line[1].length() * 0.045

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
	mi.material_override = _mat(col, 0.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	add_child(mi)
	projs.append({"n": mi, "v": vel, "life": 6.0})

func clear_projectiles() -> void:
	for p in projs:
		p.n.queue_free()
	projs.clear()

func player_shoot(origin: Vector3, dir: Vector3, muzzle: Vector3, wd: Dictionary) -> void:
	var rng: float = wd.range
	var end := origin + dir * rng
	var exclude: Array[RID] = []
	var space := get_world_3d().direct_space_state
	# Durchschlagende Waffen treffen mehrere Gegner hintereinander
	for i in (8 if wd.pierce else 1):
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * rng, 1 | 4, exclude)
		var hit := space.intersect_ray(q)
		if not hit:
			break
		end = hit.position
		var c = hit.collider
		if c and c.has_method("hit"):
			c.hit(wd.dmg, dir)
			hitmark_t = 0.15
			burst(end, Color.WHITE, 6)
			exclude.append(hit.rid)
			if not wd.pierce:
				break
		else:
			burst(end, wd.col, 5)
			break
	if wd.pierce:
		end = end if end.distance_to(origin) < rng - 0.1 else origin + dir * rng
	_tracer(muzzle, end, wd.col, 0.05 if wd.pierce else 0.012, 0.25 if wd.pierce else 0.06)

func overload(pos: Vector3) -> void:
	# Faehigkeit: Schockwelle um ECHO, schadet, schleudert weg, loescht Projektile
	shake(0.5)
	burst(pos + Vector3(0, 1, 0), Color("#c77dff"), 80)
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9
		tm.outer_radius = 1.0
		ring.mesh = tm
		ring.material_override = _mat(Color("#c77dff"), 3.0)
		ring.position = pos + Vector3(0, 0.4 + i * 0.5, 0)
		add_child(ring)
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector3.ONE * 9.0, 0.35 + i * 0.08)
		tw.tween_callback(ring.queue_free)
	clear_projectiles()
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(pos) < 9.0:
			e.hit(4, e.global_position - pos)

func _tracer(a: Vector3, b: Vector3, col: Color, thick: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len_ab := a.distance_to(b)
	bm.size = Vector3(thick, thick, len_ab)
	mi.mesh = bm
	mi.material_override = _mat(col, 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = (a + b) / 2.0
	if len_ab > 0.01:
		mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	tracers.append({"n": mi, "life": life})

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
		if state == "play":
			state = "paused"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif state == "paused":
			state = "play"
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if state == "end" and Input.is_action_just_pressed("interact") and chapter < Chapters.CHAPTERS.size():
		Game.chapter = chapter + 1
		Game.progress = 0
		Game.continue_game = false
		Game.write_save()
		get_tree().reload_current_scene()
		return
	if (state == "paused" or state == "end") and Input.is_action_just_pressed("menu"):
		Game.write_save()
		get_tree().change_scene_to_file("res://menu.tscn")
		return
	if state == "play" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if state == "wake":
		_update_wake(delta)
	if state == "play" and title_t > 0.0 and title_t < 4.5 and not seen.has("intro"):
		seen["intro"] = true
		say(sid("intro"), func(): radio(sid("controls")))
	_update_radio(delta)
	dream_time += delta
	level.dream_update(delta, player.global_position, dream_time)
	# seltene kurze Traum-Stoerung (Glitch), staerker bei Erinnerungen
	glitch_t = maxf(0.0, glitch_t - delta)
	if randf() < delta * 0.03:
		glitch_t = 0.25
	dream_mat.set_shader_parameter("glitch", glitch_t * 2.0)
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
			radio(sid("scrap"))
			objective = ch.objectives[1]
		"3":
			radio(sid("drones"))
			objective = ch.objectives[2]
		"4":
			checkpoint = player.global_position
			radio(sid("gate"))
			objective = ch.objectives[4]
		"5":
			if boss:
				say(sid("boss"), func():
					Game.play_music("boss")
					boss.active = true
					banner(ch.boss.name, Color("#ff4d6d"))
					shake(0.5))

func _check_doors() -> void:
	var T: float = level.T
	if door_cols.size() < 2:
		return
	if not seen.has("intro_done") and seen.has("intro"):
		seen["intro_done"] = true
		level.open_doors("D", (door_cols[0] + 1) * T)
	if level.doors_of("D").is_empty():
		return
	var alive := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != boss and e.global_position.x < door_cols[1] * T and e.global_position.x > door_cols[0] * T:
			alive = true
	if not alive and player.global_position.x > door_cols[0] * T:
		level.open_doors("D", (door_cols[1] + 1) * T)
		banner("DOOR UNLOCKED", Color("#38f5c4"))
		Game.reach_stage(1)
		checkpoint = player.global_position
		if not player.unlocked[1]:
			player.unlocked[1] = true
			radio("scatter")

func _check_shard() -> void:
	if shard_node and player.global_position.distance_to(Vector3(shard_node.position.x, 0, shard_node.position.z)) < 1.6:
		burst(shard_node.position, Color("#c77dff"), 50)
		shard_node.queue_free()
		shard_node = null
		shards = chapter
		checkpoint = player.global_position
		player.hp = player.max_hp
		glitch_t = 1.2
		Game.reach_stage(2)
		var first_time: bool = not player.unlocked[2]
		say(sid("shard"), func():
			player.unlocked[2] = true
			player.ability_unlocked = true
			if first_time:
				radio("rail")
			level.open_doors("G")
			objective = ch.objectives[3]
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
		boss.position = boss.spawn_pos
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss:
				e.queue_free()
	radio("death")

func on_enemy_killed(_e) -> void:
	shake(0.1)

func on_boss_killed(b) -> void:
	burst(b.global_position, Color("#dfe9ec"), 150)
	burst(b.global_position, Color.WHITE, 80)
	shake(1.0)
	b.queue_free()
	boss = null
	clear_projectiles()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	Game.play_music(ch.music)
	Game.sfx("enemy_die", 0.5, 1.0)
	if Game.best_time <= 0.0 or play_time < Game.best_time:
		Game.best_time = play_time
	Game.reach_stage(3)
	Game.write_save()
	say(sid("victory"), func():
		state = "end"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
