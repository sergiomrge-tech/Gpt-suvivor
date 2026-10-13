extends Node3D

const TERRAIN_SCRIPT = preload("res://scripts/terrain.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const WORLD_SCRIPT = preload("res://scripts/world.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const STATE_SCRIPT = preload("res://scripts/survival_state.gd")

var terrain: SurvivorTerrain
var player: SurvivorPlayer
var world: SurvivorWorld
var hud: SurvivorHUD
var state: SurvivorState
var camera: Camera3D
var joystick_direction := Vector2.ZERO
var running := false
var collector_timer := 0.0
var autosave_timer := 0.0
var session_finished := false
var camera_zoom := 1.0
var fishing_cooldown := 0.0

func _ready() -> void:
    terrain = TERRAIN_SCRIPT.new() as SurvivorTerrain
    terrain.name = "ProceduralIsland"
    add_child(terrain)
    world = WORLD_SCRIPT.new() as SurvivorWorld
    world.name = "IslandResourcesAndBuildings"
    world.terrain = terrain
    add_child(world)
    player = PLAYER_SCRIPT.new() as SurvivorPlayer
    player.name = "Survivor"
    player.terrain = terrain
    player.position = Vector3(139.0, 0.0, 0.0)
    add_child(player)
    camera = Camera3D.new()
    camera.name = "SurvivalCamera"
    camera.current = true
    camera.fov = 52.0
    add_child(camera)
    _position_camera(1.0)
    state = STATE_SCRIPT.new() as SurvivorState
    hud = HUD_SCRIPT.new() as SurvivorHUD
    add_child(hud)
    hud.action_requested.connect(_on_action)
    hud.recipe_selected.connect(_craft)
    hud.move_changed.connect(func(direction: Vector2) -> void: joystick_direction = direction)

func _position_camera(weight: float) -> void:
    var target: Vector3 = player.position + Vector3(0.0, 1.6, 0.0)
    var target_camera: Vector3 = target + Vector3(0.0, 33.0, 25.0) * camera_zoom
    camera.global_position = camera.global_position.lerp(target_camera, weight)
    camera.look_at(target, Vector3.UP)

func _process(delta: float) -> void:
    if not running:
        player.move_vector = Vector2.ZERO
        return
    _position_camera(clampf(delta * 6.0, 0.0, 1.0))
    state.tick(delta)
    fishing_cooldown = maxf(0.0, fishing_cooldown - delta)
    terrain.set_time_of_day(state.clock)
    var keyboard := Vector2.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        keyboard.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        keyboard.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        keyboard.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        keyboard.x += 1.0
    player.move_vector = (keyboard.normalized() + joystick_direction).limit_length(1.0)
    var near: Node3D = world.nearest_resource(player.position)
    var hint := ""
    if near != null:
        var kind: String = str(near.get_meta("resource_kind"))
        var tool: String = state.required_tool(kind)
        hint = "[E] " + world.resource_title(kind)
        if tool != "":
            hint += " • " + ("PRONTO" if state.is_equipped(tool) else "Equipar " + SurvivorState.ITEM_NAMES[tool])
    hud.update_display(state, hint)
    collector_timer += delta
    autosave_timer += delta
    if collector_timer >= 90.0:
        collector_timer = 0.0
        if int(state.crafted.get("collector", 0)) > 0:
            state.add_item("water", int(state.crafted["collector"]))
            hud.notify("Coletor de chuva: água potável disponível.")
    if autosave_timer >= 120.0:
        autosave_timer = 0.0
        _save(false)
    if state.dead:
        _finish(false)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_E: _on_action("collect")
        KEY_F: _on_action("fish")
        KEY_H: _on_action("eat")
        KEY_T: _on_action("drink")
        KEY_B: _on_action("craft_menu")
        KEY_I: _on_action("inventory")
        KEY_P: _on_action("save")
        KEY_ESCAPE: _on_action("close_inventory" if hud.inventory_is_open() else "menu")

func _start() -> void:
    state.reset()
    world.reset_world()
    player.position = Vector3(139.0, terrain.height_at(139.0, 0.0), 0.0)
    collector_timer = 0.0
    autosave_timer = 0.0
    session_finished = false
    fishing_cooldown = 0.0
    _position_camera(1.0)
    running = true
    hud.show_game()
    hud.notify("Você acordou na praia. Reúna suprimentos para sobreviver!")

func _load() -> void:
    var data: Dictionary = SurvivorState.read_save()
    if data.is_empty() or not state.from_dict(data):
        hud.show_main_menu()
        return
    var world_data: Variant = data.get("world", {})
    if world_data is Dictionary:
        world.restore(world_data)
    else:
        world.reset_world()
    var coords: Variant = data.get("player", [])
    if coords is Array and coords.size() == 2:
        var x: float = clampf(float(coords[0]), -210.0, 210.0)
        var z: float = clampf(float(coords[1]), -210.0, 210.0)
        if terrain.is_land(x, z):
            player.position = Vector3(x, terrain.height_at(x, z), z)
        else:
            player.position = Vector3(139.0, terrain.height_at(139.0, 0.0), 0.0)
    collector_timer = 0.0
    autosave_timer = 0.0
    session_finished = false
    fishing_cooldown = 0.0
    _position_camera(1.0)
    running = not state.dead
    if running:
        hud.show_game()
        hud.notify("Sobrevivência retomada.")
    else:
        hud.show_ending(false)

func _save(show_message: bool = true) -> void:
    if not running:
        return
    var ok: bool = state.save_game(world.to_dict(), player.position)
    if show_message:
        hud.notify("Partida salva no dispositivo." if ok else "Erro ao salvar partida.")

func _collect() -> void:
    var nearest: Node3D = world.nearest_resource(player.position)
    if nearest == null:
        hud.notify("Aproxime-se de uma árvore, pedra, fruta ou fonte.")
        return
    var kind: String = str(nearest.get_meta("resource_kind"))
    var needed: String = state.required_tool(kind)
    if needed != "" and not state.is_equipped(needed):
        hud.notify("Equipe %s na aba EQUIPAR." % SurvivorState.ITEM_NAMES[needed])
        return
    var collected: Dictionary = world.harvest(nearest)
    if collected.is_empty():
        return
    var desc: Array[String] = []
    for item in collected:
        state.add_item(str(item), int(collected[item]))
        desc.append("%s +%d" % [SurvivorState.ITEM_NAMES[str(item)], int(collected[item])])
    hud.notify("%s: %s" % [world.resource_title(kind), ", ".join(desc)])

func _fish() -> void:
    if not state.is_equipped("fishing_rod"):
        hud.notify("Crie a VARA DE PESCAR e equipe na MÃO PRINCIPAL.")
        return
    if not terrain.is_fishing_spot(player.position.x, player.position.z):
        hud.notify("Aproxime-se da beira do mar para pescar.")
        return
    if fishing_cooldown > 0.0:
        hud.notify("Aguarde %d segundos para pescar novamente." % int(ceilf(fishing_cooldown)))
        return
    fishing_cooldown = 7.0
    state.add_item("fish", 1)
    hud.notify("Peixe capturado! +1 peixe no inventário.")

func _craft(recipe: String) -> void:
    if not running:
        return
    if not SurvivorState.RECIPES.has(recipe):
        return
    if recipe == "raft" and not terrain.is_shore(player.position.x, player.position.z):
        hud.notify("A jangada precisa ser construída na faixa de areia.")
        return
    if not state.can_craft(recipe):
        hud.notify("Materiais insuficientes para %s." % SurvivorHUD.RECIPE_NAMES[recipe])
        return
    var is_building: bool = SurvivorState.BUILDING_RECIPES.has(recipe)
    if is_building and world.structure_records.size() >= 100:
        hud.notify("Limite de construções atingido.")
        return
    if not state.craft(recipe):
        hud.notify("Não foi possível fabricar.")
        return
    if is_building:
        var facing: float = player.body_pivot.rotation.y
        var offset := Vector3(sin(facing), 0.0, cos(facing)) * 5.0
        var destination: Vector3 = player.position + offset
        if not terrain.is_land(destination.x, destination.z):
            destination = player.position + Vector3(2.0, 0.0, 0.0)
        world.place_structure(recipe, destination)
    if is_building:
        hud.close_inventory()
    else:
        hud.open_inventory("equipment")
    hud.notify("Criado: " + SurvivorHUD.RECIPE_NAMES[recipe] + (". Equipe na aba EQUIPAR." if not is_building else ""))
    if recipe == "raft":
        _finish(true)

func _finish(won: bool) -> void:
    if session_finished:
        return
    session_finished = true
    running = false
    player.move_vector = Vector2.ZERO
    hud.show_ending(won)

func _on_action(action: String) -> void:
    if action == "start":
        _start()
        return
    if action == "load":
        _load()
        return
    if action == "menu":
        if running:
            _save(false)
        running = false
        hud.show_main_menu()
        return
    if not running:
        return
    if action.begins_with("equip:"):
        var item: String = action.trim_prefix("equip:")
        if state.equip(item):
            hud.notify("Item equipado: " + SurvivorState.ITEM_NAMES[item])
        else:
            hud.notify("Você ainda não possui esse equipamento.")
        return
    if action.begins_with("unequip:"):
        if state.unequip(action.trim_prefix("unequip:")):
            hud.notify("Equipamento removido.")
        return
    match action:
        "collect": _collect()
        "fish": _fish()
        "eat": hud.notify(state.eat())
        "drink": hud.notify(state.drink())
        "inventory": hud.toggle_inventory()
        "craft_menu": hud.open_inventory("craft")
        "close_inventory": hud.close_inventory()
        "zoom_in":
            camera_zoom = maxf(0.62, camera_zoom - 0.12)
        "zoom_out":
            camera_zoom = minf(1.85, camera_zoom + 0.12)
        "save": _save()
