extends SceneTree

# Actual game framebuffer inspection; not an artist's concept or composite.
# Fixtures reposition the survivor, leaving the game world and original saves intact.
var game: Node3D
const OUTPUT_DIR := "/tmp/survivor-biomes-cc0_v20"

func _initialize() -> void:
    call_deferred("capture_biomes")

func shot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(OUTPUT_DIR.path_join(name + ".png"))
    assert(result == OK)
    print("REAL_BIOME_CAPTURE ", name)

func travel(point: Vector2, zoom: float) -> void:
    game.player.position = Vector3(point.x, game.terrain.height_at(point.x, point.y), point.y)
    game.camera_distance = zoom
    await create_timer(1.0).timeout

func travel_to_habitat(family: int) -> void:
    var chosen := Vector2.ZERO
    var found := false
    for batch in game.world.scenery.biome_batches:
        if int(batch.family) != family:
            continue
        for entry in batch.entries:
            var sample: Vector3 = entry.position
            if Vector2(sample.x,sample.z).length() > 180.0:
                continue
            chosen = Vector2(sample.x,sample.z)
            found = true
            break
        if found:
            break
    assert(found)
    await travel(chosen,12.0)

func capture_biomes() -> void:
    DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
    root.size = Vector2i(1280, 720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game.hud.close_modal()
    game._create_world(SurvivalState.new())
    game.playing = true
    game.player.enabled = true
    game.hud.set_playing(true)
    game.player.set_physics_process(false)
    game.light_visuals = false
    game.apply_quality()
    await travel(Vector2(0,173),26.0)
    await shot("01_tropical_beach_full")
    await travel(Vector2(0,173),15.0)
    await shot("02_tidal_sand_detail")
    await travel(Vector2(-55,72),28.0)
    await shot("03_forest_understory")
    await travel(Vector2(0,0),33.0)
    await shot("04_central_highlands")
    await travel(Vector2(0,173),26.0)
    game.terrain.set_weather(0.72,0.23)
    game.world.scenery.set_weather(0.64,0.72)
    await create_timer(0.4).timeout
    await shot("05_rain_wet_shore")
    game.terrain.set_weather(0.0,0.0)
    game.world.scenery.set_weather(0.0,0.0)
    game.light_visuals = true
    game.apply_quality()
    await create_timer(0.4).timeout
    await shot("06_mobile_light_preset")
    game.light_visuals = false
    game.apply_quality()
    await travel_to_habitat(3)
    await shot("07_coastal_driftwood")
    await travel_to_habitat(4)
    await shot("08_forest_moss_roots")
    await travel(Vector2(-8,164),12.0)
    await shot("09_authored_aircraft_crash")
    game.world.add_structure({"kind":"workbench","x":1.0,"z":147.0,"rotation":0.0})
    await travel(Vector2(0,151),10.0)
    await shot("10_real_carpentry_workbench")
    await travel(Vector2(-25,142),13.0)
    await shot("11_real_coconut_trees")
    await travel(Vector2(45,80),19.0)
    await shot("12_dense_B_forest_scanned")
    print("IMPORTED_REAL_MODEL_COUNTS: ",SurvivorRealWorldAssets.instances)
    print("BIOMES: ", game.world.scenery.biome_counts)
    print("RENDER: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " calls (software rendering, not Android FPS)")
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.18).timeout
    quit()
