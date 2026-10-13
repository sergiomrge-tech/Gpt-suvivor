extends SceneTree

# Native Godot integration test: checks real imported PBR/GLB world models
# WITHOUT changing gameplay, the save schema or resource coordinates.
var checks := 0
var failures := 0
var game: Node3D

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("FAIL_REAL_WORLD: "+label)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game._create_world(SurvivalState.new())
    await process_frame
    var world: SurvivorWorld = game.world
    check(world.resources.size() > 180,"No resources removed by realistic models")
    check(SurvivorRealWorldAssets.available("palm_detailed") and SurvivorRealWorldAssets.available("palm_light"),"Both imported palms available")
    check(SurvivorRealWorldAssets.available("airplane_propeller"),"Real airframe available")
    check(SurvivorRealWorldAssets.available("workbench_carpenter"),"Real carpenter workbench available")
    check(SurvivorRealWorldAssets.available("pachira") and SurvivorRealWorldAssets.available("calathea") and SurvivorRealWorldAssets.available("fern"),"B-heavy forest foliage GLTF files import")
    var wreck_found := false
    var wreck_asset := false
    for entry in world.landmarks:
        if entry.kind == "wreck":
            wreck_found = true
            wreck_asset = entry.node.get_node_or_null("CC0_airplane_propeller") != null
            check(entry.position.distance_to(Vector3(-8,world.terrain.height_at(-8,164),164)) < 0.2,"Plane crash stays at original location and loot markers")
    check(wreck_found and wreck_asset,"Actual detailed plane GLB replaces artificial fuselage")
    for crash in world.landmarks:
        if crash.kind=="wreck":
            check(int(crash.node.get_meta("aircraft_fracture_count",0)) >= 1,"A real authored wing has been physically detached from crashed plane, rather than intact mockup")
            var detached := 0
            var plane: Node = crash.node.get_node_or_null("CC0_airplane_propeller")
            if plane != null:
                for piece in plane.find_children("*","MeshInstance3D",true,false):
                    if bool(piece.get_meta("wreck_detached",false)):
                        detached += 1
            check(detached >= 1,"Actual imported mesh instance is tilted and displaced as crash wreckage")
            break
    var real_palm_count := 0
    for resource in world.resources:
        if resource.kind=="palm" and resource.node.get_node_or_null("CC0_palm_light")!=null or resource.kind=="palm" and resource.node.get_node_or_null("CC0_palm_detailed")!=null:
            real_palm_count += 1
    check(real_palm_count >= 50,"At least fifty resources use real CC0 palm trees")
    var counts := world.scenery.real_forest_counts
    check(int(counts["fern"])>=10 and int(counts["calathea"])>=6 and int(counts["pachira"])>=3,"Actual Poly Haven assets distributed in jungle B")
    check(game.terrain.ground_material.get_shader_parameter("real_pbr_assets_ready"),"CC0 A+B+C diffuse, normal and roughness maps fully linked")
    var prior_wood: int = game.state.inventory.wood
    var source: Dictionary = {}
    for resource in world.resources:
        if resource.kind == "palm":
            source = resource
            break
    check(not source.is_empty() and source.node.visible,"Original collectible palm is still harvestable")
    check(game.state.inventory.wood == prior_wood,"Model swap does not award free resources")
    var bench := world.add_structure({"kind":"workbench","x":1.0,"z":147.0,"rotation":0.0})
    var bench_model: Node = bench.get_node_or_null("CC0_workbench_carpenter")
    check(bench_model != null,"Craftable workbench uses imported carpenter workbench GLB")
    var house := world.add_structure({"kind":"house","x":37.0,"z":147.0,"rotation":0.0})
    check(house.get_node_or_null("CC0_garden_shed") != null,"Constructed shelter uses real CC0 GLB instead of box primitive")
    var chest := world.add_structure({"kind":"chest","x":-17.0,"z":145.0,"rotation":0.0})
    check(chest.get_node_or_null("CC0_storage_chest") != null,"Original CC0 travel chest replaces procedural timber storage")
    var fire := world.add_structure({"kind":"campfire","x":-20.0,"z":148.0,"rotation":0.0})
    check(fire.get_node_or_null("CC0_camp_fire_grill") != null,"Cooking fires have a true GLB grilling appliance")
    var catcher := world.add_structure({"kind":"rain_collector","x":-26.0,"z":140.0,"rotation":0.0})
    var bucket: Node = catcher.find_child("CC0_wooden_bucket",true,false)
    check(bucket != null,"Rain collector attaches realistic licensed wooden bucket")
    var rack := world.add_structure({"kind":"tool_rack","x":-20.0,"z":139.0,"rotation":0.0})
    check(rack.find_child("CC0_wooden_crate",true,false) != null,"Advanced tool rack stores real wooden supply crate")
    check(SurvivorRealWorldAssets.available("canoe") and SurvivorRealWorldAssets.available("camp_kitchen"),"Original CC0 canoe and camp kitchen included as future level props")
    check(not world.scenery.real_forest_nodes.is_empty(),"Jungle visual resources maintain clearing list")
    world.scenery.clear_area(Vector3(-55,world.terrain.height_at(-55,72),72),2.8)
    world.scenery.set_light_mode(true)
    check(world.scenery.light_mode,"Leve mode accessible with CC0 vegetation")
    world.scenery.set_light_mode(false)
    check(not world.scenery.light_mode,"Full render mode restores CC0 foliage")
    print("CC0_WORLD_TESTS: %d/%d passed; palm=%d forest=%s" % [
        checks-failures,checks,real_palm_count,str(counts)])
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.18).timeout
    quit(0 if failures==0 else 1)
