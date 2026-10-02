class_name HorrorWatcher
extends CharacterBody3D
## A patrolling watcher with a visible light cone. If it sees the target long enough, `spotted` fires
## (use it for instant death, an alarm, a chase …). It cannot be hurt: hit() just makes it suspicious.
##
##   var w := HorrorWatcher.new()
##   w.patrol = [Vector3(0,0,0), Vector3(12,0,0)]
##   w.target = $Player
##   w.spotted.connect(func(t): print("caught!"))
##   add_child(w)
## Set `ignore_target = func(): return has_ticket` to make it ignore the player (e.g. ticket inspectors).

signal spotted(target: Node3D)

@export var view_range := 15.0
@export var fov_deg := 34.0                ## half opening angle
@export var walk_speed := 1.7
@export var alert_speed_near := 2.8        ## alert per second when closer than 6 m
@export var alert_speed_far := 1.3
@export var light_color := Color(1.0, 0.95, 0.75)
@export var body_color := Color(0.15, 0.13, 0.12)
var patrol: Array = []                     ## Array of Vector3 points
var target: Node3D
var ignore_target: Callable
var alert := 0.0
var visual: Node3D
var _i := 0
var _wait := 0.0
var _t := 0.0
var _cone_mat: StandardMaterial3D
var _spot: SpotLight3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 1.0
	add_child(cs)
	visual = get_node_or_null("Visual")
	if visual == null:
		visual = Node3D.new()
		add_child(visual)
		_default_body()
	var fov := deg_to_rad(fov_deg)
	_spot = SpotLight3D.new()
	_spot.light_color = light_color
	_spot.light_energy = 3.0
	_spot.spot_range = view_range
	_spot.spot_angle = fov_deg
	_spot.position = Vector3(0, 1.8, 0)
	_spot.rotation.x = -0.18
	visual.add_child(_spot)
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = tan(fov) * view_range * 0.6
	cm.height = view_range * 0.6
	cm.cap_top = false
	cm.cap_bottom = false
	cone.mesh = cm
	_cone_mat = StandardMaterial3D.new()
	_cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = _cone_mat
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cone.rotation.x = PI / 2.0 - 0.12
	cone.position = Vector3(0, 1.75, -view_range * 0.3)
	visual.add_child(cone)
	if not patrol.is_empty():
		global_position = patrol[0]

## Default body: a too-tall, too-thin figure with a lamp for a head.
func _default_body() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = body_color
	var torso := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.22
	c.height = 1.5
	torso.mesh = c
	torso.material_override = m
	torso.position.y = 1.25
	visual.add_child(torso)
	for s in [-1, 1]:
		var leg := MeshInstance3D.new()
		var lc := CapsuleMesh.new()
		lc.radius = 0.08
		lc.height = 1.0
		leg.mesh = lc
		leg.material_override = m
		leg.position = Vector3(0.12 * s, 0.5, 0)
		visual.add_child(leg)
		var arm := MeshInstance3D.new()
		var ac := CapsuleMesh.new()
		ac.radius = 0.06
		ac.height = 1.3
		arm.mesh = ac
		arm.material_override = m
		arm.position = Vector3(0.3 * s, 1.15, 0)
		visual.add_child(arm)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.16
	hs.height = 0.36
	head.mesh = hs
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0, 0, 0)
	hm.roughness = 0.05
	head.material_override = hm
	head.position = Vector3(0, 2.15, 0)
	visual.add_child(head)

func hit(_a = null, _b = null) -> void:
	alert = maxf(alert, 0.7)

func _physics_process(delta: float) -> void:
	_t += delta
	var seen := false
	var ignored: bool = ignore_target.is_valid() and ignore_target.call()
	if target and not ignored:
		var eye := global_position + Vector3(0, 1.7, 0)
		var tp := target.global_position + Vector3(0, 1.2, 0)
		var to := tp - eye
		var d := to.length()
		var fwd := -visual.global_basis.z
		if d < view_range and fwd.angle_to(Vector3(to.x, 0, to.z).normalized()) < deg_to_rad(fov_deg):
			var ex: Array[RID] = [get_rid()]
			if target is CollisionObject3D:
				ex.append((target as CollisionObject3D).get_rid())
			var q := PhysicsRayQueryParameters3D.create(eye, tp, 1, ex)
			if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				seen = true
				alert += delta * (alert_speed_near if d < 6.0 else alert_speed_far)
	if not seen:
		alert = maxf(0.0, alert - delta * 0.6)
	_cone_mat.albedo_color = Color(light_color.r, light_color.g - alert * 0.8, light_color.b - alert * 0.7, 0.06 + alert * 0.15)
	_spot.light_color = Color(light_color.r, light_color.g - alert * 0.8, light_color.b - alert * 0.7)
	if alert >= 1.0:
		alert = 0.0
		spotted.emit(target)
		return
	if (seen or alert > 0.3) and target:
		velocity = Vector3.ZERO
		var tp2 := target.global_position - global_position
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-tp2.x, -tp2.z), minf(1.0, delta * 3.0))
		move_and_slide()
		return
	if patrol.size() < 2:
		visual.rotation.y += sin(_t * 0.7) * delta * 0.6
		return
	if _wait > 0.0:
		_wait -= delta
		visual.rotation.y += sin(_t * 1.3) * delta * 0.8
		return
	var goal: Vector3 = patrol[_i]
	var dir := goal - global_position
	dir.y = 0.0
	if dir.length() < 0.6:
		_i = (_i + 1) % patrol.size()
		_wait = randf_range(1.2, 2.5)
		return
	dir = dir.normalized()
	velocity = Vector3(dir.x * walk_speed, -5.0, dir.z * walk_speed)
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 5.0))
	move_and_slide()
