extends Node3D

var state := SurvivalState.new()
var terrain: SurvivorTerrain
var world: SurvivorWorld
var player: SurvivorPlayer
var camera: Camera3D
var hud: SurvivorHUD
var playing := false
var selected_recipe := ""
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
    hud = SurvivorHUD.new()
    add_child(hud)
    hud.minimap.terrain = terrain
    hud.action_requested.connect(interact)
    hud.build_requested.connect(select_recipe)
    hud.fishing_requested.connect(fish_or_cancel)
    hud.consume_requested.connect(consume)
    hud.save_requested.connect(save_game)
    hud.menu_requested.connect(pause_game)
    hud.start_requested.connect(start_game)
    hud.resume_requested.connect(resume_game)
    hud.quality_requested.connect(toggle_quality)
    hud.sound_requested.connect(toggle_sound)
    hud.journal_requested.connect(func(): hud.show_journal())
    hud.zoom_requested.connect(change_zoom)
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
    player.terrain = terrain
    player.world = world
    player.position = state.player_position
    if not world.walkable(player.position, player.position):
        player.position = SurvivalState.START_POSITION
    player.position.y = world.surface_height(player.position)
    add_child(player)
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
        hud.activity_name = {"chop":"Cortando madeira","mine":"Extraindo pedra","gather":"Coletando","search":"Investigando","fish":"Pescando","build":"Construindo","craft":"Fabricando","handcraft":"Fabricando ferramenta","cut":"Cortando fibras","cook":"Preparando alimento","eat":"Comendo","rest":"Descansando","drink":"Bebendo água"}.get(player.action_kind,"")
        hud.activity_fraction = 1-player.action_remaining/player.action_duration
    elif not pending_work.is_empty():
        hud.activity_name = "Aproximando-se"
        hud.activity_fraction = 0
    else:
        hud.activity_name = ""
    state.advance(delta)
    terrain.set_time_of_day(fmod(8.0 / 24.0 + state.elapsed / SurvivalState.DAY_SECONDS, 1.0))
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
        var error := world.placement_error(selected_recipe, point, player.position)
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
        hud.toast("Aproxime-se de coqueiros, pedras, fibras, metal ou da nascente.")
        return
    action_cooldown = 0.65
    match str(target.kind):
        "palm", "tree", "rock", "fiber", "metal", "discovery", "loose_log", "loose_stone":
            var error := state.harvest_error(str(target.kind))
            if error != "":
                hud.toast(error,5)
                return
            var animation: String = {"palm":"chop","tree":"chop","rock":"mine","metal":"search","fiber":"cut" if state.owns("stone_knife") else "gather","discovery":"search","loose_log":"gather","loose_stone":"gather"}[target.kind]
            queue_work(target,animation,1.05,"harvest",float(target.radius)+0.85)
        "spring":
            player.perform_action("drink",0.95,target.position)
            state.thirst = 100
            hud.toast("Água fresca da nascente. Sede recuperada.")
        "campfire": craft_meal()
        "house":
            if state.hunger <= 10 or state.thirst <= 10:
                hud.toast("Coma e beba antes de descansar.")
            else:
                player.perform_action("rest",2.5,target.position)
                state.health = minf(100, state.health + 25)
                state.hunger = maxf(0, state.hunger - 4)
                state.thirst = maxf(0, state.thirst - 6)
                hud.toast("Descanso no abrigo: +25 de saúde.")
                action_cooldown = 5
        "boat": escape_island()

func consume() -> void:
    if not paused() and selected_recipe == "" and fishing_remaining <= 0:
        var before: int = state.inventory.coconut+state.inventory.meal
        var message := state.consume()
        if state.inventory.coconut+state.inventory.meal < before:
            cancel_work()
            player.perform_action("eat",0.9,player.position)
        hud.toast(message)

func select_recipe(kind: String) -> void:
    if paused() or fishing_remaining > 0:
        return
    cancel_work()
    cancel_placement()
    var error := state.recipe_error(kind)
    if error != "":
        hud.toast(error)
        return
    if kind == "meal":
        craft_meal()
        return
    if kind in ["stone_knife", "stone_axe", "stone_pickaxe"]:
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
            queue_work(world.near_structure(player.position,"workbench",8),"craft",1.4,"station",2.35)
            hud.toast("Vara pronta. Aproxime-se do mar e toque em Pescar.")
            save_game(false)
        return
    cancel_placement()
    selected_recipe = kind
    preview = Node3D.new()
    add_child(preview)
    SurvivorModels.building(preview, kind)
    if kind != "campfire":
        SurvivorModels.merge_static(preview, "building_" + kind)
    # Preview lights must not affect the island before construction is committed.
    for node in preview.get_children():
        if node is Light3D:
            node.visible = false
    hud.toast("Mova-se para posicionar. Confirmar constrói; Cancelar volta.", 4)

func placement_point() -> Vector3:
    var facing := Vector3(sin(player.body_pivot.rotation.y), 0, cos(player.body_pivot.rotation.y))
    var point := player.position + facing * (7.0 if selected_recipe == "house" else 5.5)
    if selected_recipe == "boat":
        var dock := world.near_structure(player.position, "dock", 15)
        if not dock.is_empty():
            point = world.boat_location(dock.position)
            return point
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
    var error := world.placement_error(selected_recipe, point, player.position)
    if error == "":
        error = state.recipe_error(selected_recipe)
    if error != "":
        hud.toast(error)
        return
    var kind := selected_recipe
    if not state.pay_recipe(kind):
        return
    var entry := {"kind": kind, "x": point.x, "z": point.z}
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
    if is_instance_valid(preview):
        preview.queue_free()
    preview = null
    if is_instance_valid(hud):
        hud.update_placement("", "")

func craft_meal() -> void:
    if world.near_structure(player.position, "campfire", 6).is_empty():
        hud.toast("Aproxime-se da fogueira para assar o peixe.")
        return
    if state.pay_recipe("meal"):
        state.add_item("meal", 1)
        queue_work(world.near_structure(player.position,"campfire",6),"cook",1.4,"station",2.05)
        hud.toast("Peixe assado pronto. Toque em Comer / beber.")
    else:
        hud.toast(state.recipe_error("meal"))

func fish_or_cancel() -> void:
    if paused():
        return
    if selected_recipe != "":
        cancel_placement()
        return
    if not state.owns("fishing_rod"):
        hud.toast("Fabrique a vara perto da bancada primeiro.")
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
    var effect: String = {"chop":"chop","mine":"mine","cut":"rustle","handcraft":"rustle","gather":"rustle","search":"rustle","fish":"splash","build":"hammer","craft":"hammer","cook":"rustle","eat":"consume","drink":"splash","rest":"rustle"}.get(kind,"rustle")
    soundscape.play_effect(effect,point)
    if not pending_work.is_empty() and pending_work.mode == "tool":
        var recipe: String = pending_work.recipe
        if state.craft_tool(recipe):
            hud.toast("%s pronto! Usado automaticamente na coleta." % SurvivalState.RECIPES[recipe].title,4)
            save_game(false)
        else:
            hud.toast(state.recipe_error(recipe))
        pending_work.clear()
    if not pending_work.is_empty() and pending_work.mode=="harvest":
        var entry: Dictionary = pending_work.entry
        if entry.kind=="discovery":
            pending_discovery = world.discover(entry)
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
