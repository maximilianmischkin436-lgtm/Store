extends Node
# Screenshots von Menue, Waffen und Drohne (Entwicklung)
var t := 0.0
var step := 0
var g
func snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots3d/" + n + ".png")
	print("shot ", n)
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	var m = load("res://menu.tscn").instantiate()
	add_child(m)
func _process(d: float) -> void:
	t += d
	match step:
		0:
			if t > 1.0: snap("10_menu"); step = 1; t = 0
		1:
			for c in get_children(): c.queue_free()
			g = load("res://game3d.tscn").instantiate(); add_child(g); step = 2; t = 0
		2:
			if g.dialog.active: g.dialog.skip()
			if t > 0.5:
				g.player.unlocked = [true, true, true]
				g.player.global_position = Vector3(47 * 3, 0.2, 15 * 3); g.player.yaw = -PI / 2; g.player.pitch = 0.05
				g.player.inv = 99
				step = 3; t = 0
		3:
			if g.dialog.active: g.dialog.skip()
			g.player.inv = 99
			if t > 1.5: snap("11_pulse"); g.player.select_weapon(1); step = 4; t = 0
		4:
			g.player.inv = 99
			if t > 0.6: snap("12_scatter"); g.player.select_weapon(2); step = 5; t = 0
		5:
			g.player.inv = 99
			if t > 0.6: snap("13_rail"); step = 6; t = 0
		6:
			print("progress saved: ", Game.progress); get_tree().quit()
