@tool
extends StaticBody3D
class_name CasaModular

enum HouseType {
	RUSTICA_1_PISO,      # 1 piso con dintel de eucalipto, ventana enrejada y vigas salientes
	COLONIAL_BALCON,     # 2 pisos con balcón andino de madera y zócalo de piedra
	ALTILLO_ANDINO,      # 1.5 pisos con desván en frontón y vigas expuestas
	TAPIAL_CONTRAFUERTE  # Muro ancho con contrafuerte de piedra y portón doble
}

enum RoofType {
	CALAMINA_OXIDADA,    # Planchas de calamina marrón-rojizo oxidada
	CALAMINA_ZINC,       # Planchas de zinc gris desgastado
	PAJA_ICHU            # Techo espeso de paja brava / ichu andino
}

enum WallPalette {
	BLANCO_CAL,          # Blanco tiza tradicional (revoque de cal)
	ADOBE_TIERRA,        # Tierra rojiza / barro natural
	OCRE_SIERRA,         # Ocre andino cálido
	ADOBE_DESLAVADO      # Barro grisáceo envejecido por lluvia y helada
}

@export_group("Configuración Modular")
@export var house_type: HouseType = HouseType.RUSTICA_1_PISO:
	set(v):
		house_type = v
		_request_rebuild()

@export var roof_type: RoofType = RoofType.CALAMINA_OXIDADA:
	set(v):
		roof_type = v
		_request_rebuild()

@export var wall_palette: WallPalette = WallPalette.BLANCO_CAL:
	set(v):
		wall_palette = v
		_request_rebuild()

@export_group("Dimensiones")
@export var house_width: float = 6.0:
	set(v):
		house_width = max(4.0, v)
		_request_rebuild()

@export var house_depth: float = 4.5:
	set(v):
		house_depth = max(3.5, v)
		_request_rebuild()

@export var pirca_base_height: float = 0.8:
	set(v):
		pirca_base_height = max(0.2, v)
		_request_rebuild()

@export_group("Detalles Andinos")
@export var add_roof_stones: bool = true:
	set(v):
		add_roof_stones = v
		_request_rebuild()

@export var add_ridge_cross: bool = true:
	set(v):
		add_ridge_cross = v
		_request_rebuild()

@export var add_eucalyptus_beams: bool = true:
	set(v):
		add_eucalyptus_beams = v
		_request_rebuild()

@export var random_seed: int = 0:
	set(v):
		random_seed = v
		_request_rebuild()

# Referencias internas
var _root_visual: Node3D = null
var _collision_shape: CollisionShape3D = null
var _is_rebuilding: bool = false

# Shader
const SHADER_RES = preload("res://shaders/ps2_lit.gdshader")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	_build_house()

func _request_rebuild() -> void:
	if not is_inside_tree():
		return
	if _is_rebuilding:
		return
	_is_rebuilding = true
	call_deferred("_do_rebuild")

func _do_rebuild() -> void:
	_is_rebuilding = false
	_build_house()

func _create_mat(col: Color, roughness: float = 0.95) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = SHADER_RES
	mat.set_shader_parameter("albedo_color", col)
	mat.set_shader_parameter("roughness_val", roughness)
	mat.set_shader_parameter("jitter_enabled", true)
	mat.set_shader_parameter("jitter_resolution", 280.0)
	mat.set_shader_parameter("jitter_strength", 1.0)
	return mat

func _get_wall_color() -> Color:
	match wall_palette:
		WallPalette.BLANCO_CAL:
			return Color(0.88, 0.87, 0.84, 1.0)
		WallPalette.ADOBE_TIERRA:
			return Color(0.56, 0.38, 0.26, 1.0)
		WallPalette.OCRE_SIERRA:
			return Color(0.72, 0.52, 0.32, 1.0)
		WallPalette.ADOBE_DESLAVADO:
			return Color(0.64, 0.61, 0.56, 1.0)
	return Color(0.8, 0.8, 0.8, 1.0)

func _build_house() -> void:
	# Limpieza de geometrías anteriores
	if _root_visual and is_instance_valid(_root_visual):
		_root_visual.queue_free()
	
	_root_visual = Node3D.new()
	_root_visual.name = "Visuals"
	add_child(_root_visual)

	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed if random_seed != 0 else hash(name)

	# Materiales cacheados
	var mat_wall = _create_mat(_get_wall_color(), 0.98)
	var mat_pirca_dark = _create_mat(Color(0.34, 0.33, 0.31, 1.0), 0.95)
	var mat_pirca_light = _create_mat(Color(0.42, 0.40, 0.38, 1.0), 0.95)
	var mat_wood = _create_mat(Color(0.24, 0.17, 0.12, 1.0), 0.92)
	var mat_interior_dark = _create_mat(Color(0.04, 0.04, 0.05, 1.0), 1.0)
	var mat_stone_roof = _create_mat(Color(0.38, 0.37, 0.35, 1.0), 0.95)
	var mat_iron_cross = _create_mat(Color(0.68, 0.64, 0.58, 1.0), 0.8)

	var mat_roof: ShaderMaterial
	var mat_roof_eave: ShaderMaterial
	match roof_type:
		RoofType.CALAMINA_OXIDADA:
			mat_roof = _create_mat(Color(0.53, 0.32, 0.22, 1.0), 0.90)
			mat_roof_eave = mat_wood
		RoofType.CALAMINA_ZINC:
			mat_roof = _create_mat(Color(0.46, 0.49, 0.52, 1.0), 0.85)
			mat_roof_eave = mat_wood
		RoofType.PAJA_ICHU:
			mat_roof = _create_mat(Color(0.55, 0.47, 0.32, 1.0), 0.98)
			mat_roof_eave = _create_mat(Color(0.42, 0.35, 0.24, 1.0), 1.0)

	# Alturas según arquetipo
	var total_wall_height: float = 3.4
	var has_second_floor: bool = false
	match house_type:
		HouseType.RUSTICA_1_PISO:
			total_wall_height = 3.3
		HouseType.COLONIAL_BALCON:
			total_wall_height = 5.4
			has_second_floor = true
		HouseType.ALTILLO_ANDINO:
			total_wall_height = 4.2
		HouseType.TAPIAL_CONTRAFUERTE:
			total_wall_height = 3.6

	var z_offset = -house_depth * 0.5

	# 1. BASE DE PIRCA (Piedras de río / mampostería)
	# Permite enterrarse en desniveles de terreno
	var pirca_box = _add_box(
		_root_visual,
		Vector3(house_width + 0.15, pirca_base_height, house_depth + 0.15),
		Vector3(0, pirca_base_height * 0.5, z_offset),
		mat_pirca_dark,
		"PircaBase"
	)
	# Piedras de relieve toscas en las esquinas
	_add_box(_root_visual, Vector3(0.5, 0.45, 0.55), Vector3(-house_width * 0.5 + 0.1, pirca_base_height * 0.4, 0.05), mat_pirca_light, "ReliefL")
	_add_box(_root_visual, Vector3(0.6, 0.40, 0.55), Vector3(house_width * 0.5 - 0.1, pirca_base_height * 0.4, 0.05), mat_pirca_light, "ReliefR")

	# 2. CUERPO DE ADOBE
	var adobe_height = total_wall_height - pirca_base_height
	var adobe_center_y = pirca_base_height + adobe_height * 0.5
	_add_box(
		_root_visual,
		Vector3(house_width, adobe_height, house_depth),
		Vector3(0, adobe_center_y, z_offset),
		mat_wall,
		"AdobeBody"
	)

	# 3. DETALLES DE FACHADA SEGÚN ARQUETIPO
	match house_type:
		HouseType.RUSTICA_1_PISO:
			# Puerta de madera con dintel de eucalipto
			var door_w = 1.3
			var door_h = 2.1
			var door_x = -1.3
			_add_box(_root_visual, Vector3(door_w, door_h, 0.1), Vector3(door_x, pirca_base_height + door_h * 0.5, 0.05), mat_interior_dark, "Door")
			_add_box(_root_visual, Vector3(door_w + 0.4, 0.22, 0.35), Vector3(door_x, pirca_base_height + door_h + 0.1, 0.1), mat_wood, "DoorLintel")
			
			# Ventana baja con reja
			var win_x = 1.4
			var win_y = pirca_base_height + 1.2
			_add_box(_root_visual, Vector3(1.1, 1.2, 0.08), Vector3(win_x, win_y, 0.04), mat_interior_dark, "Window")
			_add_box(_root_visual, Vector3(1.3, 0.15, 0.25), Vector3(win_x, win_y + 0.65, 0.08), mat_wood, "WinLintel")
			_add_box(_root_visual, Vector3(0.08, 1.2, 0.12), Vector3(win_x - 0.25, win_y, 0.08), mat_wood, "Bar1")
			_add_box(_root_visual, Vector3(0.08, 1.2, 0.12), Vector3(win_x + 0.25, win_y, 0.08), mat_wood, "Bar2")

		HouseType.COLONIAL_BALCON:
			# Puerta principal abajo
			var door_w = 1.4
			var door_h = 2.3
			_add_box(_root_visual, Vector3(door_w, door_h, 0.1), Vector3(0, pirca_base_height + door_h * 0.5, 0.05), mat_interior_dark, "Door")
			_add_box(_root_visual, Vector3(door_w + 0.4, 0.24, 0.3), Vector3(0, pirca_base_height + door_h + 0.12, 0.1), mat_wood, "DoorLintel")

			# Balcón de madera voladizo en segundo piso
			var balc_w = house_width * 0.75
			var balc_y = pirca_base_height + 2.7
			var balc_depth = 0.95
			# Plataforma
			_add_box(_root_visual, Vector3(balc_w, 0.22, balc_depth), Vector3(0, balc_y, balc_depth * 0.5), mat_wood, "BalconyFloor")
			# Baranda frontal
			_add_box(_root_visual, Vector3(balc_w, 0.9, 0.1), Vector3(0, balc_y + 0.55, balc_depth), mat_wood, "BalconyRailFront")
			# Barandas laterales
			_add_box(_root_visual, Vector3(0.1, 0.9, balc_depth), Vector3(-balc_w * 0.5, balc_y + 0.55, balc_depth * 0.5), mat_wood, "BalconyRailL")
			_add_box(_root_visual, Vector3(0.1, 0.9, balc_depth), Vector3(balc_w * 0.5, balc_y + 0.55, balc_depth * 0.5), mat_wood, "BalconyRailR")
			# Ménsulas de soporte (puntales)
			_add_box(_root_visual, Vector3(0.2, 0.6, 0.7), Vector3(-balc_w * 0.35, balc_y - 0.35, balc_depth * 0.3), mat_wood, "BracketL")
			_add_box(_root_visual, Vector3(0.2, 0.6, 0.7), Vector3(balc_w * 0.35, balc_y - 0.35, balc_depth * 0.3), mat_wood, "BracketR")

			# Ventanas altas coloniales
			_add_box(_root_visual, Vector3(1.0, 1.4, 0.08), Vector3(-1.4, balc_y + 0.85, 0.04), mat_interior_dark, "UpperWinL")
			_add_box(_root_visual, Vector3(1.0, 1.4, 0.08), Vector3(1.4, balc_y + 0.85, 0.04), mat_interior_dark, "UpperWinR")

		HouseType.ALTILLO_ANDINO:
			# Puerta lateral
			var door_w = 1.3
			var door_h = 2.1
			_add_box(_root_visual, Vector3(door_w, door_h, 0.1), Vector3(-1.4, pirca_base_height + door_h * 0.5, 0.05), mat_interior_dark, "Door")
			_add_box(_root_visual, Vector3(door_w + 0.3, 0.2, 0.3), Vector3(-1.4, pirca_base_height + door_h + 0.1, 0.1), mat_wood, "DoorLintel")
			
			# Ventana baja
			_add_box(_root_visual, Vector3(1.0, 1.1, 0.08), Vector3(1.4, pirca_base_height + 1.2, 0.04), mat_interior_dark, "WinLower")

			# Ventana pequeña triangular de desván / altillo
			var attic_y = total_wall_height - 0.7
			_add_box(_root_visual, Vector3(0.8, 0.8, 0.08), Vector3(0, attic_y, 0.04), mat_interior_dark, "AtticWindow")
			_add_box(_root_visual, Vector3(1.0, 0.15, 0.2), Vector3(0, attic_y + 0.45, 0.08), mat_wood, "AtticLintel")

		HouseType.TAPIAL_CONTRAFUERTE:
			# Contrafuerte de piedra en esquina izquierda
			_add_box(_root_visual, Vector3(1.1, total_wall_height * 0.7, 1.2), Vector3(-house_width * 0.5 + 0.45, total_wall_height * 0.35, 0.4), mat_pirca_dark, "Contrafuerte")
			
			# Portón ancho de madera (portón corral/almacén)
			var gate_w = 2.4
			var gate_h = 2.5
			_add_box(_root_visual, Vector3(gate_w, gate_h, 0.1), Vector3(0.6, pirca_base_height + gate_h * 0.5, 0.05), mat_interior_dark, "Porton")
			_add_box(_root_visual, Vector3(gate_w + 0.5, 0.3, 0.35), Vector3(0.6, pirca_base_height + gate_h + 0.15, 0.1), mat_wood, "PortonLintel")
			# Tranca de madera en el medio
			_add_box(_root_visual, Vector3(gate_w + 0.2, 0.16, 0.18), Vector3(0.6, pirca_base_height + gate_h * 0.5, 0.1), mat_wood, "Tranca")

	# 4. VIGAS DE EUCALIPTO SALIENTES (CHUPADORES)
	if add_eucalyptus_beams:
		var beam_y = total_wall_height - 0.2
		var beam_count = 4
		var spacing = (house_width - 1.2) / float(beam_count - 1)
		for i in range(beam_count):
			var bx = -house_width * 0.5 + 0.6 + i * spacing
			_add_box(_root_visual, Vector3(0.18, 0.18, 0.45), Vector3(bx, beam_y, 0.2), mat_wood, "Beam_%d" % i)

	# 5. TECHO MODULAR PROPORCIONAL
	var roof_rise = 1.1 if roof_type != RoofType.PAJA_ICHU else 1.3
	var roof_overhang_front = 0.6
	var roof_overhang_side = 0.4
	var sheet_w = house_width + roof_overhang_side * 2.0
	var sheet_half_depth = (house_depth * 0.5 + roof_overhang_front) / cos(deg_to_rad(22.0))
	var sheet_thick = 0.12 if roof_type != RoofType.PAJA_ICHU else 0.32

	var roof_base_y = total_wall_height

	# Plancha frontal
	var front_angle = deg_to_rad(22.0)
	var front_trans = Transform3D().rotated(Vector3.RIGHT, -front_angle)
	front_trans.origin = Vector3(0, roof_base_y + roof_rise * 0.45, z_offset + house_depth * 0.25 + 0.1)
	var sheet_f = _add_box_trans(_root_visual, Vector3(sheet_w, sheet_thick, sheet_half_depth), front_trans, mat_roof, "RoofSlopeFront")

	# Plancha trasera
	var back_trans = Transform3D().rotated(Vector3.RIGHT, front_angle)
	back_trans.origin = Vector3(0, roof_base_y + roof_rise * 0.45, z_offset - house_depth * 0.25 - 0.1)
	var sheet_b = _add_box_trans(_root_visual, Vector3(sheet_w, sheet_thick, sheet_half_depth), back_trans, mat_roof, "RoofSlopeBack")

	# Cumbrera / Viga de caballete
	_add_box(
		_root_visual,
		Vector3(sheet_w + 0.1, 0.24, 0.28),
		Vector3(0, roof_base_y + roof_rise + 0.05, z_offset),
		mat_roof_eave,
		"RidgeBeam"
	)

	# Aleros de paja espesa si es ichu
	if roof_type == RoofType.PAJA_ICHU:
		_add_box(
			_root_visual,
			Vector3(sheet_w + 0.15, 0.32, 0.5),
			Vector3(0, roof_base_y + 0.1, z_offset + house_depth * 0.5 + roof_overhang_front - 0.2),
			mat_roof_eave,
			"EaveFront"
		)
		_add_box(
			_root_visual,
			Vector3(sheet_w + 0.15, 0.32, 0.5),
			Vector3(0, roof_base_y + 0.1, z_offset - house_depth * 0.5 - roof_overhang_front + 0.2),
			mat_roof_eave,
			"EaveBack"
		)

	# 6. PIEDRAS SOBRE LA CALAMINA (Detalle andino contra el viento)
	if add_roof_stones and roof_type != RoofType.PAJA_ICHU:
		var stone_count = rng.randi_range(3, 5)
		for s in range(stone_count):
			var sx = rng.randf_range(-house_width * 0.38, house_width * 0.38)
			var is_front = (s % 2 == 0)
			var sz = z_offset + (rng.randf_range(0.4, 1.4) if is_front else rng.randf_range(-1.4, -0.4))
			var sy = roof_base_y + roof_rise * 0.45 + (0.2 if is_front else 0.2)
			var stone_sz = Vector3(rng.randf_range(0.35, 0.55), rng.randf_range(0.2, 0.3), rng.randf_range(0.3, 0.45))
			_add_box(_root_visual, stone_sz, Vector3(sx, sy, sz), mat_stone_roof, "RoofStone_%d" % s)

	# 7. CRUZ DE HOJALATA / CUMBRERA
	if add_ridge_cross:
		var cross_y = roof_base_y + roof_rise + 0.45
		# Palo vertical
		_add_box(_root_visual, Vector3(0.08, 0.7, 0.08), Vector3(0, cross_y, z_offset), mat_iron_cross, "CrossV")
		# Palo horizontal
		_add_box(_root_visual, Vector3(0.4, 0.08, 0.08), Vector3(0, cross_y + 0.15, z_offset), mat_iron_cross, "CrossH")

	# 8. COLISIÓN ÚNICA Y OPTIMIZADA (1 solo BoxShape3D para todo el edificio)
	# Cero sobrecoste físico, cero warnings de Jolt, compatible con cualquier escala.
	if _collision_shape == null or not is_instance_valid(_collision_shape):
		_collision_shape = get_node_or_null("CollisionMain")
		if _collision_shape == null:
			_collision_shape = CollisionShape3D.new()
			_collision_shape.name = "CollisionMain"
			add_child(_collision_shape)
			_collision_shape.owner = self

	var box_shape = BoxShape3D.new()
	var total_col_h = total_wall_height + roof_rise * 0.6
	box_shape.size = Vector3(house_width, total_col_h, house_depth)
	_collision_shape.shape = box_shape
	_collision_shape.transform.origin = Vector3(0, total_col_h * 0.5, z_offset)

func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material, node_name: String) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.transform.origin = pos
	parent.add_child(mi)
	return mi

func _add_box_trans(parent: Node, size: Vector3, trans: Transform3D, mat: Material, node_name: String) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.transform = trans
	parent.add_child(mi)
	return mi
