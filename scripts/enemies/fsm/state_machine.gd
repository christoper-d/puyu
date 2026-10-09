class_name EnemyStateMachine
extends Node

## Controlador de Máquina de Estados Finita — PUYU
## Administra el estado activo y las transiciones de IA para cualquier enemigo.

const EnemyStateScript = preload("res://scripts/enemies/fsm/state.gd")

signal state_transitioned(old_state: StringName, new_state: StringName)

@export var initial_state_name: String = "patrol"

var current_state: Node = null
var states: Dictionary = {} # StringName -> Node (EnemyState)
var host: CharacterBody3D = null

func init(host_node: CharacterBody3D) -> void:
	host = host_node
	for child in get_children():
		if child is EnemyStateScript or child.has_method("physics_update"):
			var s_name = child.name.to_lower()
			if not states.has(s_name):
				states[s_name] = child

	for s in states.values():
		s.set("state_machine", self)
		s.set("host", host)

	if not states.is_empty():
		var start_key = initial_state_name.to_lower()
		if states.has(start_key):
			transition_to(start_key)
		else:
			transition_to(states.keys()[0])

func add_state(state_name: String, state_node: Node) -> void:
	var key = state_name.to_lower()
	state_node.name = key
	states[key] = state_node
	state_node.set("state_machine", self)
	state_node.set("host", host)
	if state_node.get_parent() != self:
		add_child(state_node)

func transition_to(target_state_name: String) -> void:
	var key = target_state_name.to_lower()
	if not states.has(key):
		push_warning("EnemyStateMachine: No existe el estado '%s' en %s" % [target_state_name, str(host.name) if host else "Host"])
		return

	var new_state: Node = states[key]
	if current_state == new_state:
		return

	var old_name = StringName(current_state.name.to_lower()) if current_state else &""
	if current_state and current_state.has_method("exit"):
		current_state.exit()

	current_state = new_state
	if current_state.has_method("enter"):
		current_state.enter()
	state_transitioned.emit(old_name, StringName(key))

func physics_process(delta: float) -> void:
	if current_state and current_state.has_method("physics_update"):
		current_state.physics_update(delta)

func process(delta: float) -> void:
	if current_state and current_state.has_method("update"):
		current_state.update(delta)

func get_current_state_name() -> String:
	return current_state.name.to_lower() if current_state else ""
