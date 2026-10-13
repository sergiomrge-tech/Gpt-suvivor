extends SceneTree

# Native, unpainted Godot framebuffer screenshots of the v1.7 game actor.
# Fixtures hold pose frames strictly for auditing geometry and tool grips.
var game: Node3D
const OUTPUT_DIR := "/tmp/survivor-hero-v17"

func _initialize() -> void:
    call_deferred("run")

func _shot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var status := root.get_texture().get_image().save_png(OUTPUT_DIR.path_join(name+".png"))
    assert(status == OK)
    print("REAL_HERO_CAPTURE ",name)

func _settle() -> void:
    await create_timer(0.40).timeout

func run() -> void:
    DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
    root.size = Vector2i(1280,720)
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
    game.player.position = Vector3(0,game.terrain.height_at(0,173),173)
    game.camera_distance = 8.0
    game.player.body_pivot.rotation.y = 0.0
    game.player.cancel_action()
    await create_timer(1.0).timeout
    await _shot("01_hero_front_anatomy")
    game.player.body_pivot.rotation.y = PI*0.5
    await _settle()
    await _shot("02_hero_profile_proportions")
    game.player.body_pivot.rotation.y = PI
    await _settle()
    await _shot("03_hero_pack_and_boots")
    game.player.body_pivot.rotation.y = 0.0
    game.player.walking = true
    game.player.animation_clock = PI*0.5
    game.player._base_pose()
    await _settle()
    await _shot("04_hero_walk_ankle_fixture")
    game.player.walking = false
    game.player.cancel_action()
    game.player.perform_action("chop",1.0,Vector3(0,0,177))
    game.player.pose_action(0.48)
    await _settle()
    await _shot("05_hero_chopping_fixture")
    game.player.cancel_action()
    game.player.perform_action("fish",2.0,Vector3(1,game.terrain.sea_level,193))
    game.player.pose_action(0.40)
    game.player._update_fishing_line()
    await _settle()
    await _shot("06_hero_fishing_fixture")
    game.player.cancel_action()
    game.camera_distance = 19.0
    game.light_visuals = true
    game.apply_quality()
    await _settle()
    await _shot("07_hero_mobile_gameplay_scale")
    # Close-up inspection is still a REAL Godot camera, with authentic world
    # lighting and unmodified character meshes; only the HUD is hidden.
    var inspection_camera := Camera3D.new()
    inspection_camera.fov = 38.0
    game.add_child(inspection_camera)
    inspection_camera.global_position = game.player.global_position+Vector3(1.0,2.25,5.8)
    inspection_camera.look_at(game.player.global_position+Vector3(0,1.45,0),Vector3.UP)
    inspection_camera.make_current()
    game.hud.visible = false
    game.light_visuals = false
    game.apply_quality()
    game.player.body_pivot.rotation.y = 0.0
    await _settle()
    await _shot("08_real_camera_hero_closeup_front")
    game.player.body_pivot.rotation.y = PI*0.50
    await _settle()
    await _shot("09_real_camera_hero_closeup_side")
    game.player.body_pivot.rotation.y = 0.0
    inspection_camera.global_position = game.player.global_position+Vector3(0.65,0.92,2.45)
    inspection_camera.look_at(game.player.global_position+Vector3(0,0.53,0),Vector3.UP)
    await _settle()
    await _shot("10_real_camera_boots_closeup")
    print("HERO V17 MESHES: left_ankle=",game.player.left_foot.get_child_count()," right_ankle=",game.player.right_foot.get_child_count())
    print("RENDER: ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," calls (software renderer, not Android FPS)")
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.20).timeout
    quit()
