extends SceneTree

var failures := 0
var checks := 0
var game: Node3D

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("FAIL: " + message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var state := SurvivalState.new()
    check(SurvivorClimate.rainfall_at(100.0) == 0.0,"Clear weather stays rain-free")
    check(SurvivorClimate.rainfall_at(220.0) > 0.5,"Scheduled tropical rain builds naturally")
    check(SurvivorClimate.storm_at(312.0) > 0.5 and SurvivorClimate.label_at(312.0) == "Temporal","Storm peak drives UI weather description")
    check(SurvivorClimate.wind_at(312.0) > SurvivorClimate.wind_at(100.0),"Storm increases foliage and wave wind")
    check(SurvivorClimate.rainfall_at(600.0) == 0.0,"Rain stops during dry weather")
    check(state.recipe_error("boat") != "", "Boat locked at start")
    check(state.recipe_error("not_a_recipe") != "", "Unknown recipe rejected")
    check(not state.pay_recipe("campfire"), "Insufficient resources cannot be spent")
    state.add_item("wood", 10)
    state.add_item("stone", 6)
    check(state.pay_recipe("campfire"), "Campfire recipe charged exactly once")
    state.buildings.append({"kind": "campfire", "x": 0.0, "z": 165.0})
    check(state.inventory.wood == 0 and state.inventory.stone == 0, "Exact costs deducted")
    check(not state.pay_recipe("campfire"), "Duplicate structure rejected")
    state.thirst = 45
    state.hunger = 60
    state.consume()
    check(state.thirst == 75 and state.hunger == 75 and state.inventory.coconut == 1, "Coconut restores hunger and thirst")
    state.add_item("meal", 1)
    state.hunger = 40
    state.consume()
    check(state.hunger == 78 and state.inventory.meal == 0, "Cooked meal consumed")
    var wild_food_state := SurvivalState.new()
    wild_food_state.add_item("wood", 4)
    wild_food_state.add_item("stone", 2)
    wild_food_state.add_item("fiber", 3)
    check(wild_food_state.craft_tool("stone_spear") and wild_food_state.is_equipped("stone_spear"), "Stone spear crafted and equipped in utility slot")
    check(wild_food_state.harvest_error("boar") == "" and wild_food_state.harvest_error("palm") != "", "Spear enables hunting without bypassing axe requirement")
    wild_food_state.buildings.append({"kind":"campfire","x":0.0,"z":155.0})
    wild_food_state.add_item("raw_crab", 2)
    wild_food_state.add_item("raw_meat", 2)
    check(wild_food_state.pay_recipe("grilled_crab"), "Campfire recipe consumes exactly one raw crab")
    wild_food_state.add_item("grilled_crab", 1)
    check(wild_food_state.pay_recipe("cooked_meat"), "Campfire recipe consumes exactly one piece of raw meat")
    wild_food_state.add_item("cooked_meat", 1)
    wild_food_state.hunger = 15.0
    wild_food_state.health = 60.0
    check(wild_food_state.consume().contains("Carne assada") and wild_food_state.hunger == 63.0 and wild_food_state.health == 68.0, "Cooked meat restores balanced hunger and health")
    check(wild_food_state.consume().contains("Caranguejo assado") and wild_food_state.hunger == 89.0, "Cooked crab is edible and recovers hunger")
    var wildlife_saved := SurvivalState.from_data(wild_food_state.to_data())
    check(wildlife_saved != null and wildlife_saved.inventory.raw_crab == 1 and wildlife_saved.inventory.raw_meat == 1 and wildlife_saved.owns("stone_spear"), "Old save version preserves wildlife food and tool without schema migration")
    var research := SurvivalState.new()
    research.buildings.append({"kind":"campfire","x":0.0,"z":161.0})
    research.buildings.append({"kind":"workbench","x":0.0,"z":156.0})
    research.add_item("stone_axe",1)
    research.add_item("stone_pickaxe",1)
    research.add_item("wood",6)
    research.add_item("plank",8)
    research.add_item("metal",8)
    research.add_item("rope",2)
    research.add_item("cave_crystal",1)
    check(research.recipe_error("tool_rack").contains("Relicário"), "Workshop tier two cannot be researched without exploring the eastern cave")
    research.discoveries["east_vault"] = true
    check(research.pay_recipe("tool_rack"), "Rare crystal and intermediate materials pay for workshop tier two")
    research.buildings.append({"kind":"tool_rack","x":6.0,"z":156.0})
    check(research.inventory.cave_crystal == 0 and research.has_structure("tool_rack"), "Crafting upgrade consumes exactly one crystal and adds persistent workshop")
    check(research.craft_tool("reinforced_axe") and research.is_equipped("reinforced_axe"), "Level-two axe can be crafted and equipped after workshop upgrade")
    check(research.harvest_error("tree") == "", "Upgraded axe satisfies wooden resource gating")
    check(research.craft_tool("reinforced_pickaxe") and research.is_equipped("reinforced_pickaxe"), "Level-two pickaxe can be crafted and equipped at the same workshop")
    check(research.harvest_error("rock") == "" and research.inventory.metal == 0, "Improved pickaxe mines rocks and upgrade costs never produce free metal")
    var saved_research := SurvivalState.from_data(research.to_data())
    check(saved_research != null and saved_research.has_structure("tool_rack") and saved_research.is_equipped("reinforced_pickaxe"), "Workshop and advanced tool equipment survive original v3 save roundtrip")
    var grace := SurvivalState.new()
    grace.advance(120)
    check(grace.hunger == 100 and grace.thirst == 100, "Three-minute learning grace period")
    grace.elapsed = 181
    grace.hunger = 0
    grace.advance(5)
    check(grace.health < 100, "Starvation damages health")
    grace.escaped = true
    var prior := grace.health
    grace.advance(30)
    check(grace.health == prior, "Victory stops health loss")
    var path := "user://test_survivor.json"
    state.harvested["palm_1"] = 600
    state.player_position = Vector3(25, 4, 151)
    check(SurvivorSave.save_state(state, path) == OK, "Atomic save succeeds")
    var restored := SurvivorSave.load_state(path)
    check(restored != null and restored.inventory == state.inventory and restored.buildings == state.buildings, "Inventory and buildings survive JSON round-trip")
    check(restored.player_position.x == 25 and restored.harvested.has("palm_1"), "Position and harvested nodes survive save")
    check(SurvivorSave.save_state(state, path) == OK and FileAccess.file_exists(path + ".bak"), "Second save creates usable backup")
    check(SurvivalState.from_data({"version": 99}) == null, "Unsupported save version rejected")
    var corrupt := state.to_data().duplicate(true)
    corrupt.inventory.wood = "garbage"
    check(SurvivalState.from_data(corrupt) == null, "Invalid inventory rejected")
    corrupt = state.to_data().duplicate(true)
    corrupt.position = ["oops", 170]
    check(SurvivalState.from_data(corrupt) == null, "Invalid position rejected")
    corrupt = state.to_data().duplicate(true)
    corrupt.buildings = [{"kind": "boat", "x": INF, "z": 2}]
    check(SurvivalState.from_data(corrupt) == null, "Non-finite building coordinates rejected")
    corrupt = state.to_data().duplicate(true)
    corrupt.escaped = true
    check(not SurvivalState.from_data(corrupt).escaped, "Victory flag requires a boat")
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path + suffix):
            DirAccess.remove_absolute(path + suffix)

    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(game.world.resources.size() >= 190, "Island generated with abundant accessible resources")
    check(game.world.fauna != null and game.world.fauna.animals.size() >= 12, "Coastal and forest fauna populate the island")
    var crab_entry: Dictionary = {}
    var boar_entry: Dictionary = {}
    for creature in game.world.fauna.animals:
        if creature.kind == "crab" and crab_entry.is_empty():
            crab_entry = creature
        if creature.kind == "boar" and boar_entry.is_empty():
            boar_entry = creature
    check(not crab_entry.is_empty() and not boar_entry.is_empty(), "Harvestable crab and boar exist on valid habitats")
    if not crab_entry.is_empty() and not boar_entry.is_empty():
        var wildlife_state: SurvivalState = game.world.fauna.state
        var hunting_fixture := SurvivalState.new()
        game.world.fauna.state = hunting_fixture
        check(game.world.fauna.nearest_prey(crab_entry.position, 1.0).get("kind", "") == "crab", "Nearby wildlife is targetable from live island nodes")
        check(game.world.harvest(crab_entry).contains("Caranguejo") and hunting_fixture.inventory.raw_crab == 1, "Collecting a crab grants raw crab meat")
        check(hunting_fixture.harvested.has(crab_entry.id) and not crab_entry.node.visible, "Wildlife harvest hides node and records a respawn deadline")
        game.world.harvest(crab_entry)
        check(hunting_fixture.inventory.raw_crab == 1, "Same crab cannot be harvested twice during cooldown")
        hunting_fixture.elapsed = 901.0
        check(game.world.harvest(crab_entry).contains("Caranguejo") and hunting_fixture.inventory.raw_crab == 2, "Crabs return after saved world-time cooldown")
        check(game.world.harvest(boar_entry).contains("lança") and hunting_fixture.inventory.raw_meat == 0, "Boar hunting requires equipped spear")
        hunting_fixture.add_item("stone_spear", 1)
        hunting_fixture.equip_tool("stone_spear")
        check(game.world.harvest(boar_entry).contains("Carne") and hunting_fixture.inventory.raw_meat == 2, "Spear hunting drops exactly two raw meats")
        var round_trip := SurvivalState.from_data(hunting_fixture.to_data())
        check(round_trip != null and round_trip.harvested.has(boar_entry.id) and round_trip.inventory.raw_meat == 2, "Wildlife cooldown and drops persist in version-three save")
        game.world.fauna.state = wildlife_state
    var wildlife_species := {}
    for animal in game.world.fauna.animals:
        wildlife_species[animal.kind] = true
    check(wildlife_species.has("boar") and wildlife_species.has("bird") and wildlife_species.has("fish"), "Forest, sky and reef fauna generated")
    game.world.fauna.set_light_mode(true)
    check(game.world.fauna.light_mode, "Light quality can reduce visible wildlife")
    game.world.fauna.set_light_mode(false)
    var terrain_mesh: MeshInstance3D = game.terrain.get_node("IslandTerrain")
    var terrain_normals: PackedVector3Array = terrain_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
    var upward := true
    for normal in terrain_normals:
        if normal.y <= 0.0:
            upward = false
            break
    check(upward, "Terrain faces and normals point upward")
    var resource_meshes := 0
    for child in game.world.resources[0].node.get_children():
        if child is MeshInstance3D:
            resource_meshes += 1
    check(resource_meshes == 1, "Static palm merged to one mesh for mobile rendering")
    check(game.world.scenery.cover_count > 1000, "Decorative groundcover generated without replacing harvestable resources")
    check(not game.terrain.is_shore(0,170), "Beach plateau inland is not mistaken for actual shoreline")
    game.light_visuals = true
    game.apply_quality()
    var limited := true
    for batch in game.world.scenery.batches:
        if batch.node.multimesh.visible_instance_count >= batch.node.multimesh.instance_count:
            limited = false
    check(not game.terrain.sun.shadow_enabled and limited and game.climate.particles.amount == 90, "Light mode reduces shadows, cover and weather particles")
    game.light_visuals = false
    game.apply_quality()
    check(game.terrain.sun.shadow_enabled and game.world.scenery.batches[0].node.multimesh.visible_instance_count == -1 and game.climate.particles.amount == 280, "Full mode restores shadows, groundcover and weather particles")
    var old_state := SurvivalState.new()
    old_state.buildings.append({"kind":"dock","x":20.0,"z":180.0})
    old_state.buildings.append({"kind":"boat","x":23.5,"z":185.0})
    var old_world := SurvivorWorld.new()
    old_world.terrain = game.terrain
    old_world.state = old_state
    old_world.repair_coastal_buildings()
    check(game.terrain.is_shore(old_state.buildings[0].x,old_state.buildings[0].z), "Existing inland dock relocated to true coast")
    check(game.terrain.height_at(old_state.buildings[1].x,old_state.buildings[1].z) <= game.terrain.sea_level+0.15, "Existing grounded boat relocated to water")
    old_world.free()
    check(ProjectSettings.get_setting("display/window/handheld/orientation")==DisplayServer.SCREEN_SENSOR_LANDSCAPE,"Landscape rotation configured for Android")
    check(game.world.trails.paths.size()==3,"Three routes connect the crash beach, spring and caves")
    var safe_paths := true
    for path_points in game.world.trails.paths:
        for i in range(path_points.size()-1):
            for fraction in [0.0,0.25,0.5,0.75,1.0]:
                var p: Vector2 = path_points[i].lerp(path_points[i+1],fraction)
                var point := Vector3(p.x,game.terrain.height_at(p.x,p.y),p.y)
                if not game.world.walkable(point,point): safe_paths=false
    check(safe_paths,"Trail centers remain walkable after planting forest groups")
    var trees := 0
    for entry in game.world.resources:
        if entry.kind=="tree": trees+=1
    check(trees>=10,"Harvestable broadleaf trees generated in forest groups")
    check(game.world.discoverables.size()==5,"Unique clues available at crash site and caves")
    check(game.soundscape.streams.size()==13 and game.soundscape.voices.size()==7,"Original ambience and pooled positional effect voices loaded")
    check(game.soundscape.streams.sea.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Sea ambience loops natively")
    game.soundscape.set_muted(true)
    check(not game.soundscape.sea.playing,"Muted audio stops ambient playback")
    game.soundscape.set_muted(false)
    check(game.world.landmarks.size() == 4, "Crash site, spring and two caves generated")
    check(game.world.caves != null and game.world.caves.rooms.size() == 2 and game.world.caves.caches.size() == 4, "Two playable 3D cave interiors and four persistent caches generated")
    check(game.world.caves.puzzles != null and game.world.caves.puzzles.mechanisms.size() == 6, "Both caves spawn two seal pedestals and an independent relic vault")
    var puzzles: SurvivorCavePuzzles = game.world.caves.puzzles
    var original_puzzle_state: SurvivalState = puzzles.state
    var isolated_puzzle_state := SurvivalState.new()
    puzzles.state = isolated_puzzle_state
    var first_seal: Dictionary = puzzles.mechanisms[0]
    var second_seal: Dictionary = {}
    var first_vault: Dictionary = {}
    for mechanism in puzzles.mechanisms:
        if mechanism.kind == "cave_seal" and mechanism.cave == first_seal.cave and mechanism.id != first_seal.id:
            second_seal = mechanism
        if mechanism.kind == "cave_vault" and mechanism.cave == first_seal.cave:
            first_vault = mechanism
    check(not second_seal.is_empty() and not first_vault.is_empty(), "Every relic vault has exactly two separate stone-seal mechanisms")
    if not second_seal.is_empty() and not first_vault.is_empty():
        check(not puzzles.vault_unlocked(first_vault.id) and puzzles.collect_vault(first_vault).is_empty(), "Relic vault refuses rewards while puzzle is locked")
        check(puzzles.activate_seal(first_seal).contains("Selo ativado"), "First seal starts a persistent environmental puzzle")
        check(not puzzles.vault_unlocked(first_vault.id), "One activated seal is insufficient")
        check(puzzles.activate_seal(second_seal).contains("Selo ativado") and puzzles.vault_unlocked(first_vault.id), "Two independent seals unlock one vault")
        var crystal_before: int = isolated_puzzle_state.inventory.cave_crystal
        var unlocked_reward := puzzles.collect_vault(first_vault)
        check(not unlocked_reward.is_empty() and isolated_puzzle_state.inventory.cave_crystal == crystal_before + 1, "Opened relic vault grants exactly one rare crafting crystal")
        check(puzzles.collect_vault(first_vault).is_empty(), "Relic reward cannot be duplicated by touching a closed vault")
        var relic_save := SurvivalState.from_data(isolated_puzzle_state.to_data())
        check(relic_save != null and relic_save.discoveries.has(first_vault.id) and relic_save.inventory.cave_crystal == 1, "Puzzle seals, vault state and rare item persist in version-three save")
        first_vault.node.visible = true
    puzzles.state = original_puzzle_state

    var root_cave_spawn := SurvivorCaves.spawn_position("roots")
    check(game.world.caves.is_inside(root_cave_spawn) and game.world.walkable(root_cave_spawn,root_cave_spawn),"Cave pocket has a walkable entry and isolated ground height")
    check(not game.world.walkable(SurvivorCaves.CENTERS["roots"]+Vector3(19,0,0),root_cave_spawn), "Cave walls prevent walking into the unloaded sea")
    var cave_save := SurvivalState.new()
    cave_save.player_position = root_cave_spawn
    var saved_inside := SurvivalState.from_data(cave_save.to_data())
    check(saved_inside != null and saved_inside.player_position.x == root_cave_spawn.x and saved_inside.player_position.z == root_cave_spawn.z, "Legacy save v3 preserves the player position inside either cave")
    check(game.player != null and game.camera != null and game.hud != null, "Scene boot creates player, camera, HUD")
    check(not game.player.enabled and not game.hud.game_controls.visible, "Controls hidden during menu and intro")
    # Use a dedicated test save to preserve any user progress on test machines.
    var original_save := FileAccess.get_file_as_string(SurvivorSave.PATH) if FileAccess.file_exists(SurvivorSave.PATH) else ""
    var original_backup := FileAccess.get_file_as_string(SurvivorSave.PATH + ".bak") if FileAccess.file_exists(SurvivorSave.PATH + ".bak") else ""
    game.hud.close_modal()
    game.start_game(false)
    await process_frame
    check(game.playing and game.player.enabled, "New survival starts")
    var original_cave_player: Vector3 = game.player.position
    game.player.position = Vector3(80,game.terrain.height_at(80,20),20)
    game.action_cooldown = 0
    game.interact()
    check(SurvivorCaves.cave_at(game.player.position) == "east", "Explorar enters eastern cave through the live portal")
    var cave_test_state := SurvivalState.new()
    game.world.caves.state = cave_test_state
    var first_cave_cache: Dictionary = game.world.caves.caches[0]
    var cave_reward: Dictionary = game.world.caves.collect_cache(first_cave_cache)
    check(not cave_reward.is_empty() and cave_test_state.discoveries.has(first_cave_cache.id), "Cave stash grants unique supplies and records the clue")
    var saved_cave_loot := SurvivalState.from_data(cave_test_state.to_data())
    check(saved_cave_loot != null and saved_cave_loot.discoveries.has(first_cave_cache.id), "Exploration reward survives save/load")
    check(game.world.caves.collect_cache(first_cave_cache).is_empty(), "Cave supply stash cannot be collected twice")
    game.world.caves.state = game.state
    first_cave_cache.node.visible = true
    game.player.position = SurvivorCaves.exit_position("east")
    game.action_cooldown = 0
    game.interact()
    check(not game.world.caves.is_inside(game.player.position) and game.world.walkable(game.player.position,game.player.position), "Exit returns safely to the island")
    game.player.position = original_cave_player
    check(game.climate != null and game.climate.particles.mesh != null,"Dynamic rain particles initialize in the scene")
    game.toggle_sprint()
    check(game.player.sprint_enabled and game.hud.run_button.text == "Andar","Mobile sprint toggle enables running gait")
    game.player.locomotion_blend = 1.0
    game.player.walking = true
    game.player._base_pose()
    check(game.player.torso.rotation.x > 0.10,"Running leans torso forward")
    game.player.walking = false
    game.toggle_sprint()
    check(not game.player.sprint_enabled and game.hud.run_button.text == "Correr","Run toggle reverts to normal walking")
    game.climate.update_weather(310.0,game.player.position,game.terrain,game.world.scenery)
    check(game.climate.intensity > 0.9 and game.terrain.rainfall_amount > 0.9 and game.world.scenery.grass_material != null,"Climate drives atmospheric wetness and vegetation together")
    game.climate.update_weather(0.0,game.player.position,game.terrain,game.world.scenery)
    check(game.climate.intensity == 0.0 and game.terrain.rainfall_amount == 0.0,"Clear weather resets wetness")

    check(game.world.walkable(game.player.position, game.player.position), "Spawn is unobstructed")
    game.capture_mode = true
    check(not game.state.owns("stone_axe") and not game.state.owns("stone_pickaxe") and not game.state.owns("stone_knife"),"New survival starts without free tools")
    var uncut: Dictionary = game.world.resources[0]
    game.world.harvest(uncut)
    check(game.state.inventory.wood == 0 and uncut.node.visible,"Direct tree harvesting rejects missing axe without depleting resource")
    game.player.position = uncut.position+Vector3(0,0,float(uncut.radius)+0.8)
    game.action_cooldown = 0
    game.interact()
    check(not game.player.is_busy() and game.pending_work.is_empty(),"Interaction cannot conjure an axe before it is crafted")
    var unmined: Dictionary = game.world.resources[10]
    game.world.harvest(unmined)
    check(game.state.inventory.stone == 0 and unmined.node.visible,"Rocks require a pickaxe in the authoritative harvest path")
    var starting_logs := 0
    var starting_stones := 0
    for entry in game.world.resources:
        if str(entry.id).begins_with("start_log_") or str(entry.id).begins_with("start_pebble_") or entry.id == "start_hand_fiber":
            check(game.terrain.is_land(entry.position.x,entry.position.z) and game.world.walkable(entry.position,entry.position),"Bootstrap pickup lies on accessible land: " + str(entry.id))
            game.world.harvest(entry)
            if entry.kind == "loose_log": starting_logs += 1
            if entry.kind == "loose_stone": starting_stones += 1
    check(starting_logs == 6 and starting_stones == 6 and game.state.inventory.wood == 18 and game.state.inventory.stone == 12 and game.state.inventory.fiber == 5,"Loose beach resources supply all basic tools without a workstation")
    var craft_before: Dictionary = game.state.inventory.duplicate(true)
    game.select_recipe("stone_axe")
    check(game.player.action_kind == "handcraft" and not game.player.tools.hammer.visible,"Stone tools use a handcraft animation without an invented hammer")
    game.interact()
    check(game.state.inventory == craft_before and not game.state.owns("stone_axe"),"Cancelling before craft contact spends and grants nothing")
    for kind in ["stone_axe","stone_pickaxe","stone_knife"]:
        game.select_recipe(kind)
        check(not game.state.owns(kind),"Tool is not granted before contact: " + kind)
        game.player.enabled = true
        game.player._physics_process(0.7)
        check(game.state.owns(kind),"Tool crafted from real loose resources: " + kind)
        var paid: Dictionary = game.state.inventory.duplicate(true)
        game.player._physics_process(0.8)
        game.select_recipe(kind)
        check(game.state.inventory == paid and game.selected_recipe == "","Duplicate tool request cannot spend again or create a structure")
    check(game.state.inventory.wood == 11 and game.state.inventory.stone == 5 and game.state.inventory.fiber == 0,"Basic tools consume exact wood, stone and fiber costs")
    var knife_fiber: Dictionary = game.world.resources[11]
    var fiber_before: int = game.state.inventory.fiber
    game.world.harvest(knife_fiber)
    check(game.state.inventory.fiber == fiber_before+8,"Crafted knife improves fiber gathering from five to eight")
    var tools_saved := SurvivalState.from_data(game.state.to_data())
    check(tools_saved != null and tools_saved.owns("stone_axe") and tools_saved.owns("stone_knife") and tools_saved.owns("stone_pickaxe"),"Crafted tools survive save round-trip")
    check(tools_saved != null and tools_saved.is_equipped("stone_knife") and not tools_saved.is_equipped("stone_axe"),"Equipped utility slot survives save round-trip")
    var legacy: Dictionary = game.state.to_data().duplicate(true)
    legacy.version = 1
    legacy.erase("equipment")
    for key in ["stone_axe","stone_pickaxe","stone_knife"]: legacy.inventory.erase(key)
    var migrated := SurvivalState.from_data(legacy)
    check(migrated != null and migrated.inventory.wood == game.state.inventory.wood and migrated.owns("stone_axe") == false,"v0.4 saves migrate without loss or gifting tools")
    legacy.buildings.append({"kind":"stone_axe","x":0.0,"z":170.0})
    check(SurvivalState.from_data(legacy) == null,"Tools cannot masquerade as saved structures")
    var old_zoom: float = game.camera_distance
    game.change_zoom(-100)
    check(game.camera_distance == 12 and game.hud.zoom_in_button.disabled,"Mobile zoom reaches closer view and clamps minimum")
    game.change_zoom(100)
    check(game.camera_distance == 48 and game.hud.zoom_out_button.disabled,"Zoom clamps farthest view")
    game.change_zoom(old_zoom-48)
    check(game.hud.joystick.size == Vector2(220,220) and game.hud.joystick.offset_left == 100 and SurvivorJoystick.RADIUS == 88,"Joystick is larger and moved inward from the corner")
    game.capture_mode = false
    check(game.state.equip_tool("stone_axe") and game.state.is_equipped("stone_axe"),"Equipping axe activates resource harvesting")
    var sample: Dictionary = game.world.resources[0]
    var wood_before: int = game.state.inventory.wood
    game.world.harvest(sample)
    check(game.state.inventory.wood == wood_before + 8 and not sample.node.visible, "Harvest updates inventory and visibility")
    game.world.harvest(sample)
    check(game.state.inventory.wood == wood_before + 8, "Harvest cannot be repeated on depleted node")
    game.state.elapsed = 601
    game.world.refresh_resources()
    check(sample.node.visible, "Renewable resources regrow after cooldown")
    game.player.position = sample.position+Vector3(0,0,float(sample.radius)+0.8)
    game.player.position.y = game.world.surface_height(game.player.position)
    game.action_cooldown=0
    var contact_wood: int = game.state.inventory.wood
    game.interact()
    game._physics_process(0.016)
    check(game.player.action_kind=="chop" and game.player.tools.axe.visible,"Wood harvesting equips the axe at interaction range")
    check(game.state.inventory.wood==contact_wood,"Harvest grants nothing before tool contact")
    game.player._physics_process(0.55)
    check(game.soundscape.last_effect=="chop","Tool contact dispatches the corresponding positional sound")
    check(game.state.inventory.wood==contact_wood+8 and not sample.node.visible,"Tool-contact marker grants harvested wood once")
    game.player._physics_process(0.6)
    check(game.state.inventory.wood==contact_wood+8 and not game.player.tools.axe.visible,"Animation finish hides tool and cannot grant wood again")
    game.player.perform_action("mine",1.0,sample.position)
    var first_pose: float = game.player.right_arm.rotation.x
    game.player.pose_action(0.5)
    check(game.player.tools.pick.visible and not is_equal_approx(first_pose,game.player.right_arm.rotation.x),"Mining uses its own tool and changing skeletal pose")
    game.player.cancel_action()
    check(not game.player.is_busy() and not game.player.tools.pick.visible,"Cancelled action clears pose and tool")
    game.state.elapsed = 2000
    game.world.refresh_resources()
    game.action_cooldown=0
    game.interact()
    game._physics_process(0.016)
    var cancellation_wood: int=game.state.inventory.wood
    game.pause_game()
    game.player._physics_process(0.6)
    check(game.state.inventory.wood==cancellation_wood and game.pending_work.is_empty(),"Pausing before contact cancels harvesting without rewards")
    check(game.soundscape.frozen,"Pause blocks audio dispatch, including silent test backends")
    game.hud.close_modal()
    game.resume_game()
    check(not game.soundscape.frozen,"Resume releases paused audio dispatch")
    game.hud.toggle_inventory()
    await process_frame
    await process_frame
    check(game.hud.panel.get_rect().end.y <= game.hud.root.size.y and game.hud.panel.get_rect().end.x <= game.hud.root.size.x,"Inventory stays inside the viewport after wrapped-label layout")
    game.hud._item_callback("stone_axe").call()
    check(game.hud.item_detail.text.contains("Machado de pedra") and game.hud.item_detail.text.contains("árvores"),"Inventory item selection shows quantity and actual tool function")
    check(game.hud.modal_mode == "inventory" and not game.hud.joystick.active and game.hud.item_buttons.size() == 21,"Inventory grid opens with tool slots and blocks movement")
    game.hud.show_inventory("equipment")
    check(game.hud.modal_mode == "inventory" and game.hud.inventory_tab == "equipment","Separate equip tab opens inside backpack")
    game.hud._equip_callback("stone_pickaxe").call()
    check(game.state.is_equipped("stone_pickaxe") and not game.state.is_equipped("stone_axe"),"Equip tab switches utility tool")
    game.hud._unequip_callback("utility").call()
    check(not game.state.is_equipped("stone_pickaxe"),"Equip tab removes utility tool")
    game.hud._equip_callback("stone_axe").call()
    check(game.state.is_equipped("stone_axe"),"Equip tab restores axe for tree harvesting")
    game.hud.toggle_inventory()
    check(game.hud.modal_mode == "" and game.hud.joystick.active,"Backpack returns to compact HUD")
    var found_entry: Dictionary = game.world.discoverables[0]
    var discovery_wood: int = game.state.inventory.wood
    var found: Dictionary=game.world.discover(found_entry)
    check(game.state.inventory.wood==discovery_wood+4 and game.state.discoveries.has("pilot_bag"),"Unique discovery records progress and supplies")
    game.world.discover(found_entry)
    check(game.state.inventory.wood==discovery_wood+4,"Unique discovery cannot be looted twice")
    found.clear()
    check(SurvivorWorld.DISCOVERIES.pilot_bag.has("text"),"Discovery result cannot mutate the content registry")
    var before_capture := FileAccess.get_file_as_string(SurvivorSave.PATH)
    game.capture_mode=true
    game.save_game(false)
    check(FileAccess.get_file_as_string(SurvivorSave.PATH)==before_capture,"Capture mode cannot overwrite player save with inspection fixtures")
    game.capture_mode=false
    var discovery_save:=SurvivalState.from_data(game.state.to_data())
    check(discovery_save.discoveries.has("pilot_bag"),"Found records survive save/load")
    game.hud.show_journal()
    check(game.hud.modal_mode=="journal" and not game.hud.joystick.active,"Journal displays records while blocking gameplay input")
    game.hud.close_modal()
    var metal: Dictionary = game.world.resources[22]
    check(metal.kind == "metal", "Crash metal exists")
    game.world.harvest(metal)
    game.state.elapsed = 1800
    game.world.refresh_resources()
    check(not metal.node.visible, "Metal remains depleted permanently")
    var boundary := Vector3(300, 0, 300)
    check(not game.world.walkable(boundary, boundary), "Ocean boundary blocks walking")
    check(game.world.placement_error("house", boundary, boundary) != "", "House cannot be built at sea")
    check(game.world.placement_error("dock", Vector3.ZERO, Vector3.ZERO) != "", "Dock cannot be built inland")
    check(game.world.placement_error("house", sample.position, sample.position) != "", "Buildings cannot overlap standing resources")
    # Collect actual island resources, then play the complete progression through game methods.
    for entry in game.world.resources:
        game.world.harvest(entry)
    var total_wood: int = game.state.inventory.wood
    var sail_found := false
    for clue in game.world.discoverables:
        if str(clue.id) == "sail_diagram":
            var reward: Dictionary = game.world.discover(clue)
            sail_found = not reward.is_empty() and game.state.discoveries.get("sail_diagram",false)
    check(sail_found,"Sailing plan clue can be found near the eastern cave")
    check(total_wood >= 142 and game.state.inventory.fiber >= 48 and game.state.inventory.metal >= 8, "Island resources cover the complete escape recipe")
    var camp_pos := Vector3(0, game.terrain.height_at(0, 154), 154)
    game.player.position = Vector3(0, game.terrain.height_at(0, 159.5), 159.5)
    game.player.body_pivot.rotation.y = PI
    game.select_recipe("campfire")
    check(game.selected_recipe == "campfire" and game.preview != null, "Building preview created")
    game.rotate_preview()
    check(is_equal_approx(game.preview_rotation,PI*0.5) and game.preview.has_node("BuildFootprint"),"Rotatable preview displays building footprint")
    var error: String = game.world.placement_error("campfire", camp_pos, game.player.position)
    check(error == "", "Starting beach supports campfire placement: " + error)
    game.confirm_placement()
    check(game.state.owns("campfire") and game.selected_recipe == "", "Campfire committed through gameplay")
    var charged: int = game.state.inventory.wood
    game.confirm_placement() if game.selected_recipe != "" else game.cancel_placement()
    check(game.state.inventory.wood == charged, "No repeated payment after placement")
    game.player.position = Vector3(9, game.terrain.height_at(9, 157), 157)
    game.player.body_pivot.rotation.y = PI
    game.select_recipe("workbench")
    game.confirm_placement()
    check(game.state.owns("workbench"), "Workbench construction")
    var bench: Dictionary = game.world.near_structure(game.player.position, "workbench", 10)
    check(not bench.is_empty(), "Workbench close enough for crafting")
    for crafting_round in range(10):
        game.select_recipe("rope")
        game.select_recipe("plank")
    check(game.state.inventory.rope == 10 and game.state.inventory.plank == 10,"Ten rope and ten plank crafts succeed near the workbench")
    game.select_recipe("fishing_rod")
    check(game.state.owns("fishing_rod"), "Fishing rod fabricated at workbench")
    check(game.state.is_equipped("fishing_rod"), "Crafted rod is equipped in main hand so fishing is usable")
    game.player.position = Vector3(-10, game.terrain.height_at(-10, 135), 135)
    game.player.body_pivot.rotation.y = PI
    game.select_recipe("house")
    game.confirm_placement()
    check(game.state.owns("house"), "House construction on cleared terrain")
    var before_move: Dictionary = game.state.inventory.duplicate(true)
    game.relocate_structure("house")
    check(game.selected_recipe == "house" and game.relocation_kind == "house","Existing house enters move mode")
    game.cancel_placement()
    check(game.state.has_structure("house") and game.state.inventory == before_move,"Cancelled relocation preserves house and inventory")
    game.relocate_structure("house")
    game.rotate_preview()
    game.confirm_placement()
    check(game.relocation_kind == "" and game.state.buildings.size() == 3 and game.state.inventory == before_move,"Confirmed relocation keeps one building and charges nothing")
    var rotated_house: Dictionary = game.state.buildings[2]
    check(is_equal_approx(float(rotated_house.get("rotation",0.0)),PI*0.5),"Relocated building stores its new rotation")

    var shore := Vector3.ZERO
    for z in range(172, 224):
        if game.terrain.is_shore(4, z) and game.world.placement_error("dock", Vector3(4, game.terrain.height_at(4, z), z), Vector3(4, game.terrain.height_at(4, z), z - 5.5)) == "":
            shore = Vector3(4, game.terrain.height_at(4, z), z)
            break
    check(shore != Vector3.ZERO, "Coast offers valid dock location")
    game.player.position = shore - Vector3(0, 0, 5.5)
    game.player.position.y = game.terrain.height_at(game.player.position.x, game.player.position.z)
    game.player.body_pivot.rotation.y = 0
    game.select_recipe("dock")
    game.confirm_placement()
    check(game.state.owns("dock"), "Dock construction on coast")
    var dock_entry: Dictionary = game.world.near_structure(game.player.position,"dock",12)
    var offshore: Vector3 = dock_entry.position+Vector3(dock_entry.position.x,0,dock_entry.position.z).normalized()*6.0
    check(not game.terrain.is_land(offshore.x,offshore.z) and game.world.walkable(offshore,offshore),"Built pier provides walkable surface over the sea")
    check(game.world.surface_height(offshore)>game.terrain.sea_level+0.5,"Pier walkers stand on the deck rather than the seabed")
    game.state.unequip_slot("main_hand")
    game.fish_or_cancel()
    check(game.fishing_remaining == 0,"Fishing requires the rod in the main-hand slot")
    game.state.equip_tool("fishing_rod")
    game.fish_or_cancel()
    check(game.fishing_remaining == 3, "Fishing starts near dock")
    check(game.player.tools.rod.visible and game.player.fishing_line.visible,"Fishing visibly equips rod and fishing line")
    var fish_before_cancel: int = game.state.inventory.raw_fish
    game.interact()
    game._process(4.0)
    check(game.fishing_remaining==0 and game.state.inventory.raw_fish==fish_before_cancel,"Cancelled fishing grants no fish")
    check(not game.player.tools.rod.visible and not game.player.fishing_line.visible,"Cancelled fishing hides rod and line")
    game.fish_or_cancel()
    game._process(3.1)
    check(game.state.inventory.raw_fish >= 2 and game.fishing_remaining == 0, "Fishing produces raw fish after timer")
    game.player.position = camp_pos
    game.craft_meal()
    check(game.state.inventory.meal > 0, "Fish cooked near campfire")
    var before_pause: float = game.state.elapsed
    game.pause_game()
    game._process(5)
    check(game.state.elapsed == before_pause, "Pause freezes survival clock")
    game.hud.close_modal()
    game.resume_game()
    game.player.position = shore
    game.select_recipe("boat")
    game.confirm_placement()
    check(game.state.owns("boat"), "Boat built next to dock after all prerequisites")
    var built_boat: Dictionary = game.world.near_structure(game.player.position,"boat",12)
    check(not built_boat.is_empty() and game.terrain.height_at(built_boat.position.x,built_boat.position.z) <= game.terrain.sea_level+0.15, "Constructed escape boat actually floats offshore")
    check(game.state.inventory.wood == total_wood - 142, "Processed plank stages preserve complete wood budget")
    game.state.player_position = game.player.position
    var full := SurvivalState.from_data(game.state.to_data())
    check(full != null and full.buildings.size() == 5 and full.owns("fishing_rod") and full.discoveries.get("sail_diagram",false), "Camp, tools and cave clue survive save round-trip")
    var modular_state := SurvivalState.new()
    modular_state.buildings.append({"kind":"workbench","x":20.0,"z":120.0})
    modular_state.add_item("wood",30)
    modular_state.add_item("plank",20)
    modular_state.add_item("rope",8)
    modular_state.add_item("fiber",12)
    check(modular_state.pay_recipe("floor_panel"),"First floor consumes real crafting materials")
    modular_state.buildings.append({"kind":"floor_panel","x":32.0,"z":135.0,"rotation":0.0})
    check(modular_state.pay_recipe("floor_panel"),"Additional modular floor is repeatable")
    modular_state.buildings.append({"kind":"floor_panel","x":35.2,"z":135.0,"rotation":0.0})
    check(modular_state.pay_recipe("wall_panel"),"Wall unlocks after first modular floor")
    modular_state.buildings.append({"kind":"wall_panel","x":32.0,"z":136.6,"rotation":0.0})
    check(modular_state.pay_recipe("roof_panel"),"Roof unlocks after modular wall")
    modular_state.buildings.append({"kind":"roof_panel","x":32.0,"z":135.0,"rotation":0.0})
    var modular_saved := SurvivalState.from_data(modular_state.to_data())
    check(modular_saved != null and modular_saved.buildings.size() == 5 and modular_saved.inventory.plank == 11,"Repeated modular pieces and costs survive save/load")
    check(modular_state.pay_recipe("door_panel"), "Crafting a door consumes materials without reusing an occupied wall slot")
    check(modular_state.pay_recipe("window_panel"), "Crafting a window consumes the correct resource inventory")
    var door_fixture := {"kind":"door_panel","x":33.6,"z":135.0,"rotation":PI * 0.5,"door_open":false}
    modular_state.buildings.append(door_fixture)
    modular_state.buildings.append({"kind":"window_panel","x":35.2,"z":136.6,"rotation":0.0})
    var saved_openings := SurvivalState.from_data(modular_state.to_data())
    check(saved_openings != null and saved_openings.buildings.size() == 7, "Door/window modules survive an existing version-three save")
    var corrupt_door := modular_state.to_data().duplicate(true)
    corrupt_door.buildings[5]["door_open"] = "yes"
    check(SurvivalState.from_data(corrupt_door) == null, "Malformed door state rejected during save recovery")
    var grid_world := SurvivorWorld.new()
    grid_world.terrain = game.terrain
    grid_world.state = modular_state
    root.add_child(grid_world)
    var floor_cell := Vector3(32.0,game.terrain.height_at(32.0,135.0),135.0)
    var wall_cell := Vector3(32.0,game.terrain.height_at(32.0,136.6),136.6)
    check(grid_world.placement_error("wall_panel",wall_cell,wall_cell) != "","Modular wall requires nearby floor support")
    check(grid_world.placement_error("floor_panel",floor_cell,floor_cell) == "","Flat land allows initial foundation")
    grid_world.add_structure({"kind":"floor_panel","x":32.0,"z":135.0})
    check(grid_world.placement_error("wall_panel",wall_cell,wall_cell) == "","Wall snaps to foundation perimeter")
    grid_world.add_structure({"kind":"wall_panel","x":32.0,"z":136.6})
    check(not grid_world.walkable(wall_cell,wall_cell),"Placed modular wall blocks player traversal")
    check(grid_world.placement_error("roof_panel",floor_cell,floor_cell) == "","Roof requires supported wall and foundation")
    grid_world.add_structure({"kind":"roof_panel","x":32.0,"z":135.0})
    check(grid_world.placement_error("roof_panel",floor_cell,floor_cell) != "","Roof socket cannot be occupied twice")
    var door_cell := Vector3(33.6,game.terrain.height_at(33.6,135.0),135.0)
    var window_cell := Vector3(35.2,game.terrain.height_at(35.2,136.6),136.6)
    check(grid_world.placement_error("door_panel",door_cell,door_cell) == "","Door can occupy another perimeter socket adjacent to a wall")
    check(grid_world.placement_error("window_panel",window_cell,window_cell) != "","Window without its own supporting floor is rejected")
    grid_world.add_structure(door_fixture)
    check(grid_world.placement_error("window_panel",door_cell,door_cell) != "","Different panel types cannot occupy one wall socket")
    check(not grid_world.walkable(door_cell,door_cell),"Closed door blocks traversal")
    var door_target := grid_world.near_structure(door_cell,"door_panel",0.5)
    check(not door_target.is_empty() and grid_world.toggle_door(door_target),"Door toggles to open")
    check(grid_world.walkable(door_cell,door_cell) and bool(door_fixture.door_open),"Open door allows passage and writes persistence data")
    check(not grid_world.toggle_door(door_target) and not grid_world.walkable(door_cell,door_cell),"Closing door restores collision")
    grid_world.queue_free()
    var supplemental := SurvivalState.new()
    supplemental.buildings.append({"kind":"chest","x":10.0,"z":20.0,"rotation":PI*0.5})
    supplemental.buildings.append({"kind":"rain_collector","x":14.0,"z":20.0})
    supplemental.add_item("wood",5)
    check(supplemental.transfer_storage("wood",true,2) and supplemental.storage.wood == 2 and supplemental.inventory.wood == 3,"Storage deposit conserves resources")
    check(supplemental.transfer_storage("wood",false,1) and supplemental.storage.wood == 1 and supplemental.inventory.wood == 4,"Storage withdrawal conserves resources")
    supplemental.elapsed = 220.0
    supplemental.advance(10.0)
    check(supplemental.rain_water > 0.0,"Collector fills during scheduled rain")
    var loaded_camp := SurvivalState.from_data(supplemental.to_data())
    check(loaded_camp != null and loaded_camp.storage.wood == 1 and loaded_camp.rain_water > 0.0 and is_equal_approx(loaded_camp.buildings[0].rotation,PI*0.5),"Version 3 save stores chest, water and rotation")

    game.escape_island()
    check(game.state.escaped and not game.playing, "Embarking completes survival")
    game.hud.show_end(true, game.state.elapsed)
    game.hud.target = {"kind":"boat"}
    game.hud._process(0.2)
    # Touch ownership: another finger cannot cancel joystick movement.
    game.hud.close_modal()
    game.hud.set_playing(true)
    var joystick: SurvivorJoystick = game.hud.joystick
    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = joystick.global_position + joystick.size * 0.5 + Vector2(45, 0)
    joystick._input(touch)
    check(joystick.finger == 0 and joystick.value.x > 0.5, "Touch joystick controls movement")
    var taps := [0]
    game.hud.action_button.pressed.connect(func(): taps[0] += 1)
    var action_touch := InputEventScreenTouch.new()
    action_touch.index = 1
    action_touch.pressed = true
    action_touch.position = game.hud.action_button.global_position + game.hud.action_button.size * 0.5
    game.hud.action_button._input(action_touch)
    action_touch.pressed = false
    game.hud.action_button._input(action_touch)
    check(taps[0] == 1 and joystick.finger == 0, "Second finger activates action while joystick stays held")
    action_touch.pressed = true
    game.hud.action_button._input(action_touch)
    var drag := InputEventScreenDrag.new()
    drag.index = 1
    drag.position = action_touch.position + Vector2(0, 35)
    drag.relative = Vector2(0, 35)
    game.hud.action_button._input(drag)
    action_touch.pressed = false
    game.hud.action_button._input(action_touch)
    check(taps[0] == 1, "Dragging a button cancels its tap for scrolling")
    game.hud.show_crafting()
    check(game.hud.build_buttons.has("stone_axe") and game.hud.build_buttons.has("stone_knife") and game.hud.build_buttons.has("stone_pickaxe") and game.hud.build_buttons.has("stone_spear"),"Inventory construction tab contains all basic tool recipes and spear")
    check(game.hud.build_buttons.has("grilled_crab") and game.hud.build_buttons.has("cooked_meat"),"Campfire cooking recipes available in backpack")
    action_touch.pressed = true
    game.hud.action_button._input(action_touch)
    action_touch.pressed = false
    game.hud.action_button._input(action_touch)
    check(taps[0] == 1, "Modal blocks background touch buttons")
    game.hud.close_modal()
    joystick.active = true
    joystick.finger = 0
    joystick.value = Vector2(0.6, 0)
    touch.index = 1
    touch.pressed = false
    joystick._input(touch)
    check(joystick.finger == 0, "Second touch release cannot steal joystick")
    touch.index = 0
    joystick._input(touch)
    check(joystick.value == Vector2.ZERO and joystick.finger == -1, "Touch release stops movement")
    joystick.active = false
    touch.pressed = true
    joystick._input(touch)
    check(joystick.value == Vector2.ZERO, "Joystick disabled in modals")
    game.soundscape.shutdown()
    game.queue_free()
    # Mixer stop requests are asynchronous; allow queued buffers to drain.
    await create_timer(0.18).timeout
    for pair in [[SurvivorSave.PATH, original_save], [SurvivorSave.PATH + ".bak", original_backup]]:
        if pair[1] != "":
            var file := FileAccess.open(pair[0], FileAccess.WRITE)
            file.store_string(pair[1])
            file.close()
        elif FileAccess.file_exists(pair[0]):
            DirAccess.remove_absolute(pair[0])
    print("SURVIVOR TESTS: %d/%d passed" % [checks - failures, checks])
    quit(0 if failures == 0 else 1)
