extends RefCounted
class_name SurvivalState

const SAVE_VERSION := 1
const DAY_SECONDS := 1200.0
const START_POSITION := Vector3(0.0, 0.0, 170.0)
const ITEMS := {"wood": "Madeira", "stone": "Pedra", "fiber": "Fibra", "metal": "Metal", "coconut": "Coco", "raw_fish": "Peixe cru", "meal": "Peixe assado"}
const RECIPES := {
    "campfire": {"title": "Fogueira", "cost": {"wood": 10, "stone": 6}, "requires": [], "description": "Asse peixes e ilumine o acampamento."},
    "workbench": {"title": "Bancada", "cost": {"wood": 16, "stone": 8}, "requires": ["campfire"], "description": "Libera ferramentas e construção avançada."},
    "fishing_rod": {"title": "Vara de pesca", "cost": {"wood": 6, "fiber": 8}, "requires": ["workbench"], "description": "Pesque na costa ou no cais."},
    "house": {"title": "Casa", "cost": {"wood": 30, "stone": 10, "fiber": 10}, "requires": ["workbench"], "description": "Abrigo para descansar e recuperar saúde."},
    "dock": {"title": "Cais", "cost": {"wood": 20, "fiber": 10}, "requires": ["workbench"], "description": "Construa na praia. Ponto de pesca e embarque."},
    "boat": {"title": "Barco de fuga", "cost": {"wood": 60, "fiber": 20, "metal": 8}, "requires": ["house", "dock", "fishing_rod"], "description": "Construa junto ao cais e parta da ilha."},
    "meal": {"title": "Assar peixe", "cost": {"raw_fish": 1}, "requires": ["campfire"], "description": "Prepare na fogueira. Recupera 38 de fome."}
}
var inventory: Dictionary = {"wood": 0, "stone": 0, "fiber": 0, "metal": 0, "coconut": 2, "raw_fish": 0, "meal": 0, "fishing_rod": 0}
var buildings: Array[Dictionary] = []
var harvested: Dictionary = {}
var discoveries: Dictionary = {}
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var elapsed := 0.0
var escaped := false
var player_position := START_POSITION

func has_structure(kind: String) -> bool:
    for entry in buildings:
        if entry.get("kind") == kind:
            return true
    return false

func owns(kind: String) -> bool:
    if kind == "fishing_rod":
        return int(inventory.get(kind, 0)) > 0
    return has_structure(kind)

func recipe_error(kind: String) -> String:
    if not RECIPES.has(kind):
        return "Receita desconhecida."
    if kind != "meal" and owns(kind):
        return "Você já possui esse item."
    var recipe: Dictionary = RECIPES[kind]
    for requirement in recipe.requires:
        if not owns(requirement):
            return "Primeiro: %s." % RECIPES[requirement].title
    for item in recipe.cost:
        if int(inventory.get(item, 0)) < int(recipe.cost[item]):
            return "Faltam recursos: %s." % ITEMS.get(item, item)
    return ""

func pay_recipe(kind: String) -> bool:
    if recipe_error(kind) != "":
        return false
    for item in RECIPES[kind].cost:
        inventory[item] = int(inventory.get(item, 0)) - int(RECIPES[kind].cost[item])
    return true

func add_item(kind: String, count: int) -> void:
    inventory[kind] = int(inventory.get(kind, 0)) + count

func consume() -> String:
    if int(inventory.meal) > 0 and hunger < 99.0:
        inventory.meal -= 1
        hunger = minf(100.0, hunger + 38.0)
        health = minf(100.0, health + 6.0)
        return "Peixe assado: +38 de fome."
    if int(inventory.coconut) > 0 and (thirst < 99.0 or hunger < 99.0):
        inventory.coconut -= 1
        hunger = minf(100.0, hunger + 15.0)
        thirst = minf(100.0, thirst + 30.0)
        return "Coco: +30 de água e +15 de fome."
    return "Sem alimento pronto ou necessidades já cheias."

func advance(delta: float) -> void:
    elapsed += delta
    if elapsed < 180.0 or escaped or health <= 0.0:
        return
    hunger = maxf(0.0, hunger - delta * 0.045)
    thirst = maxf(0.0, thirst - delta * 0.065)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 0.6)
    elif hunger > 65.0 and thirst > 65.0:
        health = minf(100.0, health + delta * 0.04)

func objective() -> String:
    if escaped:
        return "Você sobreviveu e deixou a ilha!"
    if not owns("campfire"):
        return "1/6 • Reúna 10 madeiras e 6 pedras. Construa uma fogueira."
    if not owns("workbench"):
        return "2/6 • Construa a bancada: 16 madeiras + 8 pedras."
    if not owns("fishing_rod"):
        return "3/6 • Faça a vara: 6 madeiras + 8 fibras. Pesque na costa."
    if not owns("house"):
        return "4/6 • Construa sua casa e estabeleça um acampamento."
    if not owns("dock"):
        return "5/6 • Monte um cais na praia. Procure metal nos destroços e cavernas."
    if not owns("boat"):
        return "6/6 • Construa o barco junto ao cais: 60 madeiras, 20 fibras, 8 metais."
    return "O barco está pronto! Aproxime-se e toque em Embarcar."

func to_data() -> Dictionary:
    return {"version": SAVE_VERSION, "inventory": inventory, "buildings": buildings, "harvested": harvested, "discoveries": discoveries, "health": health, "hunger": hunger, "thirst": thirst, "elapsed": elapsed, "escaped": escaped, "position": [player_position.x, player_position.z]}

static func from_data(data: Dictionary) -> SurvivalState:
    if int(data.get("version", 0)) != SAVE_VERSION:
        return null
    var state := SurvivalState.new()
    var inv = data.get("inventory", {})
    if not inv is Dictionary:
        return null
    for key in state.inventory.keys():
        var value = inv.get(key, 0)
        if not (value is int or value is float) or not is_finite(float(value)):
            return null
        state.inventory[key] = clampi(int(value), 0, 100000)
    for stat in ["health", "hunger", "thirst", "elapsed"]:
        var value = data.get(stat, 100.0 if stat != "elapsed" else 0.0)
        if not (value is int or value is float) or not is_finite(float(value)):
            return null
        state.set(stat, clampf(float(value), 0.0, 100.0 if stat != "elapsed" else 10000000.0))
    var coords = data.get("position", [0.0, 170.0])
    if not coords is Array or coords.size() != 2:
        return null
    for coord in coords:
        if not (coord is int or coord is float) or not is_finite(float(coord)):
            return null
    state.player_position = Vector3(clampf(float(coords[0]), -220.0, 220.0), 0, clampf(float(coords[1]), -220.0, 220.0))
    var entries = data.get("buildings", [])
    if not entries is Array or entries.size() > 20:
        return null
    for entry in entries:
        if not entry is Dictionary or not RECIPES.has(str(entry.get("kind", ""))):
            return null
        var kind := str(entry.kind)
        if kind in ["meal", "fishing_rod"] or state.has_structure(kind):
            return null
        for axis in ["x", "z"]:
            var value = entry.get(axis)
            if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 240.0:
                return null
        state.buildings.append({"kind": kind, "x": float(entry.x), "z": float(entry.z)})
    var gathered = data.get("harvested", {})
    if not gathered is Dictionary or gathered.size() > 2000:
        return null
    for key in gathered:
        var value = gathered[key]
        if not (value is int or value is float) or not is_finite(float(value)):
            return null
        state.harvested[str(key)] = maxf(0.0, float(value))
    var discovered = data.get("discoveries",{})
    if not discovered is Dictionary or discovered.size()>128:
        return null
    for id in discovered:
        if not discovered[id] is bool:
            return null
        state.discoveries[str(id)] = discovered[id]
    state.escaped = bool(data.get("escaped", false)) and state.has_structure("boat")
    return state
