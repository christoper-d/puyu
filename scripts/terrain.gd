@tool
extends MeshInstance3D
class_name ProceduralTerrain

@export var size: Vector2 = Vector2(80, 80)
@export var sub_divisions: Vector2 = Vector2(40, 40)
@export var height_scale: float = 3.0
@export var noise_scale: float = 0.05
@export var generate: bool = false:
	set(val):
		_generate_terrain()

func _ready() -> void:
	if Engine.is_editor_hint() or mesh == null:
		_generate_terrain()

func _generate_terrain() -> void:
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 1234
	noise.frequency = noise_scale

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var start_x = -size.x / 2.0
	var start_z = -size.y / 2.0
	var step_x = size.x / sub_divisions.x
	var step_z = size.y / sub_divisions.y

	# Calculate vertices and normals
	var verts = []
	var uvs = []
	var normals = []
	
	for z in range(sub_divisions.y + 1):
		for x in range(sub_divisions.x + 1):
			var px = start_x + x * step_x
			var pz = start_z + z * step_z
			var h = noise.get_noise_2d(px, pz) * height_scale
			
			# Flatten the center for the plaza
			var dist_to_center = Vector2(px, pz).length()
			if dist_to_center < 15.0:
				h = lerp(0.0, h, max(0.0, (dist_to_center - 8.0) / 7.0))
				
			verts.append(Vector3(px, h, pz))
			uvs.append(Vector2(float(x) / sub_divisions.x, float(z) / sub_divisions.y) * 10.0)

	for z in range(sub_divisions.y):
		for x in range(sub_divisions.x):
			var i = x + z * (sub_divisions.x + 1)
			
			# Triangle 1
			st.set_uv(uvs[i])
			st.add_vertex(verts[i])
			st.set_uv(uvs[i + 1])
			st.add_vertex(verts[i + 1])
			st.set_uv(uvs[i + sub_divisions.x + 1])
			st.add_vertex(verts[i + sub_divisions.x + 1])
			
			# Triangle 2
			st.set_uv(uvs[i + 1])
			st.add_vertex(verts[i + 1])
			st.set_uv(uvs[i + sub_divisions.x + 2])
			st.add_vertex(verts[i + sub_divisions.x + 2])
			st.set_uv(uvs[i + sub_divisions.x + 1])
			st.add_vertex(verts[i + sub_divisions.x + 1])

	st.generate_normals()
	mesh = st.commit()
	
	# Generate collision
	if get_child_count() > 0:
		for c in get_children():
			c.queue_free()
			
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 2
	var coll_shape = CollisionShape3D.new()
	var shape = mesh.create_trimesh_shape()
	coll_shape.shape = shape
	static_body.add_child(coll_shape)
	add_child(static_body)
