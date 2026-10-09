extends "res://scripts/enemies/fsm/state.gd"

## Estado de Patrullaje — El Muki
## Recorre rincones oscuros y callejones, buscando vetas de mineral y picando el suelo con su piqueta.

var pickaxe_clink_timer: float = 0.0

func enter() -> void:
	if is_instance_valid(host):
		host.patrol_wait_timer = 0.0
		pickaxe_clink_timer = randf_range(2.0, 4.0)
		if host.lamp_light:
			host.lamp_light.light_energy = 1.2
			host.lamp_light.light_color = Color(1.0, 0.85, 0.35, 1.0)
		if host.eye_left and host.eye_right:
			host.eye_left.light_energy = 0.4
			host.eye_right.light_energy = 0.4

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host._check_sensors()
	_update_miner_rhythm(delta)

	if host.patrol_points.is_empty():
		return

	var target = host.patrol_points[host.current_patrol_idx]
	var dist = host.global_position.distance_to(target)

	if dist < 1.2:
		host.patrol_wait_timer += delta
		host.velocity.x = move_toward(host.velocity.x, 0.0, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, host.acceleration * delta)
		if host.patrol_wait_timer > 3.5:
			host.patrol_wait_timer = 0.0
			host.current_patrol_idx = (host.current_patrol_idx + 1) % host.patrol_points.size()
	else:
		host._move_toward_point(target, host.stalk_speed, delta)

func _update_miner_rhythm(delta: float) -> void:
	pickaxe_clink_timer -= delta
	if pickaxe_clink_timer <= 0.0:
		pickaxe_clink_timer = randf_range(4.0, 7.0)
		if is_instance_valid(host):
			host._play_pickaxe_tap_animation()
