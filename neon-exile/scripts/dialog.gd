extends Control
# Dialogfenster mit Schreibmaschinen-Effekt. main.gd ruft start() auf.

const Story = preload("res://scripts/story.gd")
var lines: Array = []
var idx := 0
var shown := 0.0
var on_done: Callable
var active := false
var dlg_id := ""
var voice: AudioStreamPlayer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	voice = AudioStreamPlayer.new()
	voice.volume_db = 2.0
	voice.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(voice)

func start(id: String, done: Callable = Callable()) -> void:
	lines = Story.DIALOG[id]
	idx = 0
	shown = 0.0
	on_done = done
	active = true
	visible = true
	dlg_id = id
	_play_voice()

func _process(delta: float) -> void:
	if not active:
		return
	shown += delta * 55.0
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("dash"):
		var full: String = lines[idx][1]
		if shown < full.length():
			shown = full.length()
		else:
			idx += 1
			shown = 0.0
			voice.stop()
			if idx < lines.size():
				_play_voice()
			if idx >= lines.size():
				active = false
				visible = false
				if on_done.is_valid():
					on_done.call()
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var sz := get_viewport_rect().size
	var box := Rect2(60, sz.y - 200, sz.x - 120, 160)
	draw_rect(box, Color(0.02, 0.02, 0.06, 0.92))
	var who: String = lines[idx][0]
	var col: Color = Story.SPEAKERS.get(who, Color.WHITE)
	draw_rect(box, col, false, 2.0)
	draw_rect(Rect2(box.position.x, box.position.y - 34, 220, 34), Color(0.02, 0.02, 0.06, 0.92))
	draw_rect(Rect2(box.position.x, box.position.y - 34, 220, 34), col, false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, box.position + Vector2(14, -10), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
	var full: String = lines[idx][1]
	var txt := full.substr(0, int(shown))
	draw_multiline_string(font, box.position + Vector2(20, 38), txt, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 40, 22, -1, Color.WHITE)
	if shown >= full.length() and int(Time.get_ticks_msec() / 400) % 2 == 0:
		draw_string(font, box.end - Vector2(150, 14), "[E / Click] >", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.6))

# Fuer automatische Tests: Dialog sofort beenden
func skip() -> void:
	if not active:
		return
	voice.stop()
	active = false
	visible = false
	if on_done.is_valid():
		on_done.call()

# Vertonte Zeile abspielen (assets/voice/<dialog>_<index>.mp3), falls vorhanden
func _play_voice() -> void:
	var path := "res://assets/voice/%s_%d.ogg" % [dlg_id, idx]
	if ResourceLoader.exists(path):
		voice.stream = load(path)
		voice.play()
