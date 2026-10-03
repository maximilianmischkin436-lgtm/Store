extends Node
var t := 0.0
var g
var times := [1.4, 2.5, 4.5, 6.2, 8.5]
var k := 0
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	Game.continue_game = false
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if k < times.size() and t > times[k]:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots3d/wake%d.png" % k)
		print("wake shot ", k, " state ", g.state)
		k += 1
	if k >= times.size():
		g.dialog.skip(); g.player.global_position = Vector3(33 * 3, 0.2, 13 * 3); g.player.yaw = 0.4; g.player.pitch = 0.0
		g.title_t = 0; g.radio_line = []
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != g.boss: e.awake = true
		if t > 11.0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/enemies.png")
			get_tree().quit()
