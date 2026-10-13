extends Node3D
class_name SurvivorCaves

# Cavernas em setores separados do mundo para manter a ilha original intacta.
# Os bolsões ficam fora da costa e só podem ser alcançados pelos portais.
const CENTERS := {"east": Vector3(800.0, 0.0, 0.0), "roots": Vector3(-800.0, 0.0, 0.0)}
const CACHE_INFO := {
    "east_scrap": {"cave":"east", "local":Vector3(-8.5,0.0,-6.0), "title":"Ferragens na galeria", "text":"Junto a um lampião apagado, restos de uma expedição antiga. Entre rochas úmidas, você recolhe metal e pedras que ainda podem servir ao barco.", "reward":{"metal":6,"stone":4}},
    "east_provisions": {"cave":"east", "local":Vector3(9.0,0.0,-7.5), "title":"Caixa protegida da chuva", "text":"Uma pequena caixa esquecida na rocha guarda tábuas e cordas secas. Uma marca aponta para uma abertura acima da maré.", "reward":{"plank":4,"rope":4}},
    "roots_cache": {"cave":"roots", "local":Vector3(-9.0,0.0,-5.0), "title":"Abrigo entre raízes", "text":"Sob as raízes, alguém escondeu uma reserva de fibras e alimentos. A caverna também foi abrigo de outros sobreviventes.", "reward":{"fiber":12,"coconut":3}},
    "roots_ore": {"cave":"roots", "local":Vector3(8.5,0.0,-8.0), "title":"Veio de minério", "text":"O fundo da gruta esconde pequenos fragmentos de metal entre as pedras. Você recolhe somente as peças soltas.", "reward":{"metal":4,"stone":5}}
}
const WIDTH := 17.0
const DEPTH := 13.0
var state: SurvivalState
var rooms: Dictionary = {}
var caches: Array[Dictionary] = []
var puzzles: SurvivorCavePuzzles

static func cave_at(pos: Vector3) -> String:
    for id in CENTERS:
        var center: Vector3 = CENTERS[id]
        if absf(pos.x-center.x) < 19.0 and absf(pos.z-center.z) < 16.0:
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

func _model_cache(node: Node3D, id: String) -> void:
    SurvivorModels.box(node,Vector3(1.5,0.75,1.05),Color(0.32,0.20,0.10),Vector3(0,0.43,0))
    for x in [-0.6,0.6]:
        SurvivorModels.box(node,Vector3(0.10,0.82,1.13),Color(0.58,0.46,0.23),Vector3(x,0.45,0))
    SurvivorModels.box(node,Vector3(1.55,0.12,1.13),Color(0.59,0.42,0.20),Vector3(0,0.85,0))
    SurvivorModels.sphere(node,0.17,Color(0.31,0.81,0.88) if id.begins_with("east") else Color(0.86,0.73,0.33),Vector3(0,1.18,0))
    SurvivorModels.merge_static(node,"cache_"+id)

func is_inside(pos: Vector3) -> bool:
    return is_cave_position(pos)

func is_walkable(pos: Vector3) -> bool:
    if not is_inside(pos):
        return false
    var id := cave_at(pos)
    var local: Vector3 = pos-CENTERS[id]
    if absf(local.x) > WIDTH-0.7 or absf(local.z) > DEPTH-0.7:
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
    if puzzles != null:
        var mechanism := puzzles.nearest_target(pos,limit)
        if not mechanism.is_empty():
            best = mechanism
    return best

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
