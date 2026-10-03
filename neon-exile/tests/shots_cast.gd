extends Node
# Screenshots: Bewohner + Boss je Kapitel (Entwicklung)
var t := 0.0
var g
var k := 0
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	Game.chapter = int(OS.get_cmdline_user_args()[0])
	Game.continue_game = false
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if g.dialog.active: g.dialog.skip()
	if g.state == "wake": g.wake_t = 99
	g.title_t = 0; g.radio_line = []; g.radio_queue = []
	g.player.inv = 99
	if not g.player.has_gun(): g.player.give_weapon(0)
	if k == 0 and t > 0.4:
		for e in get_tree().get_nodes_in_group("npcs"): e.queue_free()
		var base: Vector3 = g.checkpoint
		g.player.global_position = base + Vector3(0, 0.1, 0)
		g.player.yaw = -PI / 2; g.player.pitch = 0.1
		var roles := ["passive", "passive", "hostile", "special"]
		for i in roles.size():
			var n = g.spawn_npc(roles[i], base + Vector3(4.0 + i * 0.4, 0, -2.4 + i * 1.6))
			n.rotation.y = 0
		k = 1; t = 0
	elif k == 1:
		g.player.global_position = g.checkpoint + Vector3(0, 0.1, 0); g.player.velocity = Vector3.ZERO
		if t > 0.5:
			for e in get_tree().get_nodes_in_group("npcs"):
				e.set_physics_process(false); e.visual.visible = true
				e.visual.rotation.y = PI / 2
		if t > 0.8:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/cast_%d.png" % Game.chapter)
			for e in get_tree().get_nodes_in_group("npcs"): e.queue_free()
			var bp: Vector3 = g.boss.global_position
			g.player.global_position = bp + Vector3(-13, 0.2, 0)
			g.player.yaw = -PI / 2; g.player.pitch = 0.22
			g.boss.active = true
			k = 2; t = 0
	elif k == 2:
		g.player.inv = 99
		var bp2: Vector3 = g.boss.global_position
		var to: Vector3 = bp2 + Vector3(0, 2.5, 0) - g.player.cam.global_position
		g.player.yaw = atan2(-to.x, -to.z); g.player.pitch = atan2(to.y, Vector2(to.x, to.z).length())
		if t > 3.5:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/boss_%d.png" % Game.chapter)
			get_tree().quit()
