extends RefCounted
# Echte, animierte Figur (Mixamo X Bot, gesichtslos) statt der Kapsel-Puppe.
# Liminal: blasse Haut, kaltes Randleuchten, zu lange Glieder, schief gelegter Kopf, ruckartige Bewegung.
const Figure = preload("res://scripts3d/figure.gd")
const SCENE := "res://assets/models/xbot.glb"
static var _scene: PackedScene

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
		for b in ["Head", "Neck", "LeftForeArm", "RightForeArm", "Spine2"]:
			var bi := skel.find_bone("mixamorig:" + b)
			if bi < 0:
				bi = skel.find_bone("mixamorig_" + b)
			bones[b] = bi
	# eigenes Material: blasse Haut + dunkle Gelenke
	var body := Figure.mat(col, alpha, 0.6, 0.0)
	var joints := Figure.mat(col.darkened(0.55), alpha if alpha < 1.0 else 1.0, 0.35, 0.0)
	mats = [body, joints]
	for m in mats:
		if alpha < 1.0:
			# Geister: nur die Silhouette ist durchsichtig, nicht das Innere
			m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m3.mesh.get_surface_count():
			var nm: String = str(m3.mesh.surface_get_material(s).resource_name) if m3.mesh.surface_get_material(s) else ""
			m3.set_surface_override_material(s, joints if nm.to_lower().contains("joint") else body)
		m3.material_override = null
	# liminal-Huelle auf alle Oberflaechen
	for m in mats:
		_shell(m, rim, rim_str, glitch)
	play("idle")
	if anim:
		anim.seek(randf() * 2.0, true)

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

# speed in m/s. Waehlt Animation, laeuft (ggf. ruckartig) weiter und biegt danach die Knochen.
func update(delta: float, speed: float) -> void:
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
