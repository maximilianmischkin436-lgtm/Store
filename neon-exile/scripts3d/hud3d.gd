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
	# Wasser/Traenen laufen ueber das Bild (nur beim Aufwachen)
	if main.chapter == 1 and main.play_time < 12.0:
		var tt: float = main.wake_t if main.state == "wake" else main.play_time
		var fade := clampf((12.0 - tt) / 4.0, 0.0, 1.0)
		for tr in main.tears:
			var age: float = tt - tr.delay
			if age < 0.0:
				continue
			var x: float = tr.x * sz.x + sin(age * 2.0 + tr.wob) * 6.0
			var y0: float = tr.y * sz.y
			var y1: float = y0 + age * tr.v * sz.y * 3.0
			var steps := 18
			for k in steps:
				var f := float(k) / steps
				var yy := lerpf(y0, y1, f)
				var xx: float = x + sin(f * 6.0 + tr.wob) * 3.0
				draw_circle(Vector2(xx, yy), tr.w * (0.4 + 0.6 * f), Color(0.8, 0.9, 1.0, 0.07 * fade))
			draw_circle(Vector2(x, y1), tr.w * 1.3, Color(0.85, 0.95, 1.0, 0.18 * fade))
			draw_circle(Vector2(x - tr.w * 0.3, y1 - tr.w * 0.3), tr.w * 0.4, Color(1, 1, 1, 0.35 * fade))
	# Uebergang: VHS-Zurueckspulen, dann schwarz mit Text
	if main.state == "transition":
		var tt: float = main.trans_t
		var a := clampf(tt / 1.5, 0.0, 1.0)
		var fin: float = clampf((tt - (main.trans_lines.size() * 2.6 + 1.2)) / 0.8, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, a).lerp(Color(1, 0.98, 0.94, 1), fin))
		if tt < 1.6:
			for i in 14:
				var y := fmod(i * 61.0 + tt * 900.0, sz.y)
				draw_rect(Rect2(0, y, sz.x, 3 + (i % 3) * 4), Color(1, 1, 1, 0.25 * (1.0 - a * 0.5)))
			draw_string(font, Vector2(40, 60), "<< REW", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.8))
		var lines: Array = main.trans_lines
		for i in lines.size():
			var la := clampf((tt - 1.8 - i * 2.6) / 0.8, 0.0, 1.0) * clampf((2.0 + lines.size() * 2.6 - tt) / 0.8, 0.0, 1.0)
			draw_string(font, Vector2(0, sz.y * 0.42 + i * 44), lines[i], HORIZONTAL_ALIGNMENT_CENTER, sz.x, 26, Color(0.9, 0.9, 0.95, la))
		return
	# wenig Leben: pulsierender dunkler Rand
	if main.player.hp <= 2 and main.state == "play":
		var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 7.0)
		for i in 8:
			var g := 30.0 + i * 22.0
			var c2 := Color(0.3, 0, 0.05, 0.08 * beat)
			draw_rect(Rect2(0, 0, sz.x, g), c2)
			draw_rect(Rect2(0, sz.y - g, sz.x, g), c2)
			draw_rect(Rect2(0, 0, g, sz.y), c2)
			draw_rect(Rect2(sz.x - g, 0, g, sz.y), c2)
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
	if main.state == "arrive":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 0.98, 0.94, clampf(1.0 - main.arrive_t / 1.4, 0.0, 1.0)))
		return
	if main.state == "wake":
		return
	# VHS-Anzeige wie auf alter Kassette
	if Game.retro and main.state != "end":
		var blink := int(Time.get_ticks_msec() / 600) % 2 == 0
		draw_string(font, Vector2(sz.x - 250, sz.y - 215), ("PLAY  " if blink else "      ") + "\u25B6", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.75))
		draw_string(font, Vector2(sz.x - 250, sz.y - 190), "OCT 01 1998  4:%02d PM" % (int(main.play_time / 60.0) % 60), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.6))
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
			if main.crit_t > 0.0:
				hc = Color(1, 0.82, 0.24, main.hitmark_t * 5.0)
			for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_line(c + d * 7.0, c + d * 15.0, hc, 2.5)
		# Kill-Marker: grosses rotes X, das kurz aufpoppt
		if main.killmark_t > 0.0:
			var k: float = main.killmark_t / 0.35
			var kc := Color(1, 0.2, 0.3, k)
			var sz2: float = 14.0 + (1.0 - k) * 10.0
			for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_line(c + d * (sz2 * 0.4), c + d * sz2, kc, 4.0)
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
		var r := Rect2(sz.x - 330 + i * 100, sz.y - 70, 92, 40)
		if i >= p.slots.size():
			draw_rect(r, Color(1, 1, 1, 0.03))
			draw_rect(r, Color(1, 1, 1, 0.08), false, 2.0)
			draw_string(font, r.position + Vector2(6, 16), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.3))
			draw_string(font, r.position + Vector2(6, 33), "EMPTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.2))
			continue
		var wid: int = p.slots[i]
		var wd: Dictionary = p.WEAPONS[wid]
		var on: bool = wid == p.weapon
		draw_rect(r, Color(wd.col, 0.25 if on else 0.06))
		draw_rect(r, wd.col if on else Color(1, 1, 1, 0.15), false, 2.0)
		draw_string(font, r.position + Vector2(6, 16), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
		draw_string(font, r.position + Vector2(6, 33), wd.name.split(" ")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, wd.col)
	# Laerm-Anzeige (nur gegen die Nachtschwester)
	if main.boss and is_instance_valid(main.boss) and main.boss.kind == "nurse" and main.boss.active:
		var nr := Rect2(sz.x / 2.0 - 120, 70, 240, 8)
		draw_rect(nr, Color(0, 0, 0, 0.4))
		draw_rect(Rect2(nr.position, Vector2(nr.size.x * clampf(main.noise, 0.0, 1.0), 8)), Color(0.4, 1, 0.8) if main.noise < 0.7 else Color(1, 0.3, 0.3))
		draw_string(font, Vector2(0, 66), "NOISE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 12, Color(1, 1, 1, 0.6))
	# Munition + Nachladen
	if p.has_gun() and p.weapon >= 0:
		var wdc: Dictionary = p.WEAPONS[p.weapon]
		var am: int = p.ammo[p.weapon]
		var low: bool = am <= int(wdc.mag) / 4 and int(wdc.mag) > 0
		var acol: Color = Color("#ff4d6d") if low and int(Time.get_ticks_msec() / 250) % 2 == 0 else wdc.col
		draw_string(font, Vector2(sz.x - 330, sz.y - 128), ("%d / %d" % [am, wdc.mag]) if int(wdc.mag) > 0 else "\u221e", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, acol)
		if p.perfect[p.weapon]:
			draw_string(font, Vector2(sz.x - 210, sz.y - 128), "PERFECT +DMG", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if p.reload_t > 0.0:
			var rc := sz / 2.0
			var bw := 160.0
			var br := Rect2(rc.x - bw / 2, rc.y + 40, bw, 8)
			draw_rect(br, Color(0, 0, 0, 0.5))
			draw_rect(Rect2(br.position.x + bw * p.SWEET_A, br.position.y, bw * (p.SWEET_B - p.SWEET_A), 8), Color(1, 1, 1, 0.35 if p.reload_tried else 0.8))
			draw_rect(Rect2(br.position.x + bw * p.reload_progress() - 2, br.position.y - 3, 4, 14), wdc.col)
			draw_string(font, Vector2(0, rc.y + 70), "RELOAD  [R] im weissen Feld = PERFEKT", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 13, Color(1, 1, 1, 0.7))
		elif am <= 0 and int(wdc.mag) > 0:
			draw_string(font, Vector2(0, sz.y / 2.0 + 60), "[R] RELOAD", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 16, Color("#ff4d6d"))
		if p.charge > 0.0:
			var c2 := sz / 2.0
			draw_arc(c2, 26, -PI / 2, -PI / 2 + TAU * p.charge, 40, wdc.col if p.charge < 1.0 else Color.WHITE, 3.0)
	if p.ability_unlocked:
		var ar := Rect2(sz.x - 330, sz.y - 112, 292, 30)
		var ready: bool = p.ability_cd <= 0.0
		draw_rect(ar, Color(0.78, 0.49, 1, 0.08))
		draw_rect(Rect2(ar.position, Vector2(ar.size.x * (1.0 - p.ability_cd / p.ABILITY_CD), ar.size.y)), Color(0.78, 0.49, 1, 0.35 if ready else 0.15))
		draw_rect(ar, Color("#c77dff"), false, 2.0)
		draw_string(font, ar.position + Vector2(8, 21), "[Q] OVERLOAD" + ("  READY" if ready else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c77dff"))
	if main.pickup_hint != "":
		draw_string(font, Vector2(0, sz.y * 0.62), main.pickup_hint, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 22, Color.WHITE)
	# Funk
	if main.radio_line.size() > 0:
		var who: String = main.radio_line[0]
		var col: Color = main.Story.SPEAKERS.get(who, Color.WHITE)
		var rb := Rect2(sz.x * 0.2, sz.y - 170, sz.x * 0.6, 64)
		draw_rect(rb, Color(0, 0, 0, 0.55))
		draw_rect(Rect2(rb.position, Vector2(4, rb.size.y)), col)
		draw_string(font, rb.position + Vector2(16, 22), "((( " + who, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		draw_multiline_string(font, rb.position + Vector2(16, 44), main.radio_line[1], HORIZONTAL_ALIGNMENT_LEFT, rb.size.x - 30, 16, -1, Color.WHITE)
	draw_string(font, Vector2(30, 34), "Memory shards: %d/7" % main.shards, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c77dff"))
	if main.objective != "":
		draw_string(font, Vector2(0, 34), main.objective, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 30, 16, Color(1, 1, 1, 0.85))
	# Boss
	var boss = main.boss
	if boss and is_instance_valid(boss) and boss.active:
		var bw := sz.x * 0.5
		var x := (sz.x - bw) / 2.0
		draw_string(font, Vector2(0, 38), main.ch.boss.name, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color("#ff2d55"))
		draw_rect(Rect2(x, 48, bw, 12), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(x, 48, bw * maxf(0, boss.hp) / boss.max_hp, 12), Color("#ff2d55"))
		for f in [0.34, 0.67]:
			draw_rect(Rect2(x + bw * f - 1, 48, 2, 12), Color.BLACK)
	if main.banner_t > 0.0:
		draw_string(font, Vector2(0, sz.y * 0.3), main.banner_text, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 46, Color(main.banner_col, minf(1.0, main.banner_t)))
	if main.title_t > 0.0:
		var a2: float = clampf(minf(main.title_t, 6.0 - main.title_t), 0.0, 1.0)
		draw_string(font, Vector2(0, sz.y * 0.4), "CHAPTER %d" % main.chapter, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 22, Color(1, 0.82, 0.24, a2))
		draw_string(font, Vector2(0, sz.y * 0.4 + 58), main.ch.name, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 60, Color(1, 1, 1, a2))
	if main.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0, 0.02, 0.6))
		draw_string(font, Vector2(0, sz.y * 0.45), "SYSTEM FAILURE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color("#ff2d55"))
		draw_string(font, Vector2(0, sz.y * 0.45 + 50), "Press E to reboot", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
	if main.state == "paused":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(0, sz.y * 0.42), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color.WHITE)
		draw_string(font, Vector2(0, sz.y * 0.42 + 50), "ESC  resume      M  main menu (progress is saved)", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.7))
	if main.state == "end":
		draw_string(font, Vector2(0, sz.y * 0.4 + 130), "Press M for main menu" + ("   -   E: replay the finale" if main.ending != "" else ""), HORIZONTAL_ALIGNMENT_CENTER, sz.x, 16, Color(1, 1, 1, 0.5))
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.8))
		if main.ending != "":
			draw_string(font, Vector2(0, sz.y * 0.4), main.ENDINGS[main.ending].title, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 48, main.ENDINGS[main.ending].col)
			draw_string(font, Vector2(0, sz.y * 0.4 + 50), "NEON EXILE  -  THE END   (3 endings: try the other doors)", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
		else:
			draw_string(font, Vector2(0, sz.y * 0.4), "END OF PART ONE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 48, Color("#ffd23d"))
			draw_string(font, Vector2(0, sz.y * 0.4 + 50), "To be continued in " + main.ch.next, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
		draw_string(font, Vector2(0, sz.y * 0.4 + 90), "Time: %ds   Deaths: %d" % [int(main.play_time), main.deaths], HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.6))
	if main.state == "play" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		draw_string(font, Vector2(0, sz.y * 0.62), "Click to control the camera", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.7))
