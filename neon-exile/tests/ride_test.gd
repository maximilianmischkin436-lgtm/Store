extends Node
# Testet die Zugfahrt in Kapitel 7 (nur Entwicklung)
var main
var t := 0.0
var step := 0
func _ready() -> void:
	Game.chapter = 7
	Game.continue_game = false
	main = load("res://game3d.tscn").instantiate()
	add_child(main)
func _process(delta: float) -> void:
	t += delta
	if main.dialog.active:
		main.dialog.skip()
	if t < 2.5:
		return
	var p = main.player
	p.inv = 99
	main.has_ticket = true
	match step:
		0:
			main.state = "play"
			main.level.open_doors("D")
			var ra: Rect2 = main.level.trains[0]
			p.global_position = Vector3(ra.get_center().x, 0.2, ra.get_center().y)
			p.yaw = PI / 2.0
			print("trains: ", main.level.trains)
			step = 1; t = 2.5
		1:
			if main.ride == "ride" and t > 6.0:
				_snap("ride_c7")
				step = 2
			if t > 8.0 and main.ride == "wait":
				print("RIDE did not start, objective: ", main.objective); get_tree().quit()
		2:
			if main.ride == "done":
				print("arrived at ", p.global_position, " objective: ", main.objective)
				_snap("ride_arrive")
				step = 3; t = 0
		3:
			if t > 0.5:
				print("RIDE done"); get_tree().quit()
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/%s.png" % n)
	print("shot ", n)
