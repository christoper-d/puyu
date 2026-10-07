extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "PlayerCatModel"
    
    var shader = load("res://shaders/ps2_lit.gdshader")
    
    # Helper to make materials
    var make_mat = func(color: Color) -> ShaderMaterial:
        var mat = ShaderMaterial.new()
        mat.shader = shader
        mat.set_shader_parameter("albedo_color", color)
        mat.set_shader_parameter("roughness_val", 0.95)
        mat.set_shader_parameter("jitter_enabled", true)
        mat.set_shader_parameter("jitter_resolution", 280.0)
        mat.set_shader_parameter("jitter_strength", 1.0)
        return mat
        
    var mat_fur = make_mat(Color(0.85, 0.45, 0.15))
    var mat_eye = make_mat(Color(0.05, 0.05, 0.05))
    var mat_ch_red = make_mat(Color(0.7, 0.1, 0.1))
    var mat_ch_yel = make_mat(Color(0.8, 0.7, 0.1))
    var mat_ch_blu = make_mat(Color(0.1, 0.2, 0.6))
    var mat_ch_grn = make_mat(Color(0.1, 0.5, 0.2))
    
    # Body
    var body = MeshInstance3D.new()
    body.name = "Body"
    var b_mesh = CylinderMesh.new()
    b_mesh.top_radius = 0.25
    b_mesh.bottom_radius = 0.35
    b_mesh.height = 0.6
    b_mesh.radial_segments = 8
    b_mesh.material = mat_fur
    body.mesh = b_mesh
    body.position = Vector3(0, 0.3, 0)
    root.add_child(body)
    body.owner = root
    
    # Legs
    for i in [-1, 1]:
        var leg = MeshInstance3D.new()
        leg.name = "Leg_" + str(i)
        var l_mesh = CylinderMesh.new()
        l_mesh.top_radius = 0.08
        l_mesh.bottom_radius = 0.06
        l_mesh.height = 0.3
        l_mesh.radial_segments = 6
        l_mesh.material = mat_fur
        leg.mesh = l_mesh
        leg.position = Vector3(i * 0.15, 0.15, 0)
        root.add_child(leg)
        leg.owner = root
        
    # Arms
    for i in [-1, 1]:
        var arm = MeshInstance3D.new()
        arm.name = "Arm_" + str(i)
        var a_mesh = CapsuleMesh.new()
        a_mesh.radius = 0.07
        a_mesh.height = 0.4
        a_mesh.radial_segments = 6
        a_mesh.rings = 2
        a_mesh.material = mat_fur
        arm.mesh = a_mesh
        arm.position = Vector3(i * 0.35, 0.45, 0)
        arm.rotation_degrees = Vector3(0, 0, i * 20)
        root.add_child(arm)
        arm.owner = root
        
    # Head
    var head = MeshInstance3D.new()
    head.name = "Head"
    var h_mesh = SphereMesh.new()
    h_mesh.radius = 0.35
    h_mesh.height = 0.6
    h_mesh.radial_segments = 12
    h_mesh.rings = 6
    h_mesh.material = mat_fur
    head.mesh = h_mesh
    head.position = Vector3(0, 0.85, 0)
    root.add_child(head)
    head.owner = root
    
    # Eyes
    for i in [-1, 1]:
        var eye = MeshInstance3D.new()
        eye.name = "Eye_" + str(i)
        var e_mesh = SphereMesh.new()
        e_mesh.radius = 0.06
        e_mesh.height = 0.12
        e_mesh.radial_segments = 8
        e_mesh.rings = 4
        e_mesh.material = mat_eye
        eye.mesh = e_mesh
        eye.position = Vector3(i * 0.12, 0.85, -0.28)
        root.add_child(eye)
        eye.owner = root
        
    # Ears (triangles sticking out sideways)
    for i in [-1, 1]:
        var ear = MeshInstance3D.new()
        ear.name = "Ear_" + str(i)
        var er_mesh = PrismMesh.new()
        er_mesh.size = Vector3(0.3, 0.3, 0.1)
        er_mesh.material = mat_fur
        ear.mesh = er_mesh
        ear.position = Vector3(i * 0.4, 0.95, -0.05)
        ear.rotation_degrees = Vector3(0, 0, i * -60)
        root.add_child(ear)
        ear.owner = root
        
    # Chullo Hat
    var hat_base = MeshInstance3D.new()
    hat_base.name = "HatBase"
    var hat_m = CylinderMesh.new()
    hat_m.top_radius = 0.15
    hat_m.bottom_radius = 0.36
    hat_m.height = 0.3
    hat_m.radial_segments = 10
    hat_m.material = mat_ch_red
    hat_base.mesh = hat_m
    hat_base.position = Vector3(0, 1.1, 0)
    root.add_child(hat_base)
    hat_base.owner = root
    
    # Hat top cone
    var hat_top = MeshInstance3D.new()
    hat_top.name = "HatTop"
    var ht_m = CylinderMesh.new()
    ht_m.top_radius = 0.0
    ht_m.bottom_radius = 0.15
    ht_m.height = 0.25
    ht_m.radial_segments = 8
    ht_m.material = mat_ch_grn
    hat_top.mesh = ht_m
    hat_top.position = Vector3(0, 1.35, 0)
    hat_top.rotation_degrees = Vector3(20, 0, 15)
    root.add_child(hat_top)
    hat_top.owner = root
    
    # Hat bobble top
    var bob_top = MeshInstance3D.new()
    bob_top.name = "BobbleTop"
    var bt_m = SphereMesh.new()
    bt_m.radius = 0.06
    bt_m.height = 0.12
    bt_m.radial_segments = 6
    bt_m.rings = 3
    bt_m.material = mat_ch_blu
    bob_top.mesh = bt_m
    bob_top.position = Vector3(-0.06, 1.48, 0.02)
    root.add_child(bob_top)
    bob_top.owner = root
    
    # Ear flaps
    for i in [-1, 1]:
        var flap = MeshInstance3D.new()
        flap.name = "Flap_" + str(i)
        var f_mesh = PrismMesh.new()
        f_mesh.size = Vector3(0.2, 0.3, 0.05)
        f_mesh.material = mat_ch_yel
        flap.mesh = f_mesh
        flap.position = Vector3(i * 0.34, 0.85, 0)
        flap.rotation_degrees = Vector3(0, 0, 180)
        root.add_child(flap)
        flap.owner = root
        
        var cord = MeshInstance3D.new()
        cord.name = "Cord_" + str(i)
        var c_m = CylinderMesh.new()
        c_m.top_radius = 0.015
        c_m.bottom_radius = 0.015
        c_m.height = 0.2
        c_m.material = mat_ch_red
        cord.mesh = c_m
        cord.position = Vector3(i * 0.34, 0.6, 0)
        root.add_child(cord)
        cord.owner = root
        
        var bob = MeshInstance3D.new()
        bob.name = "Bobble_" + str(i)
        var bb_m = SphereMesh.new()
        bb_m.radius = 0.04
        bb_m.height = 0.08
        bb_m.material = mat_ch_grn
        bob.mesh = bb_m
        bob.position = Vector3(i * 0.34, 0.48, 0)
        root.add_child(bob)
        bob.owner = root

    var packed = PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/props/player_cat_model.tscn")
    print("Generated player_cat_model.tscn")
    quit()
