extends Node3D

var state := SurvivalState.new()
var terrain: SurvivorTerrain
var world: SurvivorWorld
var player: SurvivorPlayer
var camera: Camera3D
var hud: SurvivorHUD
var playing := false
var selected_recipe := ""
var relocation_kind := ""
var preview_rotation := 0.0
var preview: Node3D
var marker: MeshInstance3D
var target: Dictionary = {}
var action_cooldown := 0.0
var fishing_remaining := 0.0
var autosave_clock := 0.0
var camera_distance := 29.0
const MIN_ZOOM_DISTANCE := 12.0
const MAX_ZOOM_DISTANCE := 48.0
var _saved_state: SurvivalState
var departure_tween: Tween
var light_visuals := false
var soundscape: SurvivorSoundscape
var climate: SurvivorClimate
var running_mode := false
var muted := false
var capture_mode := false
var pending_work: Dictionary = {}
var approach_timer := 0.0
var pending_discovery: Dictionary = {}

func _ready() -> void:
    terrain = SurvivorTerrain.new()
    add_child(terrain)
    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.fov = 48.0
    camera.far = 700.0
    camera.current = true
    add_child(camera)
    marker = SurvivorModels.sphere(self, 0.3, Color(1.0, 0.85, 0.36), Vector3.ZERO)
    marker.visible = false
    soundscape = SurvivorSoundscape.new()
    add_child(soundscape)
    climate = SurvivorClimate.new()
    add_child(climate)
    hud = SurvivorHUD.new()
    add_child(hud)
    hud.minimap.terrain = terrain
    hud.action_requested.connect(interact)
    hud.build_requested.connect(select_recipe)
    hud.rotate_requested.connect(rotate_preview)
    hud.relocate_requested.connect(relocate_structure)
    hud.storage_requested.connect(_transfer_storage)
    hud.fishing_requested.connect(fish_or_cancel)
    hud.equipment_requested.connect(_equip_item)
    hud.unequip_requested.connect(_unequip_item)
    hud.consume_requested.connect(consume)
    hud.save_requested.connect(save_game)
    hud.menu_requested.connect(pause_game)
    hud.start_requested.connect(start_game)
    hud.resume_requested.connect(resume_game)
    hud.quality_requested.connect(toggle_quality)
    hud.sound_requested.connect(toggle_sound)
    hud.journal_requested.connect(func(): hud.show_journal())
    hud.zoom_requested.connect(change_zoom)
    hud.sprint_requested.connect(toggle_sprint)
    var settings := ConfigFile.new()
    if settings.load("user://visual.cfg") == OK:
        light_visuals = bool(settings.get_value("graphics", "light", false))
        muted = bool(settings.get_value("audio","muted",false))
        var saved_zoom = settings.get_value("camera","distance",29.0)
        if (saved_zoom is float or saved_zoom is int) and is_finite(float(saved_zoom)):
            camera_distance = clampf(float(saved_zoom),MIN_ZOOM_DISTANCE,MAX_ZOOM_DISTANCE)
    hud.update_zoom(camera_distance)
    hud.light_visuals = light_visuals
    hud.muted = muted
    soundscape.set_muted(muted)
    _saved_state = SurvivorSave.recover()
    _create_world(_saved_state if _saved_state != null else state)
    hud.show_menu(_saved_state != null)
    get_tree().auto_accept_quit = false

func _create_world(next_state: SurvivalState) -> void:
    cancel_work()
    pending_discovery.clear()
    soundscape.set_active(false)
    if departure_tween != null and departure_tween.is_valid():
        departure_tween.kill()
    if is_instance_valid(world):
        remove_child(world)
        world.queue_free()
    if is_instance_valid(player):
        remove_child(player)
        player.queue_free()
    cancel_placement()
    state = next_state
    world = SurvivorWorld.new()
    world.terrain = terrain
    world.state = state
    add_child(world)
    world.generate()
    apply_quality()
    player = SurvivorPlayer.new()
    player.sprint_enabled = running_mode
    player.terrain = terrain
    player.world = world
    player.position = state.player_position
    if not world.walkable(player.position, player.position):
        player.position = SurvivalState.START_POSITION
    player.position.y = world.surface_height(player.position)
    add_child(player)
    world.fauna.player = player
    player.action_contact.connect(_on_action_contact)
    player.action_finished.connect(_on_action_finished)
    player.footstep.connect(func(surface: String,point: Vector3): soundscape.play_effect("step_"+surface,point))
    hud.state = state
    hud.minimap.world = world
    hud.minimap.player = player
    _update_camera(1.0)

func start_game(load_save: bool) -> void:
    var next_state := SurvivorSave.recover() if load_save else SurvivalState.new()
    if next_state == null:
        hud.toast("Não foi possível carregar esse progresso.")
        hud.show_menu(false)
        return
    _create_world(next_state)
    playing = true
    player.enabled = true
    action_cooldown = 0
    fishing_remaining = 0
    autosave_clock = 0
    hud.set_playing(true)
    soundscape.set_active(true)
    if state.escaped or state.health <= 0:
        playing = false
        player.enabled = false
        hud.show_end(state.escaped, state.elapsed)
    else:
        if not load_save:
            save_game(false)
        hud.toast("Pegue troncos e pedras no chão. Fabrique ferramentas em Mochila → Construções.",5)

func pause_game() -> void:
    if not playing:
        return
    cancel_placement()
    cancel_work()
    pending_discovery.clear()
    fishing_remaining = 0
    player.move_vector = Vector2.ZERO
    player.enabled = false
    save_game(false)
    hud.show_menu(true, true)
    soundscape.set_frozen(true)

func resume_game() -> void:
    player.enabled = true
    soundscape.set_frozen(false)

func paused() -> bool:
    return not playing or hud.modal_mode != ""

func _process(delta: float) -> void:
    if player == null:
        return
    _update_camera(delta)
    soundscape.set_frozen(paused())
    if paused():
        player.enabled = false
        player.move_vector = Vector2.ZERO
        return
    player.enabled = true
    soundscape.update_environment(player.position,terrain,world,delta)
    SurvivorModels.merged_material.set_shader_parameter("survivor_position",player.position)
    hud.can_fish = terrain.is_shore(player.position.x,player.position.z) or not world.near_structure(player.position,"dock",8).is_empty()
    if player.is_busy():
        hud.activity_name = {"spear":"Caçando","chop":"Cortando madeira","mine":"Extraindo pedra","gather":"Coletando","search":"Investigando","fish":"Pescando","build":"Construindo","craft":"Fabricando","handcraft":"Fabricando ferramenta","cut":"Cortando fibras","cook":"Preparando alimento","eat":"Comendo","rest":"Descansando","drink":"Bebendo água"}.get(player.action_kind,"")
        hud.activity_fraction = 1-player.action_remaining/player.action_duration
    elif not pending_work.is_empty():
        hud.activity_name = "Aproximando-se"
        hud.activity_fraction = 0
    else:
        hud.activity_name = ""
    state.advance(delta)
    terrain.set_time_of_day(fmod(8.0 / 24.0 + state.elapsed / SurvivalState.DAY_SECONDS, 1.0))
    climate.update_weather(state.elapsed,player.position,terrain,world.scenery)
    climate.visible = not world.caves.is_inside(player.position)
    action_cooldown = maxf(0, action_cooldown - delta)
    autosave_clock += delta
    if autosave_clock >= 60:
        autosave_clock = 0
        save_game(false)
    if state.health <= 0:
        playing = false
        player.enabled = false
        save_game(false)
        hud.show_end(false, state.elapsed)
        return
    target = world.nearest_target(player.position)
    hud.target = target
    marker.visible = not target.is_empty() and selected_recipe == ""
    if marker.visible:
        marker.position = target.position + Vector3(0, 3.8 + sin(state.elapsed * 3) * 0.15, 0)
    if selected_recipe != "":
        var point := placement_point()
        preview.position = point
        if selected_recipe == "dock":
            preview.rotation.y = atan2(-point.x, -point.z)
        elif selected_recipe != "boat":
            preview.rotation.y = preview_rotation
        var error := world.placement_error(selected_recipe, point, player.position, relocation_kind)
        _tint_preview(error == "")
        hud.update_placement(selected_recipe, error)
    if fishing_remaining > 0:
        player.move_vector = Vector2.ZERO
        fishing_remaining = maxf(0.0, fishing_remaining - delta)
        if fishing_remaining <= 0:
            state.add_item("raw_fish", 2)
            soundscape.play_effect("splash",player.action_point)
            player.cancel_action()
            hud.toast("Boa pesca! +2 peixes crus. Asse na fogueira.")
        else:
            hud.activity_name = "Pescando"
            hud.activity_fraction = 1-fishing_remaining/3.0

func _physics_process(delta: float) -> void:
    if paused() or fishing_remaining > 0:
        return
    if player.is_busy():
        player.move_vector = Vector2.ZERO
        return
    if not pending_work.is_empty():
        if pending_work.mode == "tool": return
        approach_timer += delta
        var entry: Dictionary = pending_work.entry
        var direction := Vector2(entry.position.x-player.position.x,entry.position.z-player.position.z)
        if direction.length() <= float(pending_work.reach):
            player.perform_action(pending_work.animation,pending_work.duration,entry.get("animation_point",entry.position))
            pending_work.approaching = false
        elif approach_timer > 4.5:
            var harvesting: bool = pending_work.mode == "harvest"
            cancel_work()
            if harvesting: hud.toast("O caminho está bloqueado. Aproxime-se por outro lado.")
        else:
            player.move_vector = direction.normalized()
        return
    var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
    player.move_vector = (keyboard + hud.joystick.value).limit_length(1.0)

func _update_camera(delta: float) -> void:
    var point := player.position + Vector3(0, 1.2, 0)
    var desired := point + Vector3(0, camera_distance, camera_distance * 0.85)
    camera.position = camera.position.lerp(desired, minf(1, delta * 5))
    camera.look_at(point)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode == KEY_ESCAPE:
        if selected_recipe != "":
            cancel_placement()
        elif hud.modal_mode in ["craft", "inventory", "pause"]:
            hud.close_modal()
            resume_game()
        elif playing and hud.modal_mode == "":
            pause_game()
        return
    if paused():
        return
    match event.physical_keycode:
        KEY_E: interact()
        KEY_B:
            if selected_recipe != "":
                cancel_placement()
            else:
                hud.show_crafting()
        KEY_F: fish_or_cancel()
        KEY_H: consume()
        KEY_P: save_game()
        KEY_EQUAL, KEY_KP_ADD: change_zoom(-3)
        KEY_MINUS, KEY_KP_SUBTRACT: change_zoom(3)

func toggle_sprint() -> void:
    if not playing or paused():
        return
    running_mode = not running_mode
    player.sprint_enabled = running_mode
    hud.update_sprint(running_mode)

func change_zoom(amount: float) -> void:
    camera_distance = clampf(camera_distance+amount,MIN_ZOOM_DISTANCE,MAX_ZOOM_DISTANCE)
    hud.update_zoom(camera_distance)
    var settings := ConfigFile.new()
    settings.load("user://visual.cfg")
    settings.set_value("camera","distance",camera_distance)
    if not capture_mode: settings.save("user://visual.cfg")

func interact() -> void:
    if paused(): return
    if fishing_remaining>0 or player.is_busy() or not pending_work.is_empty():
        fishing_remaining=0
        cancel_work()
        pending_discovery.clear()
        hud.activity_name=""
        return
    if action_cooldown>0: return
    if selected_recipe != "":
        confirm_placement()
        return
    target = world.nearest_target(player.position)
    if target.is_empty():
        hud.toast("Explore recursos, caranguejos da praia e javalis da mata.")
        return
    action_cooldown = 0.65
    match str(target.kind):
        "palm", "tree", "rock", "fiber", "metal", "discovery", "loose_log", "loose_stone", "crab", "boar":
            var error := state.harvest_error(str(target.kind))
            if error != "":
                hud.toast(error,5)
                return
            var animation: String = {"palm":"chop","tree":"chop","rock":"mine","metal":"search","fiber":"cut" if state.owns("stone_knife") else "gather","discovery":"search","loose_log":"gather","loose_stone":"gather","crab":"gather","boar":"spear"}[target.kind]
            queue_work(target,animation,1.05,"harvest",float(target.radius)+0.85)
        "cave":
            _enter_cave(target)
        "cave_exit":
            _leave_cave(target)
        "cave_cache":
            queue_work(target,"search",1.1,"harvest",1.5)
        "cave_seal":
            queue_work(target,"search",1.0,"cave_seal",1.6)
        "cave_vault":
            if not world.caves.puzzles.vault_unlocked(str(target.id)):
                hud.toast("Relicário selado. Ative os dois selos desta caverna.")
            else:
                queue_work(target,"search",1.15,"cave_vault",1.7)
        "spring":
            player.perform_action("drink",0.95,target.position)
            state.thirst = 100
            hud.toast("Água fresca da nascente. Sede recuperada.")
        "campfire": craft_meal()
        "house", "bed":
            if state.hunger <= 10 or state.thirst <= 10:
                hud.toast("Coma e beba antes de descansar.")
            else:
                player.perform_action("rest",2.5,target.position)
                state.health = minf(100, state.health + (38 if target.kind == "bed" else 25))
                state.hunger = maxf(0, state.hunger - 4)
                state.thirst = maxf(0, state.thirst - 6)
                hud.toast("Descanso: saúde recuperada.")
                action_cooldown = 5
        "chest": hud.show_storage()
        "door_panel":
            var opened := world.toggle_door(target)
            hud.toast("Porta aberta." if opened else "Porta fechada.")
            save_game(false)
        "rain_collector":
            if state.rain_water >= 1.0:
                state.rain_water -= 1.0
                state.thirst = minf(100.0, state.thirst + 40.0)
                player.perform_action("drink",0.8,target.position)
                hud.toast("Água da chuva: +40 de sede. Reservatório: %.1f" % state.rain_water)
                save_game(false)
            else:
                hud.toast("Reservatório vazio. Aguarde a próxima chuva tropical.")
        "boat": escape_island()

func _enter_cave(entry: Dictionary) -> void:
    var id := SurvivorCaves.entrance_id(str(entry.get("title","")))
    if id == "":
        return
    _teleport_to(SurvivorCaves.spawn_position(id))
    hud.toast("Você entrou na caverna. Procure suprimentos e use Explorar na saída para voltar.",5)

func _leave_cave(entry: Dictionary) -> void:
    var id := str(entry.get("id",""))
    if not SurvivorCaves.CENTERS.has(id):
        return
    var out := Vector3(80,0,28) if id == "east" else Vector3(-90,0,-52)
    _teleport_to(out)
    hud.toast("Você voltou à superfície.",3)

func _teleport_to(point: Vector3) -> void:
    cancel_work()
    cancel_placement()
    pending_discovery.clear()
    fishing_remaining = 0.0
    player.move_vector = Vector2.ZERO
    player.position = point
    player.position.y = world.surface_height(point)
    camera.position = player.position + Vector3(0,camera_distance,camera_distance*0.85)
    _update_camera(1.0)
    action_cooldown = 0.85
    save_game(false)

func consume() -> void:
    if not paused() and selected_recipe == "" and fishing_remaining <= 0:
        var before: int = state.ready_food_count()
        var message := state.consume()
        if state.ready_food_count() < before:
            cancel_work()
            player.perform_action("eat",0.9,player.position)
        hud.toast(message)

func select_recipe(kind: String) -> void:
    if paused() or fishing_remaining > 0:
        return
    cancel_work()
    cancel_placement()
    if world.caves.is_inside(player.position) and kind not in SurvivalState.TOOLS and kind not in SurvivalState.MATERIAL_RECIPES:
        hud.toast("Construa estruturas na superfície, fora das cavernas.")
        return
    var error := state.recipe_error(kind)
    if error != "":
        hud.toast(error)
        return
    if kind in SurvivalState.FOOD_RECIPES:
        craft_food(kind)
        return
    if kind in SurvivalState.MATERIAL_RECIPES:
        if kind == "plank" and world.near_structure(player.position,"workbench",8).is_empty():
            hud.toast("Aproxime-se da bancada para cortar as tábuas.")
            return
        if state.craft_material(kind):
            player.perform_action("craft" if kind == "plank" else "handcraft",1.1,player.position)
            hud.toast("+1 %s fabricada." % SurvivalState.RECIPES[kind].title)
            save_game(false)
        return
    if kind in ["stone_knife", "stone_axe", "stone_pickaxe", "stone_spear"]:
        # Charge and grant together at contact; cancelling before contact costs nothing.
        pending_work = {"mode":"tool", "recipe":kind}
        player.perform_action("handcraft",1.4,player.position)
        return
    if kind == "fishing_rod":
        if world.near_structure(player.position, "workbench", 8).is_empty():
            hud.toast("Aproxime-se da bancada para fabricar a vara.")
            return
        if state.pay_recipe(kind):
            state.add_item(kind, 1)
            state.equip_tool(kind)
            queue_work(world.near_structure(player.position,"workbench",8),"craft",1.4,"station",2.35)
            hud.toast("Vara pronta e equipada! Aproxime-se do mar e toque em Pescar.")
            save_game(false)
        return
    _begin_placement(kind)

func _begin_placement(kind: String) -> void:
    cancel_placement()
    selected_recipe = kind
    preview_rotation = 0.0
    preview = Node3D.new()
    add_child(preview)
    SurvivorModels.building(preview, kind)
    if kind != "campfire":
        SurvivorModels.merge_static(preview, "building_" + kind)
    # Area indicator marks the required footprint, not just the model geometry.
    var footprint := MeshInstance3D.new()
    footprint.name = "BuildFootprint"
    var size := 9.0 if kind == "house" else (3.2 if kind in SurvivalState.MODULES else 4.8)
    var pad := BoxMesh.new()
    pad.size = Vector3(size,0.035,0.38 if kind in SurvivalState.WALL_MODULES else size)
    footprint.mesh = pad
    footprint.position.y = 0.09
    preview.add_child(footprint)
    for node in preview.get_children():
        if node is Light3D:
            node.visible = false
    hud.set_rotation_visible(kind not in ["dock","boat"])
    hud.toast("Posicione, gire e confirme. Cancelar mantém seus materiais.",4)

func rotate_preview() -> void:
    if selected_recipe != "" and selected_recipe not in ["dock","boat"]:
        preview_rotation = fposmod(preview_rotation + PI * 0.5,TAU)
        if is_instance_valid(preview):
            preview.rotation.y = preview_rotation

func relocate_structure(kind: String) -> void:
    if not playing or paused() or not state.has_structure(kind):
        return
    if kind in ["boat","dock"] or kind in SurvivalState.MODULES:
        hud.toast("Peças modulares e estruturas costeiras ficam encaixadas e não podem ser movidas.")
        return
    cancel_work()
    _begin_placement(kind)
    relocation_kind = kind
    hud.toast("Mova a estrutura sem gastar recursos. Confirme ou cancele.",4)

func _transfer_storage(kind: String, to_chest: bool) -> void:
    if not state.has_structure("chest") or not playing:
        return
    if world.near_structure(player.position,"chest",5).is_empty():
        hud.toast("Aproxime-se do baú para guardar ou retirar itens.")
        return
    if state.transfer_storage(kind,to_chest):
        hud.show_storage()
        save_game(false)
    else:
        hud.toast("Não há itens suficientes ou o baú está cheio.")

func placement_point() -> Vector3:
    var facing := Vector3(sin(player.body_pivot.rotation.y), 0, cos(player.body_pivot.rotation.y))
    var point := player.position + facing * (7.0 if selected_recipe == "house" else 5.5)
    if selected_recipe == "boat":
        var dock := world.near_structure(player.position, "dock", 15)
        if not dock.is_empty():
            point = world.boat_location(dock.position)
            return point
    if selected_recipe in SurvivalState.MODULES:
        point.x = roundf(point.x / 3.2) * 3.2
        point.z = roundf(point.z / 3.2) * 3.2
        if selected_recipe in SurvivalState.WALL_MODULES:
            point += Vector3(sin(preview_rotation),0,cos(preview_rotation)) * 1.6
    point.y = terrain.height_at(point.x, point.z)
    return point

func _tint_preview(valid: bool) -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.4, 0.95, 0.6, 0.46) if valid else Color(1.0, 0.3, 0.18, 0.46)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for node in preview.get_children():
        if node is MeshInstance3D:
            node.material_override = mat

func confirm_placement() -> void:
    var point := placement_point()
    var error := world.placement_error(selected_recipe, point, player.position, relocation_kind)
    if error == "" and relocation_kind == "":
        error = state.recipe_error(selected_recipe)
    if error != "":
        hud.toast(error)
        return
    var kind := selected_recipe
    if relocation_kind == "":
        if not state.pay_recipe(kind):
            return
    else:
        for i in range(state.buildings.size() - 1,-1,-1):
            if str(state.buildings[i].kind) == relocation_kind:
                state.buildings.remove_at(i)
                break
        world.remove_structure(relocation_kind)
    var entry := {"kind": kind, "x": point.x, "z": point.z}
    if kind not in ["boat","dock"]:
        entry["rotation"] = preview_rotation
    state.buildings.append(entry)
    world.add_structure(entry)
    var work_entry := {"kind":kind,"position":point}
    var reach := 4.1 if kind=="house" else 2.35
    if kind=="boat":
        var dock := world.near_structure(player.position,"dock",15)
        if not dock.is_empty():
            var radial := Vector3(dock.position.x,0,dock.position.z).normalized()
            work_entry.position = dock.position+radial*4.0+Vector3(-radial.z,0,radial.x)*1.1
            work_entry.animation_point = point
            reach = 0.45
    queue_work(work_entry,"build",1.6,"station",reach)
    cancel_placement()
    hud.toast("%s pronto!" % SurvivalState.RECIPES[kind].title)
    save_game(false)

func cancel_placement() -> void:
    selected_recipe = ""
    relocation_kind = ""
    if is_instance_valid(hud):
        hud.set_rotation_visible(false)
    if is_instance_valid(preview):
        preview.queue_free()
    preview = null
    if is_instance_valid(hud):
        hud.update_placement("", "")

func craft_meal() -> void:
    var kind := "meal"
    if int(state.inventory.raw_fish) == 0:
        if int(state.inventory.raw_crab) > 0:
            kind = "grilled_crab"
        elif int(state.inventory.raw_meat) > 0:
            kind = "cooked_meat"
    craft_food(kind)

func craft_food(kind: String) -> void:
    if world.near_structure(player.position, "campfire", 6).is_empty():
        hud.toast("Aproxime-se da fogueira para preparar o alimento.")
        return
    if state.pay_recipe(kind):
        state.add_item(kind, 1)
        queue_work(world.near_structure(player.position,"campfire",6),"cook",1.4,"station",2.05)
        hud.toast("%s pronto! Toque em Comer / beber." % SurvivalState.RECIPES[kind].title)
        save_game(false)
    else:
        hud.toast(state.recipe_error(kind))

func _equip_item(kind: String) -> void:
    if not playing: return
    if state.equip_tool(kind):
        hud.show_inventory("equipment")
        hud.toast("%s equipada." % SurvivalState.RECIPES[kind].title)
    else:
        hud.toast("Fabrique esse equipamento primeiro.")

func _unequip_item(slot: String) -> void:
    if not playing: return
    if state.unequip_slot(slot):
        hud.show_inventory("equipment")
        hud.toast("Equipamento removido.")

func fish_or_cancel() -> void:
    if paused():
        return
    if selected_recipe != "":
        cancel_placement()
        return
    if not state.is_equipped("fishing_rod"):
        hud.toast("Abra Mochila → Equipar e coloque a vara na MÃO PRINCIPAL para pescar.")
        return
    if not terrain.is_shore(player.position.x, player.position.z) and world.near_structure(player.position, "dock", 8).is_empty():
        hud.toast("Aproxime-se do mar ou do cais para pescar.")
        return
    if fishing_remaining <= 0:
        cancel_work()
        fishing_remaining = 3.0
        var radial := Vector3(player.position.x,0,player.position.z).normalized()
        player.perform_action("fish",3.0,player.position+radial*6.0+Vector3(radial.z,0,-radial.x)*4.5+Vector3(0,terrain.sea_level+0.12-player.position.y,0))
        player.move_vector = Vector2.ZERO

func escape_island() -> void:
    if not state.owns("boat") or world.near_structure(player.position, "boat", 12).is_empty():
        hud.toast("Aproxime-se do barco pronto para embarcar.")
        return
    cancel_work()
    soundscape.set_active(false)
    state.escaped = true
    playing = false
    player.enabled = false
    hud.set_playing(false)
    marker.visible = false
    save_game(false)
    var boat := world.near_structure(player.position, "boat", 12)
    if not boat.is_empty():
        player.visible = false
        var radial := Vector3(boat.position.x, 0, boat.position.z).normalized()
        departure_tween = create_tween()
        departure_tween.tween_property(boat.node, "position", boat.node.position + radial * 35.0, 4.0)
        departure_tween.tween_callback(func(): hud.show_end(true, state.elapsed))
    else:
        hud.show_end(true, state.elapsed)

func save_game(show_message: bool = true) -> void:
    if capture_mode: return
    state.player_position = player.position
    var error := SurvivorSave.save_state(state)
    if show_message or error != OK:
        hud.toast("Progresso salvo." if error == OK else "Falha ao salvar (%s)." % error_string(error))

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        if playing:
            save_game(false)
        soundscape.shutdown()
        get_tree().create_timer(0.16).timeout.connect(func(): get_tree().quit())
    elif what == NOTIFICATION_APPLICATION_PAUSED:
        if playing:
            pause_game()

func apply_quality() -> void:
    terrain.sun.shadow_enabled = not light_visuals
    world.scenery.set_light_mode(light_visuals)
    if is_instance_valid(climate):
        climate.set_light_mode(light_visuals)
    if is_instance_valid(world) and is_instance_valid(world.fauna):
        world.fauna.set_light_mode(light_visuals)
    hud.light_visuals = light_visuals
    if is_instance_valid(hud.quality_button):
        hud.quality_button.text = "Visual: Leve" if light_visuals else "Visual: Completo"

func toggle_quality() -> void:
    light_visuals = not light_visuals
    apply_quality()
    var settings := ConfigFile.new()
    settings.load("user://visual.cfg")
    settings.set_value("graphics", "light", light_visuals)
    settings.save("user://visual.cfg")
    hud.toast("Visual leve: menos vegetação e sombras desligadas." if light_visuals else "Visual completo: vegetação e sombras ativas.")

func queue_work(entry: Dictionary,animation: String,duration: float,mode: String,reach: float) -> void:
    cancel_work()
    if entry.is_empty(): return
    pending_work = {"entry":entry,"animation":animation,"duration":duration,"mode":mode,"reach":reach,"approaching":true}
    approach_timer = 0

func cancel_work() -> void:
    pending_work.clear()
    approach_timer = 0
    if is_instance_valid(player): player.cancel_action()

func _on_action_contact(kind: String,point: Vector3) -> void:
    var effect: String = {"spear":"chop","chop":"chop","mine":"mine","cut":"rustle","handcraft":"rustle","gather":"rustle","search":"rustle","fish":"splash","build":"hammer","craft":"hammer","cook":"rustle","eat":"consume","drink":"splash","rest":"rustle"}.get(kind,"rustle")
    soundscape.play_effect(effect,point)
    if not pending_work.is_empty() and pending_work.mode == "tool":
        var recipe: String = pending_work.recipe
        if state.craft_tool(recipe):
            hud.toast("%s pronto! Usado automaticamente na coleta." % SurvivalState.RECIPES[recipe].title,4)
            save_game(false)
        else:
            hud.toast(state.recipe_error(recipe))
        pending_work.clear()
    if not pending_work.is_empty() and pending_work.mode == "cave_seal":
        hud.toast(world.caves.puzzles.activate_seal(pending_work.entry))
        pending_work.clear()
        save_game(false)
    if not pending_work.is_empty() and pending_work.mode == "cave_vault":
        pending_discovery = world.caves.puzzles.collect_vault(pending_work.entry)
        pending_work.clear()
    if not pending_work.is_empty() and pending_work.mode=="harvest":
        var entry: Dictionary = pending_work.entry
        if entry.kind=="discovery":
            pending_discovery = world.discover(entry)
        elif entry.kind=="cave_cache":
            pending_discovery = world.caves.collect_cache(entry)
        elif is_instance_valid(entry.node) and entry.node.visible:
            hud.toast(world.harvest(entry))
        pending_work.clear()

func _on_action_finished(kind: String) -> void:
    pending_work.clear()
    if kind=="search" and not pending_discovery.is_empty():
        var info := pending_discovery
        pending_discovery = {}
        hud.show_discovery(info)
        save_game(false)

func toggle_sound() -> void:
    muted = not muted
    soundscape.set_muted(muted)
    hud.muted = muted
    if is_instance_valid(hud.sound_button):
        hud.sound_button.text = "Som: desligado" if muted else "Som: ligado"
    var settings := ConfigFile.new()
    settings.load("user://visual.cfg")
    settings.set_value("audio","muted",muted)
    settings.save("user://visual.cfg")
