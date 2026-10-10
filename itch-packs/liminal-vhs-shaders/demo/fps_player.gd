extends CharacterBody3D
## Minimal first-person controller for the demo scenes (WASD + mouse, Shift = run, Space = jump).
@export var speed := 5.0
@export var run_speed := 8.0
@export var mouse_sens := 0.0025
var cam: Camera3D
var pitch := 0.0

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	cam = Camera3D.new()
	cam.position.y = 1.6
	cam.fov = 80.0
	add_child(cam)
	cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= e.relative.x * mouse_sens
		pitch = clampf(pitch - e.relative.y * mouse_sens, -1.4, 1.4)
		cam.rotation.x = pitch
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if e is InputEventMouseButton and e.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.z += 1
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	dir = (global_basis * dir).normalized()
	var spd := run_speed if Input.is_physical_key_pressed(KEY_SHIFT) else speed
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = 6.0
	move_and_slide()
