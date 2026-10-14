extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("MAP_ASSET_FAIL: "+label)
func run() -> void:
    var game := load("res://scenes/main.tscn").instantiate() as Node3D
    root.add_child(game)
    game.capture_mode = true
    game.player.set_physics_process(false)
    var world: SurvivorWorld = game.world
    var ids := {"palm":"palm","tree":"","fiber":"fern","rock":"","loose_log":"dead_tree_trunk_02","loose_stone":"rock_07"}
    for item in world.resources:
        if not ids.has(item.kind):
            continue
        var models: Array[Node] = item.node.find_children("CC0_*","Node3D",true,false)
        check(not models.is_empty(),"Every harvestable nature resource uses a real source asset: "+item.id)
    var textured := 0
    for source in ["fern","calathea","pachira","island_tree_01","tree_stump_01","dead_tree_trunk_02","boulder_01","rock_07","wooden_ladder_02"]:
        var low := Vector3(INF,INF,INF)
        var high := Vector3(-INF,-INF,-INF)
        for part in SurvivorWorldAssetRenderer.parts(source):
            var mesh: Mesh = part.mesh
            var bounds := mesh.get_aabb()
            low = low.min(bounds.position)
            high = high.max(bounds.end)
            var arrays: Array = mesh.surface_get_arrays(0)
            check(arrays[Mesh.ARRAY_TEX_UV]!=null and arrays[Mesh.ARRAY_NORMAL]!=null,"UVs/normals survive material batching: "+source)
            var mat := part.material as StandardMaterial3D
            if mat != null and mat.albedo_texture != null:
                textured += 1
        check(absf((high.y-low.y)-1.0)<0.01,"Common one-metre source scale: "+source)
    check(textured>=9,"Scanned vegetation/rock/wood preserve actual photographic textures")
    var decor := world.scenery
    check(decor.canopy_obstacles.size()>=70,"Canopy distributed beyond original seven groves")
    var quadrants := {}
    for obstacle in decor.canopy_obstacles:
        quadrants[Vector2i(1 if obstacle.position.x>=0 else -1,1 if obstacle.position.z>=0 else -1)] = true
        check(not decor._protected(Vector2(obstacle.position.x,obstacle.position.z)),"New trunks leave trail/resource corridors clear")
        check(not world.walkable(obstacle.position,obstacle.position),"Visible new trunk has collision")
    check(quadrants.size()==4,"Native canopy reaches all four island quadrants")
    var original: Dictionary = decor.canopy_obstacles[0]
    decor.clear_area(original.position,3.0)
    decor.set_light_mode(true)
    decor.set_light_mode(false)
    check(original.cleared and decor.scenery_walkable(original.position),"Building clearance persists after changing quality")
    for family in [decor.batches,decor.biome_batches,decor.detail_batches,decor.tropical_floor_batches,decor.canopy_batches]:
        for batch in family:
            check(batch.node.has_meta("source_asset"),"Every scenery batch uses catalog source geometry")
    for id in world.caves.rooms:
        var room: Node3D = world.caves.rooms[id]
        var floor_mesh := room.find_child("ScannedCaveFloor",true,false) as MeshInstance3D
        check(floor_mesh!=null and floor_mesh.material_override is StandardMaterial3D,"Both cave floors keep scanned PBR surface")
        check(world.caves.is_walkable(SurvivorCaves.spawn_position(id)),"Both cave spawns stay unobstructed")
        check(world.caves.is_walkable(SurvivorCaves.exit_position(id)),"Both cave exits stay unobstructed")
    var boat := world.add_structure({"kind":"boat","x":0.0,"z":200.0,"stage":5})
    check(boat.find_child("CC0_canoe",true,false)!=null,"Completed craft integrates original CC0 boat hull")
    check(game.player.using_skinned_hero,"Corrected dressed hero remains active")
    print("MAP_ASSETS_V23: %d/%d passed; canopy=%d; photographed parts=%d" % [checks-failures,checks,decor.canopy_obstacles.size(),textured])
    game.soundscape.shutdown()
    game.queue_free()
    await process_frame
    quit(0 if failures==0 else 1)
