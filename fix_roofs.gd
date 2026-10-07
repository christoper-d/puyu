extends SceneTree

func _init():
    print("Fixing roofs...")
    var scenes = ["res://scenes/architecture/techo_calamina.tscn", "res://scenes/architecture/techo_paja.tscn"]
    for path in scenes:
        var packed = load(path)
        if not packed: continue
        var root = packed.instantiate()
        
        var front = root.get_node("SheetFront")
        var front_col = root.get_node("CollisionFront")
        
        var back = root.get_node("SheetBack")
        var back_col = root.get_node("CollisionBack")
        
        var angle = deg_to_rad(20)
        
        var front_trans = Transform3D().rotated(Vector3.RIGHT, -angle)
        front_trans.origin = Vector3(0, 0.52, 1.35)
        front.transform = front_trans
        if front_col: front_col.transform = front_trans
        
        var back_trans = Transform3D().rotated(Vector3.RIGHT, angle)
        back_trans.origin = Vector3(0, 0.52, -1.35)
        back.transform = back_trans
        if back_col: back_col.transform = back_trans
        
        var new_packed = PackedScene.new()
        new_packed.pack(root)
        ResourceSaver.save(new_packed, path)
        print("Saved ", path)
        root.queue_free()
    
    quit()
