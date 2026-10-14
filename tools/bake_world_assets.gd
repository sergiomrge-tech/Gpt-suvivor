extends SceneTree
# Reproducible export preparation. Runtime retains a fallback from original GLBs.
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var directory := "res"+"://assets/optimized_world"
    DirAccess.make_dir_recursive_absolute(directory)
    for source in SurvivorRealWorldAssets.SOURCES:
        if source == "airplane_propeller":
            continue
        var destination := directory.path_join(source+".scn")
        if FileAccess.file_exists(destination):
            assert(DirAccess.remove_absolute(destination)==OK)
        SurvivorWorldAssetRenderer.geometry.erase(source)
        var parts := SurvivorWorldAssetRenderer.parts(source)
        assert(not parts.is_empty(),"Missing native asset "+source)
        var root := Node3D.new()
        if SurvivorWorldAssetRenderer.collision_boxes.has(source):
            root.set_meta("collision_bounds",SurvivorWorldAssetRenderer.collision_boxes[source])
        for part in parts:
            var mesh := MeshInstance3D.new()
            mesh.mesh = part.mesh
            root.add_child(mesh)
            mesh.owner = root
        var packed := PackedScene.new()
        assert(packed.pack(root)==OK)
        assert(ResourceSaver.save(packed,directory.path_join(source+".scn"))==OK)
        root.free()
        print("BAKED_NATIVE_ASSET ",source," material batches=",parts.size())
    quit()
