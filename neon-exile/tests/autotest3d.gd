extends Node
# Automatischer Durchlauf von Kapitel 1 in 3D (nur Entwicklung).

var main
var step := 0
var t := 0.0
var out_dir := "user://shots3d"
const T := 3.0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://game3d.tscn").instantiate()
	add_child(main)
	print("AUTOTEST3D start")

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/" + name + ".png")
	print("shot ", name)

func tp(x: float, z: float, yaw: float) -> void:
	main.player.global_position = Vector3(x * T + 1.5, 0.2, z * T + 1.5)
	main.player.yaw = yaw

func _process(delta: float) -> void:
	t += delta
	var p = main.player
	if main.dialog.active and step != 1 and step != 6 and step != 11:
		main.dialog.skip()
	match step:
		0:
			if t > 1.0: snap("01_title"); step = 1; t = 0
		1:
			if main.dialog.active and t > 1.5: snap("02_dialog"); main.dialog.skip(); step = 2; t = 0
		2:
			if t > 0.5:
				print("doors D after intro: ", main.level.doors_of("D").size())
				tp(25, 14.5, -PI / 2); step = 3; t = 0
		3:
			p.inv = 99
			p.pitch = -0.05
			Input.action_press("shoot")
			if t > 2.5: snap("03_scrapyard"); step = 4; t = 0
		4:
			Input.action_release("shoot")
			for e in get_tree().get_nodes_in_group("enemies"):
				if e != main.boss and e.global_position.x < 43 * T: e.hit(99, Vector3.RIGHT)
			if t > 0.5:
				print("doors D remaining: ", main.level.doors_of("D").size())
				tp(47, 14.5, -PI / 2); step = 5; t = 0
		5:
			p.inv = 99
			p.pitch = 0.1
			if t > 3.0: snap("04_drones"); tp(54, 15, -PI / 2); step = 6; t = 0
		6:
			if main.dialog.active and t > 0.3: snap("05_shard"); main.dialog.skip(); step = 7; t = 0
		7:
			if t > 0.3:
				print("gate remaining: ", main.level.doors_of("G").size(), " shards ", main.shards)
				tp(74, 14.5, -PI / 2); step = 8; t = 0
		8:
			if main.boss and main.boss.active and t > 0.5:
				Input.action_press("shoot"); step = 9; t = 0
		9:
			p.inv = 99
			if is_instance_valid(main.boss):
				var to: Vector3 = main.boss.global_position - p.cam.global_position
				p.yaw = atan2(-to.x, -to.z)
				p.pitch = atan2(to.y, Vector2(to.x, to.z).length())
			if t > 3.0: snap("06_boss"); step = 10; t = 0
		10:
			p.inv = 99
			if main.boss: main.boss.hp = mini(main.boss.hp, 40)
			if is_instance_valid(main.boss):
				var to: Vector3 = main.boss.global_position - p.cam.global_position
				p.yaw = atan2(-to.x, -to.z)
				p.pitch = atan2(to.y, Vector2(to.x, to.z).length())
			if t > 3.0: snap("07_boss_phase3"); main.boss.hit(999, Vector3.RIGHT); step = 11; t = 0
		11:
			Input.action_release("shoot")
			if main.dialog.active and t > 0.4: snap("08_victory"); main.dialog.skip(); step = 12; t = 0
		12:
			if t > 0.8:
				print("final state: ", main.state)
				snap("09_end"); step = 13; t = 0
		13:
			if t > 0.5: print("AUTOTEST3D done"); get_tree().quit()
