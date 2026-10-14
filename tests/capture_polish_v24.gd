extends SceneTree
var game: Node3D
const OUT := "/tmp/survivor-polish-v24"
func _initialize() -> void:
    call_deferred("run")
func shot(label: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(OUT.path_join(label+".png"))==OK)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(OUT)
    root.size = Vector2i(1280,720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game._create_world(SurvivalState.new())
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.visible = false
    game.light_visuals = false
    game.apply_quality()
    game.terrain.set_time_of_day(0.47)
    var h: float = game.terrain.height_at(0,173)
    game.player.position = Vector3(0,h,173)
    game.camera.global_position = game.player.position+Vector3(4,2.8,5)
    game.camera.look_at(game.player.position+Vector3(0,1,0))
    game.camera.make_current()
    game.player.rigged_hero.set_process(false)
    for kind in ["chop","mine","fish","eat","build"]:
        game.player.perform_action(kind,1.0,game.player.position+Vector3(0,0,2))
        game.player.action_remaining = 0.53
        game.player.rigged_hero._process(0.0)
        game.player._update_fishing_line()
        await shot("action_"+kind)
    game.player.cancel_action()
    game.world.add_structure({"kind":"house","x":37.0,"z":147.0,"rotation":0.0,"stage":1})
    var preview := Node3D.new()
    game.add_child(preview)
    preview.position = Vector3(28,game.terrain.height_at(28,147),147)
    game.world.build_structure_visual(preview,"house",1,true)
    game.camera.global_position = Vector3(42,h+12,169)
    game.camera.look_at(Vector3(32,h+1,147))
    await shot("matching_house_preview")
    var tree: Dictionary = game.world.scenery.canopy_resources[0]
    game.camera.global_position = tree.position+Vector3(10,9,14)
    game.camera.look_at(tree.position+Vector3.UP*3)
    game.state.inventory.stone_axe = 1
    game.state.equip_tool("stone_axe")
    game.world.harvest(tree)
    await process_frame
    for batch in tree.batches:
        assert(is_zero_approx(batch.node.multimesh.get_instance_transform(tree.instance).basis.determinant()))
    await create_timer(0.55).timeout
    await shot("tree_fall_and_saved_log")
    var rock: Dictionary = {}
    for entry in game.world.resources:
        if entry.kind=="rock":
            rock = entry
            break
    game.state.inventory.stone_pickaxe = 1
    game.state.equip_tool("stone_pickaxe")
    game.camera.global_position = rock.position+Vector3(3,2,4)
    game.camera.look_at(rock.position+Vector3.UP*0.2)
    game.world.harvest(rock)
    await create_timer(0.20).timeout
    await shot("rock_fragments")
    print("REAL_POLISH_V24_CAPTURE: native frames and MultiMesh hide verified")
    game.soundscape.shutdown()
    game.queue_free()
    await process_frame
    quit()
