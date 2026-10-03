extends Control
# HUD: Leben, Boss-Leiste, Ziel, Banner, Todes- und Endbildschirm.

var main

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var sz := get_viewport_rect().size
	var p = main.player
	# Leben als Energiezellen
	for i in p.max_hp:
		var r := Rect2(24 + i * 30, 22, 24, 30)
		draw_rect(r, Color("#38f5c4") if i < p.hp else Color(1, 1, 1, 0.12))
		draw_rect(r, Color("#38f5c4"), false, 2.0)
	draw_string(font, Vector2(24, 76), "ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#38f5c4"))
	draw_string(font, Vector2(24, 98), "Shards: %d/5" % main.shards, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c77dff"))
	if main.objective != "":
		draw_string(font, Vector2(0, 40), main.objective, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 24, 16, Color(1, 1, 1, 0.8))
	# Boss-Leiste
	var boss = main.boss
	if boss and is_instance_valid(boss) and boss.active:
		var bw := sz.x * 0.5
		var x := (sz.x - bw) / 2.0
		draw_string(font, Vector2(x, sz.y - 54), "WARDEN-07", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ff2d55"))
		draw_rect(Rect2(x, sz.y - 44, bw, 14), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(x, sz.y - 44, bw * maxf(0, boss.hp) / boss.max_hp, 14), Color("#ff2d55"))
		for f in [0.34, 0.67]:
			draw_rect(Rect2(x + bw * f - 1, sz.y - 44, 2, 14), Color("#0a0a14"))
	# Banner
	if main.banner_t > 0.0:
		var a := minf(1.0, main.banner_t)
		draw_string(font, Vector2(0, sz.y * 0.3), main.banner_text, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 46, Color(main.banner_col, a))
	# Kapiteltitel
	if main.title_t > 0.0:
		var a2 := clampf(minf(main.title_t, 6.0 - main.title_t), 0.0, 1.0)
		draw_string(font, Vector2(0, sz.y * 0.42), "CHAPTER 1", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 22, Color(1, 0.82, 0.24, a2))
		draw_string(font, Vector2(0, sz.y * 0.42 + 56), "THE SUMP", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 58, Color(1, 1, 1, a2))
	if main.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0, 0.02, 0.6))
		draw_string(font, Vector2(0, sz.y * 0.45), "SYSTEM FAILURE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color("#ff2d55"))
		draw_string(font, Vector2(0, sz.y * 0.45 + 50), "Press E to reboot", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
	if main.state == "end":
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, sz.y * 0.4), "CHAPTER 1 COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 48, Color("#ffd23d"))
		draw_string(font, Vector2(0, sz.y * 0.4 + 50), "To be continued in Chapter 2: The Neon Market", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 20, Color.WHITE)
		draw_string(font, Vector2(0, sz.y * 0.4 + 90), "Time: %ds   Deaths: %d" % [int(main.play_time), main.deaths], HORIZONTAL_ALIGNMENT_CENTER, sz.x, 18, Color(1, 1, 1, 0.6))
