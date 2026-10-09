class_name Casa1
extends Node3D

## Casa Andina Modular — PUYU (casa_1.glb)
## Administra la instancia visual de casa_1.glb, genera colisiones físicas trimesh automáticas
## para la base de piedra, muros de adobe y techo de tejas, y oculta el plano de suelo de Blender.

@export var show_ground_plane: bool = false
@export var auto_generate_collisions: bool = true

func _ready() -> void:
	_setup_ground_plane()
	if auto_generate_collisions:
		_setup_collisions()

func _setup_ground_plane() -> void:
	var gp = find_child("Ground_Plane", true, false)
	if gp:
		gp.visible = show_ground_plane

func _setup_collisions() -> void:
	# Mallas clave que requieren colisión sólida en el mundo
	var collision_target_names: Array[String] = [
		"Stone_Foundation",
		"Walls_Adobe",
		"Roof_Tiles_Left",
		"Roof_Tiles_Right",
		"Roof_Deck_Left",
		"Roof_Deck_Right",
		"Roof_Step_Board",
		"Awning_Deck"
	]

	for target_name in collision_target_names:
		var node = find_child(target_name, true, false)
		if node is MeshInstance3D and node.get_child_count() == 0:
			node.create_trimesh_collision()
			for child in node.get_children():
				if child is StaticBody3D:
					child.collision_layer = 1 # Capa 1: Escenario / Mundo
					child.collision_mask = 0
					child.add_to_group("wall_hug_surface")
