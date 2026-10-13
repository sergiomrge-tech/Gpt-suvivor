extends SceneTree
var game: Node3D
var output_dir := "/tmp/survivor-captures-v041"

func _initialize() -> void:
    call_deferred("capture")

func shot(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(output_dir.path_join(name+".png"))
    assert(result == OK)
    print("CAPTURE ",name," OK")

func capture() -> void:
    DirAccess.make_dir_recursive_absolute(output_dir)
    root.size = Vector2i(1280,720)
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.capture_mode = true
    game.hud.close_modal()
    game._create_world(SurvivalState.new())
    game.playing = true
    game.player.enabled = true
    game.hud.set_playing(true)
    await create_timer(1.0).timeout
    await shot("01_praia_controles")
    game.hud.show_inventory()
    await create_timer(0.4).timeout
    print("INVENTORY RECT ",game.hud.panel.size," MIN ",game.hud.panel.get_combined_minimum_size())
    print("SCROLL RECT ",game.hud.panel_content.get_parent().size," MIN ",game.hud.panel_content.get_parent().get_combined_minimum_size()," MODE ",game.hud.panel_content.get_parent().vertical_scroll_mode)
    await shot("02_mochila")
    game.hud.show_crafting()
    await create_timer(0.4).timeout
    await shot("03_ferramentas")
    game.hud.close_modal()
    for entry in game.world.resources:
        if str(entry.id).begins_with("start_log_") or str(entry.id).begins_with("start_pebble_") or entry.id == "start_hand_fiber": game.world.harvest(entry)
    game.hud.show_crafting()
    await create_timer(0.4).timeout
    await shot("04_receitas_disponiveis")
    game.hud.close_modal()
    game.change_zoom(-100)
    await create_timer(1.0).timeout
    await shot("05_zoom_proximo")
    # A narrower landscape viewport exercises canvas layout on shorter phones.
    root.size = Vector2i(1024,576)
    game.hud.show_inventory()
    await create_timer(0.5).timeout
    await shot("06_mochila_compacta")
    game.hud.show_crafting()
    await create_timer(0.5).timeout
    await shot("07_receitas_compactas")
    game.playing = false
    game.soundscape.shutdown()
    game.queue_free()
    await create_timer(0.18).timeout
    quit()
