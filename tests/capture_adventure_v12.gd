extends SceneTree

# QA screenshots come from actual Godot 4 rendering, never concept art.
var game: Node3D
const DEST := "/tmp/survivor-adventure-v12"

func _initialize() -> void:
    call_deferred("_capture")

func capture(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image.is_empty() or image.save_png(DEST.path_join(name+".png")) != OK:
        push_error("Cannot capture real Godot framebuffer: "+name)
        quit(1)
        return
    print("REAL_RENDER_SCREENSHOT: "+name)

func _capture() -> void:
    DirAccess.make_dir_recursive_absolute(DEST)
    root.size = Vector2i(1280,720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game.hud.close_modal()
    game._create_world(SurvivalState.new())
    game.playing = true
    game.player.enabled = true
    game.hud.set_playing(true)
    await create_timer(0.5).timeout
    for id in ["east","roots"]:
        game.player.position = SurvivorCaves.CENTERS[id] + Vector3(0,0,-23)
        game.player.position.y = 0
        game._update_camera(1.0)
        await create_timer(0.4).timeout
        await capture("01_cave_east" if id == "east" else "02_cave_roots")
    var shore := Vector3.ZERO
    for z in range(172,224):
        if game.terrain.is_shore(4,z):
            shore = Vector3(4,game.terrain.height_at(4,z),z)
            break
    if shore == Vector3.ZERO:
        push_error("No valid dock near coastline")
        quit(1)
        return
    game.state.buildings.append({"kind":"dock","x":shore.x,"z":shore.z})
    game.world.add_structure(game.state.buildings.back())
    var boat_pos: Vector3 = game.world.boat_location(shore)
    game.state.buildings.append({"kind":"boat","x":boat_pos.x,"z":boat_pos.z,"stage":5})
    game.world.add_structure(game.state.buildings.back())
    game.state.discoveries["voyage_prepared"] = true
    game.player.position = shore
    game._update_camera(1.0)
    game.escape_island()
    if not game.voyage.active:
        push_error("Final sea voyage failed to start from the constructed boat")
        quit(1)
        return
    await create_timer(1.0).timeout
    await capture("03_navigation_controls")
    game.voyage.steer(1)
    await create_timer(2.0).timeout
    await capture("04_navigation_steering")
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.2).timeout
    quit(0)
