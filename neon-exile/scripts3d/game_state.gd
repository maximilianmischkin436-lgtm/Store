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
	"dog": "res://assets/sfx/dog.ogg",
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
		if ResourceLoader.exists(SFX[k]):
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

var amb: AudioStreamPlayer
var current_amb := ""

# Hintergrund-Geraeusche je Ort (Wasser, Neon-Brummen, Uhr-Ticken...)
func play_ambience(theme: String) -> void:
	if theme == current_amb:
		return
	current_amb = theme
	if amb == null:
		amb = AudioStreamPlayer.new()
		amb.volume_db = -6.0
		amb.finished.connect(func(): amb.play())
		add_child(amb)
	var path := "res://assets/amb/%s.ogg" % theme
	if ResourceLoader.exists(path):
		amb.stream = load(path)
		amb.play()
	else:
		amb.stop()

func play_music(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	var path := "res://assets/music/%s.ogg" % track
	if not ResourceLoader.exists(path):
		path = "res://assets/music/school.ogg"
	music.stream = load(path)
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

# Waffen, die ins naechste Kapitel mitgenommen werden
var carry_slots: Array = []
var carry_ability := false
var carry_chapter := 0

# ---------- Erfolge & Sammelfortschritt (bleibt ueber alle Spielstaende) ----------
const ACH := {
	"first_blood": ["FIRST BLOOD", "Defeat your first enemy"],
	"lifeguard": ["NO RUNNING", "Defeat THE LIFEGUARD"],
	"mannequin": ["LOST & FOUND", "Defeat LOST & FOUND"],
	"mnemos": ["UNSIGNED", "Defeat MNEMOS"],
	"headmaster": ["DETENTION OVER", "Defeat THE HEADMASTER"],
	"nurse": ["VISITING HOURS", "Defeat THE NIGHT NURSE"],
	"mirror": ["FACE YOURSELF", "Defeat ECHO"],
	"conductor": ["END OF THE LINE", "Defeat THE CONDUCTOR"],
	"halcyon": ["IT'S SUPPOSED TO HURT", "Finish the story"],
	"good_boy": ["GOOD BOY", "Pet Biscuit"],
	"secret1": ["WHAT'S BEHIND THE WALL", "Find a secret room"],
	"secret_all": ["CARTOGRAPHER", "Find every secret room"],
	"tape1": ["PRESS PLAY", "Find a HALCYON tape"],
	"tape_all": ["MIXTAPE", "Find every tape"],
	"memory1": ["WARM", "Relive a memory"],
	"memory_all": ["I REMEMBER", "Relive every memory"],
	"ult": ["OVERLOAD", "Use an ultimate"],
	"kills100": ["EXILE", "Defeat 100 enemies"],
	"arsenal": ["ARSENAL", "Hold 3 weapons at once"],
	"stay": ["STAY A WHILE", "Reach the world after the end"],
	"motes": ["EVERY LIGHT", "Find all lights in the world after the end"],
	"complete": ["100%", "Unlock the completion weapon"],
}
var achievements := {}       # id -> true
var found := {}              # "secret_3", "tape_c4_a", "memory_5", "mote_2" -> true
var total_kills := 0
var ach_popup: Callable      # vom Spiel gesetzt: zeigt die Meldung

func unlock(id: String) -> void:
	if achievements.has(id) or not ACH.has(id):
		return
	achievements[id] = true
	write_save()
	if ach_popup.is_valid():
		ach_popup.call(ACH[id][0], ACH[id][1])
	_check_complete()

func mark(key: String) -> void:
	if found.has(key):
		return
	found[key] = true
	var n_sec := 0; var n_tape := 0; var n_mem := 0; var n_mote := 0
	for k in found:
		if k.begins_with("secret_"): n_sec += 1
		elif k.begins_with("tape_"): n_tape += 1
		elif k.begins_with("memory_"): n_mem += 1
		elif k.begins_with("mote_"): n_mote += 1
	if key.begins_with("secret_"): unlock("secret1")
	if key.begins_with("tape_"): unlock("tape1")
	if key.begins_with("memory_"): unlock("memory1")
	if n_sec >= SECRET_TOTAL: unlock("secret_all")
	if n_tape >= TAPE_TOTAL: unlock("tape_all")
	if n_mem >= MEMORY_TOTAL: unlock("memory_all")
	if n_mote >= MOTE_TOTAL: unlock("motes")
	write_save()

const SECRET_TOTAL := 8    # Kapitel 1-7 und 9
const TAPE_TOTAL := 16
const MEMORY_TOTAL := 9
const MOTE_TOTAL := 12

func completion() -> float:
	return float(achievements.size()) / float(ACH.size() - 1)

func has_completion_weapon() -> bool:
	return achievements.has("secret_all") and achievements.has("tape_all") and achievements.has("memory_all")

func _check_complete() -> void:
	if has_completion_weapon():
		unlock("complete")

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
	carry_slots = cf.get_value("progress", "carry_slots", [])
	carry_ability = cf.get_value("progress", "carry_ability", false)
	carry_chapter = cf.get_value("progress", "carry_chapter", 0)
	achievements = cf.get_value("meta", "achievements", {})
	found = cf.get_value("meta", "found", {})
	total_kills = cf.get_value("meta", "kills", 0)

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
	cf.set_value("progress", "carry_slots", carry_slots)
	cf.set_value("progress", "carry_ability", carry_ability)
	cf.set_value("progress", "carry_chapter", carry_chapter)
	cf.set_value("meta", "achievements", achievements)
	cf.set_value("meta", "found", found)
	cf.set_value("meta", "kills", total_kills)
	cf.save(SAVE_PATH)

func reach_stage(s: int) -> void:
	if s > progress:
		progress = s
		write_save()
