extends "res://scripts/enemies/fsm/state.gd"

## Estado Enlazado (Tethered) — El Muki
## Maneja la resistencia física con la soga de cabuya anclada a postes o sostenida por el jugador.
## Al ser más pequeño que la Jarjacha, 2 postes son suficientes para inmovilizarlo casi por completo.

var struggle_timer: float = 0.0
var struggle_warning_given: bool = false

func enter() -> void:
	if not is_instance_valid(host):
		return

	var post_count = host.active_tethers.size()
	struggle_warning_given = false

	# Resistencia reducida comparada con la descomunal Jarjacha
	match post_count:
		0, 1:
			struggle_timer = 9.0
		2:
			struggle_timer = 35.0
		_:
			struggle_timer = 60.0

	if host.eye_left and host.eye_right:
		host.eye_left.light_energy = 1.2
		host.eye_right.light_energy = 1.2

func exit() -> void:
	if is_instance_valid(host) and host.visual:
		host.visual.rotation.z = 0.0

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	# Si está siendo arrastrado por el jugador con tracción activa
	if host.is_being_dragged:
		struggle_timer = max(struggle_timer, 4.0) # El arrastre reinicia e impide que rompa la soga
		if host.visual:
			host.visual.rotation.x = deg_to_rad(-25.0) # Inclinado / arrastrado en el suelo
		return

	# Forcejeo físico
	struggle_timer -= delta
	var post_count = host.active_tethers.size()

	if host.visual:
		var jerk_speed = 0.04 if post_count <= 1 else 0.02
		host.visual.rotation.z = sin(Time.get_ticks_msec() * jerk_speed) * 0.14

	# Advertencia visual / auditiva a punto de ceder
	if struggle_timer <= 2.2 and not struggle_warning_given and post_count > 0:
		struggle_warning_given = true
		if Events:
			Events.prompt_flashed.emit("¡¡CRAC!! ¡El Muki está por zafarse de la soga!", 1.8)

	# Se libera de un poste
	if struggle_timer <= 0.0:
		_break_one_tether()

func _break_one_tether() -> void:
	if not is_instance_valid(host):
		return

	if not host.active_tethers.is_empty():
		var broken = host.active_tethers.pop_back()
		if broken.has("visual") and is_instance_valid(broken["visual"]):
			broken["visual"].queue_free()

		if Events:
			Events.prompt_flashed.emit("¡¡SPLIT!! ¡El Muki cortó una soga con su piqueta!", 2.0)

	if host.active_tethers.is_empty():
		host.is_tethered = false
		if state_machine:
			state_machine.transition_to("chase")
	else:
		enter() # Recalcular tiempo con los postes restantes
