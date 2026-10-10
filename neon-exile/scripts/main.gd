extends Node2D
# Spielsteuerung fuer Kapitel 1: Level, Spieler, Gegner, Kugeln, Effekte, Story-Ablauf.

const Level = preload("res://scripts/level.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Boss = preload("res://scripts/boss.gd")
const Hud = preload("res://scripts/hud.gd")
const Dialog = preload("res://scripts/dialog.gd")

var level
var player
var boss
var hud
var dialog
var camera: Camera2D
var fx: Node2D
var bullets: Array = []
var particles: Array = []
var state := "play"          # play | dialog | dead | end
var checkpoint := Vector2.ZERO
var seen := {}
var shards := 0
var objective := ""
var banner_text := ""
var banner_col := Color.WHITE
var banner_t := 0.0
var title_t := 0.0
var shake_t := 0.0
var play_time := 0.0
var deaths := 0
var shard_node: Node2D

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var friendly: bool
	var dmg: int
	var col: Color
	var life := 3.0
	var dead := false

func _ready() -> void:
	_setup_input()
	level = Level.new()
	add_child(level)
	level.load_map("res://data/chapter1.txt")
	fx = Node2D.new()
	fx.z_index = 5
	fx.draw.connect(_draw_fx)
	add_child(fx)
	for s in level.spawns:
		match s.c:
			"P":
				checkpoint = s.pos
			"c":
				spawn_enemy("crawler", s.pos)
			"d":
				spawn_enemy("drone", s.pos)
			"S":
				shard_node = Node2D.new()
				shard_node.position = s.pos
				shard_node.draw.connect(_draw_shard)
				add_child(shard_node)
			"B":
				boss = Boss.new()
				boss.main = self
				boss.position = s.pos
				add_child(boss)
	player = Player.new()
	player.main = self
	player.position = checkpoint
	add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = level.w * level.TILE
	camera.limit_bottom = level.h * level.TILE
	player.add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	hud.main = self
	ui.add_child(hud)
	dialog = Dialog.new()
	ui.add_child(dialog)
	title_t = 6.0
	objective = "Find a way out of the Sump"

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"dash": [KEY_SPACE, KEY_SHIFT], "shoot": [KEY_J], "interact": [KEY_E, KEY_ENTER],
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

func can_control() -> bool:
	return state == "play"

func say(id: String, done: Callable = Callable()) -> void:
	state = "dialog"
	dialog.start(id, func():
		state = "play" if state == "dialog" else state
		if done.is_valid():
			done.call())

func banner(text: String, col: Color) -> void:
	banner_text = text
	banner_col = col
	banner_t = 2.5

func shake(t: float) -> void:
	shake_t = maxf(shake_t, t)

func spawn_enemy(kind: String, pos: Vector2) -> void:
	var e := Enemy.new()
	e.setup(self, kind)
	e.position = pos
	add_child(e)

func spawn_bullet(pos: Vector2, vel: Vector2, friendly: bool, dmg: int, col: Color) -> void:
	var b := Bullet.new()
	b.pos = pos
	b.vel = vel
	b.friendly = friendly
	b.dmg = dmg
	b.col = col
	bullets.append(b)

func burst(pos: Vector2, col: Color, n: int) -> void:
	for i in n:
		var a := randf() * TAU
		var v := randf_range(60, 280)
		particles.append({"p": pos, "v": Vector2.from_angle(a) * v, "life": randf_range(0.3, 0.7), "c": col})

func _process(delta: float) -> void:
	if state == "play" or state == "dialog":
		play_time += delta
	banner_t = maxf(0.0, banner_t - delta)
	title_t = maxf(0.0, title_t - delta)
	shake_t = maxf(0.0, shake_t - delta)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * shake_t / 0.5 if shake_t > 0.0 else Vector2.ZERO
	if title_t < 4.5 and not seen.has("intro"):
		seen["intro"] = true
		say("intro")
	if state == "dead" and Input.is_action_just_pressed("interact"):
		_respawn()
	if state == "play":
		_check_triggers()
		_check_doors()
		_check_shard()
	_update_bullets(delta)
	for p in particles:
		p.p += p.v * delta
		p.v *= 0.92
		p.life -= delta
	particles = particles.filter(func(p): return p.life > 0.0)
	fx.queue_redraw()
	if shard_node:
		shard_node.queue_redraw()

func _update_bullets(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for b in bullets:
		if state != "play" and state != "dialog":
			break
		if state == "dialog":
			continue
		b.pos += b.vel * delta
		b.life -= delta
		if b.life <= 0.0 or level.solid(b.pos):
			b.dead = true
			burst(b.pos, b.col, 3)
			continue
		if b.friendly:
			for e in enemies:
				if is_instance_valid(e) and e.global_position.distance_to(b.pos) < e.radius + 5.0:
					e.hit(b.dmg, b.vel)
					b.dead = true
					burst(b.pos, b.col, 4)
					break
		elif player.global_position.distance_to(b.pos) < 14.0:
			player.hurt(b.dmg)
			b.dead = true
	bullets = bullets.filter(func(b): return not b.dead)

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
					shake(0.4))
				level.grid[13][70] = "#"   # Arena schliessen (nur optisch)

func _check_doors() -> void:
	for door_x in [15, 43]:
		var cells: Array = level.doors_of("D")
		var here := cells.filter(func(c): return c.x == door_x)
		if here.is_empty():
			continue
		var left_alive := false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and e.global_position.x < door_x * level.TILE and (door_x == 15 or e.global_position.x > 15 * level.TILE):
				left_alive = true
		if door_x == 15 and not seen.has("intro_done"):
			if state == "play" and seen.has("intro"):
				seen["intro_done"] = true
				level.open_doors("D", 16 * level.TILE)
			continue
		if not left_alive and player.global_position.x < door_x * level.TILE:
			level.open_doors("D", (door_x + 1) * level.TILE)
			banner("DOOR UNLOCKED", Color("#38f5c4"))
			checkpoint = player.global_position

func _check_shard() -> void:
	if shard_node and player.global_position.distance_to(shard_node.position) < 34.0:
		burst(shard_node.position, Color("#c77dff"), 40)
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
	shake(0.25)
	burst(player.global_position, Color("#38f5c4"), 14)
	if player.hp <= 0:
		state = "dead"
		deaths += 1
		burst(player.global_position, Color("#38f5c4"), 50)

func _respawn() -> void:
	player.global_position = checkpoint
	player.hp = player.max_hp
	player.inv = 1.5
	bullets.clear()
	state = "play"
	if boss and is_instance_valid(boss) and boss.active:
		boss.hp = mini(boss.max_hp, boss.hp + 30)   # Boss heilt etwas, damit der Tod zaehlt
		boss.position = Vector2(86, 14) * level.TILE
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss:
				e.queue_free()
	say("death")

func on_enemy_killed(_e) -> void:
	shake(0.08)

func on_boss_killed(b) -> void:
	burst(b.global_position, Color("#ff2d55"), 120)
	burst(b.global_position, Color.WHITE, 60)
	shake(0.8)
	b.queue_free()
	boss = null
	bullets.clear()
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	say("victory", func():
		state = "end")

func _draw_fx() -> void:
	for b in bullets:
		fx.draw_circle(b.pos, 11.0, Color(b.col, 0.15))
		fx.draw_circle(b.pos, 6.0, b.col)
		fx.draw_circle(b.pos, 2.5, Color.WHITE)
	for p in particles:
		fx.draw_circle(p.p, 3.0, Color(p.c, clampf(p.life * 2.0, 0.0, 1.0)))

func _draw_shard() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var c := Color("#c77dff")
	shard_node.draw_circle(Vector2.ZERO, 30.0 + sin(t * 4.0) * 4.0, Color(c, 0.12))
	var pts := PackedVector2Array()
	for i in 4:
		pts.append(Vector2(0, -18 if i % 2 == 0 else -10).rotated(i * PI / 2.0 + t))
	shard_node.draw_colored_polygon(PackedVector2Array([Vector2(0, -20), Vector2(10, 0), Vector2(0, 20), Vector2(-10, 0)]), c)
	shard_node.draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
