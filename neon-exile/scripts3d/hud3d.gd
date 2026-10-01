extends Control
# HUD fuer die First-Person-Version: Fadenkreuz, Leben, Boss-Leiste, Banner, Treffer-Effekte.

var main

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var sz := get_viewport_rect().size
	var c := sz / 2.0
	var p = main.player
	# Augenlider beim Aufwachen
	var lid: float = main.eyelid()
	if lid < 1.0:
		var hh := sz.y * 0.5 * (1.0 - lid)
		draw_rect(Rect2(0, 0, sz.x, hh + 30), Color.BLACK)
		draw_rect(Rect2(0, sz.y - hh - 30, sz.x, hh + 30), Color.BLACK)
		for i in 8:
			var a := 0.12 * (1.0 - i / 8.0)
			draw_rect(Rect2(0, hh + 30 + i * 12, sz.x, 12), Color(0, 0, 0, a * 4.0 * (1.0 - lid)))
			draw_rect(Rect2(0, sz.y - hh - 42 - i * 12, sz.x, 12), Color(0, 0, 0, a * 4.0 * (1.0 - lid)))
	if main.state == "wake":
		return
	# VHS-Anzeige wie auf alter Kassette
	if Game.retro and main.state != "end":
		var blink := int(Time.get_ticks_msec() / 600) % 2 == 0
		draw_string(font, Vector2(sz.x - 210, sz.y - 120), ("PLAY  " if blink else "      ") + "\u25B6", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.75))
		draw_string(font, Vector2(sz.x - 210, sz.y - 94), "OCT 01 1998  4:%02d PM" % (int(main.play_time / 60.0) % 60), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
	# Schaden: roter Rand
	if main.hurt_t > 0.0:
		var a: float = main.hurt_t * 0.8
		for i in 6:
			var g := 40.0 + i * 25.0
			var col := Color(1, 0, 0.15, a * (1.0 - i / 6.0) * 0.35)
			draw_rect(Rect2(0, 0, sz.x, g), col)
			draw_rect(Rect2(0, sz.y - g, sz.x, g), col)
			draw_rect(Rect2(0, 0, g, sz.y), col)
			draw_rect(Rect2(sz.x - g, 0, g, sz.y), col)
	# Fadenkreuz + Treffermarker
	if main.state == "play":
		var cc := Color("#38f5c4")
		var gap: float = 6.0 + p.recoil * 8.0
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(c + d * gap, c + d * (gap + 9.0), cc, 2.0)
		draw_circle(c, 1.6, cc)
		if main.hitmark_t > 0.0:
			var hc := Color(1, 1, 1, main.hitmark_t * 5.0)
			for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_line(c + d * 7.0, c + d * 15.0, hc, 2.5)
	# Leben
	for i in p.max_hp:
		var r := Rect2(30 + i * 34, sz.y - 62, 28, 34)
		draw_rect(r, Color("#38f5c4") if i < p.hp else Color(1, 1, 1, 0.1))
		draw_rect(r, Color("#38f5c4"), false, 2.0)
	draw_string(font, Vector2(30, sz.y - 72), "ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#38f5c4"))
	# Dash-Anzeige
	var dr := Rect2(30, sz.y - 22, 6 * 34 - 6, 5)
	draw_rect(dr, Color(1, 1, 1, 0.1))
	draw_rect(Rect2(dr.position, Vector2(dr.size.x * (1.0 - p.dash_cd / 0.7), dr.size.y)), Color("#c77dff"))
	# Waffen und Faehigkeit (unten rechts)
	for i in 3:
		var wd: Dictionary = p.WEAPONS[i]
		var r := Rect2(sz.x - 330 + i * 100, sz.y - 70, 92, 40)
		var on: bool = i == p.weapon
		var ok: bool = p.unlocked[i]
		draw_rect(r, Color(wd.col, 0.25 if on else 0.06))
		draw_rect(r, wd.col if on else Color(1, 1, 1, 0.15 if ok else 0.05), false, 2.0)
		draw_string(font, r.position + Vector2(6, 16), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
		draw_string(font, r.position + Vector2(6, 33), wd.name.split(" ")[0] if ok else "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, wd.col if ok else Color(1, 1, 1, 0.25))
	if p.ability_unlocked:
		var ar := Rect2(sz.x - 330, sz.y - 112, 292, 30)
		var ready: bool = p.ability_cd <= 0.0
		draw_rect(ar, Color(0.78, 0.49, 1, 0.08))
		draw_rect(Rect2(ar.position, Vector2(ar.size.x * (1.0 - p.ability_cd / p.ABILITY_CD), ar.size.y)), Color(0.78, 0.49, 1, 0.35 if ready else 0.15))
		draw_rect(ar, Color("#c77dff"), false, 2.0)
		draw_string(font, ar.position + Vector2(8, 21), "[Q] OVERLOAD" + ("  READY" if ready else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c77dff"))
	# Funk
	if main.radio_line.size() > 0:
		var who: String = main.radio_line[0]
		var col: Color = main.Story.SPEAKERS.get(who, Color.WHITE)
		var rb := Rect2(sz.x * 0.2, sz.y - 170, sz.x * 0.6, 64)
		draw_rect(rb, Color(0, 0, 0, 0.55))
		draw_rect(Rect2(rb.position, Vector2(4, rb.size.y)), col)
		draw_string(font, rb.position + Vector2(16, 22), "((( " + who, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		draw_multiline_string(font, rb.position + Vector2(16, 44), main.radio_line[1], HORIZONTAL_ALIGNMENT_LEFT, rb.size.x - 30, 16, -1, Color.WHITE)
	draw_string(font, Vector2(30, 34), "Memory shards: %d/5" % main.shards, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c77dff"))
	if main.objective != "":
		draw_string(font, Vector2(0, 34), main.objective, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 30, 16, Color(1, 1, 1, 0.85))
	# Boss
	var boss = main.boss
	if boss and is_instance_valid(boss) and boss.active:
		var bw := sz.x * 0.5
		var x := (sz.x - bw) / 2.0
		draw_string(font, Vector2(0, 38), "WARDEN-07", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color("#ff2d55"))
		draw_rect(Rect2(x, 48, bw, 12), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(x, 48, bw * maxf(0, boss.hp) / boss.max_hp, 12), Color("#ff2d55"))
		for f in [0.34, 0.67]:
			draw_rect(Rect2(x + bw * f - 1, 48, 2, 12), Color.BLACK)
	if main.banner_t > 0.0:
		draw_string(font, Vector2(0, sz.y * 0.3), main.banner_text, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 46, Color(main.banner_col, minf(1.0, main.banner_t)))
	if main.title_t > 0.0:
		var a2: float = clampf(minf(main.title_t, 6.0 - main.title_t), 0.0, 1.0)
		draw_string(font, Vector2(0, sz.y * 0.4), "CHAPTER 1", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 22, Color(1, 0.82, 0.24, a2))
		draw_string(font, Vector2(0, sz.y * 0.4 + 58), "THE DRAIN", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 60, Color(1, 1, 1, a2))
	if main.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0, 0.02, 0.6))
		draw_string(font, Vector2(0, sz.y * 0.45), "SYSTEM FAILURE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color("#ff2d55"))
		draw_string(font, Vector2(0, sz.y * 0.45 + 50), "Press E to reboot", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
	if main.state == "paused":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(0, sz.y * 0.42), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color.WHITE)
		draw_string(font, Vector2(0, sz.y * 0.42 + 50), "ESC  resume      M  main menu (progress is saved)", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.7))
	if main.state == "end":
		draw_string(font, Vector2(0, sz.y * 0.4 + 130), "Press M for main menu", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 16, Color(1, 1, 1, 0.5))
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, sz.y * 0.4), "CHAPTER 1 COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 48, Color("#ffd23d"))
		draw_string(font, Vector2(0, sz.y * 0.4 + 50), "To be continued in Chapter 2: The Neon Market", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
		draw_string(font, Vector2(0, sz.y * 0.4 + 90), "Time: %ds   Deaths: %d" % [int(main.play_time), main.deaths], HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.6))
	if main.state == "play" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		draw_string(font, Vector2(0, sz.y * 0.62), "Click to control the camera", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.7))
