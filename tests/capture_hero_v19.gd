extends SceneTree

# Only unedited native Godot framebuffer captures. Never synthetic preview.
var game: Node3D
const OUT := "/tmp/gpt-survivor-real-human-v19"

func _initialize() -> void:
    call_deferred("run")

func shot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var output := root.get_texture().get_image().save_png(OUT.path_join(name+".png"))
    assert(output == OK)
    print("REAL_SKINNED_CAPTURE ",name)

func travel_camera(relative: Vector3, focus: Vector3) -> void:
    var cam := game.camera as Camera3D
    cam.global_position = game.player.global_position + relative
    cam.look_at(game.player.global_position+focus,Vector3.UP)
    await create_timer(0.5).timeout

func run() -> void:
    DirAccess.make_dir_recursive_absolute(OUT)
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
    assert(game.player.using_skinned_hero and game.player.rigged_hero != null)
    var skeleton: Skeleton3D = game.player.rigged_hero.skeleton
    assert(skeleton != null and skeleton.get_bone_count() >= 50)
    await create_timer(0.8).timeout
    game.camera_distance = 12.0
    await shot("01_real_human_mobile_top_down")
    game.hud.visible = false
    var inspection := Camera3D.new()
    inspection.fov = 42.0
    game.add_child(inspection)
    inspection.make_current()
    inspection.global_position = game.player.global_position+Vector3(0.15,2.6,5.8)
    inspection.look_at(game.player.global_position+Vector3(0,1.18,0),Vector3.UP)
    await create_timer(0.6).timeout
    await shot("02_real_human_full_body_front")
    game.player.body_pivot.rotation.y = PI*0.50
    await create_timer(0.6).timeout
    await shot("03_real_human_profile")
    game.player.body_pivot.rotation.y = 0.0
    game.player.walking = true
    await create_timer(0.6).timeout
    await shot("04_skinned_walk_animation")
    game.player.walking = false
    game.player.perform_action("fish",2.5,Vector3(1.0,game.terrain.sea_level,192.0))
    game.player._update_fishing_line()
    await create_timer(0.6).timeout
    await shot("05_right_hand_bone_equipped_fishing")
    game.player.cancel_action()
    print("REAL_HUMAN_V19: bones=",skeleton.get_bone_count()," clips=",game.player.rigged_hero.clips.keys()," grip=",game.player.rigged_hero.grip.bone_name)
    print("RENDER_SOFTWARE_CALLS ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.2).timeout
    quit()
