extends Node3D
class_name SurvivorWorld

var terrain: SurvivorTerrain
var state: SurvivalState
var resources: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _refresh_clock := 0.0
var scenery: SurvivorScenery
var trails: SurvivorTrails
var discoverables: Array[Dictionary] = []
const DISCOVERIES := {
    "pilot_bag":{"title":"A mochila do piloto","text":"Entre os destroços, você encontra uma mochila com suprimentos secos e uma anotação: água doce deve existir onde a vegetação fica mais densa. O piloto havia marcado uma nascente a oeste da praia.","point":Vector2(-4,172),"reward":{"wood":4,"fiber":3}},
    "cave_note":{"title":"Marcas na rocha","text":"Um pequeno diário descreve uma antiga passagem por esta ilha. A última página fala de rochas com peças metálicas presas entre as raízes e de uma praia ampla, boa para montar uma embarcação. A tinta está gasta, mas a esperança continua legível.","point":Vector2(78,24),"reward":{"metal":2}},
    "tool_crate":{"title":"Ferramentas esquecidas","text":"A caixa guardava ferragens e cordas. Quem esteve aqui também tentou construir alguma coisa. Você reaproveita o que resistiu à umidade e deixa uma marca no diário: desta vez, o barco vai chegar ao mar.","point":Vector2(-88,-53),"reward":{"metal":2,"fiber":5}}
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
    _spawn_discoveries()
    scenery = SurvivorScenery.new()
    scenery.terrain = terrain
    scenery.world = self
    add_child(scenery)
    scenery.generate()

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
            SurvivorModels.palm(node, variant)
            radius = 0.8
        "tree":
            SurvivorModels.canopy_tree(node,variant)
            radius = 1.1
        "rock":
            SurvivorModels.rock(node, variant)
            radius = 1.7
        "fiber":
            SurvivorModels.fern(node,variant)
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
            SurvivorModels.wreck(node)
        "cave":
            SurvivorModels.cave(node)
        "spring":
            for i in range(9):
                SurvivorModels.sphere(node, 0.6, Color(0.32, 0.42, 0.36), Vector3(cos(i * TAU / 9) * 2.4, 0.18, sin(i * TAU / 9) * 2.4))
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
    add_child(node)
    SurvivorModels.building(node, entry.kind)
    if entry.kind != "campfire":
        SurvivorModels.merge_static(node, "building_" + str(entry.kind))
    structures.append({"kind": entry.kind, "node": node, "position": node.position})
    if scenery != null:
        scenery.clear_area(node.position, 5.0 if entry.kind == "house" else 2.8)
    return node

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
        entry.node.visible = ready_time < 0.0 or (entry.kind != "metal" and state.elapsed >= ready_time)

func harvest(entry: Dictionary) -> String:
    if not is_instance_valid(entry.get("node")) or not entry.node.visible:
        return "Esse recurso já foi coletado."
    var result := ""
    match entry.kind:
        "palm":
            state.add_item("wood", 8)
            state.add_item("coconut", 2)
            result = "+8 madeiras • +2 cocos"
        "tree":
            state.add_item("wood",8)
            state.add_item("fiber",2)
            result = "+8 madeiras • +2 fibras"
        "rock":
            state.add_item("stone", 6)
            result = "+6 pedras"
        "fiber":
            state.add_item("fiber", 5)
            result = "+5 fibras"
        "metal":
            state.add_item("metal", 4)
            result = "+4 metais recuperados"
    state.harvested[entry.id] = state.elapsed + 600.0
    entry.node.visible = false
    return result

func nearest_target(pos: Vector3, reach: float = 5.0) -> Dictionary:
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
        if entry.kind in ["wreck", "cave", "workbench", "dock"]:
            continue
        var d := Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length()
        # Boat is placed off the shore; it remains reachable from the dock.
        var max_reach := 10.0 if entry.kind == "boat" else reach
        if d < max_reach and (result.is_empty() or d < distance):
            distance = d
            result = entry
    return result

func near_structure(pos: Vector3, kind: String, reach: float = 12.0) -> Dictionary:
    for entry in structures:
        if entry.kind == kind and Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < reach:
            return entry
    return {}

func walkable(pos: Vector3, previous: Vector3) -> bool:
    if not terrain.is_land(pos.x, pos.z) and not is_on_dock(pos):
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
        var local: Vector3 = pos - entry.position
        if entry.kind == "workbench" and absf(local.x) < 1.9 and absf(local.z) < 1.1:
            return false
        if entry.kind == "house":
            if absf(local.x) < 3.2 and absf(local.z) < 3.2:
                if absf(local.x) > 2.15 or local.z < -2.15 or local.z > 2.15 and absf(local.x) > 0.65:
                    return false
    return true

func placement_error(kind: String, pos: Vector3, player_pos: Vector3) -> String:
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
    if kind == "dock" and not terrain.is_shore(pos.x, pos.z):
        return "O cais precisa ficar na faixa de areia junto ao mar."
    var radius := 4.5 if kind == "house" else 2.4
    for entry in resources:
        if entry.node.visible and entry.radius > 0 and Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < radius + float(entry.radius):
            return "Limpe os recursos desse local antes de construir."
    for entry in structures:
        if Vector2(pos.x - entry.position.x, pos.z - entry.position.z).length() < radius + (4.5 if entry.kind == "house" else 2.4):
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
    var ground := terrain.height_at(pos.x,pos.z)
    var local := dock_local(pos)
    if is_finite(local.y):
        var blend := 1-smoothstep(0.25,1.8,local.z)
        return maxf(ground,lerpf(ground,local.y,blend))
    return ground
