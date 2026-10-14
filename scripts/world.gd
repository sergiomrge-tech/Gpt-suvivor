extends Node3D
class_name SurvivorWorld

var terrain: SurvivorTerrain
var state: SurvivalState
var resources: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _refresh_clock := 0.0
var harvest_effects: SurvivorHarvestEffects
static var footprint_cache: Dictionary = {}
var scenery: SurvivorScenery
var fauna: SurvivorFauna
var caves: SurvivorCaves
var trails: SurvivorTrails
var discoverables: Array[Dictionary] = []
const DISCOVERIES := {
    "pilot_bag":{"title":"A mochila do piloto","text":"Entre os destroços, você encontra uma mochila com suprimentos secos e uma anotação: água doce deve existir onde a vegetação fica mais densa. O piloto havia marcado uma nascente a oeste da praia.","point":Vector2(-4,172),"reward":{"wood":4,"fiber":3}},
    "cave_note":{"title":"Marcas na rocha","text":"Um pequeno diário descreve uma antiga passagem por esta ilha. A última página fala de rochas com peças metálicas presas entre as raízes e de uma praia ampla, boa para montar uma embarcação. A tinta está gasta, mas a esperança continua legível.","point":Vector2(78,24),"reward":{"metal":2}},
    "tool_crate":{"title":"Ferramentas esquecidas","text":"A caixa guardava ferragens e cordas. Quem esteve aqui também tentou construir alguma coisa. Você reaproveita o que resistiu à umidade e deixa uma marca no diário: desta vez, o barco vai chegar ao mar.","point":Vector2(-88,-53),"reward":{"metal":2,"fiber":5}},
    "distress_log":{"title":"Registro do resgate","text":"Nos destroços há um registro do rádio. A rota foi desviada pela tempestade; uma embarcação leve pode alcançar o canal seguro ao leste. A mensagem aponta para a Caverna do Leste.","point":Vector2(-12,174),"reward":{"metal":2}},
    "sail_diagram":{"title":"Esquema da vela","text":"Perto da entrada da Caverna do Leste, você encontra desenhos da armação de um barco. As cordas e tábuas da bancada serão essenciais para terminar a vela e navegar para fora da ilha.","point":Vector2(75,27),"reward":{"fiber":2}}
}

func generate() -> void:
    _rng.seed = 341709
    _landmark("wreck", "Destroços do avião", Vector2(-8, 164))
    _landmark("spring", "Nascente de água", Vector2(-26, 90))
    _landmark("cave", "Caverna do Leste", Vector2(80, 20))
    _landmark("cave", "Gruta das raízes", Vector2(-90, -60))
    # Accessible resources near the starting beach keep the first objective clear.
    for i in range(10):
        _resource("palm", "start_palm_%d" % i, Vector2(-28 + i * 6.0, 142 - (i % 3) * 8))
    for i in range(6):
        _resource("rock", "start_rock_%d" % i, Vector2(14 + i * 4, 155 - i * 3))
        _resource("fiber", "start_fiber_%d" % i, Vector2(-30 + i * 4, 157 - i * 2))
    for i in range(4):
        _resource("metal", "wreck_metal_%d" % i, Vector2(-15 + i * 3, 172))
    for kind in ["palm", "rock", "fiber"]:
        var count := 72 if kind == "palm" else 52
        for i in range(count):
            for attempt in range(60):
                var p := Vector2(_rng.randf_range(-187, 187), _rng.randf_range(-187, 187))
                if terrain.height_at(p.x, p.y) < 2.4 or not terrain.is_land(p.x, p.y) or _reserved(p) or _resource_near(p, 4.0):
                    continue
                _resource(kind, "%s_%d" % [kind, i], p)
                break
    for entry in landmarks:
        if entry.kind == "cave":
            for i in range(3):
                var p := Vector2(entry.position.x + (i - 1) * 2.0, entry.position.z - 4.0 - i)
                _resource("metal", "%s_metal_%d" % [entry.title, i], p)
    repair_coastal_buildings()
    for entry in state.buildings:
        add_structure(entry)
    refresh_resources()
    trails = SurvivorTrails.new()
    trails.terrain = terrain
    trails.world = self
    trails.generate()
    terrain.set_trail_mask(trails.mask)
    _forest_groups()
    _ground_resources()
    _spawn_discoveries()
    scenery = SurvivorScenery.new()
    scenery.terrain = terrain
    scenery.world = self
    add_child(scenery)
    scenery.generate()
    fauna = SurvivorFauna.new()
    fauna.terrain = terrain
    fauna.state = state
    add_child(fauna)
    fauna.generate()
    caves = SurvivorCaves.new()
    caves.state = state
    add_child(caves)
    caves.generate()
    harvest_effects = SurvivorHarvestEffects.new()
    add_child(harvest_effects)
    for drop in state.wood_drops:
        _spawn_wood_drop(drop)
    refresh_resources()

func _reserved(p: Vector2) -> bool:
    if p.distance_to(Vector2(0, 170)) < 17.0:
        return true
    for entry in landmarks:
        if p.distance_to(Vector2(entry.position.x, entry.position.z)) < 13.0:
            return true
    return false

func _resource_near(p: Vector2, distance: float) -> bool:
    for entry in resources:
        if p.distance_to(Vector2(entry.position.x, entry.position.z)) < distance:
            return true
    return false

func _resource(kind: String, id: String, p: Vector2) -> void:
    var node := Node3D.new()
    node.name = id.validate_node_name()
    node.position = Vector3(p.x, terrain.height_at(p.x, p.y), p.y)
    node.rotation.y = _rng.randf_range(0, TAU)
    add_child(node)
    var variant := resources.size() % 12
    var radius := 0.0
    match kind:
        "palm":
            # The resource entry, collection cooldown and hit radius do not
            # depend on which visual mesh represents the coconut tree.
            var palm_lod := "palm_detailed" if p.distance_to(Vector2(0,170)) < 48.0 else "palm_light"
            if not SurvivorRealWorldAssets.attach(node,palm_lod,8.25,80.0 if palm_lod == "palm_detailed" else 120.0):
                SurvivorModels.palm(node,variant)
            radius = 0.8
        "tree":
            # Harvestable forest trees keep their IDs and axe gate; native CC0
            # tree and existing photogrammetric pachira replace geometric cones.
            var source_id := "island_tree_01" if variant % 7 == 0 else "pachira"
            if not SurvivorRealWorldAssets.attach(node,source_id,9.3 if source_id == "island_tree_01" else 7.3,65.0 if source_id == "island_tree_01" else 78.0):
                SurvivorModels.canopy_tree(node,variant)
            radius = 1.1
        "rock":
            var rock_source := "boulder_01" if variant % 5 == 0 else "rock_07"
            if not SurvivorRealWorldAssets.attach(node,rock_source,2.2 if rock_source == "boulder_01" else 1.45,65.0):
                SurvivorModels.rock(node, variant)
            radius = 1.7
        "fiber":
            if not SurvivorRealWorldAssets.attach(node,"fern",0.85,47.0):
                SurvivorModels.fern(node,variant)
        "loose_log":
            # Scanned fallen timber is decorative only: hand-pickup stays unchanged.
            if not SurvivorRealWorldAssets.attach(node,"dead_tree_trunk_02",0.78,43.0):
                SurvivorModels.beam(node, Vector3(-1.1,0.3,0), Vector3(1.1,0.3,0), 0.3, Color(0.37,0.23,0.10))
                SurvivorModels.sphere(node,0.29,Color(0.73,0.53,0.28),Vector3(-1.11,0.3,0),Vector3(0.08,1,1))
                SurvivorModels.sphere(node,0.29,Color(0.73,0.53,0.28),Vector3(1.11,0.3,0),Vector3(0.08,1,1))
                SurvivorModels.beam(node,Vector3(0.4,0.4,0),Vector3(0.6,0.5,0.5),0.09,Color(0.37,0.23,0.10))
        "loose_stone":
            if not SurvivorRealWorldAssets.attach(node,"rock_07",0.45,38.0):
                SurvivorModels.sphere(node,0.42,Color(0.5,0.53,0.49),Vector3(0,0.23,0),Vector3(1.1,0.65,0.9))
                SurvivorModels.sphere(node,0.26,Color(0.39,0.43,0.41),Vector3(0.55,0.12,0.18),Vector3(1,0.6,0.8))
        "metal":
            for i in range(3):
                var part := SurvivorModels.box(node, Vector3(0.8, 0.2, 1.0), Color(0.47, 0.54, 0.56), Vector3((i - 1) * 0.7, 0.2 + i * 0.15, 0))
                part.rotation_degrees.z = i * 25
    SurvivorModels.merge_static(node, "%s_%d" % [kind, variant])
    resources.append({"kind": kind, "id": id, "node": node, "position": node.position, "radius": radius})

func _landmark(kind: String, title: String, p: Vector2) -> void:
    var node := Node3D.new()
    node.position = Vector3(p.x, terrain.height_at(p.x, p.y), p.y)
    add_child(node)
    match kind:
        "wreck":
            if SurvivorRealWorldAssets.attach(node,"airplane_propeller",3.3,135.0):
                var aircraft := node.get_node_or_null("CC0_airplane_propeller") as Node3D
                if aircraft != null:
                    aircraft.rotation_degrees = Vector3(-10.0,23.0,11.5)
                    aircraft.position.y -= 0.55
                var fractured := SurvivorRealWorldAssets.fracture_airplane(aircraft) if aircraft != null else 0
                node.set_meta("aircraft_fracture_count",fractured)
                SurvivorWorldAssetRenderer.compact_aircraft(aircraft)
                SurvivorRealWorldAssets.add_crash_damage(node)
            else:
                SurvivorModels.wreck(node)
        "cave":
            _scanned_cave_entrance(node)
            # PBR rock faces flank the accessible cave instead of replacing
            # its interaction trigger or blocking the original corridor.
            for side in [-1,1]:
                var cliff := Node3D.new()
                cliff.name = "Nature_CaveCliff_%d" % side
                var dx := float(side)*5.7
                cliff.position = Vector3(dx,terrain.height_at(p.x+dx,p.y+2.1)-node.position.y,2.1)
                cliff.rotation.y = float(side)*0.4
                node.add_child(cliff)
                SurvivorRealWorldAssets.attach(cliff,"rock_face_01",4.15,85.0)
            if p.x < -50.0:
                var cave_ladder := Node3D.new()
                cave_ladder.name = "Nature_CliffLadder"
                cave_ladder.position = Vector3(7.5,terrain.height_at(p.x+7.5,p.y)-node.position.y,0.0)
                cave_ladder.rotation.y = -0.4
                node.add_child(cave_ladder)
                SurvivorRealWorldAssets.attach(cave_ladder,"wooden_ladder_02",2.7,50.0)
        "spring":
            for i in range(9):
                var stone := Node3D.new()
                stone.position = Vector3(cos(i*TAU/9)*2.4,-0.06,sin(i*TAU/9)*2.4)
                stone.rotation.y = i*0.61
                node.add_child(stone)
                SurvivorRealWorldAssets.attach(stone,"rock_07",0.58,66.0)
            SurvivorModels.sphere(node, 2.3, Color(0.13, 0.57, 0.63), Vector3(0, 0.12, 0), Vector3(1, 0.08, 1))
    SurvivorModels.merge_static(node, "landmark_" + kind)
    landmarks.append({"kind": kind, "title": title, "node": node, "position": node.position})

func add_structure(entry: Dictionary) -> Node3D:
    var node := Node3D.new()
    node.name = str(entry.kind)
    var base_y := terrain.height_at(float(entry.x), float(entry.z))
    node.position = Vector3(float(entry.x), base_y, float(entry.z))
    if entry.kind == "boat":
        node.position.y = terrain.sea_level + 0.45
    if entry.kind == "dock":
        # Point away from the center of the island into the ocean.
        node.rotation.y = atan2(-node.position.x, -node.position.z)
    elif entry.kind != "boat":
        node.rotation.y = float(entry.get("rotation", 0.0))
    add_child(node)
    build_structure_visual(node,str(entry.kind),int(entry.get("stage",5)))
    if entry.kind == "door_panel":
        var leaf: Node3D = node.get_node_or_null("DoorLeaf")
        if leaf != null:
            leaf.rotation.y = -PI * 0.5 if bool(entry.get("door_open", false)) else 0.0
    var collider := node.get_meta("visual_bounds") as AABB
    if entry.kind=="house":
        var main_model := node.get_node_or_null("CC0_garden_shed") as Node3D
        if main_model!=null:
            collider = main_model.transform*SurvivorWorldAssetRenderer.collision_bounds("garden_shed")
    node.set_meta("collision_bounds",collider)
    structures.append({"kind": entry.kind, "node": node, "position": node.position, "door_open": bool(entry.get("door_open", false)), "stage":int(entry.get("stage",5)) if entry.kind == "boat" else 0, "save_entry": entry})
    if scenery != null:
        scenery.clear_area(node.position, 5.0 if entry.kind == "house" else 2.8)
    return node

func _build_boat_model(parent: Node3D, stage: int) -> void:
    var model := Node3D.new()
    model.name = "BoatModel"
    parent.add_child(model)
    if stage>=2 and SurvivorRealWorldAssets.attach(model,"canoe",0.90,115.0):
        model.set_meta("native_hull",true)
        var canoe := model.get_node("CC0_canoe") as Node3D
        var bounds := AABB()
        var first := true
        for part in canoe.get_children():
            if part is MeshInstance3D:
                bounds = part.mesh.get_aabb() if first else bounds.merge(part.mesh.get_aabb())
                first = false
        if bounds.size.x>bounds.size.z:
            canoe.scale = Vector3(8.8/bounds.size.x,0.9,3.5/bounds.size.z)
            canoe.rotation.y = PI*0.5
        else:
            canoe.scale = Vector3(3.5/bounds.size.x,0.9,8.8/bounds.size.z)
        canoe.position.y = -0.45
    SurvivorModels.boat_stage(model,stage)
    SurvivorModels.merge_static(model,"boat_model_stage_%d" % stage)

func refresh_boat_stage(entry: Dictionary) -> void:
    if str(entry.get("kind","")) != "boat":
        return
    var new_stage := state.boat_stage()
    entry["stage"] = new_stage
    var old_model: Node3D = entry.node.get_node_or_null("BoatModel")
    if old_model != null:
        entry.node.remove_child(old_model)
        old_model.queue_free()
    _build_boat_model(entry.node,new_stage)

func toggle_door(entry: Dictionary) -> bool:
    if str(entry.get("kind", "")) != "door_panel":
        return false
    var next_open := not bool(entry.get("door_open", false))
    entry["door_open"] = next_open
    var saved: Dictionary = entry.get("save_entry", {})
    saved["door_open"] = next_open
    var leaf: Node3D = entry.node.get_node_or_null("DoorLeaf")
    if leaf != null:
        var animation := create_tween()
        animation.tween_property(leaf, "rotation:y", -PI * 0.5 if next_open else 0.0, 0.32)
    return next_open

func remove_structure(kind: String) -> void:
    for index in range(structures.size() - 1, -1, -1):
        if str(structures[index].kind) == kind:
            var node: Node3D = structures[index].node
            structures.remove_at(index)
            if is_instance_valid(node):
                node.queue_free()
            return

func _process(delta: float) -> void:
    _refresh_clock += delta
    if _refresh_clock >= 2.0:
        _refresh_clock = 0
        refresh_resources()
    for entry in structures:
        if entry.kind == "boat":
            entry.node.position.y = terrain.sea_level + 0.45 + sin(Time.get_ticks_msec() * 0.0015) * 0.08

func refresh_resources() -> void:
    for entry in resources:
        var ready_time := float(state.harvested.get(entry.id, -1.0))
        entry.node.visible = not bool(entry.get("cleared",false)) and (ready_time < 0.0 or (entry.kind != "metal" and state.elapsed >= ready_time))
    if scenery != null:
        scenery.sync_canopy()

func harvest(entry: Dictionary) -> String:
    if str(entry.get("kind", "")) in ["crab", "boar"]:
        return fauna.harvest_prey(entry)
    if bool(entry.get("cleared",false)) or not is_instance_valid(entry.get("node")) or not entry.node.visible:
        return "Esse recurso já foi coletado."
    var error := state.harvest_error(str(entry.kind))
    if error != "":
        return error
    var result := ""
    match entry.kind:
        "palm":
            var wood_amount := 12 if state.is_equipped("reinforced_axe") else 8
            _tree_wood_reward(entry,wood_amount)
            state.add_item("coconut", 3 if wood_amount == 12 else 2)
            result = "+%d madeiras no total • recolha o tronco no chão • cocos coletados" % wood_amount
        "tree":
            var wood_amount := 12 if state.is_equipped("reinforced_axe") else 8
            _tree_wood_reward(entry,wood_amount)
            state.add_item("fiber",2)
            result = "+%d madeiras no total • recolha o tronco no chão • +2 fibras" % wood_amount
        "rock":
            var stones := 9 if state.is_equipped("reinforced_pickaxe") else 6
            state.add_item("stone", stones)
            result = "+%d pedras" % stones
        "fiber":
            var count := 8 if state.is_equipped("stone_knife") else 5
            state.add_item("fiber", count)
            result = "+%d fibras" % count
        "loose_log":
            var amount := int(entry.get("pickup_amount",3))
            state.add_item("wood",amount)
            result = "+%d madeiras • tronco recolhido à mão" % amount
            if bool(entry.get("drop",false)):
                for index in range(state.wood_drops.size()-1,-1,-1):
                    if state.wood_drops[index].id==entry.id:
                        state.wood_drops.remove_at(index)
                entry.cleared = true
        "loose_stone":
            state.add_item("stone",2)
            result = "+2 pedras • recolhidas à mão"
        "metal":
            state.add_item("metal", 4)
            result = "+4 metais recuperados"
    if harvest_effects != null:
        harvest_effects.collect(entry,terrain)
    if not bool(entry.get("drop",false)):
        state.harvested[entry.id] = state.elapsed + 600.0
    entry.node.visible = false
    if scenery != null:
        scenery.sync_canopy()
    return result

func nearest_target(pos: Vector3, reach: float = 5.0) -> Dictionary:
    if caves != null and caves.is_inside(pos):
        return caves.nearest_target(pos, reach)
    var result: Dictionary = {}
    var distance := reach
    for entry in resources:
        if not entry.node.visible:
            continue
        var d := Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length()
        if d < distance:
            distance = d
            result = entry
    for entry in discoverables:
        if not entry.node.visible:
            continue
        var d := Vector2(pos.x-entry.position.x,pos.z-entry.position.z).length()
        if d < distance:
            distance = d
            result = entry
    for entry in structures + landmarks:
        if entry.kind in ["wreck", "workbench", "dock", "floor_panel", "wall_panel", "window_panel", "roof_panel", "reinforced_wall", "reinforced_roof"]:
            continue
        var d := Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length()
        # Boat is placed off the shore; it remains reachable from the dock.
        var max_reach := 10.0 if entry.kind == "boat" else reach
        if d < max_reach and (result.is_empty() or d < distance):
            distance = d
            result = entry
    if fauna != null:
        var prey := fauna.nearest_prey(pos, distance)
        if not prey.is_empty():
            result = prey
    return result

func near_structure(pos: Vector3, kind: String, reach: float = 12.0) -> Dictionary:
    for entry in structures:
        if entry.kind == kind and Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < reach:
            return entry
    return {}

func walkable(pos: Vector3, previous: Vector3) -> bool:
    if caves != null and caves.is_inside(previous):
        return caves.is_walkable(pos)
    if caves != null and caves.is_inside(pos):
        return false
    if not terrain.is_land(pos.x, pos.z) and not is_on_dock(pos):
        return false
    if scenery != null and not scenery.scenery_walkable(pos):
        return false
    var horizontal := Vector2(pos.x - previous.x, pos.z - previous.z).length()
    if horizontal > 0.001 and absf(surface_height(pos)-surface_height(previous)) > horizontal * 1.3:
        return false
    for entry in resources:
        if entry.node.visible and entry.radius > 0.0 and Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < float(entry.radius) + 0.45:
            return false
    for entry in landmarks:
        var local: Vector3 = pos - entry.position
        if entry.kind == "wreck" and absf(local.x) < 5.8 and absf(local.z) < 2.1:
            return false
        if entry.kind == "cave" and local.z < 1.0 and local.z > -12.5:
            if absf(local.x) > 3.0 and absf(local.x) < 7.0 or local.z < -9.5 and absf(local.x) < 7.0:
                return false
    for entry in structures:
        var local: Vector3 = entry.node.to_local(Vector3(pos.x,entry.position.y,pos.z))
        if entry.kind in ["chest","rain_collector","workbench","tool_rack","campfire","bed"]:
            var box: AABB = entry.node.get_meta("collision_bounds")
            if local.x>box.position.x-0.22 and local.x<box.end.x+0.22 and local.z>box.position.z-0.22 and local.z<box.end.z+0.22:
                return false
        if entry.kind in SurvivalState.WALL_MODULES and absf(local.x) < 1.75 and absf(local.z) < 0.33:
            if entry.kind == "door_panel" and bool(entry.get("door_open", false)) and absf(local.x) < 1.10:
                continue
            return false
        if entry.kind == "house":
            var box: AABB = entry.node.get_meta("collision_bounds")
            if local.x>box.position.x-0.2 and local.x<box.end.x+0.2 and local.z>box.position.z-0.2 and local.z<box.end.z+0.2:
                if local.x<box.position.x+0.22 or local.x>box.end.x-0.22 or local.z<box.position.z+0.22 or local.z>box.end.z-0.22 and absf(local.x)>0.58:
                    return false
    return true

func placement_error(kind: String, pos: Vector3, player_pos: Vector3, ignore_kind: String = "") -> String:
    if pos.distance_to(player_pos) > 15.0:
        return "Construa perto do personagem."
    if kind == "boat":
        if near_structure(pos, "dock").is_empty():
            return "O barco precisa ficar junto ao cais."
        if terrain.height_at(pos.x, pos.z) > terrain.sea_level + 0.15:
            return "O barco precisa ficar na água junto ao cais."
        return ""
    if not terrain.is_land(pos.x, pos.z):
        return "Escolha um ponto em terra firme."
    if kind == "tool_rack" and near_structure(pos,"workbench",12).is_empty():
        return "Construa a estação de aprimoramento próxima da bancada."
    if kind == "dock" and not terrain.is_shore(pos.x, pos.z):
        return "O cais precisa ficar na faixa de areia junto ao mar."
    var modular := kind in SurvivalState.MODULES
    var radius := footprint_radius(kind)
    if kind in SurvivalState.WALL_MODULES:
        var supported := false
        for entry in structures:
            if entry.kind == "floor_panel" and Vector2(pos.x-entry.position.x,pos.z-entry.position.z).length() < 1.85:
                supported = true
        if not supported:
            return "Encaixe a parede na borda de um piso modular."
    if kind in SurvivalState.ROOF_MODULES:
        var supported_floor := false
        var supported_wall := false
        for entry in structures:
            var d := Vector2(pos.x-entry.position.x,pos.z-entry.position.z).length()
            if entry.kind == "floor_panel" and d < 0.25:
                supported_floor = true
            if entry.kind in SurvivalState.WALL_MODULES and d < 2.0:
                supported_wall = true
        if not supported_floor or not supported_wall:
            return "O telhado precisa de um piso e uma parede modular."
    for entry in resources:
        if entry.node.visible and entry.radius > 0 and Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < radius + float(entry.radius):
            return "Limpe os recursos desse local antes de construir."
    for entry in structures:
        if ignore_kind != "" and entry.kind == ignore_kind:
            continue
        var distance := Vector2(pos.x-entry.position.x,pos.z-entry.position.z).length()
        if modular and entry.kind in SurvivalState.MODULES:
            # Floor + roof at the same grid center and walls at the tile edges are valid.
            if kind == "floor_panel" and entry.kind == "floor_panel" and distance < 2.8:
                return "Esse encaixe já está ocupado."
            if kind in SurvivalState.ROOF_MODULES and entry.kind in SurvivalState.ROOF_MODULES and distance < 0.45:
                return "Esse encaixe já está ocupado."
            if kind in SurvivalState.WALL_MODULES and entry.kind in SurvivalState.WALL_MODULES and distance < 0.45:
                return "Esse espaço de parede já está ocupado."
            # Distinct modular sockets may share a foundation or adjoining edges.
            continue
        if distance < radius + footprint_radius(entry.kind):
            return "Deixe espaço entre as construções."
    for entry in landmarks:
        if Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < radius + 7.0:
            return "Deixe os destroços, cavernas e nascente livres."
    for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
        var edge: Vector2 = Vector2(pos.x, pos.z) + direction * radius
        if not terrain.is_land(edge.x, edge.y) and kind != "dock":
            return "A construção precisa caber em terra firme."
        if absf(terrain.height_at(edge.x, edge.y) - terrain.height_at(pos.x, pos.z)) > 1.6 and kind != "dock":
            return "Esse terreno é muito inclinado."
    return ""

func boat_location(dock_pos: Vector3) -> Vector3:
    var radial := Vector3(dock_pos.x,0,dock_pos.z).normalized()
    var side := Vector3(-radial.z,0,radial.x) * 3.5
    var result := dock_pos + radial * 5.0 + side
    for distance in [5.0,6.0,7.0,8.0,9.0]:
        result = dock_pos + radial * distance + side
        if terrain.height_at(result.x,result.z) <= terrain.sea_level + 0.15:
            break
    result.y = terrain.sea_level + 0.45
    return result

func repair_coastal_buildings() -> void:
    var dock_entry: Dictionary = {}
    for entry in state.buildings:
        if entry.kind == "dock":
            dock_entry = entry
            if not terrain.is_shore(entry.x,entry.z):
                var direction := Vector2(entry.x,entry.z).normalized()
                if direction == Vector2.ZERO:
                    direction = Vector2(0,1)
                var radius := terrain.radius_at_angle(atan2(direction.y,direction.x))
                for step in range(18):
                    var p := direction * (radius * 0.962 + step * 0.25)
                    if terrain.is_shore(p.x,p.y):
                        entry.x = p.x
                        entry.z = p.y
                        break
    if dock_entry.is_empty():
        return
    for entry in state.buildings:
        if entry.kind == "boat" and terrain.height_at(entry.x,entry.z) > terrain.sea_level + 0.15:
            var pos := boat_location(Vector3(dock_entry.x,0,dock_entry.z))
            entry.x = pos.x
            entry.z = pos.z

func _forest_groups() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 507421
    var index := 0
    for center in [Vector2(-55,72),Vector2(45,80),Vector2(66,-26),Vector2(-45,-36),Vector2(14,-87),Vector2(-110,2),Vector2(52,-85)]:
        for i in range(7):
            for attempt in range(14):
                var p: Vector2 = center+Vector2(rng.randf_range(-12,12),rng.randf_range(-12,12))
                if terrain.height_at(p.x,p.y) < 4 or terrain.height_at(p.x,p.y) > 23 or _reserved(p) or _resource_near(p,7.5) or trails.distance_to(p)<4.5:
                    continue
                var protected := false
                for entry in structures:
                    if p.distance_to(Vector2(entry.position.x,entry.position.z)) < 8:
                        protected = true
                if protected:
                    continue
                _resource("tree","forest_tree_%d"%index,p)
                # Deterministic scanned stumps sit near select forest trees.
                # Decoration has no collider, loot ID or harvest requirement.
                if index % 6 == 0:
                    var stump := Node3D.new()
                    stump.name = "Nature_ForestStump_%d" % index
                    var sx := p.x + 3.3
                    var sz := p.y - 2.2
                    stump.position = Vector3(sx,terrain.height_at(sx,sz),sz)
                    stump.rotation.y = float(index)*0.38
                    add_child(stump)
                    SurvivorRealWorldAssets.attach(stump,"tree_stump_01",0.73,51.0)
                index += 1
                break
    refresh_resources()

func _spawn_discoveries() -> void:
    for id in DISCOVERIES:
        var info: Dictionary = DISCOVERIES[id]
        var node := Node3D.new()
        node.position = Vector3(info.point.x,terrain.height_at(info.point.x,info.point.y),info.point.y)
        node.visible = not state.discoveries.get(id,false)
        add_child(node)
        SurvivorModels.discovery_prop(node,id)
        SurvivorModels.merge_static(node,"discovery_"+id)
        discoverables.append({"kind":"discovery","id":id,"title":info.title,"node":node,"position":node.position,"radius":0.4})

func discover(entry: Dictionary) -> Dictionary:
    if state.discoveries.get(entry.id,false):
        return {}
    state.discoveries[entry.id] = true
    entry.node.visible = false
    var info: Dictionary = DISCOVERIES[entry.id]
    for item in info.reward:
        state.add_item(item,info.reward[item])
    return info.duplicate(true)

func dock_local(pos: Vector3) -> Vector3:
    for entry in structures:
        if entry.kind=="dock":
            var local: Vector3 = entry.node.to_local(Vector3(pos.x,entry.position.y,pos.z))
            if absf(local.x)<1.5 and local.z>-9.0 and local.z<1.8:
                return Vector3(local.x,entry.position.y+0.72,local.z)
    return Vector3(INF,INF,INF)

func is_on_dock(pos: Vector3) -> bool:
    return is_finite(dock_local(pos).y)

func surface_height(pos: Vector3) -> float:
    if caves != null and caves.is_inside(pos):
        return 0.0
    var ground := terrain.height_at(pos.x,pos.z)
    var local := dock_local(pos)
    if is_finite(local.y):
        var blend := 1-smoothstep(0.25,1.8,local.z)
        return maxf(ground,lerpf(ground,local.y,blend))
    return ground

func _ground_resources() -> void:
    # Separate seed and append-only IDs preserve existing resource/save identities.
    _rng.seed = 813507
    for i in range(6):
        _resource("loose_log", "start_log_%d" % i, Vector2(-5+i*2.6,179+(i%2)*3))
        _resource("loose_stone", "start_pebble_%d" % i, Vector2(-7+i*2.8,185+(i%2)*2))
    _resource("fiber", "start_hand_fiber", Vector2(8,175))
    for kind in ["loose_log", "loose_stone"]:
        for i in range(45):
            for attempt in range(60):
                var p := Vector2(_rng.randf_range(-185,185),_rng.randf_range(-185,185))
                if not terrain.is_land(p.x,p.y) or _reserved(p) or _resource_near(p,2.8):
                    continue
                _resource(kind,"%s_%d" % [kind,i],p)
                break
    refresh_resources()

func _scanned_cave_entrance(parent: Node3D) -> void:
    # A 6m clear throat matches the portal/collision corridor. Original sphere
    # rocks are replaced by textured scan modules, not overlaid with duplicates.
    for side in [-1.0,1.0]:
        for i in range(3):
            var rock := Node3D.new()
            rock.position = Vector3(side*5.25,-0.12,-float(i)*3.3)
            rock.rotation.y = side*0.42+float(i)*0.55
            parent.add_child(rock)
            SurvivorRealWorldAssets.attach(rock,"boulder_01",3.2+float(i%2)*0.5,92.0)
    var lintel := Node3D.new()
    lintel.position = Vector3(0,3.9,-6.1)
    parent.add_child(lintel)
    SurvivorRealWorldAssets.attach(lintel,"rock_face_01",1.5,92.0)
    lintel.scale.x = 2.8

func _camp_flames(parent: Node3D) -> void:
    var material := ShaderMaterial.new()
    material.shader = load("res://shaders/camp_flame.gdshader")
    for i in range(3):
        var node := MeshInstance3D.new()
        var card := QuadMesh.new()
        card.size = Vector2(0.62,0.95)
        node.mesh = card
        node.position = Vector3(0,0.92,0)
        node.rotation.y = float(i)*PI/3.0
        node.material_override = material
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(node)

func _tree_wood_reward(entry: Dictionary, amount: int) -> void:
    # Total yield is conserved: most wood arrives at contact; three units are
    # a physical pickup. Pending pickups are persisted and never paid twice.
    if state.wood_drops.size()>=256:
        state.add_item("wood",amount)
        return
    state.add_item("wood",amount-3)
    var p: Vector3 = entry.position+Vector3(1.1,0,0.5)
    var drop := {"id":"fallen_%s_%d" % [entry.id,int(state.elapsed*1000)],"amount":3,"x":p.x,"z":p.z,"rotation":fposmod(float(entry.node.rotation.y),TAU)}
    state.wood_drops.append(drop)
    _spawn_wood_drop(drop)

func _spawn_wood_drop(drop: Dictionary) -> void:
    var node := Node3D.new()
    node.name = str(drop.id).validate_node_name()
    node.position = Vector3(drop.x,terrain.height_at(drop.x,drop.z),drop.z)
    node.rotation.y = float(drop.rotation)
    add_child(node)
    SurvivorRealWorldAssets.attach(node,"dead_tree_trunk_02",0.46,55.0)
    resources.append({"kind":"loose_log","id":drop.id,"node":node,"position":node.position,"radius":0.0,"pickup_amount":drop.amount,"drop":true,"cleared":false})

func build_structure_visual(node: Node3D,kind: String,stage: int=5,preview_mode: bool=false) -> void:
    if kind == "boat":
        _build_boat_model(node,stage)
    else:
        if kind == "campfire":
            # Keep fire/glow/recipe state from original procedural fire, but
            # replace its simple stone-only silhouette with a real cooking grate.
            SurvivorModels.building(node,kind)
            for child in node.get_children():
                if child is MeshInstance3D:
                    node.remove_child(child)
                    child.free()
            SurvivorRealWorldAssets.attach(node,"camp_fire_grill",1.05,73.0)
            _camp_flames(node)
        elif kind == "chest":
            if not SurvivorRealWorldAssets.attach(node,"storage_chest",1.15,70.0):
                SurvivorModels.building(node,kind)
        elif kind == "rain_collector":
            SurvivorModels.building(node,kind)
            var bucket := Node3D.new()
            bucket.position = Vector3(1.46,0.0,0.7)
            node.add_child(bucket)
            SurvivorRealWorldAssets.attach(bucket,"wooden_bucket",0.85,55.0)
        elif kind == "tool_rack":
            SurvivorModels.building(node,kind)
            var supplies := Node3D.new()
            supplies.position = Vector3(-1.2,0.0,1.45)
            node.add_child(supplies)
            SurvivorRealWorldAssets.attach(supplies,"wooden_crate",0.95,50.0)
        elif kind == "workbench":
            if not SurvivorRealWorldAssets.attach(node,"workbench_carpenter",1.43,72.0):
                SurvivorModels.building(node,kind)
        elif kind == "house":
            # Real timber prefab is decorative. Gameplay footprint, placement,
            # doorway logic, save and progression stay owned by SurvivorWorld.
            if not SurvivorRealWorldAssets.attach(node,"garden_shed",4.15,110.0):
                SurvivorModels.building(node,kind)
            var ladder := Node3D.new()
            ladder.name = "Nature_HouseLadder"
            ladder.position = Vector3(2.45,0.0,1.55)
            ladder.rotation.y = 0.2
            node.add_child(ladder)
            SurvivorRealWorldAssets.attach(ladder,"wooden_ladder_02",2.35,56.0)
        else:
            SurvivorModels.building(node,kind)
    if kind not in ["campfire","boat"]:
        SurvivorModels.merge_static(node,"building_"+kind)
    node.set_meta("visual_bounds",structure_bounds(node))
    footprint_cache[kind] = node.get_meta("visual_bounds")
    if preview_mode:
        for light in node.find_children("*","Light3D",true,false):
            light.visible = false

func structure_bounds(node: Node3D) -> AABB:
    var first := true
    var bounds := AABB()
    for item in node.find_children("*","MeshInstance3D",true,false):
        var mesh_node := item as MeshInstance3D
        if mesh_node.mesh==null:
            continue
        var transform := SurvivorWorldAssetRenderer.relative_transform(mesh_node,node)
        var current := transform*mesh_node.mesh.get_aabb()
        bounds = current if first else bounds.merge(current)
        first = false
    return bounds

func footprint_radius(kind: String) -> float:
    if not footprint_cache.has(kind):
        var probe := Node3D.new()
        probe.visible = false
        add_child(probe)
        build_structure_visual(probe,kind,1,true)
        remove_child(probe)
        probe.free()
    var bounds: AABB = footprint_cache[kind]
    return maxf(bounds.size.x,bounds.size.z)*0.5+0.20
