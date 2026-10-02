extends Node
# Automatischer Durchlauf von Kapitel 1 in 3D (nur Entwicklung).

var main
var step := 0
var t := 0.0
var out_dir := "user://shots3d"
var pre := ""

func trig(id: String) -> Vector2i:
	for k in main.level.triggers:
		if main.level.triggers[k] == id:
			return k
	return Vector2i.ZERO
const T := 3.0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var args := OS.get_cmdline_user_args()
	Game.chapter = int(args[0]) if args.size() > 0 else 1
	Game.continue_game = false
	pre = "c%d_" % Game.chapter
	main = load("res://game3d.tscn").instantiate()
	add_child(main)
	print("AUTOTEST3D start")

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/" + pre + name + ".png")
	print("shot ", name)

func tp(x: float, z: float, yaw: float) -> void:
	main.player.global_position = Vector3(x * T + 1.5, 0.2, z * T + 1.5)
	main.player.yaw = yaw

func _process(delta: float) -> void:
	t += delta
	var p = main.player
	if main.dialog.active and step != 1 and step != 6 and step != 11:
		main.dialog.skip()
	if main.ch.get("peaceful", false):
		_meadow(delta)
		return
	match step:
		0:
			if t > 1.0: snap("01_title"); step = 1; t = 0
		1:
			if main.dialog.active and t > 1.5: snap("02_dialog"); main.dialog.skip(); step = 2; t = 0
		2:
			if t > 0.5:
				print("doors D after intro: ", main.level.doors_of("D").size(), " gun before: ", p.has_gun())
				if main.pickups.size() > 0: main._take(main.pickups[0])
				print("gun after pickup: ", p.unlocked)
				tp(main.door_cols[0] + 10, 14.5, -PI / 2); step = 3; t = 0
		3:
			p.inv = 99
			if t > 1.0 and t < 1.05: snap("03a_radio")
			p.pitch = -0.05
			Input.action_press("shoot")
			if t > 2.5: snap("03_scrapyard"); step = 4; t = 0
		4:
			Input.action_release("shoot")
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != main.boss and e.global_position.x < main.door_cols[1] * T: e.hit(99, Vector3.RIGHT)
			if t > 1.5:
				print("doors D remaining: ", main.level.doors_of("D").size())
				tp(main.door_cols[1] + 4, 14.5, -PI / 2); step = 5; t = 0
		5:
			p.inv = 99
			p.pitch = 0.1
			if t > 3.0:
				snap("04_drones")
				main.finish_event()
				var sp: Vector3 = main.shard_node.position
				p.global_position = Vector3(sp.x, 0.2, sp.z); step = 6; t = 0
		6:
			if main.dialog.active and t > 0.3: snap("05_shard"); main.dialog.skip(); step = 7; t = 0
		7:
			if t > 0.3:
				print("gate remaining: ", main.level.doors_of("G").size(), " shards ", main.shards)
				var c := trig("5")
				tp(c.x, c.y, -PI / 2); step = 8; t = 0
		8:
			if main.boss and main.boss.active and t > 0.5:
				Input.action_press("shoot"); step = 9; t = 0
		9:
			p.inv = 99
			if is_instance_valid(main.boss):
				var to: Vector3 = main.boss.global_position - p.cam.global_position
				p.yaw = atan2(-to.x, -to.z)
				p.pitch = atan2(to.y, Vector2(to.x, to.z).length())
			p.select_weapon(1)
			if Engine.get_frames_drawn() % 2 == 0: Input.action_press("shoot")
			else: Input.action_release("shoot")
			if t > 3.0: snap("06_boss_scatter"); step = 10; t = 0
		10:
			p.inv = 99
			if main.boss: main.boss.hp = mini(main.boss.hp, 50)
			p.select_weapon(2)
			if Engine.get_frames_drawn() % 2 == 0: Input.action_press("shoot")
			else: Input.action_release("shoot")
			if t > 1.0 and p.ability_cd <= 0.0:
				p.ability_cd = 8.0; main.overload(p.global_position); print("overload ok")
			if is_instance_valid(main.boss):
				var to: Vector3 = main.boss.global_position - p.cam.global_position
				p.yaw = atan2(-to.x, -to.z)
				p.pitch = atan2(to.y, Vector2(to.x, to.z).length())
			if t > 1.15 and t < 1.2: snap("07_overload")
			if t > 3.0: print("weapon ", p.weapon, " unlocked ", p.unlocked, " radio ", main.radio_line); snap("07b_rail"); main.boss.hit(999, Vector3.RIGHT); step = 11; t = 0
		11:
			Input.action_release("shoot")
			if main.dialog.active and t > 0.4: snap("08_victory"); main.dialog.skip(); step = 12; t = 0
		12:
			var drops: Array = main.pickups.filter(func(pk): return pk.cb.is_valid())
			if drops.size() > 0 and t > 0.3:
				print("boss drop: ", drops[0].kind, " ", drops[0].idx, " slots ", p.slots)
				main._take(drops[0])
				print("slots after: ", p.slots, " floor: ", main.pickups.map(func(pk): return pk.kind + str(pk.idx)))
			if t > 0.8 and drops.is_empty() and main.state == "play" and main.exit_node:
				print("exit open: ", main.objective)
				main.player.global_position = main.exit_node.position + Vector3(0, 0.2, 0)
				step = 13; t = 0
		13:
			if main.state == "transition" and t > 3.5 and t < 3.6: snap("09_transition")
			if t > 4.0:
				print("final state: ", main.state, " next chapter: ", Game.chapter)
				step = 14; t = 0
		14:
			print("AUTOTEST3D done"); get_tree().quit()

# Wiese: dem Hund folgen, streicheln, durch die Tuer
func _meadow(_delta: float) -> void:
	var p = main.player
	if main.dialog.active and step != 1 and step != 4:
		main.dialog.skip()
	if main.ch.get("afterworld", false):
		_afterworld()
		return
	match step:
		0:
			if t > 1.5: snap("01_title"); step = 1; t = 0
		1:
			if main.dialog.active and t > 1.0: snap("02_dialog"); main.dialog.skip(); step = 2; t = 0
			elif t > 4.0: step = 2; t = 0
		2:
			# dem Hund hinterher laufen (teleportieren in Etappen)
			var d: Vector3 = main.dog.position
			p.global_position = d + Vector3(-3, 0.2, 0)
			p.yaw = -PI / 2
			if t > 2.0 and t < 2.05: snap("03_follow")
			if main.dog_i >= main.dog_path.size() - 1 and main.dog.position.distance_to(main.dog_path[-1]) < 0.5:
				p.global_position = main.dog.position + Vector3(-1.5, 0.2, 0)
				snap("04_dog")
				main.pet_dog(); step = 4; t = 0
		4:
			if t > 0.5: step = 5; t = 0
		5:
			if t > 0.5 and main.exit_node:
				print("exit open: ", main.objective)
				p.global_position = main.exit_node.position + Vector3(0, 0.2, 0)
				step = 6; t = 0
		6:
			if t > 4.0:
				print("final state: ", main.state, " next chapter: ", Game.chapter)
				print("AUTOTEST3D done"); get_tree().quit()

# Welt nach dem Ende: alle Lichter einsammeln, Hund streicheln
func _afterworld() -> void:
	var p = main.player
	match step:
		0:
			if t > 2.0: snap("01_afterworld"); step = 1; t = 0
		1:
			if main.motes.size() > 0:
				p.global_position = main.motes[0].n.global_position + Vector3(0, -0.8, 0)
			elif t > 1.0:
				print("motes left: ", main.motes.size(), " found: ", Game.found.keys().filter(func(k): return k.begins_with("mote_")).size())
				p.global_position = main.dog.position + Vector3(-1.5, 0.2, 0)
				snap("02_afterworld_board")
				step = 2; t = 0
		2:
			if t > 2.0:
				print("achievements: ", Game.achievements.keys())
				print("final state: ", main.state)
				print("AUTOTEST3D done"); get_tree().quit()
