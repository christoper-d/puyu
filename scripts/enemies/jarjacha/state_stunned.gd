extends "res://scripts/enemies/fsm/state.gd"

## Estado Aturdido — Jarjacha
## Queda paralizada y temblorosa por empujón con hacha, headshot o disparo de escopeta.

var stun_timer: float = 0.0

func enter() -> void:
	if is_instance_valid(host):
		host.velocity.x *= 0.3
		host.velocity.z *= 0.3

func exit() -> void:
	if is_instance_valid(host) and host.visual:
		host.visual.rotation.z = 0.0

func set_stun_duration(duration: float) -> void:
	stun_timer = duration

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return

	host.velocity.x = move_toward(host.velocity.x, 0.0, 15.0 * delta)
	host.velocity.z = move_toward(host.velocity.z, 0.0, 15.0 * delta)

	if host.visual:
		host.visual.rotation.z = sin(Time.get_ticks_msec() * 0.03) * 0.1

	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0:
			_recover()

func _recover() -> void:
	if not is_instance_valid(host) or not state_machine:
		return

	if host.visual:
		host.visual.rotation.x = 0.0
		host.visual.rotation.z = 0.0

	if not host.active_tethers.is_empty():
		state_machine.transition_to("tethered")
	else:
		state_machine.transition_to("chase")
