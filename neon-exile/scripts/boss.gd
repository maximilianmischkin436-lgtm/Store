extends CharacterBody2D
# WARDEN-07, Boss von Kapitel 1. Drei Phasen, Angriffe: Ring, Salve, Ansturm, Helfer, Spirale.

var main
var max_hp := 140
var hp := 140
var radius := 46.0
var active := false
var phase := 0
var t := 0.0
var flash := 0.0
var cd := 2.0
var mode := "idle"   # idle | tele | charge | volley | spiral
var mode_t := 0.0
var charge_dir := Vector2.ZERO
var volley_n := 0
var spin := 0.0
var pat := 0
const COL := Color("#ff2d55")

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)
	add_to_group("enemies")
	add_to_group("boss")

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()
	if not active or not main.can_control():
		return
	var p = main.player
	var to: Vector2 = p.global_position - global_position
	var new_phase := 2 if hp < max_hp * 0.34 else (1 if hp < max_hp * 0.67 else 0)
	if new_phase > phase:
		phase = new_phase
		mode = "idle"
		cd = 1.4
		main.shake(0.5)
		main.burst(global_position, COL, 40)
		main.banner("PHASE %d" % (phase + 1) if phase < 2 else "WARDEN-07 OVERLOAD", COL)
		for b in main.bullets:
			b.dead = true
	if global_position.distance_to(p.global_position) < radius + 14.0:
		p.hurt(1)
	match mode:
		"idle":
			velocity = to.normalized() * (55.0 + phase * 25.0)
			cd -= delta
			if cd <= 0.0:
				_attack(to)
		"tele":
			velocity = Vector2.ZERO
			mode_t -= delta
			flash = 0.05 if int(mode_t * 20.0) % 2 == 0 else 0.0
			if mode_t <= 0.0:
				charge_dir = (p.global_position - global_position).normalized()
				mode = "charge"
				mode_t = 0.7
		"charge":
			velocity = charge_dir * (620.0 + phase * 80.0)
			mode_t -= delta
			if get_slide_collision_count() > 0 or mode_t <= 0.0:
				main.shake(0.3)
				_ring(10 + phase * 4, 230.0)
				mode = "idle"
				cd = 1.2
		"volley":
			velocity = Vector2.ZERO
			mode_t -= delta
			if mode_t <= 0.0:
				var a := to.angle()
				for s in ([-0.25, 0.0, 0.25] if phase > 0 else [0.0]):
					main.spawn_bullet(global_position, Vector2.from_angle(a + s) * 380.0, false, 1, COL)
				volley_n -= 1
				mode_t = 0.16
				if volley_n <= 0:
					mode = "idle"
					cd = 1.0
		"spiral":
			velocity = Vector2.ZERO
			mode_t -= delta
			spin += delta * 4.2
			if int(mode_t * 12.0) != int((mode_t + delta) * 12.0):
				for k in 4:
					main.spawn_bullet(global_position, Vector2.from_angle(spin + k * TAU / 4.0) * 240.0, false, 1, Color("#ffd23d"))
			if mode_t <= 0.0:
				mode = "idle"
				cd = 1.2
	move_and_slide()

func _attack(to: Vector2) -> void:
	var list := ["ring", "volley", "charge"]
	if phase >= 1:
		list.append("summon")
	if phase >= 2:
		list.append("spiral")
	var a: String = list[pat % list.size()]
	pat += 1
	match a:
		"ring":
			_ring(14 + phase * 4, 210.0)
			cd = 1.6 - phase * 0.3
		"volley":
			mode = "volley"
			volley_n = 5 + phase * 2
			mode_t = 0.3
		"charge":
			mode = "tele"
			mode_t = 0.75
		"summon":
			for i in 2:
				main.spawn_enemy("boss_minion", global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80)))
			cd = 1.5
		"spiral":
			mode = "spiral"
			mode_t = 2.6

func _ring(n: int, sp: float) -> void:
	var off := randf() * TAU
	for i in n:
		main.spawn_bullet(global_position, Vector2.from_angle(off + i * TAU / n) * sp, false, 1, COL)

func hit(dmg: int, _dir: Vector2) -> void:
	if not active:
		return
	hp -= dmg
	flash = 0.08
	if hp <= 0:
		main.on_boss_killed(self)

func _draw() -> void:
	var col := Color.WHITE if flash > 0.0 else COL
	if phase >= 2:
		col = col.lerp(Color("#ffd23d"), 0.3 * (0.5 + 0.5 * sin(t * 10.0)))
	for i in 3:
		draw_circle(Vector2.ZERO, radius + 20.0 + i * 12.0, Color(col, 0.05))
	# rotierender Panzer aus 8 Platten
	for i in 8:
		var a := t * (0.8 + phase * 0.6) + i * TAU / 8.0
		var p := Vector2(radius + 8.0, 0).rotated(a)
		draw_colored_polygon(PackedVector2Array([p + Vector2(10, 0).rotated(a), p + Vector2(0, 9).rotated(a), p + Vector2(-8, 0).rotated(a), p + Vector2(0, -9).rotated(a)]), col)
	draw_circle(Vector2.ZERO, radius, col)
	draw_circle(Vector2.ZERO, radius * 0.62, Color("#0a0a14"))
	var look: Vector2 = Vector2.ZERO
	if main and main.player:
		look = (main.player.global_position - global_position).normalized() * 10.0
	draw_circle(look, radius * 0.3, col)
	draw_circle(look, radius * 0.12, Color.WHITE)
	if mode == "tele":
		draw_line(Vector2.ZERO, (main.player.global_position - global_position), Color(COL, 0.4), 3.0)
