extends CanvasLayer

## Panel de Desarrollo y Depuración en Tiempo Real — PUYU
## Autoload que permite configurar controles (PC vs Móvil), iluminación y trucos de prueba.

var is_open: bool = false
var is_mobile_mode: bool = false

# UI Nodes
var toggle_button: Button = null
var main_panel: PanelContainer = null
var fps_label: Label = null
var player_info_label: Label = null
var enemy_info_label: Label = null
var control_status_label: Label = null

# Cached Scene References
var _world_env: WorldEnvironment = null
var _dir_light: DirectionalLight3D = null
var _player_node: CharacterBody3D = null
var _lantern_node: Node3D = null

func _ready() -> void:
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Detect platform default
	is_mobile_mode = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.get_name() == "Android" or OS.get_name() == "iOS"

	_build_ui()
	_close_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_F12 or event.keycode == KEY_QUOTELEFT:
			toggle_menu()
			get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if is_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	is_open = true
	_fetch_scene_references()
	_update_ui_state_from_scene()
	if main_panel:
		main_panel.visible = true
	if toggle_button:
		toggle_button.text = "✖ DEV"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Events:
		Events.dev_menu_toggled.emit(true)

func _close_menu() -> void:
	is_open = false
	if main_panel:
		main_panel.visible = false
	if toggle_button:
		toggle_button.text = "🛠 DEV"

	# Restore mouse mode according to control scheme
	if is_mobile_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Events:
		Events.dev_menu_toggled.emit(false)

func _process(_delta: float) -> void:
	if not is_open:
		return
	_update_diagnostics()

func _fetch_scene_references() -> void:
	var tree = get_tree()
	if not tree:
		return

	var players = tree.get_nodes_in_group("player")
	if not players.is_empty():
		_player_node = players[0] as CharacterBody3D
		_lantern_node = _player_node.find_child("Lantern", true, false) as Node3D

	var envs = tree.root.find_children("", "WorldEnvironment", true, false)
	if not envs.is_empty():
		_world_env = envs[0] as WorldEnvironment

	var lights = tree.root.find_children("", "DirectionalLight3D", true, false)
	if not lights.is_empty():
		_dir_light = lights[0] as DirectionalLight3D

func _build_ui() -> void:
	# 1. Floating Toggle Button (Top Right)
	toggle_button = Button.new()
	toggle_button.text = "🛠 DEV"
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.custom_minimum_size = Vector2(70, 26)
	toggle_button.position = Vector2(get_viewport().size.x - 78, 8)
	toggle_button.anchors_preset = Control.PRESET_TOP_RIGHT
	toggle_button.anchor_left = 1.0
	toggle_button.anchor_right = 1.0
	toggle_button.offset_left = -78
	toggle_button.offset_right = -8
	toggle_button.offset_top = 8
	toggle_button.offset_bottom = 34

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.14, 0.18, 0.88)
	btn_style.border_color = Color(0.3, 0.75, 0.9, 0.9)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	toggle_button.add_theme_stylebox_override("normal", btn_style)
	toggle_button.add_theme_stylebox_override("hover", btn_style)
	toggle_button.add_theme_stylebox_override("pressed", btn_style)
	toggle_button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	toggle_button.add_theme_font_size_override("font_size", 10)
	toggle_button.pressed.connect(toggle_menu)
	add_child(toggle_button)

	# 2. Main Window Panel
	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(330, 470)
	main_panel.position = Vector2(get_viewport().size.x - 342, 40)
	main_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	main_panel.anchor_left = 1.0
	main_panel.anchor_right = 1.0
	main_panel.offset_left = -342
	main_panel.offset_right = -12
	main_panel.offset_top = 40
	main_panel.offset_bottom = 510

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.10, 0.95)
	panel_style.border_color = Color(0.25, 0.65, 0.85, 0.8)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 6)
	main_panel.add_child(root_vbox)

	# Header
	var header_hbox = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "⚙️ PUYU — MODO DESARROLLADOR"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	header_hbox.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(22, 20)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_close_menu)
	header_hbox.add_child(close_btn)
	root_vbox.add_child(header_hbox)

	var hs = HSeparator.new()
	root_vbox.add_child(hs)

	# Tab Container
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 10)
	root_vbox.add_child(tabs)

	# --- TAB 1: CONTROLES ---
	var tab_controls = VBoxContainer.new()
	tab_controls.name = "🎮 Controles"
	tab_controls.add_theme_constant_override("separation", 8)
	tabs.add_child(tab_controls)

	control_status_label = Label.new()
	control_status_label.text = "Modo activo: ESCRITORIO (PC)"
	control_status_label.add_theme_font_size_override("font_size", 10)
	control_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	tab_controls.add_child(control_status_label)

	var btn_pc = Button.new()
	btn_pc.text = "🖥️ Activar Modo PC (Teclado/Mouse)"
	btn_pc.add_theme_font_size_override("font_size", 10)
	btn_pc.focus_mode = Control.FOCUS_NONE
	btn_pc.pressed.connect(func(): _set_control_scheme(false))
	tab_controls.add_child(btn_pc)

	var btn_mob = Button.new()
	btn_mob.text = "📱 Activar Modo Móvil (Touch/Joystick)"
	btn_mob.add_theme_font_size_override("font_size", 10)
	btn_mob.focus_mode = Control.FOCUS_NONE
	btn_mob.pressed.connect(func(): _set_control_scheme(true))
	tab_controls.add_child(btn_mob)

	var ctrl_desc = Label.new()
	ctrl_desc.text = "• En PC: los joysticks se ocultan y el ratón se captura.\n• En Móvil: los joysticks se activan y el ratón queda libre."
	ctrl_desc.add_theme_font_size_override("font_size", 9)
	ctrl_desc.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.9))
	ctrl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab_controls.add_child(ctrl_desc)

	# --- TAB 2: ILUMINACIÓN & CLIMA ---
	var tab_lighting = VBoxContainer.new()
	tab_lighting.name = "💡 Iluminación"
	tab_lighting.add_theme_constant_override("separation", 6)
	tabs.add_child(tab_lighting)

	var chk_fog = CheckBox.new()
	chk_fog.name = "ChkFog"
	chk_fog.text = "Niebla de la Quebrada"
	chk_fog.add_theme_font_size_override("font_size", 10)
	chk_fog.button_pressed = true
	chk_fog.toggled.connect(_on_toggle_fog)
	tab_lighting.add_child(chk_fog)

	var fog_slider_lbl = Label.new()
	fog_slider_lbl.text = "Densidad de Niebla:"
	fog_slider_lbl.add_theme_font_size_override("font_size", 9)
	tab_lighting.add_child(fog_slider_lbl)

	var sld_fog = HSlider.new()
	sld_fog.name = "SldFog"
	sld_fog.min_value = 0.0
	sld_fog.max_value = 2.0
	sld_fog.step = 0.05
	sld_fog.value = 0.9
	sld_fog.value_changed.connect(_on_fog_density_changed)
	tab_lighting.add_child(sld_fog)

	var chk_vfog = CheckBox.new()
	chk_vfog.name = "ChkVfog"
	chk_vfog.text = "Niebla Volumétrica"
	chk_vfog.add_theme_font_size_override("font_size", 10)
	chk_vfog.button_pressed = true
	chk_vfog.toggled.connect(_on_toggle_vfog)
	tab_lighting.add_child(chk_vfog)

	var chk_lantern = CheckBox.new()
	chk_lantern.name = "ChkLantern"
	chk_lantern.text = "Linterna del Jugador"
	chk_lantern.add_theme_font_size_override("font_size", 10)
	chk_lantern.button_pressed = true
	chk_lantern.toggled.connect(_on_toggle_lantern)
	tab_lighting.add_child(chk_lantern)

	var lantern_slider_lbl = Label.new()
	lantern_slider_lbl.text = "Brillo de Linterna:"
	lantern_slider_lbl.add_theme_font_size_override("font_size", 9)
	tab_lighting.add_child(lantern_slider_lbl)

	var sld_lantern = HSlider.new()
	sld_lantern.name = "SldLantern"
	sld_lantern.min_value = 0.0
	sld_lantern.max_value = 5.0
	sld_lantern.step = 0.1
	sld_lantern.value = 1.8
	sld_lantern.value_changed.connect(_on_lantern_brightness_changed)
	tab_lighting.add_child(sld_lantern)

	var chk_sun = CheckBox.new()
	chk_sun.name = "ChkSun"
	chk_sun.text = "Luz Lunar / Solar (Direccional)"
	chk_sun.add_theme_font_size_override("font_size", 10)
	chk_sun.button_pressed = true
	chk_sun.toggled.connect(_on_toggle_sun)
	tab_lighting.add_child(chk_sun)

	# --- TAB 3: COMBATE & TRUCOS ---
	var tab_combat = VBoxContainer.new()
	tab_combat.name = "⚔️ Combate"
	tab_combat.add_theme_constant_override("separation", 6)
	tabs.add_child(tab_combat)

	var chk_god = CheckBox.new()
	chk_god.text = "🛡️ Modo Dios (Vida Infinita)"
	chk_god.add_theme_font_size_override("font_size", 10)
	chk_god.toggled.connect(func(v): if Events: Events.debug_god_mode_toggled.emit(v))
	tab_combat.add_child(chk_god)

	var chk_speed = CheckBox.new()
	chk_speed.text = "⚡ Super Velocidad (x2.2)"
	chk_speed.add_theme_font_size_override("font_size", 10)
	chk_speed.toggled.connect(func(v): if Events: Events.debug_speed_boost_toggled.emit(v))
	tab_combat.add_child(chk_speed)

	var btn_weapons = Button.new()
	btn_weapons.text = "🎒 Dar Todas las Armas"
	btn_weapons.add_theme_font_size_override("font_size", 10)
	btn_weapons.focus_mode = Control.FOCUS_NONE
	btn_weapons.pressed.connect(func(): if Events: Events.debug_give_all_weapons.emit())
	tab_combat.add_child(btn_weapons)

	var btn_stun = Button.new()
	btn_stun.text = "💫 Aturdir Jarjacha (Stun 4s)"
	btn_stun.add_theme_font_size_override("font_size", 10)
	btn_stun.focus_mode = Control.FOCUS_NONE
	btn_stun.pressed.connect(_stun_jarjacha)
	tab_combat.add_child(btn_stun)

	var btn_teleport = Button.new()
	btn_teleport.text = "📍 Traer Jarjacha Frente al Jugador"
	btn_teleport.add_theme_font_size_override("font_size", 10)
	btn_teleport.focus_mode = Control.FOCUS_NONE
	btn_teleport.pressed.connect(_teleport_jarjacha)
	tab_combat.add_child(btn_teleport)

	# --- TAB 4: DIAGNÓSTICO ---
	var tab_diag = VBoxContainer.new()
	tab_diag.name = "📊 Estado"
	tab_diag.add_theme_constant_override("separation", 6)
	tabs.add_child(tab_diag)

	fps_label = Label.new()
	fps_label.text = "FPS: 60"
	fps_label.add_theme_font_size_override("font_size", 10)
	fps_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	tab_diag.add_child(fps_label)

	player_info_label = Label.new()
	player_info_label.text = "Jugador: --"
	player_info_label.add_theme_font_size_override("font_size", 9)
	tab_diag.add_child(player_info_label)

	enemy_info_label = Label.new()
	enemy_info_label.text = "Jarjacha: --"
	enemy_info_label.add_theme_font_size_override("font_size", 9)
	tab_diag.add_child(enemy_info_label)

	# --- TAB 5: LOGROS ---
	var tab_ach = VBoxContainer.new()
	tab_ach.name = "🏆 Logros"
	tab_ach.add_theme_constant_override("separation", 6)
	tabs.add_child(tab_ach)

	var ach_header = Label.new()
	ach_header.text = "Sistema de Logros (Persistente):"
	ach_header.add_theme_font_size_override("font_size", 9)
	ach_header.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3, 1.0))
	tab_ach.add_child(ach_header)

	var ach_dur_lbl = Label.new()
	var current_dur: float = 6.5
	var ach_mgr = get_node_or_null("/root/Achievements")
	if ach_mgr and "toast_display_duration" in ach_mgr:
		current_dur = ach_mgr.toast_display_duration
	ach_dur_lbl.text = "Duración Toast en pantalla: %.1fs" % current_dur
	ach_dur_lbl.add_theme_font_size_override("font_size", 9)
	ach_dur_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	tab_ach.add_child(ach_dur_lbl)

	var sld_dur = HSlider.new()
	sld_dur.min_value = 2.0
	sld_dur.max_value = 15.0
	sld_dur.step = 0.5
	sld_dur.value = current_dur
	sld_dur.value_changed.connect(func(val: float):
		ach_dur_lbl.text = "Duración Toast en pantalla: %.1fs" % val
		var mgr = get_node_or_null("/root/Achievements")
		if mgr and "toast_display_duration" in mgr:
			mgr.toast_display_duration = val
	)
	tab_ach.add_child(sld_dur)

	var btn_test_tupac = Button.new()
	btn_test_tupac.text = "🏆 Test: Desbloquear Túpac Amaru"
	btn_test_tupac.add_theme_font_size_override("font_size", 10)
	btn_test_tupac.pressed.connect(func():
		var mgr = get_node_or_null("/root/Achievements")
		if mgr and mgr.has_method("unlock"):
			mgr.unlock("tupac_amaru")
	)
	tab_ach.add_child(btn_test_tupac)

	var btn_reset_ach = Button.new()
	btn_reset_ach.text = "🔄 Resetear Todos los Logros"
	btn_reset_ach.add_theme_font_size_override("font_size", 10)
	btn_reset_ach.pressed.connect(func():
		var mgr = get_node_or_null("/root/Achievements")
		if mgr and mgr.has_method("reset_all_achievements"):
			mgr.reset_all_achievements()
			if Events:
				Events.prompt_flashed.emit("Logros reseteados en disco", 2.0)
	)
	tab_ach.add_child(btn_reset_ach)

func _set_control_scheme(mobile: bool) -> void:
	is_mobile_mode = mobile
	if control_status_label:
		control_status_label.text = "Modo activo: %s" % ("MÓVIL (Touch/Joystick)" if mobile else "ESCRITORIO (PC)")
	if Events:
		Events.control_mode_changed.emit(mobile)
		Events.prompt_flashed.emit("🛠️ Modo de control: %s" % ("MÓVIL" if mobile else "PC"), 1.8)

# --- Lighting Controls ---
func _on_toggle_fog(enabled: bool) -> void:
	if _world_env and _world_env.environment:
		_world_env.environment.fog_enabled = enabled

func _on_fog_density_changed(value: float) -> void:
	if _world_env and _world_env.environment:
		_world_env.environment.fog_density = value

func _on_toggle_vfog(enabled: bool) -> void:
	if _world_env and _world_env.environment:
		_world_env.environment.volumetric_fog_enabled = enabled

func _on_toggle_lantern(enabled: bool) -> void:
	if is_instance_valid(_lantern_node):
		_lantern_node.visible = enabled

func _on_lantern_brightness_changed(value: float) -> void:
	if is_instance_valid(_lantern_node):
		var spot = _lantern_node.find_child("SpotLight3D", true, false) as SpotLight3D
		if spot:
			spot.light_energy = value

func _on_toggle_sun(enabled: bool) -> void:
	if is_instance_valid(_dir_light):
		_dir_light.visible = enabled

# --- Combat Debug Actions ---
func _stun_jarjacha() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var stunned_count = 0
	for e in enemies:
		if is_instance_valid(e) and e.has_method("receive_push"):
			var p_pos = _player_node.global_position if is_instance_valid(_player_node) else e.global_position
			e.receive_push(p_pos, 8.0, 4.0)
			stunned_count += 1
	if Events:
		Events.prompt_flashed.emit("🛠️ Jarjacha aturdida (x%d) durante 4 seg" % stunned_count, 1.8)

func _teleport_jarjacha() -> void:
	if not is_instance_valid(_player_node):
		return
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return
	var enemy = enemies[0]
	if is_instance_valid(enemy):
		var forward = -_player_node.global_transform.basis.z
		forward.y = 0.0
		enemy.global_position = _player_node.global_position + (forward.normalized() * 5.5)
		if Events:
			Events.prompt_flashed.emit("🛠️ Jarjacha posicionada frente al jugador", 1.8)

func _update_ui_state_from_scene() -> void:
	if not is_instance_valid(main_panel):
		return
	if _world_env and _world_env.environment:
		var chk_fog = main_panel.find_child("ChkFog", true, false) as CheckBox
		if chk_fog:
			chk_fog.button_pressed = _world_env.environment.fog_enabled
		var sld_fog = main_panel.find_child("SldFog", true, false) as HSlider
		if sld_fog:
			sld_fog.value = _world_env.environment.fog_density
		var chk_vfog = main_panel.find_child("ChkVfog", true, false) as CheckBox
		if chk_vfog:
			chk_vfog.button_pressed = _world_env.environment.volumetric_fog_enabled

	if is_instance_valid(_dir_light):
		var chk_sun = main_panel.find_child("ChkSun", true, false) as CheckBox
		if chk_sun:
			chk_sun.button_pressed = _dir_light.visible

	if is_instance_valid(_lantern_node):
		var chk_lantern = main_panel.find_child("ChkLantern", true, false) as CheckBox
		if chk_lantern:
			chk_lantern.button_pressed = _lantern_node.visible

func _update_diagnostics() -> void:
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if player_info_label and is_instance_valid(_player_node):
		var pos = _player_node.global_position
		var hp = _player_node.get("current_health")
		var eq = _player_node.get("equipped_name")
		player_info_label.text = "Jugador: HP: %.0f | Arma: %s\nPos: (%.1f, %.1f, %.1f)" % [hp, eq, pos.x, pos.y, pos.z]

	if enemy_info_label:
		var enemies = get_tree().get_nodes_in_group("enemy")
		if not enemies.is_empty() and is_instance_valid(enemies[0]):
			var e = enemies[0]
			var st = e.get("current_state")
			var hp = e.get("current_health")
			enemy_info_label.text = "Jarjacha: Estado: %s | Vida: %.0f" % [str(st), hp]
		else:
			enemy_info_label.text = "Jarjacha: No encontrada en escena"
