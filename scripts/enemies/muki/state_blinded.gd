extends "res://scripts/enemies/fsm/state.gd"

## Estado Cegado por Linterna — El Muki
## Mecánica única: Sus ojos acostumbrados a la mina oscura se encandilan con el haz directo de la linterna.
## Se cubre el rostro, retrocede y queda vulnerable por 2.5 segundos.

var blind_timer: float = 0.0

func enter() -> void:
	if is_instance_valid(host):
		blind_timer = 2.5
		host.velocity.x *= 0.2
		host.velocity.z *= 0.2
		host._play_blinded_animation()

		if Events:
			Events.prompt_flashed.emit("¡¡AAGGHH!! ¡El Muki se cubre los ojos, cegado por tu linterna!", 2.2)

		# Notificar para posibles logros
		var ach_mgr = host.get_node_or_null("/root/Achievements")
		if ach_mgr and ach_mgr.has_method("unlock"):
			ach_mgr.unlock("luz_socavon")

func exit() -> void:
	if is_instance_valid(host):
		host.blindness_immunity_cooldown = 5.0
		host._reset_blinded_animation()

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	blind_timer -= delta

	# Pequeño retroceso o tambaleo
	if host.visual:
		host.visual.rotation.z = sin(Time.get_ticks_msec() * 0.04) * 0.12

	host.velocity.x = move_toward(host.velocity.x, 0.0, 10.0 * delta)
	host.velocity.z = move_toward(host.velocity.z, 0.0, 10.0 * delta)

	if blind_timer <= 0.0:
		if state_machine:
			state_machine.transition_to("chase")
