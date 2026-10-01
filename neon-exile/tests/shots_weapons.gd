extends Node
# Screenshots: jede Waffe in der Hand + alle Waffen als Pickups am Boden
var t := 0.0
var g
var k := 3
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	Game.chapter = 4
	Game.continue_game = false
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if g.dialog.active: g.dialog.skip()
	g.title_t = 0; g.radio_line = []; g.radio_queue = []
	g.player.inv = 99
	for e in get_tree().get_nodes_in_group("enemies"): e.queue_free()
	g.player.global_position = g.checkpoint + Vector3(0, 0.1, 0)
	g.player.yaw = -PI / 2; g.player.pitch = -0.05
	if t > 0.6:
		if k <= 9:
			g.player.give_weapon(k)
			if t > 1.0:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("user://shots3d/weapon_%d.png" % k)
				k += 1; t = 0.5
		elif k == 10:
			for pk in g.pickups.duplicate(): g._take(pk)
			for i in 10: g.spawn_pickup("weapon", i, g.checkpoint + Vector3(3.0, 0, -4.5 + i * 1.0))
			g.player.pitch = -0.35
			k = 11; t = 0
		elif t > 1.0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/weapon_pickups.png")
			get_tree().quit()
