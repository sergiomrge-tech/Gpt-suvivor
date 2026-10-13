extends SceneTree

var game: Node3D
var output_dir := "/tmp/survivor-captures"

func _initialize() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--out="):
            output_dir = argument.trim_prefix("--out=")
    call_deferred("capture")

func screenshot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var error := image.save_png(output_dir.path_join(name + ".png"))
    print("CAPTURE ", name, " ", error_string(error))

func capture() -> void:
    DirAccess.make_dir_recursive_absolute(output_dir)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    root.size = Vector2i(1280, 720)
    await create_timer(1.0).timeout
    await screenshot("01_menu")
    # A fresh in-memory scene avoids touching the player's persistent save.
    game.hud.close_modal()
    game._create_world(SurvivalState.new())
    game.playing = true
    game.player.enabled = true
    game.hud.set_playing(true)
    await create_timer(1.0).timeout
    await screenshot("02_praia")
    game.hud.show_crafting()
    await screenshot("03_construir")
    game.hud.close_modal()
    game.player.position = Vector3(80, game.terrain.height_at(80, 29), 29)
    await create_timer(1.5).timeout
    await screenshot("04_caverna")
    game.player.position = Vector3(-26, game.terrain.height_at(-26, 96), 96)
    await create_timer(1.5).timeout
    await screenshot("05_nascente")
    # Display fixture only: built structures are shown via the same runtime models.
    # Progression itself is tested independently by test_survivor.gd.
    for entry in game.world.resources:
        if Vector2(entry.position.x, entry.position.z).distance_to(Vector2(20, 161)) < 28:
            entry.node.visible = false
    var dock_z := 212.0
    for z in range(180, 231):
        if game.terrain.is_shore(20, z):
            dock_z = float(z)
            break
    var boat_position: Vector3 = game.world.boat_location(Vector3(20,0,dock_z))
    for entry in [{"kind": "campfire", "x": 17.0, "z": 160.0}, {"kind": "workbench", "x": 27.0, "z": 161.0}, {"kind": "house", "x": 24.0, "z": 151.0}, {"kind": "dock", "x": 20.0, "z": dock_z}, {"kind": "boat", "x": boat_position.x, "z": boat_position.z}]:
        game.state.buildings.append(entry)
        game.world.add_structure(entry)
    game.player.position = Vector3(20, game.terrain.height_at(20, 168), 168)
    game.state.inventory.fishing_rod = 1
    await create_timer(1.5).timeout
    await screenshot("06_acampamento_fixture")
    # Resize to a common 20:9 Android landscape aspect ratio.
    DisplayServer.window_set_size(Vector2i(1600, 720))
    root.size = Vector2i(1600, 720)
    await create_timer(0.5).timeout
    await screenshot("07_android_layout")
    game.player.position = Vector3(20, game.terrain.height_at(20, dock_z - 2.0), dock_z - 2.0)
    game.camera_distance = 23.0
    await create_timer(1.3).timeout
    await screenshot("08_costa_barco_fixture")
    game.player.position = Vector3(27, game.terrain.height_at(27, 160), 160)
    game.camera_distance = 19.0
    await create_timer(1.3).timeout
    await screenshot("09_materiais_acampamento_fixture")
    game.light_visuals = true
    game.apply_quality()
    await create_timer(1.3).timeout
    await screenshot("10_modo_leve_fixture")
    game.light_visuals = false
    game.apply_quality()
    game.player.set_physics_process(false)
    game.camera_distance = 12.0
    game.player.position = Vector3(0,game.terrain.height_at(0,173),173)
    game.player.body_pivot.rotation.y = 0
    game.player.cancel_action()
    await create_timer(1.4).timeout
    await screenshot("11_personagem_fixture")
    for entry in game.world.resources:
        if entry.kind=="palm" and entry.node.visible:
            game.player.position = entry.position+Vector3(0,0,1.65)
            game.player.position.y = game.world.surface_height(game.player.position)
            game.player.perform_action("chop",1.05,entry.position)
            game.player.pose_action(0.48)
            break
    await create_timer(1.4).timeout
    await screenshot("12_machadinha_fixture")
    game.player.cancel_action()
    game.player.position = Vector3(20,game.terrain.height_at(20,dock_z-2),dock_z-2)
    game.player.perform_action("fish",3.0,Vector3(25,game.terrain.sea_level+0.12,dock_z+7))
    game.player.pose_action(0.5)
    game.player._update_fishing_line()
    game.camera_distance = 19
    await create_timer(1.4).timeout
    await screenshot("13_pesca_fixture")
    game.player.cancel_action()
    game.player.position = Vector3(-55,game.terrain.height_at(-55,72),72)
    game.camera_distance = 29
    await create_timer(1.4).timeout
    await screenshot("14_mata_trilhas")
    game.world.discover(game.world.discoverables[0])
    game.hud.show_journal()
    await screenshot("15_diario")
    game.hud.close_modal()
    game.hud.toggle_inventory()
    await screenshot("16_mochila")
    game.hud.toggle_inventory()
    print("COVER: ", game.world.scenery.cover_count, " clumps in ", game.world.scenery.batches.size(), " chunks")
    print("RENDER INFO: draw calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " visible objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " fps=", Engine.get_frames_per_second())
    game.playing = false
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.18).timeout
    quit()
