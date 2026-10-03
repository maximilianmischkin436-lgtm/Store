extends Node
# Rundgang mit Screenshots (nur Entwicklung): Klassenzimmer, Fenster, Rutschen
var main
var t := 0.0
var shots: Array = []
var i := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Game.chapter = int(args[0]) if args.size() > 0 else 4
	Game.continue_game = false
	main = load("res://game3d.tscn").instantiate()
	add_child(main)

func _process(delta: float) -> void:
	t += delta
	if main.dialog.active:
		main.dialog.skip()
	if t < 2.5:
		return
	main.state = "play"
	var p = main.player
	p.inv = 99
	var lv = main.level
	if shots.is_empty():
		if not lv.side_rooms.is_empty():
			var r = lv.side_rooms[3 % lv.side_rooms.size()]
			var c: Vector3 = r.pos
			# in der Tuer zum Flur stehen, in den Raum schauen
			shots.append([c + Vector3(1.5, 0.1, r.dir * 4.5), 0.0 if r.dir > 0 else PI, -0.1, "room"])
			shots.append([c + Vector3(0, 0.1, r.dir * 3.5), 0.0 if r.dir > 0 else PI, 0.05, "window"])
		if not lv.train_cells.is_empty():
			var c0: Vector3 = lv.cell_center(lv.train_cells[0])
			shots.append([c0 + Vector3(0.5, 0.1, 1.5), -PI / 2.0, 0.0, "train_in"])
			shots.append([c0 + Vector3(-5.0, 0.1, -4.0), -PI / 2.0 - 0.6, 0.0, "train_out"])
		if not lv.pits.is_empty():
			var pc: Vector3 = lv.cell_center(lv.pits[lv.pits.size() / 2])
			shots.append([pc + Vector3(0, 0.1, 4.5), 0.0, -0.6, "pit"])
		if not lv.swing.is_empty():
			var dp: Vector3 = lv.swing[2].pos
			shots.append([dp + Vector3(0, 0.1, 4.0), 0.0, 0.0, "door"])
		shots.append([main.checkpoint + Vector3(2, 0.1, 0), -PI / 2.0, 0.0, "corridor"])
		shots.append([main.checkpoint + Vector3(6, 0.1, -1), -PI / 2.0, 0.9, "sky"])
	var s = shots[i]
	p.global_position = s[0]
	p.yaw = s[1]
	p.pitch = s[2]
	if fmod(t, 0.8) < delta:
		_snap("tour_c%d_%s" % [Game.chapter, s[3]])
		i += 1
		if i >= shots.size():
			get_tree().quit()

func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/%s.png" % n)
	print("shot ", n)
