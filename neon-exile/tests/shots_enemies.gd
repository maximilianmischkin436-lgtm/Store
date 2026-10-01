extends Node
# Portraet-Screenshots der Gegner (Entwicklung)
var t := 0.0
var g
var k := 0
var e1
var e2
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	Game.chapter = int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 1
	Game.continue_game = false
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if g.dialog.active: g.dialog.skip()
	if g.state == "wake": g.wake_t = 99
	g.title_t = 0; g.radio_line = []; g.radio_queue = []
	g.player.inv = 99
	if k == 0 and t > 0.5:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != g.boss: e.queue_free()
		var base: Vector3 = g.checkpoint + Vector3(0, 0.1, 0)
		g.player.global_position = base
		g.player.yaw = -PI / 2; g.player.pitch = 0.12
		e1 = g.Enemy.new(); e1.setup(g, "crawler"); e1.position = base + Vector3(4.5, 0.1, 0.8); g.add_child(e1)
		e2 = g.Enemy.new(); e2.setup(g, "drone"); e2.position = base + Vector3(7.5, 2.4, -1.8); g.add_child(e2)
		k = 1; t = 0
	elif k == 1:
		g.player.velocity = Vector3.ZERO
		g.player.global_position = g.checkpoint + Vector3(0, 0.1, 0)
		if t > 0.6:
			e1.set_physics_process(false); e2.set_physics_process(false)
		if t > 0.9:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/en_portrait_%d.png" % Game.chapter)
			get_tree().quit()
