extends SceneTree
var game: Node3D
const OUT := "/tmp/survivor-map-v23"
func _initialize() -> void:
    call_deferred("run")
func shot(name: String, pos: Vector3, look: Vector3) -> void:
    game.camera.global_position = pos
    game.camera.look_at(look,Vector3.UP)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(OUT.path_join(name+".png"))==OK)
    print("REAL_MAP_FRAME ",name," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
    DirAccess.make_dir_recursive_absolute(OUT)
    root.size = Vector2i(1280,720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game._create_world(SurvivalState.new())
    game.light_visuals = false
    game.apply_quality()
    game.set_process(false)
    game.player.set_physics_process(false)
    game.hud.close_modal()
    game.hud.visible = false
    game.terrain.set_time_of_day(0.47)
    game.camera.make_current()
    for entry in [["01_crash_beach",Vector2(0,170)], ["02_west_forest",Vector2(-55,72)], ["03_north_forest",Vector2(20,-130)], ["04_east_cave",Vector2(80,20)]]:
        var p: Vector2 = entry[1]
        var h: float = game.terrain.height_at(p.x,p.y)
        game.player.position = Vector3(p.x,h,p.y)
        await shot(entry[0],Vector3(p.x+5,h+24,p.y+24),Vector3(p.x,h+1,p.y-4))
    game.world.add_structure({"kind":"house","x":37.0,"z":147.0,"rotation":0.0})
    game.world.add_structure({"kind":"workbench","x":28.0,"z":146.0,"rotation":0.0})
    game.world.add_structure({"kind":"campfire","x":29.0,"z":152.0,"rotation":0.0})
    var h: float = game.terrain.height_at(33,147)
    game.player.position = Vector3(30,h,151)
    await shot("05_camp",Vector3(43,h+16,170),Vector3(32,h+1,148))
    game.player.position = SurvivorCaves.spawn_position("east")
    await shot("06_cave_interior",Vector3(805,24,22),Vector3(800,0,-7))
    game.light_visuals = true
    game.apply_quality()
    await shot("07_cave_mobile_light",Vector3(805,24,22),Vector3(800,0,-7))
    print("CANOPY_OBSTACLES ",game.world.scenery.canopy_obstacles.size())
    game.soundscape.shutdown()
    game.queue_free()
    await process_frame
    quit()
