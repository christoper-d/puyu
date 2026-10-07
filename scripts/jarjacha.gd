extends CharacterBody3D
class_name Jarjacha

@export var current_level: int = 1
@export var max_levels: int = 3

enum State {
	PATROL,
	INVESTIGATE,
	CHASE,
	ATTACK,
	TETHERED,
	STUNNED,
	DEFEATED
}

@export_group("Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var attack_damage: float = 35.0

@export_group("Speed")
@export var stalk_speed: float = 2.6
@export var chase_speed: float = 8.2
@export var rotation_speed: float = 5.0
@export var acceleration: float = 20.0

@export_group("Perception")
@export var vision_range: float = 20.0
@export var vision_angle_deg: float = 110.0
@export var hearing_range_sprint: float = 16.0
@export var hearing_range_walk: float = 6.0

@export_group("Tethering")
@export var is_tethered: bool = false
@export var tether_anchor_point: Vector3 = Vector3.ZERO
@export var tether_max_distance: float = 6.0
@export var struggle_duration: float = 6.0

# Nodes
@onready var visual: Node3D = $Visual
@onready var head_pivot: Node3D = $Visual/Neck/Head
@onready var jaw: MeshInstance3D = $Visual/Neck/Head/Jaw
@onready var eye_left: OmniLight3D = $Visual/Neck/Head/EyeLeft
@onready var eye_right: OmniLight3D = $Visual/Neck/Head/EyeRight
@onready var tether_attach_point: Marker3D = $Visual/Neck/TetherPoint
@onready var attack_area: Area3D = $AttackArea
@onready var health_bar: Node3D = get_node_or_null("HealthBar3D")

var current_state: State = State.PATROL
var player_ref: Node3D = null

# Patrol waypoints
var patrol_points: Array[Vector3] = []
var current_patrol_idx: int = 0
var patrol_wait_timer: float = 0.0

# Investigation
var investigate_target: Vector3 = Vector3.ZERO
var investigate_timer: float = 0.0

# Tethering state
var struggle_timer: float = 0.0
var struggle_warning_given: bool = false
var enrage_boost_timer: float = 0.0
var tether_source_node: Node3D = null
var is_lassoed_by_player: bool = false
var active_tethers: Array[Dictionary] = []


# Attack timer
var attack_cooldown: float = 0.0
var attack_windup: float = 0.0

# Audio/Laugh rhythm timer
var jar_sound_timer: float = 0.0

# Gravity
var gravity: float = 18.0

func _apply_level_stats() -> void:
	match current_level:
		1:
			max_health = 400.0
			chase_speed = 7.0
			stalk_speed = 3.0
			attack_damage = 20.0
		2:
			max_health = 600.0
			chase_speed = 8.5
			stalk_speed = 4.0
			attack_damage = 35.0
			if health_bar and health_bar.has_node("BossName"):
				health_bar.get_node("BossName").text = "LA JARJACHA - FASE 2"
		3:
			max_health = 800.0
			chase_speed = 10.0
			stalk_speed = 5.0
			attack_damage = 55.0
			if health_bar and health_bar.has_node("BossName"):
				health_bar.get_node("BossName").text = "LA JARJACHA - FASE FINAL"
				
	current_health = max_health
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health, max_health)

func _ready() -> void:
	_apply_level_stats()
	_find_player()
	_setup_default_patrol()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	attack_cooldown = max(0.0, attack_cooldown - delta)
	enrage_boost_timer = max(0.0, enrage_boost_timer - delta)
	_update_jar_rhythm(delta)


	match current_state:
		State.PATROL:
			_process_patrol(delta)
			_check_sensors()
		State.INVESTIGATE:
			_process_investigate(delta)
			_check_sensors()
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.TETHERED:
			_process_tethered(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.DEFEATED:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	# Enforce multi-tether constraints
	_enforce_tether_constraints()

	move_and_slide()

	# Enforce again post-move to ensure zero penetration beyond rope length
	_enforce_tether_constraints()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		# Fallback search by node name
		player_ref = get_parent().get_node_or_null("Player")

func _setup_default_patrol() -> void:
	if patrol_points.is_empty():
		# Default points relative to spawn
		patrol_points.append(global_position)
		patrol_points.append(global_position + Vector3(6.0, 0.0, -4.0))
		patrol_points.append(global_position + Vector3(-5.0, 0.0, -6.0))
		patrol_points.append(global_position + Vector3(0.0, 0.0, 7.0))

func _check_sensors() -> void:
	if not is_instance_valid(player_ref):
		_find_player()
		return

	var dist_to_player = global_position.distance_to(player_ref.global_position)
	var dir_to_player = (player_ref.global_position - global_position).normalized()
	var forward = -visual.global_transform.basis.z

	# 1. Vision check
	if dist_to_player <= vision_range:
		var angle = rad_to_deg(forward.angle_to(dir_to_player))
		if angle < vision_angle_deg * 0.5:
			# Raycast line-of-sight check
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(
				global_position + Vector3(0, 1.8, 0),
				player_ref.global_position + Vector3(0, 1.0, 0),
				1 # World collision mask
			)
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				# Clear line of sight
				_alert_to_chase()
				return

	# 2. Hearing check based on player speed
	if dist_to_player <= hearing_range_sprint and player_ref.velocity.length() > 7.0:
		alert_investigate(player_ref.global_position)
	elif dist_to_player <= hearing_range_walk and player_ref.velocity.length() > 3.0 and player_ref.is_on_floor():
		alert_investigate(player_ref.global_position)

func _alert_to_chase() -> void:
	current_state = State.CHASE
	if eye_left and eye_right:
		eye_left.light_color = Color(1.0, 0.15, 0.1, 1.0)
		eye_right.light_color = Color(1.0, 0.15, 0.1, 1.0)
		eye_left.light_energy = 1.6
		eye_right.light_energy = 1.6

func alert_investigate(location: Vector3) -> void:
	if current_state == State.CHASE or current_state == State.TETHERED:
		return
	investigate_target = location
	investigate_timer = 4.5
	current_state = State.INVESTIGATE

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target = patrol_points[current_patrol_idx]
	var dist = global_position.distance_to(target)

	if dist < 1.5:
		patrol_wait_timer += delta
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		if patrol_wait_timer > 3.0:
			patrol_wait_timer = 0.0
			current_patrol_idx = (current_patrol_idx + 1) % patrol_points.size()
	else:
		_move_toward_point(target, stalk_speed, delta)

func _process_investigate(delta: float) -> void:
	investigate_timer -= delta
	if investigate_timer <= 0.0:
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(investigate_target)
	if dist > 2.0:
		_move_toward_point(investigate_target, stalk_speed * 1.2, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		# Look around nervously
		visual.rotation.y += sin(Time.get_ticks_msec() * 0.003) * 0.8 * delta

func _process_chase(delta: float) -> void:
	if not is_instance_valid(player_ref):
		current_state = State.PATROL
		return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist > vision_range * 1.5:
		# Lost player in fog
		current_state = State.INVESTIGATE
		investigate_target = player_ref.global_position
		investigate_timer = 5.0
		return

	if is_lassoed_by_player:
		# Run away to create tension
		var run_away_target = global_position + (global_position - player_ref.global_position).normalized() * 5.0
		_move_toward_point(run_away_target, chase_speed * 0.9, delta)
		
		# Constraint physics against the player to stop infinite stretching
		var dist_to_player = global_position.distance_to(player_ref.global_position)
		if dist_to_player > 6.0:
			var pull_back_dir = (player_ref.global_position - global_position).normalized()
			var overshoot = dist_to_player - 6.0
			global_position += pull_back_dir * overshoot
			velocity *= 0.5 # Slow down as it hits the tension limit
		return

	if dist < 2.4 and attack_cooldown <= 0.0:
		_start_attack()
		return

	var effective_speed = chase_speed + (2.5 if enrage_boost_timer > 0.0 else 0.0)
	_move_toward_point(player_ref.global_position, effective_speed, delta)


func _start_attack() -> void:
	current_state = State.ATTACK
	attack_windup = 0.45
	velocity = Vector3.ZERO

func _process_attack(delta: float) -> void:
	attack_windup -= delta
	if attack_windup <= 0.0:
		# Execute strike forward
		var forward = -visual.global_transform.basis.z
		velocity = forward * 9.0

		if is_instance_valid(player_ref):
			var dist = global_position.distance_to(player_ref.global_position)
			if dist < 2.8:
				_deal_damage_to_player()

		attack_cooldown = 1.8
		current_state = State.CHASE

func _deal_damage_to_player() -> void:
	if player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	elif "velocity" in player_ref:
		# Push player back
		var push_dir = (player_ref.global_position - global_position).normalized()
		player_ref.velocity += (push_dir * 12.0) + Vector3(0, 4.0, 0)

# --- Tethering / Soga mechanics ---
func apply_player_lasso() -> void:
	is_lassoed_by_player = true
	if current_state == State.PATROL or current_state == State.INVESTIGATE:
		current_state = State.CHASE

func release_player_lasso() -> void:
	is_lassoed_by_player = false

func add_post_tether(anchor_world_pos: Vector3, max_dist: float, post_node: Node3D = null, rope_vis: Node3D = null) -> void:
	is_tethered = true
	is_lassoed_by_player = false
	current_state = State.TETHERED
	struggle_timer = 0.0
	struggle_warning_given = false
	
	active_tethers.append({
		"anchor_pos": anchor_world_pos,
		"max_dist": max_dist,
		"source_node": post_node,
		"rope_visual": rope_vis
	})

func apply_rope_tether(anchor_world_pos: Vector3, max_dist: float, source_node: Node3D = null) -> void:
	# Compatibility fallback
	add_post_tether(anchor_world_pos, max_dist, source_node, null)

func release_tether() -> void:
	for t in active_tethers:
		if is_instance_valid(t.get("rope_visual")):
			t["rope_visual"].queue_free()
	active_tethers.clear()
	is_tethered = false
	is_lassoed_by_player = false
	tether_source_node = null
	struggle_timer = 0.0
	struggle_warning_given = false
	if current_state == State.TETHERED:
		current_state = State.CHASE

func _enforce_tether_constraints() -> void:
	if active_tethers.is_empty():
		return

	var iterations = 3 if active_tethers.size() > 1 else 1
	for _i in range(iterations):
		for tether in active_tethers:
			var anchor_pos: Vector3 = tether["anchor_pos"]
			var max_dist: float = tether["max_dist"]
			var diff = global_position - anchor_pos
			diff.y = 0.0
			var dist = diff.length()
			if dist > max_dist:
				var pull_dir = -diff.normalized()
				var overshoot = dist - max_dist
				global_position += pull_dir * overshoot

				# Cancel outward velocity away from anchor
				var out_dir = diff.normalized()
				var v_dot = velocity.dot(out_dir)
				if v_dot > 0.0:
					velocity -= out_dir * v_dot

func _process_tethered(delta: float) -> void:
	var tether_count = active_tethers.size()
	if tether_count == 0:
		release_tether()
		return

	# Progressive break time based on tether count:
	# 1 post  -> 7.5 seconds
	# 2 posts -> 20.0 seconds
	# 3+ posts -> 42.0 seconds
	var break_duration = 7.5
	if tether_count == 2:
		break_duration = 20.0
	elif tether_count >= 3:
		break_duration = 42.0

	struggle_timer += delta
	var stress_ratio = clamp(struggle_timer / break_duration, 0.0, 1.0)

	# Update visual stress on all attached ropes
	for t in active_tethers:
		var rv = t.get("rope_visual")
		if is_instance_valid(rv) and "stress_level" in rv:
			rv.stress_level = stress_ratio

	# Pre-break warning when rope is about to snap
	if stress_ratio >= 0.75 and not struggle_warning_given:
		struggle_warning_given = true
		Events.prompt_flashed.emit("¡¡CRAC!! ¡La soga está a punto de romperse!", 2.2)


	# When struggle timer reaches break duration, snap a tether!
	if struggle_timer >= break_duration:
		_snap_tether()
		return

	# If tied to 3 or more posts, completely pinned and immobilized!
	if tether_count >= 3:
		velocity.x = move_toward(velocity.x, 0.0, 35.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 35.0 * delta)
		# Helpless spasm animation
		if visual:
			visual.rotation.z = sin(Time.get_ticks_msec() * 0.04) * 0.14
		return

	# If tied to 2 posts, severely constricted
	if tether_count == 2:
		var thrash = Vector3(sin(Time.get_ticks_msec() * 0.008), 0, cos(Time.get_ticks_msec() * 0.008)) * 1.2
		var target_vel = thrash * (chase_speed * 0.25)
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
		if visual:
			visual.rotation.z = sin(Time.get_ticks_msec() * 0.02) * 0.08
		return

	# 1 tether: thrashes within rope radius
	var anchor_pos: Vector3 = active_tethers[0]["anchor_pos"]
	var max_dist: float = active_tethers[0]["max_dist"]
	var to_anchor = anchor_pos - global_position
	to_anchor.y = 0.0

	if is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < max_dist + 2.0:
		_move_toward_point(player_ref.global_position, chase_speed * 0.5, delta)
	else:
		var thrash_dir = -to_anchor.normalized() + Vector3(sin(Time.get_ticks_msec() * 0.006), 0, cos(Time.get_ticks_msec() * 0.006)) * 0.4
		var target_vel = thrash_dir.normalized() * (chase_speed * 0.45)
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

func _snap_tether() -> void:
	struggle_timer = 0.0
	struggle_warning_given = false

	if active_tethers.is_empty():
		release_tether()
		return

	# Remove oldest tether
	var popped = active_tethers.pop_front()
	if is_instance_valid(popped.get("rope_visual")):
		popped["rope_visual"].queue_free()

	# Tension release snap surge forward
	if is_instance_valid(player_ref):
		var to_player = (player_ref.global_position - global_position).normalized()
		velocity += to_player * 8.5

	_flash_red_eyes()
	if visual:
		visual.rotation.x = deg_to_rad(-20.0)
		get_tree().create_timer(0.3).timeout.connect(func(): if visual: visual.rotation.x = 0.0)

	var remaining = active_tethers.size()
	if remaining == 0:
		is_tethered = false
		current_state = State.CHASE
		enrage_boost_timer = 4.0
		Events.prompt_flashed.emit("¡¡LA JARJACHA ROMPIÓ LA SOGA Y SE LIBERÓ ENFURECIDA!!", 3.5)
	else:
		var post_str = "queda 1 poste amarrado" if remaining == 1 else "quedan %d postes amarrados" % remaining
		Events.prompt_flashed.emit("¡¡SE ROMPIÓ UN AMARRE!! Aún %s" % post_str, 2.5)


func _process_stunned(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
	
	if visual:
		visual.rotation.z = sin(Time.get_ticks_msec() * 0.03) * 0.1

func receive_push(from_pos: Vector3, push_force: float = 14.0, stun_time: float = 2.4) -> void:
	if current_state == State.DEFEATED:
		return
	var push_dir = (global_position - from_pos).normalized()
	push_dir.y = 0.15
	velocity = push_dir * push_force
	current_state = State.STUNNED
	struggle_timer = max(0.0, struggle_timer - 1.8)
	# Visual flinch/recoil backwards
	if visual:
		visual.rotation.x = deg_to_rad(-25.0)
	var t = get_tree().create_timer(stun_time)
	t.timeout.connect(func():
		if current_state == State.STUNNED:
			if visual:
				visual.rotation.x = 0.0
			if not active_tethers.is_empty():
				current_state = State.TETHERED
			else:
				current_state = State.CHASE
	)

func take_damage(amount: float, is_blunt: bool = false, is_headshot: bool = false) -> void:
	if current_state == State.DEFEATED:
		return

	var final_amount = amount
	if is_headshot:
		final_amount *= 2.5
		# Head recoil flinch animation
		if head_pivot:
			head_pivot.rotation.x = deg_to_rad(-35.0)
			get_tree().create_timer(0.35).timeout.connect(func():
				if head_pivot: head_pivot.rotation.x = 0.0
			)

	current_health = max(0.0, current_health - final_amount)
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health, max_health)

	if current_health <= 0.0:
		_die()
		return

	if is_headshot or is_blunt or final_amount >= 40.0:
		current_state = State.STUNNED
		struggle_timer = max(0.0, struggle_timer - (2.5 if is_headshot else 1.2))
		var stun_duration = 2.4 if is_headshot else 1.8
		var timer = get_tree().create_timer(stun_duration)
		timer.timeout.connect(func():
			if current_state == State.STUNNED:
				if not active_tethers.is_empty():
					current_state = State.TETHERED
				else:
					current_state = State.CHASE
		)

func _die() -> void:
	# Clean up all tether rope visuals
	for t in active_tethers:
		if is_instance_valid(t.get("rope_visual")):
			t["rope_visual"].queue_free()
	active_tethers.clear()
	is_tethered = false

	if current_level < max_levels:
		current_level += 1
		current_state = State.STUNNED
		_flash_red_eyes()
		max_health = 100.0 * pow(2, current_level - 1) + 200.0 # scale health up
		current_health = max_health
		chase_speed += 1.0 # make it faster
		
		if health_bar and health_bar.has_node("BossName"):
			var phase_str = "FASE " + str(current_level)
			if current_level == max_levels: phase_str = "FASE FINAL"
			health_bar.get_node("BossName").text = "LA JARJACHA - " + phase_str
			
		if health_bar and health_bar.has_method("update_health"):
			health_bar.update_health(current_health, max_health)

		var p_text = "¡FASE " + str(current_level) + "! La Jarjacha enfurece"
		if current_level == max_levels: p_text = "¡FASE FINAL! ¡Atácala con todo!"
		Events.prompt_flashed.emit(p_text, 3.5)
			
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func():
			if current_state == State.STUNNED:
				current_state = State.CHASE
		)
		return

	current_state = State.DEFEATED
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(0.0, max_health)
	if eye_left and eye_right:
		eye_left.light_energy = 0.0
		eye_right.light_energy = 0.0
	if attack_area:
		attack_area.monitoring = false
		attack_area.monitorable = false
	collision_layer = 0

	# Collapse visual
	if visual:
		visual.rotation.x = deg_to_rad(75.0)
		visual.position.y = -0.5

	Events.prompt_flashed.emit("¡¡LA JARJACHA HA SIDO DERROTADA!!", 6.0)


func _flash_red_eyes() -> void:
	if eye_left and eye_right:
		var orig_col = eye_left.light_color
		eye_left.light_color = Color(1.0, 0.0, 0.0)
		eye_right.light_color = Color(1.0, 0.0, 0.0)
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): 
			if eye_left and eye_right:
				eye_left.light_color = orig_col
				eye_right.light_color = orig_col
		)

func _move_toward_point(target: Vector3, speed: float, delta: float) -> void:
	var to_target = target - global_position
	to_target.y = 0.0
	var dir = to_target.normalized()

	var target_vel = dir * speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	if visual and dir.length_squared() > 0.001:
		var target_angle = atan2(-dir.x, -dir.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, rotation_speed * delta)

func _update_jar_rhythm(delta: float) -> void:
	jar_sound_timer += delta
	# Visual neck/jaw spasm simulating the "jar... jar... jar..." chuckle
	if head_pivot and jaw:
		if current_state == State.CHASE:
			jaw.position.y = -0.15 + sin(Time.get_ticks_msec() * 0.02) * 0.08
		else:
			# Rhythmic twitch every 2 seconds
			if fmod(jar_sound_timer, 2.5) < 0.6:
				jaw.position.y = -0.15 + sin(Time.get_ticks_msec() * 0.015) * 0.06
			else:
				jaw.position.y = -0.15
