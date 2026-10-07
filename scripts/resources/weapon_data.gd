class_name WeaponData
extends Resource

## Definición de Arma / Herramienta — PUYU (Data-Driven Resource)

@export var id: String = "unarmed"
@export var display_name: String = "Desarmado"
@export var item_type: int = 0 # Corresponde al enum ItemType
@export var base_damage: float = 10.0
@export var headshot_multiplier: float = 2.5
@export var attack_range: float = 3.5
@export var is_blunt: bool = false
@export var tethered_damage_bonus: float = 1.0
@export var attack_cooldown: float = 0.45
@export var push_force: float = 12.0
@export var ammo_capacity: int = 0
@export var icon: Texture2D = null
