extends SceneTree

# Real Godot framebuffer screenshots of the v1.4 playable character and beach.
# Showcase fixtures freeze actions only; no screenshots are simulated or painted.
var game: Node3D
const OUTPUT_DIR := "/tmp/survivor-hero-v14"

func _initialize() -> void:
    call_deferred("run")

func _shot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(OUTPUT_DIR.path_join(name + ".png"))
    assert(result == OK)
    print("REAL_RENDER_CAPTURE ", name)

func run() -> void:
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
    game.camera_distance = 12.0
    game.player.position = Vector3(0, game.terrain.height_at(0, 173), 173)
    game.player.body_pivot.rotation.y = 0.0
    game.player.cancel_action()
    await create_timer(1.0).timeout
    await _shot("01_hero_front")
    game.player.body_pivot.rotation.y = PI * 0.55
    await create_timer(0.3).timeout
    await _shot("02_hero_profile")
    game.player.body_pivot.rotation.y = 0.0
    game.player.perform_action("chop", 1.0, Vector3(0, 0, 176))
    game.player.pose_action(0.48)
    await create_timer(0.3).timeout
    await _shot("03_hero_axe_pose_fixture")
    game.player.cancel_action()
    game.player.body_pivot.rotation.y = 0.0
    game.camera_distance = 26.0
    await create_timer(0.3).timeout
    await _shot("04_shore_complete_material")
    game.light_visuals = true
    game.apply_quality()
    await create_timer(0.3).timeout
    await _shot("05_shore_light_material")
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.18).timeout
    quit()
