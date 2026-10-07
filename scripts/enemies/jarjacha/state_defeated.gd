extends "res://scripts/enemies/fsm/state.gd"

## Estado Derrotado — Jarjacha
## Muerte final de la bestia al agotar sus 3 fases de combate.

func enter() -> void:
	if not is_instance_valid(host):
		return

	# Limpiar sogas activas
	for t in host.active_tethers:
		if is_instance_valid(t.get("rope_visual")):
			t["rope_visual"].queue_free()
	host.active_tethers.clear()
	host.is_tethered = false

	if host.health_bar and host.health_bar.has_method("update_health"):
		host.health_bar.update_health(0.0, host.max_health)

	if host.eye_left and host.eye_right:
		host.eye_left.light_energy = 0.0
		host.eye_right.light_energy = 0.0

	if host.attack_area:
		host.attack_area.monitoring = false
		host.attack_area.monitorable = false

	host.collision_layer = 0

	# Colapso visual en tierra
	if host.visual:
		host.visual.rotation.x = deg_to_rad(75.0)
		host.visual.position.y = -0.5

	Events.prompt_flashed.emit("¡¡LA JARJACHA HA SIDO DERROTADA!!", 6.0)

func physics_update(delta: float) -> void:
	if is_instance_valid(host):
		host.velocity.x = move_toward(host.velocity.x, 0.0, 10.0 * delta)
		host.velocity.z = move_toward(host.velocity.z, 0.0, 10.0 * delta)
