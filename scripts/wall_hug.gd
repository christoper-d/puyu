extends Node
class_name WallHugSystem

# Wall hugging / peek system
# Attach to Player. Requires: SpringArm3D camera, Visual node, ShapeCast for wall detection.

# --- Exports ---
@export var hug_key: String = "wall_hug"
@export var peek_key_right: String = "peek_right"
@export var peek_key_left: String = "peek_left"
@export var wall_detect_distance: float = 0.6
@export var hug_slide_speed: float = 3.5
@export var camera_shoulder_offset: float = 0.65  # lateral offset while hugging
@export var camera_peek_offset: float = 1.1        # extra lateral offset while peeking
@export var camera_smooth_speed: float = 8.0

# --- Internal state ---
enum HugState { FREE, HUGGING, PEEKING_RIGHT, PEEKING_LEFT }
var state: HugState = HugState.FREE

var _wall_normal: Vector3 = Vector3.ZERO
var _wall_contact_point: Vector3 = Vector3.ZERO
var _current_cam_offset: float = 0.0
var _target_cam_offset: float = 0.0
var _spring_arm: SpringArm3D = null
var _player: CharacterBody3D = null
var _visual: Node3D = null
var _wall_cast: ShapeCast3D = null
var _was_hugging: bool = false

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	if not _player:
		push_error("WallHugSystem must be child of CharacterBody3D")
		return
	_spring_arm = _player.get_node_or_null("CameraPivot/SpringArm3D")
	_visual = _player.get_node_or_null("Visual")
	_wall_cast = _player.get_node_or_null("WallCast")

	_ensure_inputs()

func _ensure_inputs() -> void:
	var actions = {
		"wall_hug": KEY_Q,
		"peek_right": KEY_F,
		"peek_left": KEY_R
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var events = InputMap.action_get_events(action_name)
		var found = false
		for ev in events:
			if ev is InputEventKey:
				found = true
				break
		if not found:
			var ev = InputEventKey.new()
			ev.physical_keycode = actions[action_name]
			InputMap.action_add_event(action_name, ev)

func _process(delta: float) -> void:
	if not _player or not _spring_arm:
		return

	_detect_wall()
	_handle_state_transitions()
	_smooth_camera_offset(delta)

func _detect_wall() -> void:
	if not _wall_cast:
		return
	if _wall_cast.is_colliding():
		_wall_normal = _wall_cast.get_collision_normal(0)
		_wall_contact_point = _wall_cast.get_collision_point(0)
	else:
		# If not detecting wall, exit hug
		if state != HugState.FREE:
			_exit_hug()

func _handle_state_transitions() -> void:
	var hug_pressed = Input.is_action_pressed("wall_hug")
	var peek_r = Input.is_action_pressed("peek_right")
	var peek_l = Input.is_action_pressed("peek_left")

	match state:
		HugState.FREE:
			if hug_pressed and _wall_cast and _wall_cast.is_colliding():
				_enter_hug()
		HugState.HUGGING:
			if not hug_pressed:
				_exit_hug()
			elif peek_r:
				state = HugState.PEEKING_RIGHT
				_target_cam_offset = camera_peek_offset
			elif peek_l:
				state = HugState.PEEKING_LEFT
				_target_cam_offset = -camera_peek_offset
			else:
				_target_cam_offset = camera_shoulder_offset
		HugState.PEEKING_RIGHT, HugState.PEEKING_LEFT:
			if not hug_pressed:
				_exit_hug()
			elif not peek_r and not peek_l:
				state = HugState.HUGGING
				_target_cam_offset = camera_shoulder_offset

func _enter_hug() -> void:
	state = HugState.HUGGING
	_target_cam_offset = camera_shoulder_offset
	_was_hugging = true

func _exit_hug() -> void:
	state = HugState.FREE
	_target_cam_offset = 0.0
	_was_hugging = false

func _smooth_camera_offset(delta: float) -> void:
	_current_cam_offset = lerp(_current_cam_offset, _target_cam_offset, camera_smooth_speed * delta)

	# Apply horizontal offset to SpringArm root (CameraPivot X offset)
	var pivot = _player.get_node_or_null("CameraPivot")
	if pivot:
		pivot.position.x = _current_cam_offset

# --- Public API ---
func is_hugging() -> bool:
	return state != HugState.FREE

func is_peeking() -> bool:
	return state == HugState.PEEKING_RIGHT or state == HugState.PEEKING_LEFT

func get_hug_state() -> HugState:
	return state

# Returns a movement speed multiplier for the player while hugging
func get_speed_multiplier() -> float:
	match state:
		HugState.PEEKING_RIGHT, HugState.PEEKING_LEFT:
			return 0.0  # Cant move while peeking
		HugState.HUGGING:
			return 0.45  # Slow slide along wall
		_:
			return 1.0
