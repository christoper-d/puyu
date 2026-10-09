extends "res://scripts/enemies/fsm/state.gd"

## Estado de Ataque — El Muki
## Asesta un golpe rápido y descendente con su piqueta de minero.

var attack_windup: float = 0.0

func enter() -> void:
	if is_instance_valid(host):
		attack_windup = 0.28
		host.velocity.x = 0.0
		host.velocity.z = 0.0
		host._play_pickaxe_strike_animation()

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	attack_windup -= delta
	if attack_windup <= 0.0:
		# Embestida corta frontal
		var forward = -host.visual.global_transform.basis.z if host.visual else Vector3.FORWARD
		host.velocity = forward * 5.5

		if is_instance_valid(host.player_ref):
			var dist = host.global_position.distance_to(host.player_ref.global_position)
			if dist < 2.4:
				host._deal_damage_to_player()

		host.attack_cooldown = 1.4
		if state_machine:
			state_machine.transition_to("chase")
