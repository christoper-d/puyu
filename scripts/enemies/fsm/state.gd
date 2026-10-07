class_name EnemyState
extends Node

## Clase Base de Estado — PUYU (Finite State Machine)
## Define el ciclo de vida de un estado para cualquier criatura o enemigo del juego.

var state_machine: Node = null
var host: CharacterBody3D = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func update(_delta: float) -> void:
	pass
