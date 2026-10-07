extends MeshInstance3D
class_name RopeVisual

var target_a: Node3D = null
var target_b: Node3D = null
var pos_a: Vector3 = Vector3.ZERO
var pos_b: Vector3 = Vector3.ZERO
var is_active: bool = false
var imm_mesh: ImmediateMesh
var stress_level: float = 0.0 # 0.0 (slack) to 1.0 (about to snap)
var rope_mat: StandardMaterial3D

func _ready() -> void:
	imm_mesh = ImmediateMesh.new()
	mesh = imm_mesh
	rope_mat = StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.68, 0.58, 0.40, 1.0)
	rope_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = rope_mat

func setup_targets(from_node: Node3D, to_node: Node3D) -> void:
	target_a = from_node
	target_b = to_node
	is_active = true

func set_fixed_start(start_pos: Vector3, to_node: Node3D) -> void:
	pos_a = start_pos
	target_a = null
	target_b = to_node
	is_active = true

func _process(_delta: float) -> void:
	if not is_active:
		return

	if is_instance_valid(target_a):
		pos_a = target_a.global_position
	if is_instance_valid(target_b):
		pos_b = target_b.global_position

	_draw_rope()

func _draw_rope() -> void:
	imm_mesh.clear_surfaces()
	imm_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var segments = 10
	var diff = pos_b - pos_a
	var dist = diff.length()
	var base_sag = clamp(1.2 - (dist / 6.0), 0.0, 0.9)
	# When under stress, the rope straightens into a taut line
	var sag = lerp(base_sag, 0.0, clamp(stress_level * 1.5, 0.0, 1.0))

	# Material color shifts to stressed red when struggling
	if rope_mat:
		var normal_color = Color(0.68, 0.58, 0.40, 1.0)
		var stress_color = Color(1.0, 0.22, 0.15, 1.0)
		if stress_level > 0.6:
			var pulse = sin(Time.get_ticks_msec() * 0.015) * 0.5 + 0.5
			rope_mat.albedo_color = normal_color.lerp(stress_color, stress_level * (0.7 + pulse * 0.3))
		else:
			rope_mat.albedo_color = normal_color.lerp(stress_color, stress_level * 0.5)

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var p = pos_a.lerp(pos_b, t)
		var sag_y = 4.0 * t * (1.0 - t) * sag
		p.y -= sag_y

		# Vibration jitter when under high struggle stress
		if stress_level > 0.35:
			var amp = (stress_level - 0.35) * 0.06
			p.x += randf_range(-amp, amp)
			p.z += randf_range(-amp, amp)

		imm_mesh.surface_add_vertex(to_local(p))

	imm_mesh.surface_end()
