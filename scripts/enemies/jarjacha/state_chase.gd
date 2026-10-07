extends "res://scripts/enemies/fsm/state.gd"

## Estado de Persecución — Jarjacha
## Persigue implacablemente al jugador con ojos rojos encendidos y velocidad aumentada.

func enter() -> void:
	if is_instance_valid(host):
		if host.eye_left and host.eye_right:
			host.eye_left.light_color = Color(1.0, 0.15, 0.1, 1.0)
			host.eye_right.light_color = Color(1.0, 0.15, 0.1, 1.0)
			host.eye_left.light_energy = 1.6
			host.eye_right.light_energy = 1.6

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	if not is_instance_valid(host.player_ref):
		if state_machine:
			state_machine.transition_to("patrol")
		return

	var dist = host.global_position.distance_to(host.player_ref.global_position)
	if dist > host.vision_range * 1.5:
		# Se perdió en la niebla
		host.investigate_target = host.player_ref.global_position
		host.investigate_timer = 5.0
		if state_machine:
			state_machine.transition_to("investigate")
		return

	if host.is_lassoed_by_player:
		# Huir para generar tensión con la soga
		var run_away_target = host.global_position + (host.global_position - host.player_ref.global_position).normalized() * 5.0
		host._move_toward_point(run_away_target, host.chase_speed * 0.9, delta)

		var dist_to_player = host.global_position.distance_to(host.player_ref.global_position)
		if dist_to_player > 6.0:
			var pull_back_dir = (host.player_ref.global_position - host.global_position).normalized()
			var overshoot = dist_to_player - 6.0
			host.global_position += pull_back_dir * overshoot
			host.velocity *= 0.5
		return

	if dist < 2.4 and host.attack_cooldown <= 0.0:
		if state_machine:
			state_machine.transition_to("attack")
		return

	var effective_speed = host.chase_speed + (2.5 if host.enrage_boost_timer > 0.0 else 0.0)
	host._move_toward_point(host.player_ref.global_position, effective_speed, delta)
