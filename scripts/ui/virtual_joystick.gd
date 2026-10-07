class_name PuyuVirtualJoystick
extends Control

signal joystick_moved(vector: Vector2)
signal joystick_released()

@export var max_radius: float = 46.0
@export var base_color: Color = Color(0.10, 0.10, 0.12, 0.55)
@export var base_border: Color = Color(0.85, 0.78, 0.65, 0.75)
@export var knob_color: Color = Color(0.92, 0.85, 0.72, 0.85)
@export var knob_border: Color = Color(1.0, 0.95, 0.85, 0.9)

var touch_id: int = -1
var is_active: bool = false
var knob_position: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO
var default_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	center = size * 0.5
	knob_position = center
	default_pos = position
	queue_redraw()

func _draw() -> void:
	# Base outer circle
	draw_circle(center, max_radius + 10.0, base_color)
	draw_arc(center, max_radius + 10.0, 0, TAU, 32, base_border, 2.0, true)
	
	# Center anchor dot
	draw_circle(center, 4.0, Color(base_border.r, base_border.g, base_border.b, 0.45))
	
	# Connecting stick if active
	if is_active and output_vector.length_squared() > 0.04:
		draw_line(center, knob_position, Color(base_border.r, base_border.g, base_border.b, 0.4), 2.0, true)
	
	# Knob inner circle
	var cur_knob = knob_color if not is_active else Color(1.0, 0.92, 0.78, 0.95)
	draw_circle(knob_position, 20.0, cur_knob)
	draw_arc(knob_position, 20.0, 0, TAU, 24, knob_border, 2.0, true)

func start_touch(touch_pos: Vector2) -> void:
	is_active = true
	# Center joystick on touch point
	global_position = touch_pos - center
	knob_position = center
	output_vector = Vector2.ZERO
	queue_redraw()
	joystick_moved.emit(output_vector)

func update_touch(touch_pos: Vector2) -> void:
	if not is_active:
		return
	var offset: Vector2 = touch_pos - (global_position + center)
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob_position = center + offset
	output_vector = offset / max_radius
	queue_redraw()
	joystick_moved.emit(output_vector)

func end_touch() -> void:
	is_active = false
	knob_position = center
	output_vector = Vector2.ZERO
	position = default_pos
	queue_redraw()
	joystick_released.emit()

func set_knob_offset(offset: Vector2) -> void:
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob_position = center + offset
	output_vector = offset / max_radius
	queue_redraw()
	joystick_moved.emit(output_vector)

func reset_joystick() -> void:
	end_touch()

func _reset_joystick() -> void:
	end_touch()
