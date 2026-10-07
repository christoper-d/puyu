extends CharacterBody3D
class_name Player

enum ItemType {
	NONE = -1,
	ROPE = 0,
	AXE = 1,
	MACHETE = 2,
	SHOTGUN = 3
}

@export_group("Movement")
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var acceleration: float = 40.0
@export var air_acceleration: float = 18.0
@export var friction: float = 35.0
@export var air_friction: float = 4.0
@export var rotation_speed: float = 14.0

@export_group("Jump & Gravity")
@export var jump_velocity: float = 9.5
@export var jump_cut_multiplier: float = 0.5
@export var base_gravity: float = 22.0
@export var fall_gravity_multiplier: float = 1.6
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var camera_tilt_min: float = -75.0
@export var camera_tilt_max: float = 55.0

@export_group("Player Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0

# Node references
@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var hand_point: Marker3D = $Visual/HandPoint
@onready var hud_prompt: Label = $HUD/PromptLabel
@onready var hud_equipped: Label = $HUD/EquippedLabel
@onready var hud_crosshair: Control = $HUD/Crosshair
@onready var hud_hug: Label = $HUD/HugIndicator
@onready var hud_health_bar: ProgressBar = $HUD/HealthBar
@onready var hud_health_label: Label = $HUD/HealthLabel
@onready var muzzle_flash: OmniLight3D = $Visual/HandPoint/MuzzleFlash
@onready var wall_hug_system: Node = get_node_or_null("WallHug")
@onready var combo_button: Button = get_node_or_null("HUD/ComboButton")
@onready var mobile_controls: Control = get_node_or_null("HUD/MobileControls")


# Internal timers & state
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_jumping: bool = false
var _camera_rotation: Vector2 = Vector2.ZERO

# Inventory & Equipment
var inventory: Array[int] = [] # stores ItemType ints
var item_names: Dictionary = {} # ItemType -> String name
var weapon_catalog: Dictionary = {} # ItemType -> WeaponData (Resource)
var current_weapon_data: Resource = null

var equipped_item: ItemType = ItemType.NONE
var equipped_name: String = "Desarmado"
var current_interactable: Node = null
var current_prompt_text: String = ""

# Soga / Lasso state
var is_aiming: bool = false
var active_rope_visual: Node3D = null
var tethered_enemy: CharacterBody3D = null
var holding_rope_tension: bool = false

# Shotgun ammo
var shotgun_loaded: bool = true
var is_reloading: bool = false

# Melee swing
var is_swinging: bool = false
var swing_timer: float = 0.0

# Push / Shove mechanic
var push_cooldown: float = 0.0
var push_target_enemy: Node3D = null
var flash_prompt_timer: float = 0.0
var mobile_move_vector: Vector2 = Vector2.ZERO
var is_mobile: bool = false
var is_god_mode: bool = false
var is_speed_boost: bool = false

func _ready() -> void:
	add_to_group("player")
	_setup_default_inputs()
	_load_weapon_catalog()

	if Events:
		Events.prompt_flashed.connect(_flash_prompt)
		Events.control_mode_changed.connect(_on_control_mode_changed)
		Events.debug_god_mode_toggled.connect(_on_debug_god_mode_toggled)
		Events.debug_speed_boost_toggled.connect(_on_debug_speed_boost_toggled)
		Events.debug_give_all_weapons.connect(_on_debug_give_all_weapons)
	
	if mobile_controls:
		if mobile_controls.has_method("set_player"):
			mobile_controls.set_player(self)
		else:
			mobile_controls.player = self

	# Control mode default: real mobile OS = touch, PC = keyboard/mouse captured
	var is_real_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.get_name() == "Android" or OS.get_name() == "iOS"
	set_control_mode(is_real_mobile)

	if camera_pivot:
		_camera_rotation.x = camera_pivot.rotation.y
		_camera_rotation.y = camera_pivot.rotation.x
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())
	if combo_button:
		combo_button.pressed.connect(_execute_push)
	_update_hud()

func set_control_mode(mobile_mode: bool) -> void:
	is_mobile = mobile_mode
	if is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if mobile_controls:
			mobile_controls.visible = true
			if mobile_controls.has_method("set_active"):
				mobile_controls.set_active(true)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mobile_move_vector = Vector2.ZERO
		if mobile_controls:
			mobile_controls.visible = false
			if mobile_controls.has_method("set_active"):
				mobile_controls.set_active(false)
			if mobile_controls.has_method("reset_all"):
				mobile_controls.reset_all()

func _on_control_mode_changed(mobile_mode: bool) -> void:
	set_control_mode(mobile_mode)

	if camera_pivot:
		_camera_rotation.x = camera_pivot.rotation.y
		_camera_rotation.y = camera_pivot.rotation.x
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())
	if combo_button:
		combo_button.pressed.connect(_execute_push)
	_update_hud()

func _load_weapon_catalog() -> void:
	weapon_catalog[ItemType.ROPE] = preload("res://resources/weapons/soga.tres")
	weapon_catalog[ItemType.AXE] = preload("res://resources/weapons/hacha.tres")
	weapon_catalog[ItemType.MACHETE] = preload("res://resources/weapons/machete.tres")
	weapon_catalog[ItemType.SHOTGUN] = preload("res://resources/weapons/escopeta.tres")


func _setup_default_inputs() -> void:
	_ensure_key_action("move_forward", KEY_W, KEY_UP)
	_ensure_key_action("move_backward", KEY_S, KEY_DOWN)
	_ensure_key_action("move_left", KEY_A, KEY_LEFT)
	_ensure_key_action("move_right", KEY_D, KEY_RIGHT)
	_ensure_key_action("jump", KEY_SPACE)
	_ensure_key_action("sprint", KEY_SHIFT)
	_ensure_key_action("interact", KEY_E)

func _ensure_key_action(action: StringName, primary: Key, secondary: Key = KEY_NONE) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var events = InputMap.action_get_events(action)
	var keys = [primary]
	if secondary != KEY_NONE:
		keys.append(secondary)
	for k in keys:
		var has_key = false
		for ev in events:
			if ev is InputEventKey and ev.physical_keycode == k:
				has_key = true
				break
		if not has_key:
			var new_ev = InputEventKey.new()
			new_ev.physical_keycode = k
			InputMap.action_add_event(action, new_ev)

func rotate_camera(relative: Vector2, sensitivity: float) -> void:
	var sens = sensitivity * (0.6 if is_aiming else 1.0)
	_camera_rotation.x -= relative.x * sens
	_camera_rotation.y = clamp(
		_camera_rotation.y - relative.y * sens,
		deg_to_rad(camera_tilt_min),
		deg_to_rad(camera_tilt_max)
	)
	_update_camera_rotation()

func _unhandled_input(event: InputEvent) -> void:
	# On mobile, ignore mouse motion and button events generated by touch emulation
	if is_mobile and (event is InputEventMouseMotion or event is InputEventMouseButton):
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = mouse_sensitivity * (0.6 if is_aiming else 1.0)
		_camera_rotation.x -= event.relative.x * sens
		_camera_rotation.y -= event.relative.y * sens
		_camera_rotation.y = clamp(
			_camera_rotation.y,
			deg_to_rad(camera_tilt_min),
			deg_to_rad(camera_tilt_max)
		)
		_update_camera_rotation()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				if not (mobile_controls and mobile_controls.visible):
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				_handle_primary_action()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_aiming = event.pressed
			_update_aim_visuals()

	if event.is_action_pressed("interact"):
		_handle_interaction()
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			if wall_hug_system and wall_hug_system.has_method("is_hugging") and wall_hug_system.is_hugging():
				pass # Let wall hug system peek
			else:
				_execute_push()
		elif event.keycode == KEY_R and equipped_item == ItemType.SHOTGUN:
			_reload_shotgun()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
			var idx = event.keycode - KEY_1
			if idx < inventory.size():
				_switch_weapon(inventory[idx])

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	push_cooldown = max(0.0, push_cooldown - delta)
	flash_prompt_timer = max(0.0, flash_prompt_timer - delta)
	_handle_jump_input()
	_apply_gravity(delta)
	_handle_movement(delta)
	_update_swing(delta)
	_update_rope_tension(delta)
	_update_hug_hud()
	_update_camera_spring(delta)
	_check_push_prompt()
	_update_combo_prompt()
	_check_anchor_prompt()

	# Clean up interactable if destroyed or invalid
	if current_interactable != null and not is_instance_valid(current_interactable):
		clear_interact_prompt(null)

	move_and_slide()

	# Void fall protection: respawn safely on plaza ground if physics glitch occurs
	if global_position.y < -12.0:
		velocity = Vector3.ZERO
		global_position = Vector3(0.0, 1.0, 12.0)

func _update_hug_hud() -> void:
	if not hud_hug:
		return
	if wall_hug_system and wall_hug_system.has_method("is_hugging"):
		if wall_hug_system.is_hugging():
			hud_hug.visible = true
			if wall_hug_system.is_peeking():
				hud_hug.text = "Asomándose..."
			else:
				hud_hug.text = "[F] Asomarse | [Suelta Q] Salir"
		else:
			hud_hug.visible = false
	else:
		hud_hug.visible = false

func _update_camera_rotation() -> void:
	if camera_pivot:
		camera_pivot.rotation.y = _camera_rotation.x
		camera_pivot.rotation.x = _camera_rotation.y

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_is_jumping = false
	else:
		_coyote_timer = max(0.0, _coyote_timer - delta)

	_jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)

func _handle_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	var can_jump: bool = (_coyote_timer > 0.0) and not _is_jumping
	if _jump_buffer_timer > 0.0 and can_jump:
		_execute_jump()

	if Input.is_action_just_released("jump") and velocity.y > 0.0 and _is_jumping:
		velocity.y *= jump_cut_multiplier

func _execute_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_is_jumping = true

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav = base_gravity
		if velocity.y < 0.0:
			grav *= fall_gravity_multiplier
		velocity.y -= grav * delta

func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if mobile_move_vector.length_squared() > 0.01:
		input_dir = mobile_move_vector
	
	
	var is_sprinting: bool = Input.is_action_pressed("sprint") and not is_aiming and not holding_rope_tension
	if mobile_move_vector.length() > 0.88 and not is_aiming and not holding_rope_tension:
		is_sprinting = true

	var target_speed: float = sprint_speed if is_sprinting else walk_speed
	if is_speed_boost:
		target_speed *= 2.2
	if is_aiming:
		target_speed *= 0.55
	elif holding_rope_tension:
		target_speed *= 0.70

	# Wall hug limits movement
	if wall_hug_system and wall_hug_system.has_method("get_speed_multiplier"):
		target_speed *= wall_hug_system.get_speed_multiplier()

	var direction: Vector3 = Vector3.ZERO
	if input_dir.length_squared() > 0.001 and camera_pivot:
		var cam_basis = camera_pivot.global_transform.basis
		var forward = -cam_basis.z
		var right = cam_basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		direction = (right * input_dir.x + forward * -input_dir.y).normalized()

	var accel = acceleration if is_on_floor() else air_acceleration
	var decel = friction if is_on_floor() else air_friction

	var horizontal_vel = Vector3(velocity.x, 0.0, velocity.z)
	if direction.length_squared() > 0.001:
		var target_vel = direction * target_speed
		if mobile_move_vector.length_squared() > 0.01:
			target_vel = direction * (target_speed * clamp(mobile_move_vector.length(), 0.35, 1.0))
		horizontal_vel = horizontal_vel.move_toward(target_vel, accel * delta)

		if visual:
			var target_angle = atan2(-direction.x, -direction.z)
			if is_aiming:
				# Face camera direction when aiming
				var cam_fwd = -camera_pivot.global_transform.basis.z
				cam_fwd.y = 0.0
				target_angle = atan2(-cam_fwd.x, -cam_fwd.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, rotation_speed * delta)
	else:
		horizontal_vel = horizontal_vel.move_toward(Vector3.ZERO, decel * delta)
		if is_aiming and visual:
			var cam_fwd = -camera_pivot.global_transform.basis.z
			cam_fwd.y = 0.0
			var target_angle = atan2(-cam_fwd.x, -cam_fwd.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, rotation_speed * delta)

	velocity.x = horizontal_vel.x
	velocity.z = horizontal_vel.z

# --- Interaction & Inventory ---
func set_interact_prompt(text: String, caller: Node) -> void:
	current_prompt_text = text
	current_interactable = caller
	_update_hud()

func clear_interact_prompt(caller: Node = null) -> void:
	if caller == null or current_interactable == caller:
		current_interactable = null
		current_prompt_text = ""
		if hud_prompt:
			hud_prompt.visible = false
			hud_prompt.text = ""
		_update_hud()

func equip_item(type: int, item_title: String) -> void:
	if not inventory.has(type):
		inventory.append(type)
	item_names[type] = item_title
	_switch_weapon(type)
	current_prompt_text = ""
	current_interactable = null
	if hud_prompt:
		hud_prompt.visible = false
		hud_prompt.text = ""
	if Events:
		Events.inventory_updated.emit()
	if mobile_controls and mobile_controls.has_method("_refresh_weapon_bar"):
		mobile_controls._refresh_weapon_bar()

func _switch_weapon(type: int) -> void:
	equipped_item = type as ItemType
	current_weapon_data = weapon_catalog.get(equipped_item, null)
	if current_weapon_data:
		equipped_name = current_weapon_data.display_name
	else:
		equipped_name = item_names.get(type, "Desarmado")
	_update_hud()
	_update_aim_visuals()
	if Events:
		Events.weapon_switched.emit(equipped_item, equipped_name)
	if mobile_controls and mobile_controls.has_method("_refresh_weapon_bar"):
		mobile_controls._refresh_weapon_bar()

func next_weapon() -> void:
	if inventory.is_empty():
		return
	var current_idx = inventory.find(equipped_item)
	var next_idx = (current_idx + 1) % inventory.size()
	_switch_weapon(inventory[next_idx])


func _handle_interaction() -> void:
	# 1. If holding a roped Jarjacha and near an anchor post:
	if holding_rope_tension and is_instance_valid(tethered_enemy):
		var anchors = get_tree().get_nodes_in_group("rope_anchor")
		for anchor in anchors:
			if global_position.distance_to(anchor.global_position) < 4.5:
				_tie_rope_to_anchor(anchor)
				return

	# 2. Regular item pickup:
	if is_instance_valid(current_interactable):
		if current_interactable.has_method("interact"):
			current_interactable.interact()

func _handle_primary_action() -> void:
	match equipped_item:
		ItemType.ROPE:
			if holding_rope_tension and hud_prompt.visible and "Anclar" in hud_prompt.text:
				_handle_interaction()
			else:
				_throw_rope()
		ItemType.AXE, ItemType.MACHETE:
			_swing_melee()
		ItemType.SHOTGUN:
			_fire_shotgun()

# --- Rope / Soga Mechanic ---
func _throw_rope() -> void:
	if holding_rope_tension:
		# Release current rope
		_release_rope()
		return

	var space_state = get_world_3d().direct_space_state
	var cam_pos = camera.global_position
	var cam_forward = -camera.global_transform.basis.z
	var ray_end = cam_pos + (cam_forward * 22.0)

	var query = PhysicsRayQueryParameters3D.create(cam_pos, ray_end, 5) # World + Enemy
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if not result.is_empty():
		var hit_collider = result.collider
		var enemy = hit_collider
		if not enemy.has_method("apply_rope_tether") and hit_collider.get_parent().has_method("apply_rope_tether"):
			enemy = hit_collider.get_parent()

		if enemy and enemy.has_method("apply_rope_tether"):
			_calculate_and_apply_lasso(enemy)
		else:
			_flash_prompt("La soga rebotó en la piedra", 1.5)
	else:
		_flash_prompt("Lanzaste la soga al vacío", 1.5)

func _calculate_and_apply_lasso(enemy: CharacterBody3D) -> void:
	var success_chance: float = 0.50

	# Height advantage (on roof/terrace)
	var y_diff = global_position.y - enemy.global_position.y
	if y_diff > 1.8:
		success_chance += 0.40

	# Stealth advantage
	var e_state = enemy.get("current_state")
	if e_state == 0: # PATROL
		success_chance += 0.35
	elif e_state == 1: # INVESTIGATE
		success_chance += 0.20
	elif e_state == 2: # CHASE
		success_chance -= 0.25

	var roll = randf()
	if roll <= success_chance:
		_latch_rope_to_enemy(enemy)
	else:
		_flash_prompt("¡La Jarjacha sacudió el cuello y esquivó la soga!", 2.0)
		if enemy.has_method("alert_investigate"):
			enemy.alert_investigate(global_position)

func _latch_rope_to_enemy(enemy: CharacterBody3D) -> void:
	tethered_enemy = enemy
	holding_rope_tension = true
	if enemy.has_method("apply_player_lasso"):
		enemy.apply_player_lasso()
	_flash_prompt("¡ENGRILLETADA! Corre a un poste para amarrarla [E]", 3.5)

	# Spawn visual rope
	var rope_scene = load("res://scenes/props/rope_visual.tscn")
	if rope_scene:
		active_rope_visual = rope_scene.instantiate()
		get_parent().add_child(active_rope_visual)
		var from_node: Node3D = self
		if hand_point:
			from_node = hand_point
		var target_point: Node3D = enemy
		if enemy.has_node("Visual/Neck/TetherPoint"):
			target_point = enemy.get_node("Visual/Neck/TetherPoint")
		active_rope_visual.setup_targets(from_node, target_point)

	# Apply tether physics to Jarjacha
	if enemy.has_method("apply_rope_tether"):
		enemy.apply_rope_tether(global_position, 8.0, self)

func _tie_rope_to_anchor(anchor_node: Node3D) -> void:
	if not is_instance_valid(tethered_enemy):
		return

	var anchor_pos = anchor_node.global_position
	if anchor_node.has_node("TetherMarker"):
		anchor_pos = anchor_node.get_node("TetherMarker").global_position

	# Transfer visual rope to anchor
	if is_instance_valid(active_rope_visual):
		active_rope_visual.set_fixed_start(anchor_pos, tethered_enemy.tether_attach_point)

	# Constrain enemy around the post using multi-tether system
	if tethered_enemy.has_method("add_post_tether"):
		tethered_enemy.add_post_tether(anchor_pos, 5.0, anchor_node, active_rope_visual)
	elif tethered_enemy.has_method("apply_rope_tether"):
		tethered_enemy.apply_rope_tether(anchor_pos, 5.0, anchor_node)

	if tethered_enemy.has_method("release_player_lasso"):
		tethered_enemy.release_player_lasso()

	# Handover ownership of active_rope_visual to Jarjacha
	active_rope_visual = null
	holding_rope_tension = false

	var t_count = 1
	if "active_tethers" in tethered_enemy:
		t_count = tethered_enemy.active_tethers.size()

	if t_count >= 3:
		_flash_prompt("¡¡AMARRADA A 3 POSTES!! ¡Totalmente inmovilizada!", 4.0)
	elif t_count == 2:
		_flash_prompt("¡AMARRADA A 2 POSTES! Movimiento muy reducido", 3.5)
	else:
		_flash_prompt("¡AMARRADA AL POSTE! Amárrala a más postes o atácala", 3.0)

	tethered_enemy = null
	_update_hud()

func _release_rope() -> void:
	if is_instance_valid(tethered_enemy):
		if tethered_enemy.has_method("release_player_lasso"):
			tethered_enemy.release_player_lasso()
		if "active_tethers" in tethered_enemy and tethered_enemy.active_tethers.is_empty():
			tethered_enemy.release_tether()
	if is_instance_valid(active_rope_visual):
		active_rope_visual.queue_free()
		active_rope_visual = null
	tethered_enemy = null
	holding_rope_tension = false
	_update_hud()

func _update_rope_tension(delta: float) -> void:
	if holding_rope_tension and is_instance_valid(tethered_enemy):
		var dist = global_position.distance_to(tethered_enemy.global_position)
		if dist > 11.0:
			_flash_prompt("¡La soga se rompió por exceso de tensión!", 2.5)
			_release_rope()
			return
		elif dist > 6.0:
			# Fuerte tirón físico modificando posición y velocidad
			var pull_dir = (tethered_enemy.global_position - global_position).normalized()
			var overshoot = dist - 6.0
			global_position += pull_dir * (overshoot * 4.5 * delta)
			velocity += pull_dir * (overshoot * 20.0 * delta)

# --- Weapons (Axe, Machete, Shotgun) ---
func _get_enemy_from_collider(node: Node) -> Node:
	var curr: Node = node
	while curr:
		if curr.has_method("take_damage") and curr != self:
			return curr
		curr = curr.get_parent()
	return null

func _is_headshot_hit(collider: Node, hit_pos: Vector3, enemy: Node) -> bool:
	if not enemy:
		return false
	if collider.is_in_group("enemy_head") or collider.name == "HeadArea":
		return true
	if hit_pos.y - enemy.global_position.y >= 1.45:
		return true
	return false

func _swing_melee(override_damage: float = -1.0, override_is_blunt: bool = false) -> void:
	if is_swinging:
		return
	is_swinging = true

	var damage = 20.0
	var is_blunt = false
	var cooldown = 0.45
	var hit_range = 3.8
	var tet_mult = 1.6
	var hs_mult = 2.5

	if current_weapon_data:
		damage = current_weapon_data.base_damage
		is_blunt = current_weapon_data.is_blunt
		cooldown = current_weapon_data.attack_cooldown
		hit_range = current_weapon_data.attack_range
		tet_mult = current_weapon_data.tethered_damage_bonus
		hs_mult = current_weapon_data.headshot_multiplier

	if override_damage > 0.0:
		damage = override_damage
		is_blunt = override_is_blunt

	swing_timer = cooldown

	# Visual tilt forward
	if visual:
		visual.rotation.x = deg_to_rad(20.0)

	# Hit detection forward
	var space_state = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.25, 0)
	var forward = -camera.global_transform.basis.z if is_aiming else -visual.global_transform.basis.z
	var ray_dir = forward.normalized()
	var ray_end = origin + (ray_dir * hit_range)

	var query = PhysicsRayQueryParameters3D.create(origin, ray_end, 5) # Layer 1 (world) + Layer 4 (enemy)
	query.collide_with_areas = true
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	var hit_enemy = null
	var is_headshot = false

	if not result.is_empty():
		var hit = result.collider
		var enemy = _get_enemy_from_collider(hit)
		if enemy:
			hit_enemy = enemy
			is_headshot = _is_headshot_hit(hit, result.position, enemy)

	# Proximity assist: check enemies in front within hit_range * 0.85
	if not hit_enemy:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if is_instance_valid(e) and e.has_method("take_damage") and e.get("current_state") != 6: # not DEFEATED
				var to_e = e.global_position - global_position
				to_e.y = 0.0
				if to_e.length() <= hit_range:
					var angle = rad_to_deg(forward.angle_to(to_e.normalized()))
					if angle <= 75.0:
						hit_enemy = e
						if camera and camera.rotation.x > deg_to_rad(-5.0):
							is_headshot = true
						break

	if hit_enemy:
		var is_tet = hit_enemy.get("is_tethered") == true
		var base_dmg = damage * (tet_mult if is_tet else 1.0)
		hit_enemy.take_damage(base_dmg, is_blunt, is_headshot)
		if Events:
			Events.enemy_damaged.emit(hit_enemy, base_dmg, is_headshot)
		if is_headshot:
			if Events:
				Events.headshot_landed.emit(hit_enemy, base_dmg * hs_mult)
			_flash_prompt("¡¡IMPACTO CRÍTICO EN LA CABEZA!! (%.0f)" % (base_dmg * hs_mult), 2.0)
		else:
			_flash_prompt("¡IMPACTO! (%.0f daño)" % base_dmg, 1.2)
	else:
		_flash_prompt("Ataque al aire", 0.6)

func _update_swing(delta: float) -> void:
	if is_swinging:
		swing_timer -= delta
		if swing_timer <= 0.0:
			is_swinging = false
			if visual:
				visual.rotation.x = 0.0

func _reload_shotgun() -> void:
	if shotgun_loaded or is_reloading:
		return
	is_reloading = true
	_flash_prompt("Recargando escopeta...", 1.2)
	var t = get_tree().create_timer(1.2)
	t.timeout.connect(func():
		shotgun_loaded = true
		is_reloading = false
		_flash_prompt("¡Escopeta cargada!", 1.0)
		_update_hud()
	)

func _fire_shotgun() -> void:
	if not shotgun_loaded:
		_reload_shotgun()
		return

	shotgun_loaded = false
	_update_hud()

	var shot_dmg = 65.0
	var shot_hs_mult = 2.5
	var shot_range = 25.0
	if current_weapon_data:
		shot_dmg = current_weapon_data.base_damage
		shot_hs_mult = current_weapon_data.headshot_multiplier
		shot_range = current_weapon_data.attack_range

	# Screen recoil kick
	_camera_rotation.y = clamp(_camera_rotation.y + deg_to_rad(12.0), deg_to_rad(camera_tilt_min), deg_to_rad(camera_tilt_max))
	_update_camera_rotation()

	# Flash
	if muzzle_flash:
		muzzle_flash.visible = true
		get_tree().create_timer(0.08).timeout.connect(func(): if muzzle_flash: muzzle_flash.visible = false)

	# Blast raycasts (Spread)
	var space_state = get_world_3d().direct_space_state
	var cam_pos = camera.global_position
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	var cam_up = camera.global_transform.basis.y
	
	var hit_enemy = null
	var is_headshot = false
	
	# Create a spread pattern: center, left, right, up, down + diagonals
	var offsets = [
		Vector3.ZERO,
		cam_right * 0.12,
		-cam_right * 0.12,
		cam_up * 0.12,
		-cam_up * 0.12,
		(cam_right + cam_up) * 0.08,
		(-cam_right + cam_up) * 0.08
	]
	
	for offset in offsets:
		var dir = (cam_forward + offset).normalized()
		var ray_end = cam_pos + (dir * shot_range)
		var query = PhysicsRayQueryParameters3D.create(cam_pos, ray_end, 5) # 1 (world) | 4 (enemy)
		query.collide_with_areas = true # Detects HeadArea
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			var hit = result.collider
			var enemy = _get_enemy_from_collider(hit)
			if enemy:
				hit_enemy = enemy
				if _is_headshot_hit(hit, result.position, enemy):
					is_headshot = true
					break # Priority: if any pellet landed in the head, headshot locks!
				
	if hit_enemy:
		hit_enemy.take_damage(shot_dmg, true, is_headshot) # Stuns Jarjacha!
		if Events:
			Events.enemy_damaged.emit(hit_enemy, shot_dmg, is_headshot)
		if is_headshot:
			if Events:
				Events.headshot_landed.emit(hit_enemy, shot_dmg * shot_hs_mult)
			_flash_prompt("¡¡DISPARO EN LA CABEZA!! ¡Daño crítico masivo! (%.0f)" % (shot_dmg * shot_hs_mult), 2.5)
		else:
			_flash_prompt("¡PERDIGONADA DIRECTA! Impacto al cuerpo (%.0f daño)" % shot_dmg, 2.0)
	else:
		_flash_prompt("Disparo fallido...", 1.2)

	# Pushback on player
	velocity -= cam_forward * 6.0

func take_damage(amount: float) -> void:
	if is_god_mode:
		_flash_prompt("🛡️ ¡MODO DIOS! Daño bloqueado", 1.0)
		return
	current_health = max(0.0, current_health - amount)
	if Events:
		Events.player_health_changed.emit(current_health, max_health)
	_flash_prompt("¡GOLPE RECIBIDO! Salud: %.0f" % current_health, 1.5)
	_update_hud()
	if current_health <= 0.0:
		_flash_prompt("HAS CAÍDO EN LA NIEBLA...", 5.0)

func _on_debug_god_mode_toggled(enabled: bool) -> void:
	is_god_mode = enabled
	if is_god_mode:
		current_health = max_health
		_update_hud()
		_flash_prompt("🛠️ Modo Dios: ACTIVADO", 1.5)
	else:
		_flash_prompt("🛠️ Modo Dios: DESACTIVADO", 1.5)

func _on_debug_speed_boost_toggled(enabled: bool) -> void:
	is_speed_boost = enabled
	_flash_prompt("🛠️ Super Velocidad: %s" % ("ACTIVADA" if enabled else "DESACTIVADA"), 1.5)

func _on_debug_give_all_weapons() -> void:
	equip_item(ItemType.ROPE, "Soga")
	equip_item(ItemType.AXE, "Hacha")
	equip_item(ItemType.MACHETE, "Machete")
	equip_item(ItemType.SHOTGUN, "Escopeta")
	shotgun_loaded = true
	_switch_weapon(ItemType.AXE)
	_flash_prompt("🛠️ ¡Todas las armas agregadas al inventario!", 2.5)


# --- UI / HUD ---
func _update_hud() -> void:
	if hud_health_bar and hud_health_label:
		hud_health_bar.max_value = max_health
		hud_health_bar.value = current_health
		hud_health_label.text = "VIDA: %.0f" % current_health
		
	if hud_equipped:
		var status = ""
		if equipped_item == ItemType.ROPE and holding_rope_tension:
			status = " (TENSA - [E] para amarrar)"
		elif equipped_item == ItemType.SHOTGUN:
			status = " (1/1)" if shotgun_loaded else " (Vacía)"
		hud_equipped.text = "Arma: " + equipped_name + status

	if hud_prompt:
		if current_prompt_text != "" and current_interactable != null:
			hud_prompt.text = current_prompt_text
			hud_prompt.visible = true
		else:
			hud_prompt.visible = false
			hud_prompt.text = ""

func _update_aim_visuals() -> void:
	if hud_crosshair:
		hud_crosshair.visible = is_aiming

func _update_camera_spring(delta: float) -> void:
	if not spring_arm or not camera:
		return

	# Lateral and vertical shoulder offset:
	# Normal mode: offset x=0.52, y=0.0, length=2.8, fov=52.0
	# Aim mode: pushes camera clearly past the cat's ear/shoulder (x=0.88, y=0.12, length=1.9, fov=44.0)
	var target_arm_x = 0.88 if is_aiming else 0.52
	var target_arm_y = 0.12 if is_aiming else 0.0
	var target_len = 1.9 if is_aiming else 2.8
	var target_fov = 44.0 if is_aiming else 52.0

	spring_arm.position.x = lerp(spring_arm.position.x, target_arm_x, 10.0 * delta)
	spring_arm.position.y = lerp(spring_arm.position.y, target_arm_y, 10.0 * delta)
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_len, 10.0 * delta)
	camera.fov = lerp(camera.fov, target_fov, 10.0 * delta)

func _flash_prompt(msg: String, duration: float) -> void:
	if hud_prompt:
		flash_prompt_timer = duration
		hud_prompt.text = msg
		hud_prompt.visible = true
		get_tree().create_timer(duration).timeout.connect(func():
			if hud_prompt and flash_prompt_timer <= 0.0:
				if current_prompt_text == "" or current_interactable == null:
					hud_prompt.visible = false
					hud_prompt.text = ""
				else:
					hud_prompt.text = current_prompt_text
					hud_prompt.visible = true
		)

func _check_anchor_prompt() -> void:
	if holding_rope_tension and is_instance_valid(tethered_enemy):
		var anchors = get_tree().get_nodes_in_group("rope_anchor")
		var near_anchor = false
		for anchor in anchors:
			if global_position.distance_to(anchor.global_position) < 4.5:
				near_anchor = true
				break
		if near_anchor:
			hud_prompt.text = "[E] / [Click] Anclar Soga a Poste"
			hud_prompt.visible = true
			return
		
	if flash_prompt_timer > 0.0:
		return

	if not current_interactable and not push_target_enemy:
		hud_prompt.visible = false

func _check_push_prompt() -> void:
	if holding_rope_tension or push_cooldown > 0.0:
		return

	push_target_enemy = null
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("receive_push") and e.get("current_state") != 6: # not DEFEATED
			var to_e = e.global_position - global_position
			to_e.y = 0.0
			var dist = to_e.length()
			if dist <= 3.8 and dist >= 0.3:
				var cam_fwd = -camera.global_transform.basis.z if camera else Vector3.FORWARD
				cam_fwd.y = 0.0
				cam_fwd = cam_fwd.normalized()
				var vis_fwd = -visual.global_transform.basis.z if visual else cam_fwd
				vis_fwd.y = 0.0
				vis_fwd = vis_fwd.normalized()
				var angle_cam = rad_to_deg(cam_fwd.angle_to(to_e.normalized()))
				var angle_vis = rad_to_deg(vis_fwd.angle_to(to_e.normalized()))
				if angle_cam <= 85.0 or angle_vis <= 85.0:
					push_target_enemy = e
					flash_prompt_timer = 0.0 # Push prompt takes priority
					var prompt_str = "[F] ¡EMPUJAR CON HACHA!" if equipped_item == ItemType.AXE else "[F] ¡EMPUJAR!"
					hud_prompt.text = prompt_str
					hud_prompt.visible = true
					return

func _update_combo_prompt() -> void:
	if not combo_button:
		return
	if is_instance_valid(push_target_enemy) and push_cooldown <= 0.0:
		var head_world = push_target_enemy.global_position + Vector3(0, 2.2, 0)
		if push_target_enemy.has_node("Visual/Neck/Head"):
			head_world = push_target_enemy.get_node("Visual/Neck/Head").global_position + Vector3(0, 0.45, 0)

		if camera and not camera.is_position_behind(head_world):
			var screen_pos = camera.unproject_position(head_world)
			var bob = sin(Time.get_ticks_msec() * 0.008) * 3.5
			combo_button.position = screen_pos - (combo_button.size * 0.5) + Vector2(0, bob)

			var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.06
			combo_button.scale = Vector2(pulse, pulse)

			var prompt_title = "💥 ¡EMPUJAR CON HACHA!" if equipped_item == ItemType.AXE else "💥 ¡EMPUJAR!"
			combo_button.text = prompt_title + "\n[ TOCA O 'F' ]"
			combo_button.visible = true
			return
	combo_button.visible = false

func _execute_push() -> void:
	if push_cooldown > 0.0:
		return

	if combo_button:
		combo_button.visible = false


	if not is_instance_valid(push_target_enemy):
		var enemies = get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if is_instance_valid(e) and e.has_method("receive_push") and e.get("current_state") != 6:
				var to_e = e.global_position - global_position
				to_e.y = 0.0
				if to_e.length() <= 3.5:
					push_target_enemy = e
					break

	if not is_instance_valid(push_target_enemy):
		return

	push_cooldown = 2.4

	# Visual thrust forward
	if visual:
		visual.position.z -= 0.35
		visual.rotation.x = deg_to_rad(-18.0)
		get_tree().create_timer(0.25).timeout.connect(func():
			if visual:
				visual.position.z = 0.0
				visual.rotation.x = 0.0
		)

	# Knock enemy back and stun
	if push_target_enemy.has_method("receive_push"):
		var push_force = 16.0 if equipped_item == ItemType.AXE else 12.0
		if current_weapon_data:
			push_force = current_weapon_data.push_force
		push_target_enemy.receive_push(global_position, push_force, 2.5)
		if Events:
			Events.combo_push_executed.emit(push_target_enemy, push_force)
		_flash_prompt("¡¡EMPUJÓN CERTERO!! Jarjacha aturdida", 2.2)

	# Player push recoil
	velocity -= (push_target_enemy.global_position - global_position).normalized() * 3.5

