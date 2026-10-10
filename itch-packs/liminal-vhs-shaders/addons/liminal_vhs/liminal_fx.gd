class_name LiminalFX
extends Node
## Liminal VHS effects in one node. Add it to your scene (or as an autoload) and call:
##   fx.set_vhs(true, 0.25)                  - VHS filter over the whole screen
##   fx.flashback("you were there")          - white memory flash with a line of text
##   fx.hallucinate(world_env, 4.0)          - the world turns "real" for a few seconds
##   fx.glitch(0.5)                          - short tracking glitch
##   LiminalFX.apply_shell(node, Color.CYAN) - flickering rim + double-image on any 3D model

const VHS := preload("res://addons/liminal_vhs/vhs_filter.gdshader")
const SHELL := preload("res://addons/liminal_vhs/liminal_shell.gdshader")

@export var vhs_on := true
@export_range(0.0, 1.0) var vhs_strength := 0.25

var _layer: CanvasLayer
var _vhs_rect: ColorRect
var _vhs_mat: ShaderMaterial
var _glitch_t := 0.0
var _hallu_t := 0.0
var _hallu_env: Environment
var _hallu_save := {}

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_vhs_rect = ColorRect.new()
	_vhs_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vhs_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vhs_mat = ShaderMaterial.new()
	_vhs_mat.shader = VHS
	_vhs_rect.material = _vhs_mat
	_layer.add_child(_vhs_rect)
	set_vhs(vhs_on, vhs_strength)

func set_vhs(on: bool, strength: float = -1.0) -> void:
	vhs_on = on
	if strength >= 0.0:
		vhs_strength = strength
	_vhs_rect.visible = on
	_vhs_mat.set_shader_parameter("strength", vhs_strength)

func glitch(amount: float = 0.5) -> void:
	_glitch_t = maxf(_glitch_t, amount)

func _process(delta: float) -> void:
	_glitch_t = maxf(0.0, _glitch_t - delta)
	_vhs_mat.set_shader_parameter("glitch", _glitch_t * 2.0)
	if _hallu_t > 0.0:
		_hallu_t -= delta
		if _hallu_t <= 0.0:
			_end_hallu()

## A white flash, warm tint and a line of text that fades out (memory flashback).
func flashback(text: String, duration: float = 2.5, tint: Color = Color(1, 0.96, 0.9)) -> void:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(tint, 0.0)
	_layer.add_child(r)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text = text
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color(0.25, 0.15, 0.1))
	l.modulate.a = 0.0
	_layer.add_child(l)
	glitch(0.5)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.85, 0.12)
	tw.tween_property(r, "color:a", 0.45, 0.6)
	tw.tween_interval(duration * 0.6)
	tw.tween_property(r, "color:a", 0.0, 1.2)
	tw.tween_callback(r.queue_free)
	var tl := l.create_tween()
	tl.tween_interval(0.2)
	tl.tween_property(l, "modulate:a", 1.0, 0.5)
	tl.tween_interval(duration * 0.6)
	tl.tween_property(l, "modulate:a", 0.0, 1.0)
	tl.tween_callback(l.queue_free)

## For a few seconds the world looks "real": no VHS, no fog, warm daylight, full saturation.
## Group "liminal_hide" nodes disappear during the hallucination (put your monsters in it).
func hallucinate(env: Environment, duration: float = 4.0) -> void:
	if _hallu_t > 0.0 or env == null:
		return
	_hallu_env = env
	_hallu_t = duration
	_hallu_save = {"sat": env.adjustment_saturation, "adj": env.adjustment_enabled, "exp": env.tonemap_exposure, "fog": env.fog_density, "glow": env.glow_enabled, "amb": env.ambient_light_energy, "vhs": vhs_on}
	_flash()
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.tonemap_exposure = _hallu_save.exp * 1.25
	env.fog_density = _hallu_save.fog * 0.15
	env.glow_enabled = false
	env.ambient_light_energy = _hallu_save.amb * 1.8
	set_vhs(false)
	for n in get_tree().get_nodes_in_group("liminal_hide"):
		n.visible = false

func _end_hallu() -> void:
	var env := _hallu_env
	_flash()
	env.adjustment_enabled = _hallu_save.adj
	env.adjustment_saturation = _hallu_save.sat
	env.tonemap_exposure = _hallu_save.exp
	env.fog_density = _hallu_save.fog
	env.glow_enabled = _hallu_save.glow
	env.ambient_light_energy = _hallu_save.amb
	set_vhs(_hallu_save.vhs)
	glitch(0.6)
	for n in get_tree().get_nodes_in_group("liminal_hide"):
		n.visible = true

func _flash() -> void:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(1, 1, 1, 1)
	_layer.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.6)
	tw.tween_callback(r.queue_free)

## Adds the flickering liminal shell (cold rim light, scanlines, occasional double image)
## as a next_pass to every StandardMaterial3D / ShaderMaterial under `root`.
static func apply_shell(root: Node, rim: Color = Color(0.75, 0.95, 1.0), strength: float = 1.0, glitch_amount: float = 1.0) -> void:
	var shell := ShaderMaterial.new()
	shell.shader = SHELL
	shell.set_shader_parameter("rim_col", rim)
	shell.set_shader_parameter("strength", strength)
	shell.set_shader_parameter("glitch", glitch_amount)
	shell.set_shader_parameter("seed", randf() * 100.0)
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			if mi.material_override:
				mi.material_override = mi.material_override.duplicate()
				mi.material_override.next_pass = shell
			elif mi.mesh:
				for s in mi.mesh.get_surface_count():
					var m: Material = mi.get_active_material(s)
					m = m.duplicate() if m else StandardMaterial3D.new()
					m.next_pass = shell
					mi.set_surface_override_material(s, m)
