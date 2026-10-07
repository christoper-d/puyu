extends Area3D
class_name InteractablePickup

enum ItemType {
	ROPE,
	AXE,
	MACHETE,
	SHOTGUN
}

@export var item_type: ItemType = ItemType.ROPE
@export var item_name: String = "Soga"
@export var prompt_message: String = "[E] Recoger Soga"

var is_player_in_range: bool = false
var player_ref: Node3D = null

func _ready() -> void:
	collision_layer = 8 # Interaction layer
	collision_mask = 2  # Player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player"):
		is_player_in_range = true
		player_ref = body
		if body.has_method("set_interact_prompt"):
			body.set_interact_prompt(prompt_message, self)

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_in_range = false
		if body.has_method("clear_interact_prompt"):
			body.clear_interact_prompt(self)
		player_ref = null

func interact() -> void:
	if is_player_in_range and is_instance_valid(player_ref):
		if player_ref.has_method("clear_interact_prompt"):
			player_ref.clear_interact_prompt(self)
		if player_ref.has_method("equip_item"):
			player_ref.equip_item(item_type, item_name)
		queue_free()
