extends CharacterBody3D
# Gegner in 3D: "crawler" (rennt auf dich zu) und "drone" (schwebt, haelt Abstand, schiesst).

var main
var kind := "crawler"
var hp := 3
var radius := 0.7
var col := Color("#d9e6ea")   # blasses Porzellan
var flash := 0.0
var knock := Vector3.ZERO
var fire_t := 1.5
var strafe := 1.0
var awake := false
var t := 0.0
var mat := StandardMaterial3D.new()
var visual: Node3D
var legs: Array = []

func setup(m, k: String) -> void:
	main = m
	kind = k
	col = m.ch.enemy
	if kind == "boss_minion":
		kind = "crawler"
		hp = 2
		awake = true
	if kind == "drone":
		hp = 4
		radius = 0.8
		col = m.ch.drone
		fire_t = randf_range(0.8, 1.8)
		strafe = 1.0 if randf() < 0.5 else -1.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 4
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	cs.position.y = radius
	add_child(cs)
	mat.albedo_color = col
	mat.roughness = 0.15
	mat.metallic = 0.1
	mat.emission_enabled = true
	mat.emission = Color("#ff4d6d")
	mat.emission_energy_multiplier = 0.0
	visual = Node3D.new()
	visual.position.y = radius
	add_child(visual)
	if kind == "crawler":
		_mesh(SphereMesh.new(), Vector3.ZERO, Vector3.ONE * radius * 2.0, mat)
		for i in 6:
			var leg := _mesh(BoxMesh.new(), Vector3.ZERO, Vector3(1.1, 0.08, 0.08), mat)
			leg.rotation.y = i * TAU / 6.0
			legs.append(leg)
		var eye := StandardMaterial3D.new()
		eye.albedo_color = Color(0.02, 0.03, 0.05)
		eye.roughness = 0.05
		_mesh(SphereMesh.new(), Vector3(0, 0.15, -radius * 0.85), Vector3.ONE * 0.22, eye)
	else:
		# Drohne: Kenney-Modell mit rotem Neon-Schimmer
		var model: Node3D = load("res://assets/kenney/models/enemy-flying.glb").instantiate()
		model.rotation_degrees.y = 180.0
		model.scale = Vector3.ONE * 0.9
		model.position.y = -0.4
		visual.add_child(model)
		_overlay(model)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.95
		ring.outer_radius = 1.05
		var r := _mesh(ring, Vector3.ZERO, Vector3.ONE, mat)
		r.rotation.x = PI / 2.0
		legs.append(r)
		position.y = 2.0

var ovl: StandardMaterial3D
func _overlay(n: Node) -> void:
	if ovl == null:
		ovl = StandardMaterial3D.new()
		ovl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ovl.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ovl.albedo_color = Color(col, 0.25)
	if n is MeshInstance3D:
		n.material_overlay = ovl
	for c in n.get_children():
		_overlay(c)

func _mesh(m: Mesh, pos: Vector3, scl: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.scale = scl
	mi.material_override = material
	visual.add_child(mi)
	return mi

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	mat.emission_energy_multiplier = 2.0 if flash > 0.0 else 0.0
	if ovl:
		ovl.albedo_color = Color(1, 0.3, 0.4, 0.7) if flash > 0.0 else Color(0.85, 0.92, 0.95, 0.35)
	if not main.can_control():
		return
	var p = main.player
	var to: Vector3 = p.global_position - global_position
	to.y = 0.0
	var d := to.length()
	if not awake:
		if d < 18.0:
			awake = true
		else:
			return
	var dir := to.normalized()
	if d > 0.1:
		visual.look_at(global_position + visual.position + dir, Vector3.UP)
	if kind == "crawler":
		for i in legs.size():
			legs[i].rotation.z = sin(t * 18.0 + i) * 0.35
		velocity.x = dir.x * 6.5 + knock.x
		velocity.z = dir.z * 6.5 + knock.z
		velocity.y -= 20.0 * delta
		if is_on_floor():
			velocity.y = 0.0
		if d < radius + 0.7:
			p.hurt(1)
	else:
		legs[0].rotation.z = t * 2.0
		var side := dir.cross(Vector3.UP) * strafe * 4.0
		var keep := dir * clampf(d - 11.0, -1.0, 1.0) * 5.0
		velocity = side + keep + knock
		velocity.y = (2.0 + sin(t * 2.0) * 0.4 - position.y) * 3.0
		fire_t -= delta
		if fire_t <= 0.0:
			fire_t = randf_range(1.3, 1.9)
			var from := global_position + Vector3(0, radius, 0)
			var aim: Vector3 = (p.center() - from).normalized()
			Game.sfx("enemy_shot", 1.2, 0.35)
			for s in [-0.08, 0.0, 0.08]:
				main.spawn_proj(from, aim.rotated(Vector3.UP, s) * 15.0, main.ch.proj)
		if randf() < delta * 0.4:
			strafe = -strafe
	knock = knock.lerp(Vector3.ZERO, minf(1.0, delta * 8.0))
	move_and_slide()

func hit(dmg: int, dir: Vector3) -> void:
	hp -= dmg
	flash = 0.08
	awake = true
	knock = Vector3(dir.x, 0, dir.z).normalized() * 5.0
	if hp > 0:
		Game.sfx("enemy_hurt", 1.0, 0.4)
	if hp <= 0:
		Game.sfx("enemy_die", 1.0, 0.7)
		main.burst(global_position + Vector3(0, radius, 0), col, 30)
		main.on_enemy_killed(self)
		queue_free()
