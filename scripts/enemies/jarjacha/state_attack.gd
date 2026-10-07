extends "res://scripts/enemies/fsm/state.gd"

## Estado de Ataque — Jarjacha
## Carga de embestida con mandíbula y pezuñas con tiempo de anticipación (windup).

func enter() -> void:
	if is_instance_valid(host):
		host.attack_windup = 0.45
		host.velocity = Vector3.ZERO

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host.attack_windup -= delta
	if host.attack_windup <= 0.0:
		var forward = -host.visual.global_transform.basis.z if host.visual else Vector3.FORWARD
		host.velocity = forward * 9.0

		if is_instance_valid(host.player_ref):
			var dist = host.global_position.distance_to(host.player_ref.global_position)
			if dist < 2.8:
				host._deal_damage_to_player()

		host.attack_cooldown = 1.8
		if state_machine:
			state_machine.transition_to("chase")
