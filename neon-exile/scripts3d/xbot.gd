extends RefCounted
# Echte, animierte Figur (Mixamo X Bot, gesichtslos) statt der Kapsel-Puppe.
# Liminal: blasse Haut, kaltes Randleuchten, zu lange Glieder, schief gelegter Kopf, ruckartige Bewegung.
const Figure = preload("res://scripts3d/figure.gd")
const SCENE := "res://assets/models/xbot.glb"
static var _scene: PackedScene

# Leitet die Eigenschaften, die Gegner/Bosse an ihren Materialien setzen, an den Kleidungs-Shader weiter
class Proxy:
	var sm: ShaderMaterial
	var albedo_color := Color.WHITE:
		set(v):
			albedo_color = v
			sm.set_shader_parameter("tint", v)
	var emission := Color.WHITE:
		set(v):
			emission = v
			sm.set_shader_parameter("emit_col", v)
	var emission_energy_multiplier := 0.0:
		set(v):
			emission_energy_multiplier = v
			sm.set_shader_parameter("emit_e", v)
	var roughness := 0.65:
		set(v):
			roughness = v
			sm.set_shader_parameter("rough", v)
	var emission_enabled := true
	var metallic := 0.0

static var _clothes: Shader
static var _raw := Vector2.ZERO   # (ymin, hoehe) in den Rohdaten des Meshes (vor dem Skinning)
var sitting := false
var root: Node3D
var anim: AnimationPlayer
var skel: Skeleton3D
var cur := ""
var acc := 0.0
var step := 0.0          # >0: Stop-Motion (Sekunden pro Bild)
var head_tilt := 0.0
var head_look := 0.0
var stretch := 1.0       # Unterarme/Hals laenger
var bones := {}
var base_head := Quaternion.IDENTITY
var fresh := true
var mats: Array = []

func _init(parent: Node3D, col: Color, alpha: float, rim: Color, rim_str: float, glitch: float, height: float = 1.0) -> void:
	if _scene == null:
		_scene = load(SCENE)
	root = _scene.instantiate()
	root.rotation.y = PI
	root.scale = Vector3.ONE * height
	parent.add_child(root)
	anim = root.find_child("AnimationPlayer", true, false)
	skel = root.find_child("Skeleton3D", true, false) as Skeleton3D
	if anim:
		anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		for n in ["idle", "walk", "run"]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	if skel:
		for b in ["Head", "Neck", "LeftForeArm", "RightForeArm", "Spine2", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftArm", "RightArm"]:
			var bi := skel.find_bone("mixamorig:" + b)
			if bi < 0:
				bi = skel.find_bone("mixamorig_" + b)
			bones[b] = bi
	# Kleidung + blasse Haut + verschwommenes Gesicht (ein Shader fuer alle Teile)
	if _clothes == null:
		_clothes = load("res://scripts3d/clothes.gdshader")
	var sm := ShaderMaterial.new()
	sm.shader = _clothes
	var px := Proxy.new()
	px.sm = sm
	px.albedo_color = Color(1, 1, 1, alpha)
	mats = [px]
	set_clothes({"skin": Color(0.92, 0.9, 0.88), "shirt": col, "pants": col.darkened(0.4), "shoes": Color(0.12, 0.1, 0.1), "hair": Color(0.2, 0.17, 0.15)})
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var aabb := AABB()
	for mi in meshes:
		var m3 := mi as MeshInstance3D
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if alpha >= 1.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aabb = aabb.merge(m3.mesh.get_aabb()) if aabb.size != Vector3.ZERO else m3.mesh.get_aabb()
		for s in m3.mesh.get_surface_count():
			m3.set_surface_override_material(s, sm)
		m3.material_override = null
	if _raw == Vector2.ZERO and not meshes.is_empty():
		var lo := INF; var hi := -INF
		for mi in meshes:
			var arr: PackedVector3Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for v in arr:
				lo = minf(lo, v.y); hi = maxf(hi, v.y)
		_raw = Vector2(lo, hi - lo)
	sm.set_shader_parameter("hgt", maxf(_raw.y, 0.01))
	sm.set_shader_parameter("ymin", _raw.x)
	# liminale Huelle nur bei sichtbar starkem Effekt (spart Leistung bei Hintergrund-Geistern)
	if rim_str >= 0.5:
		if Figure._shell == null:
			Figure._shell = load("res://scripts3d/creature_shell.gdshader")
		var shell := ShaderMaterial.new()
		shell.shader = Figure._shell
		shell.set_shader_parameter("rim_col", rim)
		shell.set_shader_parameter("strength", rim_str)
		shell.set_shader_parameter("glitch", glitch)
		shell.set_shader_parameter("seed", randf() * 100.0)
		sm.next_pass = shell
	play("idle")
	if anim:
		anim.seek(randf() * 2.0, true)

# Farben aus einem Figure-Outfit (blass wie Geister)
func set_clothes(o: Dictionary) -> void:
	var sm: ShaderMaterial = mats[0].sm
	for k in ["skin", "shirt", "pants", "shoes", "hair"]:
		if o.has(k):
			var c: Color = o[k]
			var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			# ausgeblichen: Richtung Grau und etwas heller
			c = Color(lerpf(c.r, l, 0.4), lerpf(c.g, l, 0.4), lerpf(c.b, l, 0.35)).lerp(Color(0.92, 0.93, 0.95), 0.18)
			sm.set_shader_parameter(k, c)
	if o.has("bare_arms"):
		sm.set_shader_parameter("short_sleeves", 1.0 if o.bare_arms else 0.0)
	if o.has("skirt"):
		sm.set_shader_parameter("skirt", 1.0 if o.skirt else 0.0)

func set_face(v: float) -> void:
	mats[0].sm.set_shader_parameter("face", v)

func _shell(m: StandardMaterial3D, rim: Color, strength: float, glitch: float) -> void:
	var holder := MeshInstance3D.new()
	holder.material_override = m
	var tmp := Node3D.new()
	tmp.add_child(holder)
	Figure.liminal(tmp, rim, strength, glitch)
	holder.material_override = null
	tmp.free()

# Gesicht = schwarzes Loch: ein glatter, lichtschluckender Kopf mit schwachem Rand
func void_head(rim: Color) -> void:
	if skel == null or bones.get("Head", -1) < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_idx = bones.Head
	skel.add_child(ba)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 13.5
	sm.height = 29.0
	sm.radial_segments = 32
	sm.rings = 16
	mi.mesh = sm
	# Mixamo-Skelett ist in Zentimetern: Kugel etwas nach oben/vorn ins Gesicht
	mi.position = Vector3(0, 8.0, 5.5)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.0, 0.0, 0.0)
	m.roughness = 0.05
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.rim = 1.0
	m.rim_tint = 1.0
	m.emission_enabled = true
	m.emission = rim * 0.15
	mi.material_override = m
	ba.add_child(mi)

func play(n: String, spd: float = 1.0) -> void:
	if anim == null or not anim.has_animation(n):
		return
	if n != cur:
		anim.play(n, 0.2)
		cur = n
	anim.speed_scale = spd

# Hinsetzen: Oberschenkel nach vorn, Knie gebeugt, Haende auf den Tisch
var sit_q := {}
func sit() -> void:
	sitting = true
	if skel == null:
		return
	var leg_up := Quaternion(Vector3(1, 0, 0), SIT_HIP)
	var knee := Quaternion(Vector3(1, 0, 0), SIT_KNEE)
	var arm := Quaternion(Vector3(1, 0, 0), SIT_ARM)
	for b in ["LeftUpLeg", "RightUpLeg"]:
		sit_q[b] = leg_up
	for b in ["LeftLeg", "RightLeg"]:
		sit_q[b] = knee
	for b in ["LeftForeArm", "RightForeArm"]:
		sit_q[b] = arm
	root.position.y -= 0.42 * root.scale.y
const SIT_HIP := -1.45
const SIT_KNEE := 1.5
const SIT_ARM := -0.9

# speed in m/s. Waehlt Animation, laeuft (ggf. ruckartig) weiter und biegt danach die Knochen.
var _scaled := false
func update(delta: float, speed: float) -> void:
	if not _scaled and root.is_inside_tree():
		_scaled = true
		var sc: float = root.global_transform.basis.get_scale().y
		mats[0].sm.set_shader_parameter("hgt", _raw.y * sc)
		mats[0].sm.set_shader_parameter("ymin", _raw.x * sc - (0.42 * sc if sitting else 0.0) * 0.0)
	if sitting:
		if skel:
			for b in sit_q:
				var bi: int = bones.get(b, -1)
				if bi >= 0:
					skel.set_bone_pose_rotation(bi, skel.get_bone_rest(bi).basis.get_rotation_quaternion() * sit_q[b])
			if bones.get("Head", -1) >= 0:
				var hb: int = bones.Head
				skel.set_bone_pose_rotation(hb, skel.get_bone_rest(hb).basis.get_rotation_quaternion() * Quaternion(Vector3(0, 0, 1), head_tilt) * Quaternion(Vector3(1, 0, 0), 0.25))
		return
	if speed > 4.0:
		play("run", clampf(speed / 6.0, 0.8, 1.8))
	elif speed > 0.3:
		play("walk", clampf(speed / 1.6, 0.6, 2.0))
	else:
		play("idle", 1.0)
	var advanced := fresh
	if anim:
		if step > 0.0:
			acc += delta
			if acc >= step:
				anim.advance(acc)
				acc = 0.0
				advanced = true
		else:
			anim.advance(delta)
			advanced = true
	fresh = false
	if skel and bones.get("Head", -1) >= 0:
		var hb: int = bones.Head
		if advanced:
			base_head = skel.get_bone_pose_rotation(hb)
		skel.set_bone_pose_rotation(hb, base_head * Quaternion(Vector3(0, 0, 1), head_tilt) * Quaternion(Vector3(0, 1, 0), head_look))
		if stretch != 1.0:
			for b in ["Neck", "LeftForeArm", "RightForeArm"]:
				var bi: int = bones.get(b, -1)
				if bi >= 0:
					skel.set_bone_pose_scale(bi, Vector3(0.9, stretch, 0.9))

func set_flash(on: bool) -> void:
	for m in mats:
		m.emission_energy_multiplier = 2.5 if on else 0.0
