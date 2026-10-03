extends Node
# Prueft "Continue" mit Spielstand 2 (Fragment geholt)
var t := 0.0
var g
func _ready() -> void:
	Game.progress = 2
	Game.continue_game = true
	g = load("res://game3d.tscn").instantiate()
	add_child(g)
func _process(d: float) -> void:
	t += d
	if t > 0.5:
		print("CONTINUE pos=", g.player.global_position.round(), " unlocked=", g.player.unlocked, " ability=", g.player.ability_unlocked, " gate=", g.level.doors_of("G").size(), " enemies=", get_tree().get_nodes_in_group("enemies").size())
		get_tree().quit()
