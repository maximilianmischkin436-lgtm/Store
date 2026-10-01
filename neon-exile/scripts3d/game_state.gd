extends Node
# Autoload "Game": Einstellungen, Spielstand, Musik und Soundeffekte.

const SAVE_PATH := "user://save.cfg"
var sensitivity := 1.0
var music_vol := 0.7
var sfx_vol := 0.8
var fullscreen := false
var retro := true          # VHS-Filter + niedrige Aufloesung
var chapter := 1
var max_chapter := 1
var progress := 0          # 0 Start, 1 Schrottplatz geschafft, 2 Fragment, 3 Kapitel fertig
var best_time := 0.0
var continue_game := false

var music: AudioStreamPlayer
var current_track := ""
var sfx_pool: Array = []
var sounds := {}
var walk: AudioStreamPlayer

const SFX := {
	"pulse": "res://assets/kenney/sounds/blaster_repeater.ogg",
	"scatter": "res://assets/kenney/sounds/blaster.ogg",
	"rail": "res://assets/kenney/sounds/blaster.ogg",
	"enemy_shot": "res://assets/kenney/sounds/enemy_attack.ogg",
	"enemy_die": "res://assets/kenney/sounds/enemy_destroy.ogg",
	"enemy_hurt": "res://assets/kenney/sounds/enemy_hurt.ogg",
	"jump": "res://assets/kenney/sounds/jump_a.ogg",
	"land": "res://assets/kenney/sounds/land.ogg",
	"swap": "res://assets/kenney/sounds/weapon_change.ogg",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()
	music = AudioStreamPlayer.new()
	music.finished.connect(func(): music.play())
	add_child(music)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_pool.append(p)
	for k in SFX:
		sounds[k] = load(SFX[k])
	walk = AudioStreamPlayer.new()
	walk.stream = load("res://assets/kenney/sounds/walking.ogg")
	walk.finished.connect(func(): if walk.get_meta("on", false): walk.play())
	add_child(walk)
	apply_settings()

func apply_settings() -> void:
	music.volume_db = linear_to_db(maxf(0.001, music_vol * 0.6))
	walk.volume_db = linear_to_db(maxf(0.001, sfx_vol * 0.5))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func play_music(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	music.stream = load("res://assets/music/%s.ogg" % track)
	music.play()

func sfx(name: String, pitch: float = 1.0, vol: float = 1.0) -> void:
	if not sounds.has(name):
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = sounds[name]
			p.pitch_scale = pitch * randf_range(0.95, 1.05)
			p.volume_db = linear_to_db(maxf(0.001, sfx_vol * vol))
			p.play()
			return

func set_walking(on: bool) -> void:
	walk.set_meta("on", on)
	if on and not walk.playing:
		walk.play()
	elif not on and walk.playing:
		walk.stop()

func load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	sensitivity = cf.get_value("settings", "sensitivity", 1.0)
	music_vol = cf.get_value("settings", "music", 0.7)
	sfx_vol = cf.get_value("settings", "sfx", 0.8)
	fullscreen = cf.get_value("settings", "fullscreen", false)
	retro = cf.get_value("settings", "retro", true)
	progress = cf.get_value("progress", "stage", 0)
	chapter = cf.get_value("progress", "chapter", 1)
	max_chapter = cf.get_value("progress", "max_chapter", 1)
	best_time = cf.get_value("progress", "best_time", 0.0)

func write_save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("settings", "sensitivity", sensitivity)
	cf.set_value("settings", "music", music_vol)
	cf.set_value("settings", "sfx", sfx_vol)
	cf.set_value("settings", "fullscreen", fullscreen)
	cf.set_value("settings", "retro", retro)
	cf.set_value("progress", "stage", progress)
	cf.set_value("progress", "chapter", chapter)
	max_chapter = maxi(max_chapter, chapter)
	cf.set_value("progress", "max_chapter", max_chapter)
	cf.set_value("progress", "best_time", best_time)
	cf.save(SAVE_PATH)

func reach_stage(s: int) -> void:
	if s > progress:
		progress = s
		write_save()
