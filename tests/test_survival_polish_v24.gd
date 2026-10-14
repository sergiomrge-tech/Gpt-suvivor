extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("POLISH_V24_FAIL: "+label)
func hand(rig: SurvivorSkinnedActor,side: String) -> Vector3:
    rig.skeleton.force_update_all_bone_transforms()
    return rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("hand_"+side)).origin
func run() -> void:
    game = load("res://scenes/main.tscn").instantiate() as Node3D
    root.add_child(game)
    game.capture_mode = true
    game._create_world(SurvivalState.new())
    game.set_process(false)
    game.player.set_physics_process(false)
    var world: SurvivorWorld = game.world
    check(world.scenery.canopy_resources.size()==world.scenery.canopy_obstacles.size(),"Every new island tree is an interactive resource")
    for tree in world.scenery.canopy_resources:
        check(world.resources.has(tree) and tree.id.begins_with("canopy_tree_"),"Append-only tree identifiers preserve reload state")
        check(not world.walkable(tree.position,tree.position),"Live tree retains visible trunk collision")
    var tree: Dictionary = world.scenery.canopy_resources[0]
    var before: int = game.state.inventory.wood
    world.harvest(tree)
    check(tree.node.visible and game.state.inventory.wood==before,"Bare hands cannot harvest canopy tree")
    game.state.inventory.stone_axe = 1
    game.state.equip_tool("stone_axe")
    world.harvest(tree)
    check(not tree.node.visible and game.state.inventory.wood==before+5,"Axe fells tree and gives partial wood once")
    check(game.state.wood_drops.size()==1 and game.state.wood_drops[0].amount==3,"Remaining three wood are an actual saved log pickup")
    check(not tree.shown and world.walkable(tree.position,tree.position),"Felled canopy stops rendering and releases its trunk collision")
    var pending := SurvivalState.from_data(game.state.to_data())
    check(pending!=null and pending.wood_drops.size()==1,"Uncollected wood survives save/reload")
    var drop: Dictionary = {}
    for resource in world.resources:
        if bool(resource.get("drop",false)):
            drop = resource
            break
    world.harvest(drop)
    check(game.state.inventory.wood==before+8 and game.state.wood_drops.is_empty(),"Total wood conserved after manual pickup")
    world.harvest(drop)
    check(game.state.inventory.wood==before+8,"Collected log cannot pay twice")
    world.refresh_resources()
    check(not drop.node.visible,"Picked-up log never regrows as free loot")
    var old: Dictionary = game.state.to_data()
    old.version = 3
    old.erase("wood_drops")
    check(SurvivalState.from_data(old)!=null,"Previous v3 saves migrate without losing inventory")
    var invalid: Dictionary = game.state.to_data()
    invalid.wood_drops = [{"id":"bad","amount":-2,"x":0.0,"z":0.0}]
    check(SurvivalState.from_data(invalid)==null,"Malformed pickup save is rejected")
    invalid.wood_drops = [{"id":"missing_position","amount":3}]
    check(SurvivalState.from_data(invalid)==null,"Pickup save requires explicit world coordinates")
    for kind in ["house","workbench","chest","campfire","rain_collector","tool_rack","boat"]:
        var preview := Node3D.new()
        game.add_child(preview)
        world.build_structure_visual(preview,kind,1,true)
        var live := world.add_structure({"kind":kind,"x":0.0,"z":150.0,"stage":1})
        var preview_bounds: AABB = preview.get_meta("visual_bounds")
        var live_bounds: AABB = live.get_meta("visual_bounds")
        check(preview_bounds.size.distance_to(live_bounds.size)<0.001,"Preview uses identical model dimensions: "+kind)
        check(preview.find_children("CC0_*","Node3D",true,false).size()==live.find_children("CC0_*","Node3D",true,false).size(),"Preview/final catalog model identity: "+kind)
        check(world.footprint_radius(kind)>=maxf(live_bounds.size.x,live_bounds.size.z)*0.5,"Placement clearance covers real model: "+kind)
        preview.queue_free()
    var rig: SurvivorSkinnedActor = game.player.rigged_hero
    rig.set_process(false)
    var positions := {}
    for kind in SurvivorHeroLocomotion.ACTIONS:
        check(rig.clips.has(kind) and rig.clips[kind]!=rig.clips.wave,"Each action has a real dedicated skeleton clip: "+kind)
        game.player.perform_action(kind,1.0,game.player.position+Vector3(0,0,2))
        for t in [0.05,0.25,0.47,0.75,0.95]:
            game.player.action_remaining = 1.0-t
            rig._process(0.016)
            var point := hand(rig,"r")
            check(point.is_finite(),"Finite wrist pose for "+kind)
            check(hand(rig,"l").x>-0.05 and point.x<0.05,"Hands do not cross through opposite sides: "+kind)
            if is_equal_approx(t,0.47):
                positions[kind] = point
        game.player.cancel_action()
    check(positions.chop.distance_to(positions.mine)>0.025,"Chopping and mining have distinct contact poses")
    check(positions.fish.distance_to(positions.gather)>0.12,"Fishing hold differs from ground pickup")
    check(positions.eat.distance_to(positions.build)>0.08,"Consumption reaches face rather than construction pose")
    game.player.walking = true
    game.player.locomotion_blend = 0.0
    game.player.measured_speed = 1.6
    rig._process(0.016)
    var normal_speed := rig.animator.speed_scale
    game.player.measured_speed = 0.8
    rig._process(0.016)
    check(rig.animator.speed_scale<normal_speed*0.6,"Walk cadence responds to actual analog displacement")
    var monitor := SurvivorPerformanceMonitor.new()
    check(monitor.snapshot().mean_fps==0.0,"No invented FPS before collecting samples")
    for sample in range(120):
        monitor.sample(1.0/60.0)
    var stats := monitor.snapshot()
    check(absf(stats.mean_fps-60.0)<0.01 and absf(stats.p95_frame_ms-16.6667)<0.02,"Performance panel reports measured frame statistics")
    check(monitor.save_report()==OK,"On-device performance report is persisted")
    check(world.harvest_effects.active<=SurvivorHarvestEffects.MAX_ACTIVE,"Harvest effect budget remains bounded")
    game.soundscape.shutdown()
    game.queue_free()
    await process_frame
    print("SURVIVAL_POLISH_V24: %d/%d passed" % [checks-failures,checks])
    quit(0 if failures==0 else 1)
