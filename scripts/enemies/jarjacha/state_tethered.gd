extends "res://scripts/enemies/fsm/state.gd"

## Estado Amarrado — Jarjacha
## Forcejeo físico contra postes de amarre, fatiga de sogas y rotura progresiva (7.5s, 20s, 42s).

func enter() -> void:
	if is_instance_valid(host):
		host.struggle_timer = 0.0
		host.struggle_warning_given = false

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	var tether_count = host.active_tethers.size()
	if tether_count == 0:
		host.release_tether()
		if state_machine:
			state_machine.transition_to("chase")
		return

	# Duración de forcejeo según cantidad de amarres
	var break_duration = 7.5
	if tether_count == 2:
		break_duration = 20.0
	elif tether_count >= 3:
		break_duration = 42.0

	host.struggle_timer += delta
	var stress_ratio = clamp(host.struggle_timer / break_duration, 0.0, 1.0)

	# Actualizar estrés visual en todas las sogas
	for t in host.active_tethers:
		var rv = t.get("rope_visual")
		if is_instance_valid(rv) and "stress_level" in rv:
			rv.stress_level = stress_ratio

	# Advertencia previa cuando la soga está por romperse
	if stress_ratio >= 0.75 and not host.struggle_warning_given:
		host.struggle_warning_given = true
		Events.prompt_flashed.emit("¡¡CRAC!! ¡La soga está a punto de romperse!", 2.2)

	# Al completar el tiempo de forcejeo, rompe un amarre
	if host.struggle_timer >= break_duration:
		host._snap_tether()
		return

	# Si está amarrada a 3 o más postes: inmovilizada por completo
	if tether_count >= 3:
		host.velocity.x = move_toward(host.velocity.x, 0.0, 35.0 * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, 35.0 * delta)
		if host.visual:
			host.visual.rotation.z = sin(Time.get_ticks_msec() * 0.04) * 0.14
		return

	# 2 postes: movimiento muy restringido
	if tether_count == 2:
		var thrash = Vector3(sin(Time.get_ticks_msec() * 0.008), 0, cos(Time.get_ticks_msec() * 0.008)) * 1.2
		var target_vel = thrash * (host.chase_speed * 0.25)
		host.velocity.x = move_toward(host.velocity.x, target_vel.x, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, target_vel.z, host.acceleration * delta)
		if host.visual:
			host.visual.rotation.z = sin(Time.get_ticks_msec() * 0.02) * 0.08
		return

	# 1 poste: forcejea dentro del radio
	var anchor_pos: Vector3 = host.active_tethers[0]["anchor_pos"]
	var max_dist: float = host.active_tethers[0]["max_dist"]
	var to_anchor = anchor_pos - host.global_position
	to_anchor.y = 0.0

	if is_instance_valid(host.player_ref) and host.global_position.distance_to(host.player_ref.global_position) < max_dist + 2.0:
		host._move_toward_point(host.player_ref.global_position, host.chase_speed * 0.5, delta)
	else:
		var thrash_dir = -to_anchor.normalized() + Vector3(sin(Time.get_ticks_msec() * 0.006), 0, cos(Time.get_ticks_msec() * 0.006)) * 0.4
		var target_vel = thrash_dir.normalized() * (host.chase_speed * 0.45)
		host.velocity.x = move_toward(host.velocity.x, target_vel.x, host.acceleration * delta)
		host.velocity.z = move_toward(host.velocity.z, target_vel.z, host.acceleration * delta)
