class_name Muki
extends CharacterBody3D

## IA de El Muki (Duende de las Minas) — PUYU
## Arquitectura modular con Finite State Machine (FSM).
## Rápido, esquivo, arroja esquirlas de mineral y es vulnerable a la luz directa de la linterna.

const EnemyStateMachineScript = preload("res://scripts/enemies/fsm/state_machine.gd")
const MukiStatePatrolScript = preload("res://scripts/enemies/muki/state_patrol.gd")
const MukiStateInvestigateScript = preload("res://scripts/enemies/muki/state_investigate.gd")
const MukiStateChaseScript = preload("res://scripts/enemies/muki/state_chase.gd")
const MukiStateAttackScript = preload("res://scripts/enemies/muki/state_attack.gd")
const MukiStateBlindedScript = preload("res://scripts/enemies/muki/state_blinded.gd")
const MukiStateTetheredScript = preload("res://scripts/enemies/muki/state_tethered.gd")
const MukiStateStunnedScript = preload("res://scripts/enemies/muki/state_stunned.gd")
const MukiStateDefeatedScript = preload("res://scripts/enemies/muki/state_defeated.gd")
const MukiRockScene = preload("res://scenes/enemies/muki_rock.tscn")

enum State {
	PATROL = 0,
	INVESTIGATE = 1,
	CHASE = 2,
	ATTACK = 3,
	TETHERED = 4,
	STUNNED = 5,
	DEFEATED = 6,
	BLINDED = 7
}

@export_group("Stats")
@export var max_health: float = 220.0
@export var current_health: float = 220.0
@export var attack_damage: float = 24.0

@export_group("Speed")
@export var stalk_speed: float = 3.2
@export var chase_speed: float = 7.6
@export var rotation_speed: float = 7.0
@export var acceleration: float = 22.0

@export_group("Perception")
@export var vision_range: float = 18.0
@export var vision_angle_deg: float = 120.0
@export var hearing_range_sprint: float = 14.0
@export var hearing_range_walk: float = 5.0

@export_group("Tethering")
@export var is_tethered: bool = false
@export var tether_anchor_point: Vector3 = Vector3.ZERO
@export var tether_max_distance: float = 5.5

# Nodos visuales y referencias
@onready var visual: Node3D = $Visual
@onready var head_pivot: Node3D = $Visual/Head
@onready var eye_left: OmniLight3D = $Visual/Head/EyeLeft
@onready var eye_right: OmniLight3D = $Visual/Head/EyeRight
@onready var lamp_light: SpotLight3D = $Visual/Head/MinerHelmet/CarbideLamp/SpotLight3D
@onready var lamp_omni: OmniLight3D = $Visual/Head/MinerHelmet/CarbideLamp/OmniLight3D
@onready var arm_left: Node3D = $Visual/ArmLeft
@onready var arm_right: Node3D = $Visual/ArmRight
@onready var pickaxe: Node3D = $Visual/ArmRight/Pickaxe
@onready var tether_attach_point: Marker3D = $Visual/Neck/TetherPoint
@onready var attack_area: Area3D = $AttackArea
@onready var health_bar: Node3D = get_node_or_null("HealthBar3D")

var state_machine: Node = null
var player_ref: Node3D = null

# Patrol
var patrol_points: Array[Vector3] = []
var current_patrol_idx: int = 0
var patrol_wait_timer: float = 0.0

# Investigation
var investigate_target: Vector3 = Vector3.ZERO
var investigate_timer: float = 0.0

# Combat & Timers
var attack_cooldown: float = 0.0
var blindness_immunity_cooldown: float = 0.0
var gravity: float = 18.0

# Tethering state
var is_lassoed_by_player: bool = false
var is_being_dragged: bool = false
var drag_strength: float = 0.0
var active_tethers: Array[Dictionary] = []

# Mapeo de compatibilidad
var _state_enum_map: Dictionary = {
	"patrol": State.PATROL,
	"investigate": State.INVESTIGATE,
	"chase": State.CHASE,
	"attack": State.ATTACK,
	"tethered": State.TETHERED,
	"stunned": State.STUNNED,
	"defeated": State.DEFEATED,
	"blinded": State.BLINDED
}

var _enum_to_name_map: Dictionary = {
	State.PATROL: "patrol",
	State.INVESTIGATE: "investigate",
	State.CHASE: "chase",
	State.ATTACK: "attack",
	State.TETHERED: "tethered",
	State.STUNNED: "stunned",
	State.DEFEATED: "defeated",
	State.BLINDED: "blinded"
}

var current_state: int:
	get:
		if state_machine and state_machine.get("current_state"):
			var cur_st = state_machine.get("current_state")
			var s_name = cur_st.name.to_lower()
			return _state_enum_map.get(s_name, State.PATROL)
		return State.PATROL
	set(val):
		if state_machine and state_machine.has_method("transition_to"):
			var target_name = _enum_to_name_map.get(val, "patrol")
			state_machine.transition_to(target_name)

func _ready() -> void:
	add_to_group("enemy")
	_find_player()
	_setup_default_patrol()
	_setup_state_machine()
	_init_health_bar()

func _init_health_bar() -> void:
	if health_bar and health_bar.has_node("BossName"):
		var lbl = health_bar.get_node("BossName") as Label3D
		if lbl:
			lbl.text = "EL MUKI (DUENDE MINERO)"

func _setup_state_machine() -> void:
	state_machine = get_node_or_null("StateMachine")
	if not state_machine:
		state_machine = EnemyStateMachineScript.new()
		state_machine.name = "StateMachine"
		add_child(state_machine)

		state_machine.add_state("patrol", MukiStatePatrolScript.new())
		state_machine.add_state("investigate", MukiStateInvestigateScript.new())
		state_machine.add_state("chase", MukiStateChaseScript.new())
		state_machine.add_state("attack", MukiStateAttackScript.new())
		state_machine.add_state("blinded", MukiStateBlindedScript.new())
		state_machine.add_state("tethered", MukiStateTetheredScript.new())
		state_machine.add_state("stunned", MukiStateStunnedScript.new())
		state_machine.add_state("defeated", MukiStateDefeatedScript.new())

	state_machine.init(self)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player_ref = players[0]
	else:
		player_ref = get_tree().root.find_child("Player", true, false)

func _setup_default_patrol() -> void:
	if patrol_points.is_empty():
		var center = global_position
		patrol_points = [
			center + Vector3(0, 0, 0),
			center + Vector3(6, 0, 4),
			center + Vector3(-5, 0, 7),
			center + Vector3(-7, 0, -3),
			center + Vector3(4, 0, -6)
		]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	attack_cooldown = max(0.0, attack_cooldown - delta)
	blindness_immunity_cooldown = max(0.0, blindness_immunity_cooldown - delta)

	# Chequeo dinámico de ceguera por la linterna del jugador
	_check_lantern_blinding()

	# Delegación a la FSM
	if state_machine and state_machine.has_method("physics_process"):
		state_machine.physics_process(delta)

	_enforce_tether_constraints()
	move_and_slide()
	_enforce_tether_constraints()

func _move_toward_point(target: Vector3, speed: float, delta: float) -> void:
	var diff = target - global_position
	diff.y = 0.0

	if diff.length() < 0.2:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		return

	var target_dir = diff.normalized()
	var target_rot = atan2(target_dir.x, target_dir.z)

	if visual:
		visual.rotation.y = lerp_angle(visual.rotation.y, target_rot, rotation_speed * delta)

	velocity.x = move_toward(velocity.x, target_dir.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_dir.z * speed, acceleration * delta)

func _check_sensors() -> void:
	if not is_instance_valid(player_ref):
		_find_player()
		if not is_instance_valid(player_ref):
			return

	var dist = global_position.distance_to(player_ref.global_position)

	# 1. Visión directa
	if dist <= vision_range and _can_see_player():
		if state_machine and current_state != State.CHASE and current_state != State.ATTACK and current_state != State.BLINDED and current_state != State.TETHERED:
			state_machine.transition_to("chase")
			if Events:
				Events.prompt_flashed.emit("¡El Muki te ha divisado entre las sombras!", 1.8)
		return

	# 2. Detección auditiva
	var player_speed = 0.0
	if "velocity" in player_ref:
		player_speed = Vector2(player_ref.velocity.x, player_ref.velocity.z).length()

	var is_sprinting = player_ref.get("is_sprinting") == true or player_speed > 6.0
	var is_moving = player_speed > 1.5

	if is_sprinting and dist <= hearing_range_sprint:
		alert_investigate(player_ref.global_position)
	elif is_moving and dist <= hearing_range_walk:
		alert_investigate(player_ref.global_position)

func _can_see_player() -> bool:
	if not is_instance_valid(player_ref):
		return false

	var to_player = player_ref.global_position - global_position
	to_player.y = 0.0
	var dist = to_player.length()

	if dist > vision_range:
		return false

	var forward = -visual.global_transform.basis.z if visual else -global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > (vision_angle_deg * 0.5):
		return false

	# Raycast de oclusión
	var space = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3(0, 0.7, 0)
	var to_pos = player_ref.global_position + Vector3(0, 1.0, 0)

	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos, 1) # Capa 1: Escenario
	query.exclude = [self]
	var res = space.intersect_ray(query)

	return res.is_empty()

## Verifica si el haz de luz de la linterna del jugador da directamente en la cara del Muki
func _check_lantern_blinding() -> void:
	if blindness_immunity_cooldown > 0.0 or current_state == State.BLINDED or current_state == State.DEFEATED:
		return

	if not is_instance_valid(player_ref):
		return

	var lantern = player_ref.find_child("Lantern", true, false)
	if not lantern or not lantern.visible:
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > 10.0:
		return

	# Comprobar si el jugador está mirando hacia el Muki
	var cam = player_ref.get_node_or_null("CameraMount/Camera3D") as Camera3D
	if not cam:
		cam = get_viewport().get_camera_3d()

	if not cam:
		return

	var cam_forward = -cam.global_transform.basis.z
	var to_muki = (global_position + Vector3(0, 0.6, 0)) - cam.global_position
	var angle = rad_to_deg(cam_forward.angle_to(to_muki.normalized()))

	# Si la linterna apunta dentro del cono directo (< 26 grados) y no hay obstáculos
	if angle < 26.0:
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(cam.global_position, global_position + Vector3(0, 0.6, 0), 1)
		query.exclude = [player_ref, self]
		var hit = space.intersect_ray(query)
		if hit.is_empty():
			if state_machine:
				state_machine.transition_to("blinded")

func _has_clear_shot_to_player() -> bool:
	if not is_instance_valid(player_ref):
		return false
	var space = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3(0, 0.7, 0)
	var to_pos = player_ref.global_position + Vector3(0, 0.9, 0)
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos, 1)
	query.exclude = [self]
	return space.intersect_ray(query).is_empty()

func _throw_mineral_rock() -> void:
	if not is_instance_valid(player_ref):
		return

	var rock = MukiRockScene.instantiate()
	get_parent().add_child(rock)
	var spawn_pos = global_position + Vector3(0, 0.7, 0)
	if arm_right:
		spawn_pos = arm_right.global_position + Vector3(0, 0.2, 0)
	rock.global_position = spawn_pos
	rock.launch(player_ref.global_position + Vector3(0, 0.8, 0))

	# Animación de lanzamiento
	_play_throw_animation()

func alert_investigate(target_pos: Vector3) -> void:
	investigate_target = target_pos
	if state_machine and current_state != State.CHASE and current_state != State.ATTACK and current_state != State.BLINDED and current_state != State.TETHERED and current_state != State.DEFEATED:
		state_machine.transition_to("investigate")

func _deal_damage_to_player() -> void:
	if not is_instance_valid(player_ref):
		return
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	elif "velocity" in player_ref:
		var push_dir = (player_ref.global_position - global_position).normalized()
		player_ref.velocity += (push_dir * 10.0) + Vector3(0, 3.0, 0)

# --- Sogas y Multi-Tethering ---
func apply_player_lasso() -> void:
	is_lassoed_by_player = true
	if current_state == State.PATROL or current_state == State.INVESTIGATE:
		if state_machine and state_machine.has_method("transition_to"):
			state_machine.transition_to("chase")

func release_player_lasso() -> void:
	is_lassoed_by_player = false
	is_being_dragged = false
	drag_strength = 0.0

func apply_player_drag(_puller_pos: Vector3, strength: float) -> void:
	is_being_dragged = true
	drag_strength = strength

func release_player_drag() -> void:
	is_being_dragged = false
	drag_strength = 0.0
	if visual:
		visual.rotation.x = 0.0

func add_post_tether(anchor_position: Vector3, max_dist: float, anchor_node: Node3D, visual_node: Node3D) -> void:
	apply_rope_tether(anchor_position, max_dist, anchor_node)
	if not active_tethers.is_empty():
		active_tethers.back()["visual"] = visual_node

func apply_rope_tether(anchor_position: Vector3, max_dist: float, _anchor_node: Node3D) -> void:
	is_tethered = true
	tether_anchor_point = anchor_position
	tether_max_distance = max_dist

	active_tethers.append({
		"anchor_pos": anchor_position,
		"max_dist": max_dist,
		"anchor_node": _anchor_node,
		"visual": null
	})

	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("tethered")

func release_tether() -> void:
	is_tethered = false
	active_tethers.clear()
	is_being_dragged = false
	if state_machine and state_machine.has_method("transition_to") and current_state != State.DEFEATED:
		state_machine.transition_to("chase")

func _enforce_tether_constraints() -> void:
	if not is_tethered or active_tethers.is_empty():
		return

	for tet in active_tethers:
		var anchor = tet["anchor_pos"]
		var max_d = tet["max_dist"]
		var diff = global_position - anchor
		var dist = diff.length()

		if dist > max_d:
			var pull_dir = -diff.normalized()
			var excess = dist - max_d
			global_position += pull_dir * excess
			var vel_away = velocity.dot(diff.normalized())
			if vel_away > 0.0:
				velocity -= diff.normalized() * vel_away

# --- Combate y Daño Recibido ---
func take_damage(damage: float, is_blunt: bool = false, is_headshot: bool = false, _hit_pos: Vector3 = Vector3.ZERO, push_dir: Vector3 = Vector3.ZERO) -> void:
	if current_state == State.DEFEATED:
		return

	var final_damage = damage
	if is_headshot:
		final_damage *= 2.5
		if Events:
			Events.prompt_flashed.emit("¡GOLPE CRÍTICO EN EL CASCO DEL MUKI! (2.5x)", 1.5)

	current_health = max(0.0, current_health - final_damage)

	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health, max_health)

	if Events:
		Events.enemy_damaged.emit(self, final_damage, is_headshot)

	if current_health <= 0.0:
		if state_machine:
			state_machine.transition_to("defeated")
		return

	# Reacción a impacto
	if is_blunt or is_headshot or final_damage >= 30.0:
		receive_push(global_position - push_dir, 6.0, 2.0)
	else:
		_play_hit_flinch()

func receive_push(from_pos: Vector3, force: float, duration: float) -> void:
	if current_state == State.DEFEATED:
		return

	var push_direction = (global_position - from_pos).normalized()
	push_direction.y = 0.2
	velocity += push_direction * force

	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("stunned")
		var st_node = state_machine.get_node_or_null("stunned")
		if st_node and st_node.has_method("set_stun_duration"):
			st_node.set_stun_duration(duration)

# --- Animaciones Procedurales Retro ---
func _play_pickaxe_strike_animation() -> void:
	if not arm_right:
		return
	var tw = create_tween()
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(-60.0), 0.12)
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(55.0), 0.10)
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(0.0), 0.20)

func _play_throw_animation() -> void:
	if not arm_right:
		return
	var tw = create_tween()
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(-45.0), 0.10)
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(45.0), 0.12)
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(0.0), 0.20)

func _play_pickaxe_tap_animation() -> void:
	if not arm_right:
		return
	var tw = create_tween()
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(30.0), 0.15)
	tw.tween_property(arm_right, "rotation:x", deg_to_rad(0.0), 0.18)

func _play_blinded_animation() -> void:
	if arm_left:
		var tw = create_tween()
		tw.tween_property(arm_left, "rotation:x", deg_to_rad(-70.0), 0.2)
		tw.parallel().tween_property(arm_left, "rotation:y", deg_to_rad(40.0), 0.2)
	if head_pivot:
		var tw_h = create_tween()
		tw_h.tween_property(head_pivot, "rotation:x", deg_to_rad(-30.0), 0.2)

func _reset_blinded_animation() -> void:
	if arm_left:
		var tw = create_tween()
		tw.tween_property(arm_left, "rotation:x", 0.0, 0.25)
		tw.parallel().tween_property(arm_left, "rotation:y", 0.0, 0.25)
	if head_pivot:
		var tw_h = create_tween()
		tw_h.tween_property(head_pivot, "rotation:x", 0.0, 0.25)

func _play_hit_flinch() -> void:
	if visual:
		var tw = create_tween()
		tw.tween_property(visual, "position:y", -0.08, 0.08)
		tw.tween_property(visual, "position:y", 0.0, 0.12)
