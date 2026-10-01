extends Control
# Hauptmenue mit Einstellungen. Hintergrund: animiertes Neon-Raster.

var t := 0.0
var main_box: VBoxContainer
var settings_box: VBoxContainer
var chap_box: VBoxContainer
const DEV_ALL_CHAPTERS := true   # waehrend der Entwicklung: alle Kapitel waehlbar
var font := ThemeDB.fallback_font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.play_music("pool")
	main_box = _box()
	if (Game.progress > 0 and Game.progress < 3) or Game.chapter > 1:
		_button(main_box, "CONTINUE  (CH. %d)" % Game.chapter, func(): _start(true))
	_button(main_box, "NEW GAME", func(): _start(false))
	_button(main_box, "CHAPTERS", func(): main_box.visible = false; chap_box.visible = true)
	_button(main_box, "SETTINGS", func(): main_box.visible = false; settings_box.visible = true)
	_button(main_box, "QUIT", func(): get_tree().quit())
	chap_box = _box()
	chap_box.visible = false
	var names := ["1  THE DRAIN", "2  THE NEON MARKET", "3  THE ARCHIVE", "4  AFTER SCHOOL"]
	for i in names.size():
		var n := i + 1
		if n <= Game.max_chapter or DEV_ALL_CHAPTERS:
			_button(chap_box, names[i], func(): Game.chapter = n; Game.progress = 0; Game.continue_game = false; Game.write_save(); get_tree().change_scene_to_file("res://game3d.tscn"))
	_button(chap_box, "BACK", func(): chap_box.visible = false; main_box.visible = true)
	settings_box = _box()
	settings_box.visible = false
	_slider(settings_box, "Mouse sensitivity", 0.2, 3.0, Game.sensitivity, func(v): Game.sensitivity = v)
	_slider(settings_box, "Music volume", 0.0, 1.0, Game.music_vol, func(v): Game.music_vol = v; Game.apply_settings())
	_slider(settings_box, "Sound volume", 0.0, 1.0, Game.sfx_vol, func(v): Game.sfx_vol = v; Game.apply_settings(); Game.sfx("pulse"))
	var fs := CheckBox.new()
	fs.text = "Fullscreen"
	fs.button_pressed = Game.fullscreen
	fs.add_theme_font_size_override("font_size", 20)
	fs.toggled.connect(func(on): Game.fullscreen = on; Game.apply_settings())
	settings_box.add_child(fs)
	var rt := CheckBox.new()
	rt.text = "Retro VHS look"
	rt.button_pressed = Game.retro
	rt.add_theme_font_size_override("font_size", 20)
	rt.toggled.connect(func(on): Game.retro = on)
	settings_box.add_child(rt)
	_button(settings_box, "BACK", func(): Game.write_save(); settings_box.visible = false; main_box.visible = true)

func _box() -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", 14)
	b.set_anchors_preset(Control.PRESET_CENTER)
	b.position = Vector2(-160, -10)
	b.custom_minimum_size = Vector2(320, 0)
	add_child(b)
	return b

func _style(col: Color, fill: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(col, fill)
	s.border_color = col
	s.set_border_width_all(2)
	s.set_content_margin_all(10)
	return s

func _button(parent: Node, label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("normal", _style(Color("#38f5c4"), 0.05))
	b.add_theme_stylebox_override("hover", _style(Color("#38f5c4"), 0.25))
	b.add_theme_stylebox_override("pressed", _style(Color("#ff4df0"), 0.3))
	b.add_theme_stylebox_override("focus", _style(Color("#ff4df0"), 0.1))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(func(): Game.sfx("swap"); cb.call())
	parent.add_child(b)

func _slider(parent: Node, label: String, lo: float, hi: float, val: float, cb: Callable) -> void:
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 18)
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(320, 24)
	s.value_changed.connect(cb)
	parent.add_child(s)

func _start(cont: bool) -> void:
	Game.continue_game = cont
	if not cont:
		Game.progress = 0
		Game.chapter = 1
		Game.write_save()
	get_tree().change_scene_to_file("res://game3d.tscn")

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var sz := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.008, 0.03))
	# Perspektivisches Raster (Horizont bei 55%)
	var hy := sz.y * 0.55
	for i in range(-14, 15):
		draw_line(Vector2(sz.x / 2 + i * 30, hy), Vector2(sz.x / 2 + i * 260, sz.y), Color(0.3, 0.3, 1, 0.35), 1.5)
	for i in 12:
		var f := fmod(i / 12.0 + t * 0.08, 1.0)
		var y := hy + (sz.y - hy) * f * f
		draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.3, 0.3, 1, 0.35 * f), 1.5)
	draw_circle(Vector2(sz.x / 2, hy - 40), 120, Color(1, 0.3, 0.6, 0.15))
	draw_string(font, Vector2(0, sz.y * 0.28), "NEON EXILE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 84, Color.WHITE)
	draw_string(font, Vector2(0, sz.y * 0.28 + 40), "REMEMBER WHAT YOU WERE MADE FOR", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color("#ff4df0"))
	if Game.best_time > 0:
		draw_string(font, Vector2(0, sz.y - 30), "Best chapter 1 time: %ds" % int(Game.best_time), HORIZONTAL_ALIGNMENT_CENTER, sz.x, 14, Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(0, sz.y - 14), "Models & sounds: Kenney (MIT)", HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 20, 11, Color(1, 1, 1, 0.3))
