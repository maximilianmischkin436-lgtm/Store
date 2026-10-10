extends Node
# Automatischer Durchlauf von Kapitel 1 (nur fuer Entwicklung):
# godot --path . res://tests/autotest.tscn

var main
var step := 0
var t := 0.0
var shots := 0
var out_dir := "user://shots"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://main.tscn").instantiate()
	add_child(main)
	print("AUTOTEST start")

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir + "/" + name + ".png")
	print("shot ", name)

func _process(delta: float) -> void:
	t += delta
	var p = main.player
	match step:
		0:
			if t > 2.0:
				snap("01_title"); step = 1; t = 0
		1:
			if main.dialog.active and t > 1.5:
				snap("02_dialog"); step = 2; t = 0
		2:
			main.dialog.skip(); 
			if main.state == "play" and t > 0.5:
				print("doors D open after intro: ", main.level.doors_of("D").size())
				p.global_position = Vector2(26, 15) * 48; step = 3; t = 0
		3:
			if main.dialog.active: main.dialog.skip()
			Input.action_press("shoot")
			if t > 2.0:
				snap("03_combat"); step = 4; t = 0
		4:
			Input.action_release("shoot")
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != main.boss and e.global_position.x < 43 * 48: e.hit(99, Vector2.RIGHT)
			if t > 0.5:
				print("door B remaining: ", main.level.doors_of("D").size())
				p.global_position = Vector2(48, 15) * 48; step = 5; t = 0
		5:
			if main.dialog.active: main.dialog.skip()
			if t > 2.5:
				snap("04_drones"); step = 6; t = 0
		6:
			p.hp = p.max_hp
			p.global_position = Vector2(54, 15) * 48
			if main.dialog.active and t > 0.3:
				snap("05_shard"); main.dialog.skip(); step = 7; t = 0
		7:
			print("gate remaining: ", main.level.doors_of("G").size(), " shards ", main.shards)
			p.global_position = Vector2(74, 15) * 48; step = 8; t = 0
		8:
			if main.dialog.active: main.dialog.skip()
			if main.boss and main.boss.active and t > 1.0:
				p.inv = 99
				Input.action_press("shoot")
				step = 9; t = 0
		9:
			p.inv = 99
			if t > 3.0:
				snap("06_boss"); step = 10; t = 0
		10:
			p.inv = 99
			if main.boss: main.boss.hp = 30
			if t > 3.0:
				snap("07_boss_phase3"); step = 11; t = 0
		11:
			p.inv = 99
			if main.boss: main.boss.hit(999, Vector2.RIGHT)
			if main.dialog.active and t > 0.5:
				snap("08_victory"); main.dialog.skip(); step = 12; t = 0
		12:
			Input.action_release("shoot")
			if main.dialog.active: main.dialog.skip()
			if t > 0.8:
				print("final state: ", main.state)
				snap("09_end"); step = 13; t = 0
		13:
			if t > 0.5:
				print("AUTOTEST done")
				get_tree().quit()
