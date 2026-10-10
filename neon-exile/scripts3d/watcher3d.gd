extends CharacterBody3D
# Waechter (Lehrer in den Schulfluren, Kontrolleure in der U-Bahn):
# laufen Streife mit einem Lichtkegel. Wer im Kegel gesehen wird, ist sofort tot.
# Man kann sie nicht verletzen. Kontrolleure ignorieren dich, wenn du ein Ticket hast.
const XBot = preload("res://scripts3d/xbot.gd")
const Figure = preload("res://scripts3d/figure.gd")

var main
var kind := "teacher"
var a := Vector3.ZERO
var b := Vector3.ZERO
var to_b := true
var wait := 0.0
var alert := 0.0
var xb
var visual: Node3D
var cone: MeshInstance3D
var cone_mat: StandardMaterial3D
var spot: SpotLight3D
var t := 0.0
const RANGE := 15.0
const FOV := 0.6      # halber Oeffnungswinkel (rad)

func _ready() -> void:
	add_to_group("watchers")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 1.0
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var o := Figure.outfit("teacher" if kind == "teacher" else "inspector", rng)
	xb = XBot.new(visual, o.shirt, 1.0, Color(1.0, 0.35, 0.3), 1.0, 0.4, 1.18)
	xb.set_clothes(o)
	xb.void_head(Color(1, 0.3, 0.3))
	xb.stretch = 1.25
	xb.step = 1.0 / 10.0
	xb.head_tilt = 0.2
	# Lichtkegel: sichtbar, damit man weiss, wohin er schaut
	spot = SpotLight3D.new()
	spot.light_color = Color(1.0, 0.95, 0.75)
	spot.light_energy = 3.0
	spot.spot_range = RANGE
	spot.spot_angle = rad_to_deg(FOV)
	spot.position = Vector3(0, 1.8, 0)
	spot.rotation.x = -0.18
	visual.add_child(spot)
	cone = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = tan(FOV) * RANGE * 0.6
	cm.height = RANGE * 0.6
	cm.radial_segments = 20
	cm.cap_top = false
	cm.cap_bottom = false
	cone.mesh = cm
	cone_mat = StandardMaterial3D.new()
	cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_mat.albedo_color = Color(1.0, 0.95, 0.7, 0.06)
	cone.material_override = cone_mat
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cone.rotation.x = PI / 2.0 - 0.12
	cone.position = Vector3(0, 1.75, -RANGE * 0.3)
	visual.add_child(cone)

func hit(_dmg = 0, _dir = Vector3.ZERO) -> void:
	# unverwundbar: Schuesse machen ihn nur wuetend
	alert = maxf(alert, 0.7)

func _physics_process(delta: float) -> void:
	t += delta
	xb.update(delta, Vector2(velocity.x, velocity.z).length())
	if main == null or not main.can_control():
		velocity = Vector3.ZERO
		return
	var p = main.player
	var ignored: bool = kind == "inspector" and main.has_ticket
	var seen := false
	if not ignored and p.hp > 0:
		var eye := global_position + Vector3(0, 1.7, 0)
		var target: Vector3 = p.global_position + Vector3(0, 1.2, 0)
		var to := target - eye
		var d := to.length()
		var fwd := -visual.global_basis.z
		if d < RANGE and fwd.angle_to(Vector3(to.x, 0, to.z).normalized()) < FOV:
			var q := PhysicsRayQueryParameters3D.create(eye, target, 1, [get_rid(), p.get_rid()])
			var hit_r := get_world_3d().direct_space_state.intersect_ray(q)
			if hit_r.is_empty():
				seen = true
				alert += delta * (2.8 if d < 6.0 else 1.3)
	if not seen:
		alert = maxf(0.0, alert - delta * 0.6)
	cone_mat.albedo_color = Color(1.0, 0.95 - alert * 0.8, 0.7 - alert * 0.7, 0.06 + alert * 0.15)
	spot.light_color = Color(1.0, 0.95 - alert * 0.8, 0.75 - alert * 0.7)
	if alert >= 1.0:
		alert = 0.0
		main.instakill("THE TEACHER SAW YOU" if kind == "teacher" else "NO VALID TICKET")
		return
	if seen or alert > 0.3:
		# bleibt stehen und starrt
		velocity = Vector3.ZERO
		var tp: Vector3 = p.global_position - global_position
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-tp.x, -tp.z), minf(1.0, delta * 3.0))
		move_and_slide()
		return
	# Streife zwischen a und b
	if wait > 0.0:
		wait -= delta
		velocity = Vector3.ZERO
		visual.rotation.y += sin(t * 1.3) * delta * 0.8
		move_and_slide()
		return
	var goal := b if to_b else a
	var dir := goal - global_position
	dir.y = 0.0
	if dir.length() < 0.6:
		to_b = not to_b
		wait = randf_range(1.2, 2.5)
		return
	dir = dir.normalized()
	velocity = Vector3(dir.x * 1.7, -5.0, dir.z * 1.7)
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 5.0))
	move_and_slide()
