extends "res://scripts/enemies/fsm/state.gd"

## Estado de Investigación — El Muki
## Se agacha sigiloso, enfoca su lámpara de carburo y rastrea pisadas o ruidos de herramientas.

func enter() -> void:
	if is_instance_valid(host):
		host.investigate_timer = 4.5
		if host.lamp_light:
			host.lamp_light.light_energy = 1.8
			host.lamp_light.light_color = Color(1.0, 0.70, 0.20, 1.0)
		if host.eye_left and host.eye_right:
			host.eye_left.light_energy = 0.8
			host.eye_right.light_energy = 0.8

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host._check_sensors()

	var dist = host.global_position.distance_to(host.investigate_target)
	if dist > 1.4:
		host._move_toward_point(host.investigate_target, host.stalk_speed * 1.2, delta)
	else:
		host.velocity.x = move_toward(host.velocity.x, 0.0, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, host.acceleration * delta)
		host.investigate_timer -= delta
		if host.investigate_timer <= 0.0:
			if state_machine:
				state_machine.transition_to("patrol")
