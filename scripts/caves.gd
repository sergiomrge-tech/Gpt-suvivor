extends Node3D
class_name SurvivorCaves

# Cavernas em setores separados do mundo para manter a ilha original intacta.
# Os bolsões ficam fora da costa e só podem ser alcançados pelos portais.
const CENTERS := {"east": Vector3(800.0, 0.0, 0.0), "roots": Vector3(-800.0, 0.0, 0.0)}
const CACHE_INFO := {
    "east_scrap": {"cave":"east", "local":Vector3(-8.5,0.0,-6.0), "title":"Ferragens na galeria", "text":"Junto a um lampião apagado, restos de uma expedição antiga. Entre rochas úmidas, você recolhe metal e pedras que ainda podem servir ao barco.", "reward":{"metal":6,"stone":4}},
    "east_provisions": {"cave":"east", "local":Vector3(9.0,0.0,-7.5), "title":"Caixa protegida da chuva", "text":"Uma pequena caixa esquecida na rocha guarda tábuas e cordas secas. Uma marca aponta para uma abertura acima da maré.", "reward":{"plank":4,"rope":4}},
    "roots_cache": {"cave":"roots", "local":Vector3(-9.0,0.0,-5.0), "title":"Abrigo entre raízes", "text":"Sob as raízes, alguém escondeu uma reserva de fibras e alimentos. A caverna também foi abrigo de outros sobreviventes.", "reward":{"fiber":12,"coconut":3}},
    "roots_ore": {"cave":"roots", "local":Vector3(8.5,0.0,-8.0), "title":"Veio de minério", "text":"O fundo da gruta esconde pequenos fragmentos de metal entre as pedras. Você recolhe somente as peças soltas.", "reward":{"metal":4,"stone":5}},
    "east_deep_cache": {"cave":"east", "local":Vector3(-9.0,0,-28.0), "title":"Bolsa do explorador", "text":"No fundo da galeria, um antigo kit de escalada contém cordas, suprimentos e ferramentas de metal.", "reward":{"rope":4,"metal":3,"coconut":2}},
    "roots_deep_cache": {"cave":"roots", "local":Vector3(9.0,0,-28.0), "title":"Depósito sob as raízes", "text":"A pedra esconde um estoque esquecido de tábuas e alimentos preservados.", "reward":{"plank":5,"coconut":2,"fiber":5}}
}
const VEINS := {
    "east_vein_1":{"cave":"east","local":Vector3(-13,0,-25),"reward":{"cave_crystal":1,"stone":4}},
    "east_vein_2":{"cave":"east","local":Vector3(12,0,-31),"reward":{"cave_crystal":1,"metal":3}},
    "roots_vein_1":{"cave":"roots","local":Vector3(-13,0,-25),"reward":{"cave_crystal":1,"stone":4}},
    "roots_vein_2":{"cave":"roots","local":Vector3(12,0,-31),"reward":{"cave_crystal":1,"metal":3}}
}
const HAZARD_POINTS := {"east":Vector2(0,-24),"roots":Vector2(0,-24)}
const WIDTH := 17.0
const DEPTH := 13.0
var state: SurvivalState
var rooms: Dictionary = {}
var caches: Array[Dictionary] = []
var veins: Array[Dictionary] = []
var puzzles: SurvivorCavePuzzles

static func cave_at(pos: Vector3) -> String:
    for id in CENTERS:
        var center: Vector3 = CENTERS[id]
        if absf(pos.x-center.x) < 19.0 and pos.z-center.z > -39.0 and pos.z-center.z < 16.0:
            return str(id)
    return ""

static func is_cave_position(pos: Vector3) -> bool:
    return cave_at(pos) != ""

static func entrance_id(title: String) -> String:
    match title:
        "Caverna do Leste": return "east"
        "Gruta das raízes": return "roots"
    return ""

static func spawn_position(id: String) -> Vector3:
    if not CENTERS.has(id):
        return Vector3.ZERO
    return CENTERS[id] + Vector3(0.0, 0.0, 7.0)

static func exit_position(id: String) -> Vector3:
    if not CENTERS.has(id):
        return Vector3.ZERO
    return CENTERS[id] + Vector3(0.0, 0.0, 10.5)

func generate() -> void:
    for id in CENTERS:
        var node := Node3D.new()
        node.name = "Cave_" + str(id)
        node.position = CENTERS[id]
        add_child(node)
        rooms[id] = node
        _model_room(node, str(id))
    for id in CACHE_INFO:
        var info: Dictionary = CACHE_INFO[id]
        var owner: Node3D = rooms[info.cave]
        var cache := Node3D.new()
        cache.name = "Cache_" + str(id)
        cache.position = info.local
        cache.visible = not bool(state.discoveries.get(id,false))
        owner.add_child(cache)
        _model_cache(cache, str(id))
        caches.append({"kind":"cave_cache","id":id,"cave":info.cave,"title":info.title,
            "position":owner.to_global(info.local),"node":cache,"radius":0.9})
    for id in VEINS:
        var info: Dictionary = VEINS[id]
        var owner: Node3D = rooms[info.cave]
        var node := Node3D.new()
        node.position = info.local
        node.name = "Vein_" + str(id)
        node.visible = not bool(state.discoveries.get(id,false))
        owner.add_child(node)
        SurvivorModels.rock(node,23,0.72)
        for i in range(5):
            var angle := TAU*float(i)/5.0
            SurvivorModels.stone(node,0.32,i+33,Color(0.22,0.65,0.71),Vector3(cos(angle)*0.65,0.72,sin(angle)*0.65),Vector3(0.6,1.5,0.7))
        SurvivorModels.merge_static(node,"deep_vein_"+str(info.cave))
        veins.append({"kind":"cave_vein","id":id,"cave":info.cave,"title":"Veio cristalino","position":owner.to_global(info.local),"node":node,"radius":0.95})
    puzzles = SurvivorCavePuzzles.new()
    puzzles.state = state
    add_child(puzzles)
    puzzles.generate()

func _model_room(room: Node3D, id: String) -> void:
    var rock := Color(0.22,0.25,0.27) if id == "east" else Color(0.25,0.23,0.19)
    var damp := Color(0.30,0.33,0.31) if id == "east" else Color(0.32,0.30,0.22)
    SurvivorModels.box(room, Vector3(37.0,0.7,30.0),Color(0.20,0.22,0.20),Vector3(0,-0.40,0))
    # Corte superior aberto: é possível visualizar o personagem com a câmera top-down.
    for i in range(20):
        if i in [7,8,9,10,11,12]:
            continue # 11 m wide gallery opening to the actual back chamber.
        var x := -18.0 + i * 1.9
        var h := 3.1 + 1.0 * sin(float(i)*2.0)
        SurvivorModels.sphere(room,2.15,rock,Vector3(x,h*0.40,-15.0),Vector3(0.65,h*0.47,0.90))
        SurvivorModels.sphere(room,1.25,damp,Vector3(x,0.20,-13.9),Vector3(1.1,0.65,0.8))
    for side in [-1.0,1.0]:
        for i in range(12):
            var z := -14.0 + i*2.6
            var h := 2.2 + absf(sin(float(i)*1.7))*2.0
            SurvivorModels.sphere(room,2.0,rock,Vector3(side*18.1,h*0.38,z),Vector3(0.75,h*0.53,0.90))
        for i in range(5):
            var x: float = float(side)*(2.8+float(i)*3.0)
            SurvivorModels.sphere(room,1.2,damp,Vector3(x,0.15,14.1),Vector3(1.2,0.6,0.9))
    for pos in [Vector3(0,0,-4),Vector3(-12,0,2),Vector3(12,0,3)]:
        SurvivorModels.sphere(room,1.9,rock,pos+Vector3(0,0.75,0),Vector3(1.0,0.82,0.88))
        SurvivorModels.sphere(room,0.62,damp,pos+Vector3(0,1.6,0),Vector3(0.72,0.9,0.72))
    if id == "roots":
        for i in range(8):
            var z := -11.0 + i*3.0
            SurvivorModels.beam(room,Vector3(-17,3.5,z),Vector3(-12,0.25,z-1.5),0.35,Color(0.32,0.21,0.10))
    else:
        for i in range(11):
            var x := -14.0 + i*2.8
            SurvivorModels.sphere(room,0.32,Color(0.17,0.58,0.65),Vector3(x,0.35,-12.5),Vector3(0.7,1.4,0.7))
    _model_deep_chamber(room,id,rock,damp)
    # Luz própria, sem sombras móveis extras no aparelho.
    for item in [[Vector3(-9,4,-5),Color(0.48,0.74,1.0)],[Vector3(8,4,3),Color(1.0,0.69,0.36)]]:
        var lamp := OmniLight3D.new()
        lamp.position = item[0]
        lamp.light_color = item[1]
        lamp.light_energy = 1.4
        lamp.omni_range = 25.0
        lamp.shadow_enabled = false
        room.add_child(lamp)
    SurvivorModels.merge_static(room,"cave_" + id)

func _model_deep_chamber(room: Node3D,id: String,rock: Color,damp: Color) -> void:
    # Connected back chamber extends south through a real opening. Keeps original
    # entrance, previous save coordinates and first four cache positions intact.
    var floor_color := Color(0.18,0.21,0.22) if id == "east" else Color(0.20,0.20,0.17)
    SurvivorModels.box(room,Vector3(35.5,0.68,26.5),floor_color,Vector3(0,-0.40,-25.8))
    for i in range(19):
        var x := -17.5+float(i)*1.95
        SurvivorModels.stone(room,1.6,i+12,rock,Vector3(x,1.12,-38.5),Vector3(0.85,1.6,0.85))
    for side in [-1.0,1.0]:
        for i in range(10):
            var z := -37.2+float(i)*2.4
            SurvivorModels.stone(room,1.6,i+22,damp,Vector3(side*18.0,0.80,z),Vector3(0.9,1.15,1.25))
        for i in range(4):
            var z := -34.0+float(i)*5.2
            if id == "roots":
                SurvivorModels.beam(room,Vector3(side*17.5,3.6,z),Vector3(side*13.5,0.2,z+2),0.28,Color(0.30,0.21,0.11))
            else:
                SurvivorModels.stone(room,0.60,i+31,Color(0.17,0.42,0.49),Vector3(side*14,0.45,z),Vector3(0.8,1.5,0.7))
    # Distinct purple mineral gases and spore mounds visibly mark risk areas.
    for i in range(6):
        var angle := TAU*float(i)/6.0
        SurvivorModels.stone(room,0.42,34+i,Color(0.55,0.29,0.47) if id == "east" else Color(0.56,0.56,0.22),
            Vector3(cos(angle)*2.2,0.26,sin(angle)*2.2-24.0),Vector3(0.8,1.3,0.8))
    # Rock arches and pointed crystal clusters introduce a readable deep biome.
    for z in [-19.0,-31.0]:
        for side in [-1.0,1.0]:
            SurvivorModels.stone(room,1.2,int(z)+int(side*5)+60,rock,Vector3(side*6.3,1.05,z),Vector3(0.75,1.7,0.9))
        for i in range(4):
            var x := -4.6+float(i)*3.1
            SurvivorModels.stone(room,0.30,i+14,Color(0.21,0.56,0.64) if id == "east" else Color(0.49,0.60,0.27),
                Vector3(x,0.35,z+float(i%2)*0.70),Vector3(0.65,1.8,0.65))
    var light := OmniLight3D.new()
    light.position = Vector3(0,3.6,-27.0)
    light.light_color = Color(0.30,0.68,0.77) if id == "east" else Color(0.68,0.58,0.34)
    light.light_energy = 0.8
    light.omni_range = 21.0
    light.shadow_enabled = false
    room.add_child(light)

func _model_cache(node: Node3D, id: String) -> void:
    SurvivorModels.box(node,Vector3(1.5,0.75,1.05),Color(0.32,0.20,0.10),Vector3(0,0.43,0))
    for x in [-0.6,0.6]:
        SurvivorModels.box(node,Vector3(0.10,0.82,1.13),Color(0.58,0.46,0.23),Vector3(x,0.45,0))
    SurvivorModels.box(node,Vector3(1.55,0.12,1.13),Color(0.59,0.42,0.20),Vector3(0,0.85,0))
    SurvivorModels.sphere(node,0.17,Color(0.31,0.81,0.88) if id.begins_with("east") else Color(0.86,0.73,0.33),Vector3(0,1.18,0))
    SurvivorModels.merge_static(node,"cache_"+id)

func hazard_rate_at(pos: Vector3) -> float:
    var cave_id := cave_at(pos)
    if cave_id == "":
        return 0.0
    var local: Vector3 = pos-CENTERS[cave_id]
    if Vector2(local.x,local.z).distance_to(HAZARD_POINTS[cave_id]) < 2.8:
        return 1.2 if cave_id == "east" else 1.65
    return 0.0

func is_inside(pos: Vector3) -> bool:
    return is_cave_position(pos)

func is_walkable(pos: Vector3) -> bool:
    if not is_inside(pos):
        return false
    var id := cave_at(pos)
    var local: Vector3 = pos-CENTERS[id]
    if absf(local.x) > WIDTH-0.7 or local.z > DEPTH-0.7 or local.z < -35.7:
        return false
    for obstacle in [Vector2(0,-4),Vector2(-12,2),Vector2(12,3)]:
        if Vector2(local.x,local.z).distance_to(obstacle) < 2.1:
            return false
    return true

func nearest_target(pos: Vector3, reach: float = 5.0) -> Dictionary:
    var id := cave_at(pos)
    if id == "":
        return {}
    var best: Dictionary = {}
    var limit := reach
    var exit_at := exit_position(id)
    var exit_distance := Vector2(pos.x-exit_at.x,pos.z-exit_at.z).length()
    if exit_distance < limit:
        best = {"kind":"cave_exit","id":id,"position":exit_at,"node":rooms[id],"title":"Voltar à superfície"}
        limit = exit_distance
    for cache in caches:
        if str(cache.cave) != id or not cache.node.visible:
            continue
        var d := Vector2(pos.x-cache.position.x,pos.z-cache.position.z).length()
        if d < limit:
            limit = d
            best = cache
    for vein in veins:
        if str(vein.cave) != id or not vein.node.visible:
            continue
        var reach_distance := Vector2(pos.x-vein.position.x,pos.z-vein.position.z).length()
        if reach_distance < limit:
            limit = reach_distance
            best = vein
    if puzzles != null:
        var mechanism := puzzles.nearest_target(pos,limit)
        if not mechanism.is_empty():
            best = mechanism
    return best

func extract_vein(entry: Dictionary) -> Dictionary:
    var id := str(entry.get("id",""))
    if not VEINS.has(id) or bool(state.discoveries.get(id,false)):
        return {}
    if not state.is_equipped("reinforced_pickaxe"):
        return {}
    state.discoveries[id] = true
    entry.node.visible = false
    var info: Dictionary = VEINS[id]
    for item in info.reward:
        state.add_item(str(item),int(info.reward[item]))
    return {"title":"Minério cristalino extraído","text":"A picareta reforçada abriu um veio mineral raro nas profundezas da ilha.","reward":info.reward.duplicate(true)}

func collect_cache(entry: Dictionary) -> Dictionary:
    var id := str(entry.get("id",""))
    if not CACHE_INFO.has(id) or bool(state.discoveries.get(id,false)) or not is_instance_valid(entry.get("node")) or not entry.node.visible:
        return {}
    var info: Dictionary = CACHE_INFO[id]
    state.discoveries[id] = true
    entry.node.visible = false
    for item in info.reward:
        state.add_item(item,int(info.reward[item]))
    return {"title":info.title,"text":info.text,"reward":info.reward.duplicate(true)}
