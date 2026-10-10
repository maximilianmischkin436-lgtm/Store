extends Node
# Screenshots der Traumwelt an mehreren Orten (Entwicklung)
var t := 0.0
var i := 0
var g
const SPOTS := [[4, 14, -1.2, 0.15], [25, 6, -2.2, 0.25], [33, 22, -0.4, 0.05], [47, 14, -1.57, 0.3], [62, 24, 2.4, 0.2], [72, 14, -1.57, 0.05]]
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://shots3d")
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if g.dialog.active: g.dialog.skip()
	g.player.inv = 99
	if g.title_t > 0: g.title_t = 0
	g.radio_line = []
	g.radio_queue = []
	for e in get_tree().get_nodes_in_group("enemies"): e.set_physics_process(false)
	if i < SPOTS.size():
		var s = SPOTS[i]
		g.player.global_position = Vector3(s[0] * 3 + 1.5, 0.2, s[1] * 3 + 1.5)
		g.player.yaw = s[2]; g.player.pitch = s[3]
		if t > 1.5:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots3d/w%d.png" % i)
			i += 1; t = 0
	else:
		get_tree().quit()
