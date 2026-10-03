extends Node
# Rennt automatisch durch "THE LONG HALLWAY" (nur Entwicklung)
var main
var t := 0.0
var shots := 0
var spd := 7.0
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	spd = float(args[0]) if args.size() > 0 else 7.0
	Game.chapter = 11
	Game.continue_game = false
	main = load("res://game3d.tscn").instantiate()
	add_child(main)
func _process(delta: float) -> void:
	t += delta
	if main.dialog.active:
		main.dialog.skip()
	if t < 2.0:
		return
	if main.state == "wake" or main.state == "arrive" or main.state == "dialog":
		main.state = "play"
	var p = main.player
	if main.state == "play":
		p.global_position.x += spd * delta
		p.yaw = -PI / 2.0
	if (t > 14.0 and shots == 0) or (t > 30.0 and shots == 1):
		shots += 1
		p.yaw = PI / 2.0
		_snap("chase_%d" % shots)
	if main.state == "dead":
		print("CAUGHT at t=", snappedf(t, 0.1), " x=", snappedf(p.global_position.x, 0.1)); get_tree().quit()
	if main.state == "transition":
		print("REACHED DOOR at t=", snappedf(t, 0.1)); get_tree().quit()
	if t > 90.0:
		print("TIMEOUT x=", p.global_position.x, " door=", main.chase_door_x); get_tree().quit()
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/%s.png" % n)
	print("shot ", n)
