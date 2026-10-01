extends CharacterBody2D
# ECHO: Bewegung, Dash (unverwundbar), Schiessen in Mausrichtung.

var main
var max_hp := 6
var hp := 6
var speed := 270.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.RIGHT
var inv := 0.0
var shoot_cd := 0.0
var facing := Vector2.RIGHT
var trail: Array = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14
	cs.shape = c
	add_child(cs)

func _physics_process(delta: float) -> void:
	inv = maxf(0.0, inv - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	shoot_cd = maxf(0.0, shoot_cd - delta)
	trail.push_front(global_position)
	if trail.size() > 8:
		trail.pop_back()
	queue_redraw()
	if not main.can_control():
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("left", "right", "up", "down")
	var aim := get_global_mouse_position() - global_position
	if aim.length() > 4.0:
		facing = aim.normalized()
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		dash_dir = dir if dir != Vector2.ZERO else facing
		dash_t = 0.17
		dash_cd = 0.55
		main.burst(global_position, Color("#38f5c4"), 10)
	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * 780.0
	else:
		velocity = dir * speed
	move_and_slide()
	if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
		shoot_cd = 0.15
		var spread := randf_range(-0.04, 0.04)
		main.spawn_bullet(global_position + facing * 22.0, facing.rotated(spread) * 760.0, true, 1, Color("#38f5c4"))

func is_dashing() -> bool:
	return dash_t > 0.0

func hurt(d: int) -> void:
	if inv > 0.0 or dash_t > 0.0 or hp <= 0:
		return
	hp -= d
	inv = 1.0
	main.on_player_hurt()

func _draw() -> void:
	var col := Color("#38f5c4")
	for i in trail.size():
		var p: Vector2 = trail[i] - global_position
		draw_circle(p, 12.0 * (1.0 - i / 8.0), Color(col, 0.08))
	if inv > 0.0 and int(inv * 20.0) % 2 == 0:
		return
	draw_circle(Vector2.ZERO, 26.0, Color(col, 0.08))
	draw_circle(Vector2.ZERO, 18.0, Color(col, 0.15))
	var a := facing.angle()
	var pts := PackedVector2Array([
		Vector2(20, 0).rotated(a), Vector2(-12, -13).rotated(a), Vector2(-6, 0).rotated(a), Vector2(-12, 13).rotated(a)])
	draw_colored_polygon(pts, col)
	draw_circle(Vector2(4, 0).rotated(a), 4.0, Color.WHITE)
