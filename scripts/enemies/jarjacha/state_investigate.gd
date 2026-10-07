extends "res://scripts/enemies/fsm/state.gd"

## Estado de Investigación — Jarjacha
## Se desplaza al origen de un sonido sospechoso y busca al intruso.

func enter() -> void:
	if is_instance_valid(host):
		host.investigate_timer = 4.5

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host._check_sensors()

	host.investigate_timer -= delta
	if host.investigate_timer <= 0.0:
		if state_machine:
			state_machine.transition_to("patrol")
		return

	var dist = host.global_position.distance_to(host.investigate_target)
	if dist > 2.0:
		host._move_toward_point(host.investigate_target, host.stalk_speed * 1.2, delta)
	else:
		host.velocity.x = move_toward(host.velocity.x, 0.0, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, host.acceleration * delta)
		if host.visual:
			host.visual.rotation.y += sin(Time.get_ticks_msec() * 0.003) * 0.8 * delta
