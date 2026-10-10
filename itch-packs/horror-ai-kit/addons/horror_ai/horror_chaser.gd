class_name HorrorChaser
extends Node3D
## Something that always stays just behind the target ("rubber band"): slower than a sprint,
## but it catches up fast when you are far away and never gives up. Emits `caught` when it reaches you.
##
##   var c := HorrorChaser.new(); c.target = $Player; add_child(c); c.start()

signal caught(target: Node3D)

@export var base_speed := 6.4             ## a bit slower than a running player
@export var catch_up := 0.25              ## extra speed per metre of distance beyond `comfort`
@export var comfort := 12.0
@export var max_extra := 6.0
@export var catch_distance := 1.6
@export var start_distance := 30.0
@export var footsteps: AudioStream       ## optional looping footsteps
@export var glow := Color(1.0, 0.2, 0.15)
var target: Node3D
var running := false
var visual: Node3D
var _steps: AudioStreamPlayer3D
var _t := 0.0

func _ready() -> void:
	visual = get_node_or_null("Visual")
	if visual == null:
		visual = Node3D.new()
		add_child(visual)
		_default_body()
	var l := OmniLight3D.new()
	l.light_color = glow
	l.light_energy = 4.0
	l.omni_range = 8.0
	l.position = Vector3(0, 2.5, 0)
	add_child(l)
	_steps = AudioStreamPlayer3D.new()
	_steps.unit_size = 6.0
	if footsteps:
		_steps.stream = footsteps
	add_child(_steps)

func _default_body() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.1, 0.09)
	var torso := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.3
	c.height = 2.2
	torso.mesh = c
	torso.material_override = m
	torso.position.y = 1.6
	torso.rotation.x = 0.4
	visual.add_child(torso)
	for s in [-1, 1]:
		var arm := MeshInstance3D.new()
		var ac := CapsuleMesh.new()
		ac.radius = 0.07
		ac.height = 1.8
		arm.mesh = ac
		arm.material_override = m
		arm.position = Vector3(0.4 * s, 1.3, -0.3)
		arm.rotation.x = 0.7
		visual.add_child(arm)

## Places the chaser `start_distance` behind the target (opposite of where it looks) and starts the hunt.
func start() -> void:
	if target:
		var back := target.global_basis.z
		back.y = 0.0
		global_position = target.global_position + back.normalized() * start_distance
	running = true
	_t = 0.0
	if _steps.stream:
		_steps.play()

func stop() -> void:
	running = false
	_steps.stop()

func _process(delta: float) -> void:
	if not running or target == null:
		return
	_t += delta
	var to := target.global_position - global_position
	to.y = 0.0
	var d := to.length()
	var spd := base_speed + clampf((d - comfort) * catch_up, 0.0, max_extra)
	if _t < 3.0:
		spd *= 0.6
	if d > 0.01:
		global_position += to / d * spd * delta
		visual.rotation.y = atan2(-to.x, -to.z)
	# ruckartige Bewegung: kleines Zittern
	visual.position.x = sin(_t * 37.0) * 0.04
	if d < catch_distance:
		stop()
		caught.emit(target)
