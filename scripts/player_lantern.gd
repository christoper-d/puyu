extends Node3D
class_name PlayerLantern

# Andean hand lantern — always on, old amber-cold bulb feel
# Child of CameraPivot/SpringArm3D or directly of player root

@export var base_color: Color = Color(1.0, 0.82, 0.52, 1.0)  # warm amber
@export var base_energy: float = 1.8
@export var base_angle_deg: float = 28.0
@export var base_range: float = 10.0

# Flicker — simulates old battery
@export var flicker_enabled: bool = true
@export var flicker_speed: float = 14.0
@export var flicker_intensity: float = 0.08

@onready var spot: SpotLight3D = $SpotLight3D

var _flicker_phase: float = 0.0

func _ready() -> void:
	if spot:
		spot.light_color = base_color
		spot.light_energy = base_energy
		spot.spot_angle = base_angle_deg
		spot.spot_range = base_range
		spot.shadow_enabled = true
		spot.shadow_bias = 0.04
		# Soft falloff for PS2 feel
		spot.spot_attenuation = 1.4
		spot.light_volumetric_fog_energy = 0.6

func _process(delta: float) -> void:
	if not spot or not flicker_enabled:
		return
	_flicker_phase += delta * flicker_speed
	# Two layered sines + tiny noise to break periodicity
	var f = sin(_flicker_phase) * 0.5 + sin(_flicker_phase * 2.3 + 1.1) * 0.3
	f = f * flicker_intensity
	spot.light_energy = max(0.05, base_energy + f)
