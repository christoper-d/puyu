class_name PlayerLantern
extends Node3D

## Linterna Andina de Mano / Cinturón — PUYU
## Iluminación estilo survival horror con haz direccional, brillo ambiental cálido y modelo 3D visible.

@export var base_color: Color = Color(1.0, 0.84, 0.50, 1.0) # Ámbar cálido andino
@export var base_energy: float = 3.6                        # Haz potente que corta la niebla
@export var base_angle_deg: float = 45.0                     # Cono amplio de visión
@export var base_range: float = 28.0                        # Rango de 28 metros

# Parpadeo sutil (batería / llama vieja)
@export var flicker_enabled: bool = true
@export var flicker_speed: float = 12.0
@export var flicker_intensity: float = 0.10

# Nodos
@onready var spot: SpotLight3D = get_node_or_null("SpotLight3D")
var omni_fill: OmniLight3D = null
var visual_root: Node3D = null

var _flicker_phase: float = 0.0

func _ready() -> void:
	_build_visual_mesh()
	_setup_lighting()

func _setup_lighting() -> void:
	# 1. Haz principal (SpotLight3D)
	if not spot:
		spot = SpotLight3D.new()
		spot.name = "SpotLight3D"
		add_child(spot)

	spot.position = Vector3(0, 0, -0.14) # Justo al frente del cristal para evitar auto-sombras
	spot.light_color = base_color
	spot.light_energy = base_energy
	spot.spot_angle = base_angle_deg
	spot.spot_range = base_range
	spot.spot_attenuation = 0.85 # Atenuación suave para atmósfera retro
	spot.shadow_enabled = true
	spot.shadow_bias = 0.08
	spot.shadow_normal_bias = 1.8
	spot.light_volumetric_fog_energy = 0.9

	# 2. Luz de relleno ambiental (OmniLight3D alrededor de la linterna)
	omni_fill = get_node_or_null("OmniFill") as OmniLight3D
	if not omni_fill:
		omni_fill = OmniLight3D.new()
		omni_fill.name = "OmniFill"
		add_child(omni_fill)

	omni_fill.position = Vector3.ZERO
	omni_fill.light_color = base_color
	omni_fill.light_energy = 1.1
	omni_fill.omni_range = 3.8
	omni_fill.omni_attenuation = 1.0
	omni_fill.shadow_enabled = false # Sin sombras para iluminar suavemente cuerpo y suelo inmediato

func _build_visual_mesh() -> void:
	if has_node("Visual"):
		visual_root = get_node("Visual")
		return

	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)

	# Material de hierro/latón andino
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.20, 0.18, 0.16, 1.0)
	metal_mat.metallic = 0.65
	metal_mat.roughness = 0.50

	# Cristal incandescente luminoso
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.88, 0.55, 0.9)
	glass_mat.emission_enabled = true
	glass_mat.emission = base_color
	glass_mat.emission_energy_multiplier = 4.2
	glass_mat.roughness = 0.15

	# 1. Base metálica inferior
	var base_mesh = MeshInstance3D.new()
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = 0.075
	base_cyl.bottom_radius = 0.085
	base_cyl.height = 0.045
	base_cyl.material = metal_mat
	base_mesh.mesh = base_cyl
	base_mesh.position = Vector3(0, -0.09, 0)
	visual_root.add_child(base_mesh)

	# 2. Núcleo de vidrio luminoso
	var glass_mesh = MeshInstance3D.new()
	var glass_cyl = CylinderMesh.new()
	glass_cyl.top_radius = 0.065
	glass_cyl.bottom_radius = 0.065
	glass_cyl.height = 0.13
	glass_cyl.material = glass_mat
	glass_mesh.mesh = glass_cyl
	glass_mesh.position = Vector3(0, 0, 0)
	visual_root.add_child(glass_mesh)

	# 3. Tapa metálica superior
	var top_mesh = MeshInstance3D.new()
	var top_cyl = CylinderMesh.new()
	top_cyl.top_radius = 0.05
	top_cyl.bottom_radius = 0.075
	top_cyl.height = 0.04
	top_cyl.material = metal_mat
	top_mesh.mesh = top_cyl
	top_mesh.position = Vector3(0, 0.085, 0)
	visual_root.add_child(top_mesh)

	# 4. Asa / Anillo superior
	var handle_mesh = MeshInstance3D.new()
	var handle_torus = TorusMesh.new()
	handle_torus.inner_radius = 0.028
	handle_torus.outer_radius = 0.042
	handle_torus.material = metal_mat
	handle_mesh.mesh = handle_torus
	handle_mesh.rotation.x = deg_to_rad(90.0)
	handle_mesh.position = Vector3(0, 0.13, 0)
	visual_root.add_child(handle_mesh)

	# 5. Jaula de 4 barras metálicas
	var angles = [0.0, 90.0, 180.0, 270.0]
	for a in angles:
		var bar = MeshInstance3D.new()
		var bar_cyl = CylinderMesh.new()
		bar_cyl.top_radius = 0.006
		bar_cyl.bottom_radius = 0.006
		bar_cyl.height = 0.13
		bar_cyl.material = metal_mat
		bar.mesh = bar_cyl
		var rad = deg_to_rad(a)
		bar.position = Vector3(cos(rad) * 0.072, 0, sin(rad) * 0.072)
		visual_root.add_child(bar)

func _process(delta: float) -> void:
	if not visible:
		return

	if flicker_enabled and spot:
		_flicker_phase += delta * flicker_speed
		var f = (sin(_flicker_phase) * 0.5 + sin(_flicker_phase * 2.3 + 1.1) * 0.3) * flicker_intensity
		spot.light_energy = max(0.2, base_energy + (f * base_energy))
		if omni_fill:
			omni_fill.light_energy = max(0.1, 1.1 + (f * 0.8))

func toggle() -> bool:
	visible = not visible
	return visible
