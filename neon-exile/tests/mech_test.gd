extends Node
# Prueft Waechter, Becken-Tod und Farbschloss (nur Entwicklung)
var main
var t := 0.0
var step := 0
var ch := 4

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	ch = int(args[0]) if args.size() > 0 else 4
	Game.chapter = ch
	Game.continue_game = false
	main = load("res://game3d.tscn").instantiate()
	add_child(main)

func _process(delta: float) -> void:
	t += delta
	if main.dialog.active:
		main.dialog.skip()
	if t < 2.5:
		return
	var p = main.player
	match step:
		0:
			main.state = "play"
			print("watchers: ", get_tree().get_nodes_in_group("watchers").size(), " puzzle: ", main.puzzle_seq, " pits: ", main.level.pits.size(), " doors: ", main.level.swing.size(), " train: ", main.level.train_cells.size())
			# Raetsel loesen
			for k in main.puzzle_seq:
				main._puzzle_press(k, MeshInstance3D.new())
			print("puzzle solved: ", main.puzzle_solved)
			var ws := get_tree().get_nodes_in_group("watchers")
			if ws.size() > 0:
				var w = ws[0]
				var tgt: Vector3 = w.b if w.to_b else w.a
				var fwd: Vector3 = (tgt - w.global_position); fwd.y = 0
				p.global_position = w.global_position + fwd.normalized() * 3.0 + Vector3(0, 0.1, 0)
				print("watcher at ", w.global_position, " player at ", p.global_position)
				step = 1
			elif main.level.pits.size() > 0:
				p.global_position = main.level.cell_center(main.level.pits[0]) + Vector3(0, 1.0, 0)
				step = 1
			else:
				step = 2
			t = 2.5
		1:
			if main.state == "dead" or t > 6.0:
				print("state after danger: ", main.state, " banner: ", main.banner_text)
				step = 2
		2:
			print("MECH done")
			get_tree().quit()
