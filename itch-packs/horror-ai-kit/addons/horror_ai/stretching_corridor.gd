class_name StretchingCorridor
extends Node3D
## A long corridor whose exit door keeps running away for `stretch_time` seconds
## (it always stays `door_lead` metres ahead of the target). After that it stops and can be reached.
## Builds its own geometry along +X. Emits `door_reached`.

signal door_reached

@export var length := 360.0
@export var width := 3.0
@export var height := 3.0
@export var stretch_time := 38.0
@export var door_lead := 55.0
@export var wall_material: Material
@export var floor_material: Material
@export var side_doors := true
var target: Node3D
var running := false
var door_x := 0.0
var door: Node3D
var _t := 0.0
var _done := false

func _ready() -> void:
	if wall_material == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.78, 0.7, 0.62)
		wall_material = m
	if floor_material == null:
		var f := StandardMaterial3D.new()
		f.albedo_color = Color(0.45, 0.32, 0.2)
		floor_material = f
	_box(Vector3(length / 2.0, -0.25, 0), Vector3(length + 10, 0.5, width + 1), floor_material, true)
	_box(Vector3(length / 2.0, height + 0.25, 0), Vector3(length + 10, 0.5, width + 1), wall_material, true)
	for s in [-1, 1]:
		_box(Vector3(length / 2.0, height / 2.0, s * (width / 2.0 + 0.25)), Vector3(length + 10, height, 0.5), wall_material, true)
	_box(Vector3(-2.5, height / 2.0, 0), Vector3(0.5, height, width), wall_material, true)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.35, 0.22, 0.15)
	var lamp := StandardMaterial3D.new()
	lamp.emission_enabled = true
	lamp.emission = Color(1.0, 0.8, 0.6)
	lamp.emission_energy_multiplier = 2.0
	var x := 6.0
	while x < length:
		if side_doors:
			var s := -1 if int(x / 9.0) % 2 == 0 else 1
			_box(Vector3(x, 1.1, s * (width / 2.0 - 0.02)), Vector3(1.0, 2.2, 0.06), dm, false)
		_box(Vector3(x, height - 0.03, 0), Vector3(1.2, 0.04, 0.5), lamp, false)
		if int(x) % 18 == 0:
			var o := OmniLight3D.new()
			o.light_color = Color(1.0, 0.75, 0.55)
			o.light_energy = 0.9
			o.omni_range = 9.0
			o.position = Vector3(x, height - 0.4, 0)
			add_child(o)
		x += 9.0
	door = Node3D.new()
	add_child(door)
	_box_on(door, Vector3(0, 1.15, 0), Vector3(0.3, 2.3, 1.6), dm)
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(1, 0.95, 0.8)
	glow.emission_energy_multiplier = 4.0
	_box_on(door, Vector3(-0.17, 1.15, 0.6), Vector3(0.02, 2.2, 0.08), glow)
	door_x = length - 4.0
	door.position = Vector3(door_x, 0, 0)

func start() -> void:
	running = true
	_t = 0.0
	_done = false
	door_x = length - 4.0

func _process(delta: float) -> void:
	if not running or target == null or _done:
		return
	_t += delta
	var px := to_local(target.global_position).x
	if _t < stretch_time:
		door_x = clampf(maxf(door_x, px + door_lead), 0.0, length - 4.0)
	door.position.x = door_x
	if absf(px - door_x) < 1.8:
		_done = true
		running = false
		door_reached.emit()

func _box(pos: Vector3, size: Vector3, m: Material, collide: bool) -> void:
	var node: Node3D = StaticBody3D.new() if collide else Node3D.new()
	_box_on(node, Vector3.ZERO, size, m)
	if collide:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	node.position = pos
	add_child(node)

func _box_on(parent: Node3D, pos: Vector3, size: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
