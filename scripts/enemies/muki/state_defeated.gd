extends "res://scripts/enemies/fsm/state.gd"

## Estado Derrotado — El Muki
## Cae de rodillas, su lámpara de carburo chisporrotea hasta apagarse.

func enter() -> void:
	if not is_instance_valid(host):
		return

	host.velocity = Vector3.ZERO

	# Apagar luces de los ojos y lámpara
	if host.lamp_light:
		var tw = host.create_tween()
		tw.tween_property(host.lamp_light, "light_energy", 0.0, 1.2)
	if host.eye_left:
		host.eye_left.light_energy = 0.0
	if host.eye_right:
		host.eye_right.light_energy = 0.0

	# Animación de caída al suelo (PS2 estilo ragdoll estático)
	if host.visual:
		var tw_fall = host.create_tween()
		tw_fall.tween_property(host.visual, "position:y", 0.15, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw_fall.parallel().tween_property(host.visual, "rotation:x", deg_to_rad(-80.0), 0.6)

	# Desactivar colisiones para no estorbar el paso del jugador
	var col = host.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)

	if Events:
		Events.prompt_flashed.emit("¡EL MUKI HA SIDO DERROTADO! El socavón queda en silencio.", 3.5)

	var ach_mgr = host.get_node_or_null("/root/Achievements")
	if ach_mgr and ach_mgr.has_method("unlock"):
		ach_mgr.unlock("rey_socavon")

func physics_update(delta: float) -> void:
	if not is_instance_valid(host):
		return
	host.velocity.x = move_toward(host.velocity.x, 0.0, 10.0 * delta)
	host.velocity.z = move_toward(host.velocity.z, 0.0, 10.0 * delta)
