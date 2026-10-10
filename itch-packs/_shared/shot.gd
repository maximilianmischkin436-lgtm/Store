extends Node
## Takes screenshots of the demo for the store page (run with:  godot --path . -- shot <out_dir>)
var t := 0.0
var n := 0
var out := ""
var actions: Array = []    # [[time, callable_or_null, name]]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[1] if a.size() > 1 else "/tmp"
func _process(delta: float) -> void:
	t += delta
	while n < actions.size() and t >= actions[n][0]:
		var act = actions[n]
		if act[1] is Callable and act[1].is_valid():
			act[1].call()
		if act[2] != "":
			_snap(act[2])
		n += 1
	if n >= actions.size() and t > (actions[-1][0] + 0.5 if actions.size() > 0 else 2.0):
		get_tree().quit()
func _snap(nm: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + nm + ".png")
	print("shot ", nm)
