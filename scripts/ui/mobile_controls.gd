class_name MobileControls
extends Control

@export var camera_sensitivity: float = 0.006

@onready var joystick: PuyuVirtualJoystick = $Joystick
@onready var actions: Control = $Actions
@onready var btn_attack: Button = $Actions/BtnAttack
@onready var btn_aim: Button = $Actions/BtnAim
@onready var btn_jump: Button = $Actions/BtnJump
@onready var btn_interact: Button = $Actions/BtnInteract
@onready var btn_reload: Button = $Actions/BtnReload
@onready var weapon_dock: Control = $WeaponDock
@onready var weapon_bar: HBoxContainer = $WeaponDock/WeaponBar
@onready var btn_cycle_weapon: Button = $WeaponDock/BtnCycleWeapon
@onready var pc_toggle_btn: Button = $PCToggleButton

var player: CharacterBody3D = null
var is_mobile: bool = false
var joystick_touch_id: int = -1
var camera_touch_id: int = -1

func _ready() -> void:
	_find_player()

	is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.get_name() == "Android" or OS.get_name() == "iOS" or DisplayServer.is_touchscreen_available()

	visible = is_mobile
	if pc_toggle_btn:
		pc_toggle_btn.visible = not is_mobile
		pc_toggle_btn.text = "Touch: OFF"

	_connect_signals()
	_refresh_weapon_bar()

func set_player(p: CharacterBody3D) -> void:
	player = p
	_refresh_weapon_bar()

func _find_player() -> void:
	if is_instance_valid(player):
		return
	var cur: Node = get_parent()
	while cur:
		if cur is CharacterBody3D:
			player = cur
			return
		cur = cur.get_parent()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _connect_signals() -> void:
	if joystick:
		joystick.joystick_moved.connect(_on_joystick_moved)
		joystick.joystick_released.connect(_on_joystick_released)

	if btn_attack:
		btn_attack.pressed.connect(_on_attack_pressed)
	if btn_aim:
		btn_aim.pressed.connect(_on_aim_pressed)
	if btn_jump:
		btn_jump.pressed.connect(_on_jump_pressed)
	if btn_interact:
		btn_interact.pressed.connect(_on_interact_pressed)
	if btn_reload:
		btn_reload.pressed.connect(_on_reload_pressed)
	if btn_cycle_weapon:
		btn_cycle_weapon.pressed.connect(_on_cycle_weapon_pressed)
	if pc_toggle_btn:
		pc_toggle_btn.pressed.connect(_on_pc_toggle_pressed)

	if Events:
		if not Events.weapon_switched.is_connected(_on_event_weapon_switched):
			Events.weapon_switched.connect(_on_event_weapon_switched)
		if not Events.inventory_updated.is_connected(_on_event_inventory_updated):
			Events.inventory_updated.connect(_on_event_inventory_updated)

func _on_event_weapon_switched(_type: int, _name: String) -> void:
	_refresh_weapon_bar()

func _on_event_inventory_updated() -> void:
	_refresh_weapon_bar()

func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return

	# Reload button visibility (only for shotgun when empty)
	if btn_reload:
		var has_shotgun = player.get("equipped_item") == 3 # ItemType.SHOTGUN
		var loaded = player.get("shotgun_loaded") == true
		btn_reload.visible = has_shotgun and not loaded

	# Aim button highlight indicator
	if btn_aim and "is_aiming" in player:
		btn_aim.modulate = Color(1.3, 1.25, 0.7, 1.0) if player.is_aiming else Color(1.0, 1.0, 1.0, 0.85)

func _on_joystick_moved(vec: Vector2) -> void:
	if is_instance_valid(player):
		player.mobile_move_vector = vec

func _on_joystick_released() -> void:
	if is_instance_valid(player):
		player.mobile_move_vector = Vector2.ZERO

func _on_attack_pressed() -> void:
	if is_instance_valid(player) and player.has_method("_handle_primary_action"):
		player._handle_primary_action()

func _on_aim_pressed() -> void:
	if is_instance_valid(player) and "is_aiming" in player:
		player.is_aiming = not player.is_aiming
		if player.has_method("_update_aim_visuals"):
			player._update_aim_visuals()

func _on_jump_pressed() -> void:
	if is_instance_valid(player) and player.has_method("_execute_jump"):
		if player.is_on_floor():
			player._execute_jump()

func _on_interact_pressed() -> void:
	if is_instance_valid(player) and player.has_method("_handle_interaction"):
		player._handle_interaction()

func _on_reload_pressed() -> void:
	if is_instance_valid(player) and player.has_method("_reload_shotgun"):
		player._reload_shotgun()

func _on_cycle_weapon_pressed() -> void:
	if is_instance_valid(player) and player.has_method("next_weapon"):
		player.next_weapon()
		_refresh_weapon_bar()

func _on_pc_toggle_pressed() -> void:
	visible = not visible
	if pc_toggle_btn:
		pc_toggle_btn.text = "Touch: ON" if visible else "Touch: OFF"
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if is_instance_valid(player):
			player.mobile_move_vector = Vector2.ZERO
		if joystick:
			joystick.reset_joystick()
		joystick_touch_id = -1
		camera_touch_id = -1

func _refresh_weapon_bar() -> void:
	if not is_instance_valid(player) or not weapon_bar:
		return

	for c in weapon_bar.get_children():
		c.queue_free()

	var inv = player.get("inventory")
	if not inv or inv.is_empty():
		if btn_cycle_weapon:
			btn_cycle_weapon.text = "Desarmado"
		return

	var equipped = player.get("equipped_item")
	var names = player.get("item_names")

	if btn_cycle_weapon:
		var cur_name = names.get(equipped, "Arma") if names else "Arma"
		btn_cycle_weapon.text = "↻ " + cur_name

	for item_type in inv:
		var btn = Button.new()
		var item_name = names.get(item_type, str(item_type)) if names else str(item_type)
		btn.text = item_name
		btn.custom_minimum_size = Vector2(56, 24)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

		var is_cur = (item_type == equipped)
		if is_cur:
			btn.modulate = Color(1.3, 1.2, 0.4, 1.0)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85, 0.75)

		btn.pressed.connect(func():
			if is_instance_valid(player) and player.has_method("_switch_weapon"):
				player._switch_weapon(item_type)
				_refresh_weapon_bar()
		)
		weapon_bar.add_child(btn)

func _is_touch_on_ui(pos: Vector2) -> bool:
	var interactive_controls: Array[Control] = [
		btn_attack, btn_aim, btn_jump, btn_interact, btn_reload,
		btn_cycle_weapon, pc_toggle_btn
	]
	for ctrl in interactive_controls:
		if is_instance_valid(ctrl) and ctrl.is_visible_in_tree():
			if ctrl.get_global_rect().has_point(pos):
				return true

	if is_instance_valid(weapon_bar) and weapon_bar.is_visible_in_tree():
		for child in weapon_bar.get_children():
			if child is Control and child.is_visible_in_tree():
				if child.get_global_rect().has_point(pos):
					return true

	if is_instance_valid(player):
		var combo_btn = player.get_node_or_null("HUD/ComboButton")
		if combo_btn and combo_btn.is_visible_in_tree() and combo_btn.get_global_rect().has_point(pos):
			return true

	return false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return

	var vp_size: Vector2 = get_viewport_rect().size
	var split_x: float = vp_size.x * 0.5

	# 1. SCREEN TOUCH
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < split_x:
				# Left half: Virtual Joystick
				if joystick_touch_id == -1:
					joystick_touch_id = event.index
					if joystick:
						joystick.start_touch(event.position)
			else:
				# Right half: Camera Drag (if not on interactive UI)
				if not _is_touch_on_ui(event.position):
					if camera_touch_id == -1:
						camera_touch_id = event.index
		else:
			# Release
			if event.index == joystick_touch_id:
				joystick_touch_id = -1
				if joystick:
					joystick.end_touch()
				player.mobile_move_vector = Vector2.ZERO
			elif event.index == camera_touch_id:
				camera_touch_id = -1

	# 2. SCREEN DRAG
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			if joystick:
				joystick.update_touch(event.position)
				player.mobile_move_vector = joystick.output_vector
		elif event.index == camera_touch_id:
			_drag_camera(event.relative)

	# 3. MOUSE FALLBACK (PC TEST ONLY)
	elif not is_mobile:
		_handle_mouse_fallback(event, split_x)

func _handle_mouse_fallback(event: InputEvent, split_x: float) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.x < split_x:
				if joystick_touch_id == -1:
					joystick_touch_id = 999
					if joystick:
						joystick.start_touch(event.position)
			else:
				if not _is_touch_on_ui(event.position):
					if camera_touch_id == -1:
						camera_touch_id = 999
		else:
			if joystick_touch_id == 999:
				joystick_touch_id = -1
				if joystick:
					joystick.end_touch()
				player.mobile_move_vector = Vector2.ZERO
			elif camera_touch_id == 999:
				camera_touch_id = -1

	elif event is InputEventMouseMotion:
		if joystick_touch_id == 999:
			if joystick:
				joystick.update_touch(event.position)
				player.mobile_move_vector = joystick.output_vector
		elif camera_touch_id == 999:
			_drag_camera(event.relative)

func _drag_camera(relative: Vector2) -> void:
	if not is_instance_valid(player):
		return
	if player.has_method("rotate_camera"):
		player.rotate_camera(relative, camera_sensitivity)
	else:
		var sens = camera_sensitivity * (0.6 if player.get("is_aiming") == true else 1.0)
		player._camera_rotation.x -= relative.x * sens
		player._camera_rotation.y = clamp(
			player._camera_rotation.y - relative.y * sens,
			deg_to_rad(player.camera_tilt_min),
			deg_to_rad(player.camera_tilt_max)
		)
		player._update_camera_rotation()
