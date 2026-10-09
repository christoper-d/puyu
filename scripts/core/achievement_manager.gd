class_name AchievementManager
extends CanvasLayer

## Sistema de Logros (Achievements) — PUYU
## Administra el catálogo, persistencia local (user://achievements.json)
## y despliega notificaciones animadas en pantalla (Toast UI).

const SAVE_PATH: String = "user://achievements.json"

var catalog: Dictionary = {
	"tupac_amaru": {
		"title": "Túpac Amaru",
		"description": "Amarra a la Jarjacha a 4 postes simultáneamente.",
		"secret": false
	},
	"primer_lazo": {
		"title": "Enlazador Andino",
		"description": "Asegura a la bestia con tu primer poste de amarre.",
		"secret": false
	},
	"fuerza_chaccu": {
		"title": "Fuerza del Chaccu",
		"description": "Gánale en fuerza a la Jarjacha y arrástrala agachado.",
		"secret": false
	},
	"punteria_serrana": {
		"title": "Puntería Serrana",
		"description": "Conecta un impacto crítico en la cabeza de la criatura.",
		"secret": false
	},
	"fin_del_pecado": {
		"title": "Fin del Pecado",
		"description": "Derrota a la Jarjacha en su fase final y libera al pueblo.",
		"secret": false
	}
}

var unlocked: Dictionary = {} # id -> timestamp string
var toast_queue: Array[Dictionary] = []
@export var toast_display_duration: float = 6.5

var is_showing_toast: bool = false

# Nodos de UI del Toast
var toast_panel: PanelContainer = null
var lbl_header: Label = null
var lbl_title: Label = null
var lbl_desc: Label = null
var current_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 125 # Por encima del HUD y elementos del juego
	_build_toast_ui()
	load_achievements()
	_connect_event_bus()

func _build_toast_ui() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "AchievementToast"
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.custom_minimum_size = Vector2(280, 56)

	# Centrado en el tope de la pantalla
	toast_panel.anchor_left = 0.5
	toast_panel.anchor_right = 0.5
	toast_panel.offset_left = -140
	toast_panel.offset_right = 140
	toast_panel.offset_top = -90 # Oculto fuera de pantalla por defecto
	toast_panel.offset_bottom = -26

	# Estilo visual andino/PS2
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.09, 0.94)
	style.border_color = Color(0.90, 0.75, 0.26, 0.95) # Borde dorado
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	toast_panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	toast_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	lbl_header = Label.new()
	lbl_header.text = "🏆 ¡LOGRO DESBLOQUEADO!"
	lbl_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_header.add_theme_font_size_override("font_size", 9)
	lbl_header.add_theme_color_override("font_color", Color(0.96, 0.82, 0.35, 1.0))
	vbox.add_child(lbl_header)

	lbl_title = Label.new()
	lbl_title.text = "TÍTULO DEL LOGRO"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(lbl_title)

	lbl_desc = Label.new()
	lbl_desc.text = "Descripción del logro."
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 8)
	lbl_desc.add_theme_color_override("font_color", Color(0.82, 0.80, 0.76, 0.9))
	vbox.add_child(lbl_desc)

	add_child(toast_panel)

func _connect_event_bus() -> void:
	if not Events:
		return

	if not Events.enemy_tethered_to_post.is_connected(_on_enemy_tethered_to_post):
		Events.enemy_tethered_to_post.connect(_on_enemy_tethered_to_post)

	if not Events.headshot_landed.is_connected(_on_headshot_landed):
		Events.headshot_landed.connect(_on_headshot_landed)

	if not Events.prompt_flashed.is_connected(_on_prompt_flashed):
		Events.prompt_flashed.connect(_on_prompt_flashed)

func _on_enemy_tethered_to_post(_enemy: Node, total_posts: int) -> void:
	if total_posts >= 1:
		unlock("primer_lazo")
	if total_posts >= 4:
		unlock("tupac_amaru")

func _on_headshot_landed(_enemy: Node3D, _damage: float) -> void:
	unlock("punteria_serrana")

func _on_prompt_flashed(message: String, _duration: float) -> void:
	if "ARRASTRANDO A LA JARJACHA" in message:
		unlock("fuerza_chaccu")
	elif "LA JARJACHA HA SIDO DERROTADA" in message:
		unlock("fin_del_pecado")

## Desbloquea un logro si aún no ha sido obtenido
func unlock(id: String) -> bool:
	var key = id.to_lower()
	if not catalog.has(key):
		push_warning("AchievementManager: El logro '%s' no existe en el catálogo." % id)
		return false

	if unlocked.has(key):
		return false # Ya fue obtenido anteriormente

	var now = Time.get_datetime_string_from_system()
	unlocked[key] = now
	save_achievements()

	var data = catalog[key]
	var title = data.get("title", id)
	var description = data.get("description", "")

	# Notificar a la comunidad de sistemas vía EventBus
	if Events:
		Events.achievement_unlocked.emit(key, title, description)

	# Encolar para la animación del Toast UI
	toast_queue.append({
		"title": title,
		"description": description
	})

	if not is_showing_toast:
		_show_next_toast()

	return true

func is_unlocked(id: String) -> bool:
	return unlocked.has(id.to_lower())

func get_all_achievements() -> Dictionary:
	var result = {}
	for k in catalog.keys():
		var ach = catalog[k].duplicate()
		ach["is_unlocked"] = unlocked.has(k)
		ach["unlocked_at"] = unlocked.get(k, "")
		result[k] = ach
	return result

func get_unlocked_count() -> int:
	return unlocked.size()

func reset_all_achievements() -> void:
	unlocked.clear()
	save_achievements()

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		is_showing_toast = false
		return

	is_showing_toast = true
	var item = toast_queue.pop_front()

	if lbl_title:
		lbl_title.text = item.title
	if lbl_desc:
		lbl_desc.text = item.description

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	toast_panel.offset_top = -90.0
	toast_panel.modulate.a = 0.0

	current_tween = create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(toast_panel, "offset_top", 16.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.45)

	current_tween.chain().tween_interval(toast_display_duration)

	var exit_tween = current_tween.chain()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(toast_panel, "offset_top", -90.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.45)

	current_tween.chain().tween_callback(Callable(self, "_show_next_toast"))

func save_achievements() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("AchievementManager: No se pudo abrir %s para escritura." % SAVE_PATH)
		return
	var json_str = JSON.stringify(unlocked, "\t")
	file.store_string(json_str)
	file.close()

func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		unlocked = {}
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_str = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		unlocked = parsed
	else:
		unlocked = {}
