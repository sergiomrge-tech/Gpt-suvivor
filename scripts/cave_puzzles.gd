extends Node3D
class_name SurvivorCavePuzzles

# Environmental exploration loop inspired by layered survival progression:
# examine two seals in each grotto to open one rare resource cache.
# Every collected flag lives in existing v3 discoveries, without schema changes.
const SEALS := {
    "east_amber": {"cave":"east", "local":Vector3(-7,0,6), "title":"Selo âmbar"},
    "east_blue": {"cave":"east", "local":Vector3(7,0,-2), "title":"Selo azul"},
    "roots_amber": {"cave":"roots", "local":Vector3(-7,0,6), "title":"Selo das raízes"},
    "roots_blue": {"cave":"roots", "local":Vector3(7,0,-2), "title":"Selo mineral"}
}
const VAULTS := {
    "east_vault": {"cave":"east", "local":Vector3(0,0,-10),
        "title":"Relicário da maré",
        "text":"Os dois selos liberam um relicário de pedra. Você encontra um cristal que pode aprimorar a oficina do acampamento e ferragens preservadas.",
        "reward":{"cave_crystal":1,"metal":2}},
    "roots_vault": {"cave":"roots", "local":Vector3(0,0,-10),
        "title":"Relicário das raízes",
        "text":"A trava de pedra se abre. Minerais luminosos e fibras protegidas da umidade esperavam outro explorador.",
        "reward":{"cave_crystal":1,"fiber":4}}
}
var state: SurvivalState
var mechanisms: Array[Dictionary] = []

func generate() -> void:
    for id in SEALS:
        var info: Dictionary = SEALS[id]
        var node := Node3D.new()
        node.name = "Seal_" + str(id)
        node.position = SurvivorCaves.CENTERS[info.cave] + info.local
        add_child(node)
        _model_seal(node,bool(state.discoveries.get(id,false)))
        mechanisms.append({"kind":"cave_seal","id":id,"cave":info.cave,"title":info.title,
            "position":node.position,"node":node,"radius":0.8})
    for id in VAULTS:
        var info: Dictionary = VAULTS[id]
        var node := Node3D.new()
        node.name = "Vault_" + str(id)
        node.position = SurvivorCaves.CENTERS[info.cave] + info.local
        node.visible = not bool(state.discoveries.get(id,false))
        add_child(node)
        _model_vault(node,str(id))
        mechanisms.append({"kind":"cave_vault","id":id,"cave":info.cave,"title":info.title,
            "position":node.position,"node":node,"radius":1.1})

func _model_seal(node: Node3D,active: bool) -> void:
    SurvivorModels.stone(node,0.8,2,Color(0.35,0.37,0.34),Vector3(0,0.48,0),Vector3(0.90,0.64,0.9))
    for i in range(4):
        var angle := float(i)*TAU/4.0
        SurvivorModels.beam(node,Vector3(cos(angle)*0.57,0.45,sin(angle)*0.57),
            Vector3(cos(angle)*0.46,1.05,sin(angle)*0.46),0.09,Color(0.66,0.51,0.30))
    SurvivorModels.merge_static(node,"cave_puzzle_seal_base")
    var gem := SurvivorModels.sphere(node,0.30,
        Color(0.36,0.94,0.76) if active else Color(0.42,0.44,0.40),
        Vector3(0,1.20,0),Vector3(0.82,1.20,0.82))
    gem.name = "Gem"

func _model_vault(node: Node3D,id: String) -> void:
    var stone_color := Color(0.32,0.36,0.40) if id.begins_with("east") else Color(0.38,0.33,0.27)
    SurvivorModels.box(node,Vector3(2.45,0.75,1.70),stone_color,Vector3(0,0.40,0))
    for side in [-1.0,1.0]:
        SurvivorModels.beam(node,Vector3(side*0.95,0.85,-0.73),
            Vector3(side*0.95,1.30,0.73),0.085,Color(0.70,0.56,0.33))
    for i in range(5):
        var angle := float(i)*TAU/5.0
        SurvivorModels.stone(node,0.37,i,Color(0.24,0.65,0.77),
            Vector3(cos(angle)*0.50,1.00+float(i%2)*0.12,sin(angle)*0.36),
            Vector3(0.67,1.50,0.65))
    SurvivorModels.merge_static(node,"cave_puzzle_vault_"+id)

func nearest_target(pos: Vector3,reach: float = 5.0) -> Dictionary:
    var cave_id := SurvivorCaves.cave_at(pos)
    if cave_id == "":
        return {}
    var closest := reach
    var result: Dictionary = {}
    for entry in mechanisms:
        if str(entry.cave) != cave_id or bool(state.discoveries.get(entry.id,false)):
            continue
        var distance := Vector2(entry.position.x-pos.x,entry.position.z-pos.z).length()
        if distance < closest:
            closest = distance
            result = entry
    return result

func vault_unlocked(id: String) -> bool:
    if not VAULTS.has(id):
        return false
    var cave_id: String = VAULTS[id].cave
    return bool(state.discoveries.get(cave_id+"_amber",false)) and bool(state.discoveries.get(cave_id+"_blue",false))

func activate_seal(entry: Dictionary) -> String:
    var id := str(entry.get("id",""))
    if not SEALS.has(id) or bool(state.discoveries.get(id,false)):
        return "Este selo já foi ativado."
    state.discoveries[id] = true
    var gem: MeshInstance3D = entry.node.get_node_or_null("Gem")
    if gem != null:
        gem.material_override = SurvivorModels.material(Color(0.36,0.94,0.76))
    return "Selo ativado! Encontre o segundo selo para abrir o relicário."

func collect_vault(entry: Dictionary) -> Dictionary:
    var id := str(entry.get("id",""))
    if not VAULTS.has(id) or not vault_unlocked(id) or bool(state.discoveries.get(id,false)):
        return {}
    var info: Dictionary = VAULTS[id]
    state.discoveries[id] = true
    entry.node.visible = false
    for item in info.reward:
        state.add_item(str(item),int(info.reward[item]))
    return {"title":info.title,"text":info.text,"reward":info.reward.duplicate(true)}
