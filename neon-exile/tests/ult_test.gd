extends Node
# Testet alle 10 Ults gegen eine Gruppe Gegner
var g
var t := 0.0
var k := 0
func _ready() -> void:
	Game.chapter = 3
	Game.continue_game = false
	Game.carry_chapter = 0
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if g.dialog.active: g.dialog.skip()
	g.title_t = 0
	g.player.inv = 99
	if t < 1.0:
		return
	if k < 10 and t > 1.0 + k * 1.6:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != g.boss: e.queue_free()
		for i in 5:
			var e = g.spawn_npc("hostile", g.player.global_position + Vector3(-6 - i, 0, i - 2))
			e.awake = true
		g.player.yaw = PI / 2
		g.player.give_weapon(k)
		g.player.ult = 100.0
		g.player._do_ult(k)
		print("ult ", k, " ", g.player.ULT_NAMES[k], " ok")
		k += 1
	if k >= 10 and t > 1.0 + 10 * 1.6 + 1.0:
		print("ULT TEST done, enemies left: ", get_tree().get_nodes_in_group("enemies").size())
		get_tree().quit()
