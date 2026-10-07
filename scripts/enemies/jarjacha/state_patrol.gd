extends "res://scripts/enemies/fsm/state.gd"

## Estado de Patrullaje — Jarjacha
## Recorre los puntos de patrulla del pueblo mientras escanea con vista y oído.

func enter() -> void:
	if is_instance_valid(host):
		host.patrol_wait_timer = 0.0
		if host.eye_left and host.eye_right:
			host.eye_left.light_color = Color(1.0, 0.75, 0.2, 1.0)
			host.eye_right.light_color = Color(1.0, 0.75, 0.2, 1.0)
			host.eye_left.light_energy = 0.8
			host.eye_right.light_energy = 0.8

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host._check_sensors()

	if host.patrol_points.is_empty():
		return

	var target = host.patrol_points[host.current_patrol_idx]
	var dist = host.global_position.distance_to(target)

	if dist < 1.5:
		host.patrol_wait_timer += delta
		host.velocity.x = move_toward(host.velocity.x, 0.0, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, host.acceleration * delta)
		if host.patrol_wait_timer > 3.0:
			host.patrol_wait_timer = 0.0
			host.current_patrol_idx = (host.current_patrol_idx + 1) % host.patrol_points.size()
	else:
		host._move_toward_point(target, host.stalk_speed, delta)
