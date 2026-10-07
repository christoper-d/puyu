extends Node3D
class_name HealthBar3D

@export var boss_name: String = "LA JARJACHA"

@onready var fill_mesh: MeshInstance3D = $Fill
@onready var bg_mesh: MeshInstance3D = $Background
@onready var border_mesh: MeshInstance3D = $Border
@onready var name_label: Label3D = $BossName

var original_width: float = 1.44
var target_pct: float = 1.0
var display_pct: float = 1.0

func _ready() -> void:
	if fill_mesh and fill_mesh.mesh is BoxMesh:
		original_width = fill_mesh.mesh.size.x
	if name_label:
		name_label.text = boss_name

var hide_tween: Tween = null

func update_health(current: float, maximum: float) -> void:
	if maximum > 0.0:
		target_pct = clamp(current / maximum, 0.0, 1.0)
		
	if target_pct > 0.0:
		if hide_tween and hide_tween.is_valid():
			hide_tween.kill()
		visible = true
		scale = Vector3.ONE
		if display_pct < 0.05:
			display_pct = target_pct
	else:
		if hide_tween and hide_tween.is_valid():
			hide_tween.kill()
		hide_tween = create_tween()
		hide_tween.tween_property(self, "scale", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		hide_tween.tween_callback(func(): if target_pct <= 0.0: visible = false)

func _process(delta: float) -> void:
	# Smooth bar interpolation
	display_pct = move_toward(display_pct, target_pct, 1.5 * delta)

	if fill_mesh:
		fill_mesh.scale.x = max(0.001, display_pct)
		# Local +X is screen left when facing camera, so positive offset pins left edge
		fill_mesh.position.x = (original_width * (1.0 - display_pct)) * 0.5

	# Always face the player camera (billboard)
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_pos = cam.global_position
		cam_pos.y = global_position.y # Lock Y axis for clean horizontal bar
		if global_position.distance_squared_to(cam_pos) > 0.001:
			look_at(cam_pos, Vector3.UP)
			rotate_object_local(Vector3.UP, PI)
