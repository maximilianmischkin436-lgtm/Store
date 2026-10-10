extends CharacterBody2D
# Gegner: "crawler" (rennt auf dich zu) und "drone" (haelt Abstand und schiesst).

var main
var kind := "crawler"
var hp := 3
var radius := 15.0
var flash := 0.0
var knock := Vector2.ZERO
var fire_t := 1.5
var strafe := 1.0
var awake := false
var t := 0.0

func setup(m, k: String) -> void:
	main = m
	kind = k
	if kind == "drone":
		hp = 4
		radius = 16.0
		fire_t = randf_range(0.8, 1.8)
		strafe = 1.0 if randf() < 0.5 else -1.0
	elif kind == "boss_minion":
		hp = 2
		kind = "crawler"
		awake = true

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	queue_redraw()
	if not main.can_control():
		return
	var p = main.player
	var to: Vector2 = p.global_position - global_position
	var d := to.length()
	if not awake:
		if d < 430.0:
			awake = true
		else:
			return
	var v := Vector2.ZERO
	if kind == "crawler":
		v = to.normalized() * 165.0
		if d < radius + 16.0:
			p.hurt(1)
	else:
		var want := 270.0
		var side := to.normalized().orthogonal() * strafe * 110.0
		v = side + to.normalized() * clampf(d - want, -1.0, 1.0) * 120.0
		fire_t -= delta
		if fire_t <= 0.0:
			fire_t = randf_range(1.2, 1.8)
			for s in [-0.15, 0.0, 0.15]:
				main.spawn_bullet(global_position, to.normalized().rotated(s) * 300.0, false, 1, Color("#ff4d6d"))
		if randf() < delta * 0.4:
			strafe = -strafe
	velocity = v + knock
	knock = knock.lerp(Vector2.ZERO, minf(1.0, delta * 10.0))
	move_and_slide()

func hit(dmg: int, dir: Vector2) -> void:
	hp -= dmg
	flash = 0.1
	awake = true
	knock = dir.normalized() * 220.0
	if hp <= 0:
		main.burst(global_position, Color("#ff4d6d") if kind == "drone" else Color("#ff9f3d"), 24)
		main.on_enemy_killed(self)
		queue_free()

func _draw() -> void:
	var col := Color.WHITE if flash > 0.0 else (Color("#ff4d6d") if kind == "drone" else Color("#ff9f3d"))
	draw_circle(Vector2.ZERO, radius + 10.0, Color(col, 0.1))
	if kind == "crawler":
		# Krabbler: Koerper mit zappelnden Beinen
		for i in 6:
			var a := i * TAU / 6.0 + sin(t * 14.0 + i) * 0.25
			draw_line(Vector2.ZERO, Vector2(radius + 8.0, 0).rotated(a), col, 3.0)
		draw_circle(Vector2.ZERO, radius, col)
		draw_circle(Vector2(0, -3), 4.0, Color("#0a0a14"))
	else:
		# Drohne: Raute mit Auge, das auf den Spieler zielt
		var pts := PackedVector2Array([Vector2(0, -radius - 4), Vector2(radius + 4, 0), Vector2(0, radius + 4), Vector2(-radius - 4, 0)])
		draw_colored_polygon(pts, col)
		var look: Vector2 = (main.player.global_position - global_position).normalized() * 4.0
		draw_circle(look, 6.0, Color("#0a0a14"))
		draw_circle(look, 2.5, Color.WHITE)
		draw_arc(Vector2.ZERO, radius + 14.0, t * 3.0, t * 3.0 + 1.5, 12, Color(col, 0.6), 2.0)
