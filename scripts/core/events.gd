extends Node

## EventBus Global — PUYU
## Canal centralizado de señales para desacoplar UI, Combate, Enemigos y Jugador.

# --- Señales de HUD y Textos ---
@warning_ignore("unused_signal")
signal prompt_flashed(message: String, duration: float)
@warning_ignore("unused_signal")
signal prompt_requested(text: String, caller: Node)
@warning_ignore("unused_signal")
signal prompt_cleared(caller: Node)

# --- Señales del Jugador ---
@warning_ignore("unused_signal")
signal player_health_changed(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal weapon_switched(weapon_type: int, weapon_name: String)
@warning_ignore("unused_signal")
signal inventory_updated()

# --- Señales de Combate y Combos ---
@warning_ignore("unused_signal")
signal combo_prompt_updated(target_enemy: Node3D, can_push: bool, is_axe: bool)
@warning_ignore("unused_signal")
signal combo_push_executed(target_enemy: Node3D, force: float)
@warning_ignore("unused_signal")
signal headshot_landed(enemy: Node3D, damage: float)

# --- Señales de la Criatura / Enemigos ---
@warning_ignore("unused_signal")
signal enemy_damaged(enemy: Node, amount: float, is_headshot: bool)
@warning_ignore("unused_signal")
signal enemy_state_changed(enemy: Node, new_state: int)
@warning_ignore("unused_signal")
signal enemy_tether_strained(enemy: Node, stress_ratio: float)
@warning_ignore("unused_signal")
signal enemy_tether_snapped(enemy: Node, remaining_count: int)

# --- Señales de Configuración y Modo de Desarrollo (DevMenu & Plataforma) ---
@warning_ignore("unused_signal")
signal control_mode_changed(is_mobile: bool)
@warning_ignore("unused_signal")
signal dev_menu_toggled(is_open: bool)
@warning_ignore("unused_signal")
signal debug_god_mode_toggled(enabled: bool)
@warning_ignore("unused_signal")
signal debug_speed_boost_toggled(enabled: bool)
@warning_ignore("unused_signal")
signal debug_give_all_weapons()
