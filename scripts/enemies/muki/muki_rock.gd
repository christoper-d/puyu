class_name MukiRock
extends Node3D

## Proyectil de Mineral Arrojado — El Muki
## Pedazo de pirita/roca afilada que viaja por el aire y daña al jugador al impactar.

@export var damage: float = 16.0
@export var speed: float = 14.0

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 16.0
var lifetime: float = 4.0
var has_hit: bool = false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var area: Area3D = $Area3D

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)

func launch(target_pos: Vector3) -> void:
	var dir = (target_pos - global_position)
	var horizontal_dist = Vector2(dir.x, dir.z).length()
	var time_to_target = horizontal_dist / speed
	time_to_target = clamp(time_to_target, 0.4, 1.8)

	var vy = (dir.y / time_to_target) + (0.5 * gravity * time_to_target)
	var h_dir = Vector3(dir.x, 0, dir.z).normalized()
	velocity = (h_dir * speed) + Vector3(0, vy, 0)

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	velocity.y -= gravity * delta
	global_position += velocity * delta

	# Rotación caótica de la piedra en el aire
	if mesh:
		mesh.rotate_x(delta * 12.0)
		mesh.rotate_y(delta * 8.0)

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return

	# Ignorar al lanzador u otros enemigos
	if body.is_in_group("enemy"):
		return

	has_hit = true

	if body.has_method("take_damage"):
		body.take_damage(damage)
		if Events:
			Events.prompt_flashed.emit("¡¡CLINK!! ¡El Muki te golpeó con una piedra de pirita!", 1.5)
	elif "current_health" in body:
		body.current_health = max(0.0, body.current_health - damage)

	queue_free()
