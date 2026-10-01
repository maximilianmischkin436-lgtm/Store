extends CharacterBody3D
# ECHO in First-Person: Maus-Blick, laufen, springen, Dash, Laser-Gewehr.

var main
var max_hp := 6
var hp := 6
var head: Node3D
var cam: Camera3D
var gun: Node3D
var muzzle: Node3D
var yaw := 0.0
var pitch := 0.0
var sens := 0.0025
const SPEED := 7.5
const ACCEL := 70.0
const AIR_ACCEL := 25.0
const JUMP := 7.0
const GRAV := 20.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.ZERO
var inv := 0.0
var shoot_cd := 0.0
var bob := 0.0
var recoil := 0.0
var gun_base := Vector3(0.24, -0.22, -0.45)

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 85
	cam.near = 0.05
	head.add_child(cam)
	_build_gun()

func _build_gun() -> void:
	gun = Node3D.new()
	gun.position = gun_base
	cam.add_child(gun)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.3, 0.3, 0.4)
	dark.metallic = 0.8
	dark.roughness = 0.3
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color.BLACK
	glow.emission_enabled = true
	glow.emission = Color("#38f5c4")
	glow.emission_energy_multiplier = 1.2
	for part in [[Vector3(0, 0, 0), Vector3(0.09, 0.12, 0.5), dark], [Vector3(0, -0.1, 0.12), Vector3(0.06, 0.16, 0.08), dark],
			[Vector3(0, 0.035, -0.32), Vector3(0.05, 0.05, 0.25), dark], [Vector3(0.048, 0.02, -0.05), Vector3(0.01, 0.025, 0.4), glow],
			[Vector3(-0.048, 0.02, -0.05), Vector3(0.01, 0.025, 0.4), glow], [Vector3(0, 0.035, -0.45), Vector3(0.06, 0.06, 0.02), glow]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		mi.mesh = bm
		mi.material_override = part[2]
		mi.position = part[0]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gun.add_child(mi)
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.035, -0.47)
	gun.add_child(muzzle)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= e.relative.x * sens
		pitch = clampf(pitch - e.relative.y * sens, -1.45, 1.45)

func _physics_process(delta: float) -> void:
	inv = maxf(0.0, inv - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	shoot_cd = maxf(0.0, shoot_cd - delta)
	rotation.y = yaw
	head.rotation.x = pitch
	recoil = lerpf(recoil, 0.0, minf(1.0, delta * 14.0))
	if not is_on_floor():
		velocity.y -= GRAV * delta
	if not main.can_control():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var inp := Input.get_vector("left", "right", "up", "down")
	var dir := (transform.basis * Vector3(inp.x, 0, inp.y)).normalized()
	var acc := ACCEL if is_on_floor() else AIR_ACCEL
	velocity.x = move_toward(velocity.x, dir.x * SPEED, acc * delta)
	velocity.z = move_toward(velocity.z, dir.z * SPEED, acc * delta)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		dash_dir = dir if dir != Vector3.ZERO else -transform.basis.z
		dash_t = 0.18
		dash_cd = 0.7
	if dash_t > 0.0:
		dash_t -= delta
		velocity.x = dash_dir.x * 24.0
		velocity.z = dash_dir.z * 24.0
	move_and_slide()
	cam.fov = lerpf(cam.fov, 98.0 if dash_t > 0.0 else 85.0, minf(1.0, delta * 10.0))
	var moving := Vector2(velocity.x, velocity.z).length() > 1.0 and is_on_floor()
	if moving:
		bob += delta * 11.0
	head.position.y = lerpf(head.position.y, 1.6 + (sin(bob) * 0.05 if moving else 0.0), minf(1.0, delta * 12.0))
	gun.position = gun_base + Vector3(sin(bob * 0.5) * 0.012, abs(sin(bob * 0.5)) * -0.012, recoil * 0.07)
	gun.rotation.x = recoil * 0.12
	if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
		shoot_cd = 0.13
		recoil = 1.0
		var spread := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.008
		var fwd := (-cam.global_basis.z + cam.global_basis * spread).normalized()
		main.player_shoot(cam.global_position, fwd, muzzle.global_position)

func center() -> Vector3:
	return global_position + Vector3(0, 0.9, 0)

func is_dashing() -> bool:
	return dash_t > 0.0

func hurt(d: int) -> void:
	if inv > 0.0 or dash_t > 0.0 or hp <= 0:
		return
	hp -= d
	inv = 0.8
	main.on_player_hurt()
