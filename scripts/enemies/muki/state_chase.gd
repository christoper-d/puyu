extends "res://scripts/enemies/fsm/state.gd"

## Estado de Persecución — El Muki
## Corre velozmente agitando la piqueta. Arroja rocas de mineral si el jugador guarda distancia.

var lost_sight_timer: float = 0.0
var rock_throw_cooldown: float = 0.0

func enter() -> void:
	if is_instance_valid(host):
		lost_sight_timer = 0.0
		rock_throw_cooldown = randf_range(1.5, 3.0)
		if host.lamp_light:
			host.lamp_light.light_energy = 2.4
			host.lamp_light.light_color = Color(1.0, 0.45, 0.15, 1.0)
		if host.eye_left and host.eye_right:
			host.eye_left.light_energy = 1.0
			host.eye_right.light_energy = 1.0
			host.eye_left.light_color = Color(1.0, 0.25, 0.1, 1.0)
			host.eye_right.light_color = Color(1.0, 0.25, 0.1, 1.0)

func physics_update(delta: float) -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.player_ref):
		if state_machine:
			state_machine.transition_to("patrol")
		return

	rock_throw_cooldown -= delta

	var player_pos = host.player_ref.global_position
	var dist = host.global_position.distance_to(player_pos)

	# 1. Chequeo de ataque cuerpo a cuerpo (piquetazo)
	if dist <= 2.2 and host.attack_cooldown <= 0.0:
		if state_machine:
			state_machine.transition_to("attack")
		return

	# 2. Chequeo de ataque a distancia (lanzar esquirla de mineral)
	if dist >= 4.5 and dist <= 14.0 and rock_throw_cooldown <= 0.0:
		if host._has_clear_shot_to_player():
			rock_throw_cooldown = randf_range(4.0, 6.5)
			host._throw_mineral_rock()
			return

	# 3. Movimiento de persecución
	var can_see = host._can_see_player()
	if can_see:
		lost_sight_timer = 0.0
		host._move_toward_point(player_pos, host.chase_speed, delta)
	else:
		lost_sight_timer += delta
		if lost_sight_timer > 4.0:
			host.investigate_target = player_pos
			if state_machine:
				state_machine.transition_to("investigate")
			return
		else:
			host._move_toward_point(player_pos, host.chase_speed * 0.9, delta)
