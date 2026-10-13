extends RefCounted
class_name SurvivalState

const SAVE_VERSION := 3
const TOOLS := ["stone_knife", "stone_axe", "stone_pickaxe", "stone_spear", "fishing_rod", "reinforced_axe", "reinforced_pickaxe"]
const MATERIAL_RECIPES := ["rope", "plank"]
const FOOD_RECIPES := ["meal", "grilled_crab", "cooked_meat"]
const UPGRADE_TOOLS := ["reinforced_axe", "reinforced_pickaxe"]
const MODULES := ["floor_panel", "wall_panel", "door_panel", "window_panel", "roof_panel"]
const WALL_MODULES := ["wall_panel", "door_panel", "window_panel"]
const STORABLE := ["wood", "stone", "fiber", "metal", "rope", "plank", "coconut", "raw_fish", "meal", "raw_crab", "raw_meat", "grilled_crab", "cooked_meat", "cave_crystal"]
const TOOL_SLOTS := {"stone_knife":"utility", "stone_axe":"utility", "stone_pickaxe":"utility", "stone_spear":"utility", "fishing_rod":"main_hand", "reinforced_axe":"utility", "reinforced_pickaxe":"utility"}
const DAY_SECONDS := 1200.0
const START_POSITION := Vector3(0.0, 0.0, 170.0)
const BOAT_STAGE_NAMES := ["", "Quilha", "Casco", "Convés", "Mastro", "Vela e leme"]
const BOAT_STAGE_COSTS := {
    2: {"wood":12, "plank":3, "rope":2},
    3: {"wood":4, "plank":3, "rope":2},
    4: {"wood":8, "plank":1, "rope":2},
    5: {"fiber":10, "plank":1, "rope":3, "metal":8}
}
const ITEMS := {"wood": "Madeira", "stone": "Pedra", "fiber": "Fibra", "metal": "Metal", "coconut": "Coco", "raw_fish": "Peixe cru", "meal": "Peixe assado", "raw_crab": "Caranguejo cru", "raw_meat": "Carne crua", "grilled_crab": "Caranguejo assado", "cooked_meat": "Carne assada", "rope": "Corda", "plank": "Tábua", "cave_crystal": "Cristal da caverna"}
const RECIPES := {
    "stone_knife": {"title": "Faca de pedra", "cost": {"wood": 1, "stone": 2, "fiber": 1}, "requires": [], "description": "Feita à mão. Corta fibras: coleta 8 em vez de 5."},
    "stone_axe": {"title": "Machado de pedra", "cost": {"wood": 3, "stone": 2, "fiber": 2}, "requires": [], "description": "Feito à mão. Necessário para cortar árvores e coqueiros."},
    "stone_pickaxe": {"title": "Picareta de pedra", "cost": {"wood": 3, "stone": 3, "fiber": 2}, "requires": [], "description": "Feita à mão. Necessária para extrair pedra das rochas."},
    "stone_spear": {"title": "Lança de pedra", "cost": {"wood": 4, "stone": 2, "fiber": 3}, "requires": [], "description": "Ferramenta de caça artesanal. Equipe para caçar javalis na mata."},
    "reinforced_axe": {"title": "Machado reforçado", "cost": {"metal": 3, "plank": 2, "rope": 1}, "requires": ["stone_axe", "tool_rack"], "description": "Ferramenta de nível 2. Corta madeira mais rapidamente e rende 12 madeiras por árvore."},
    "reinforced_pickaxe": {"title": "Picareta reforçada", "cost": {"metal": 3, "plank": 2, "rope": 1}, "requires": ["stone_pickaxe", "tool_rack"], "description": "Ferramenta de nível 2. Extração de 9 pedras por rocha."},
    "rope": {"title": "Corda", "cost": {"fiber": 1}, "requires": [], "description": "Trance fibras à mão. Usada nos móveis e no barco."},
    "plank": {"title": "Tábua", "cost": {"wood": 2}, "requires": ["workbench"], "description": "Prepare madeira na bancada. Usada nas peças do barco."},
    "campfire": {"title": "Fogueira", "cost": {"wood": 10, "stone": 6}, "requires": [], "description": "Asse peixes e ilumine o acampamento."},
    "workbench": {"title": "Bancada", "cost": {"wood": 16, "stone": 8}, "requires": ["campfire"], "description": "Libera ferramentas e construção avançada."},
    "tool_rack": {"title": "Estação de aprimoramento", "cost": {"wood": 6, "plank": 4, "metal": 2, "cave_crystal": 1}, "requires": ["workbench"], "description": "Nível 2 da oficina. Pesquise o relicário do Leste para construir e melhorar machado e picareta."},
    "fishing_rod": {"title": "Vara de pesca", "cost": {"wood": 6, "fiber": 8}, "requires": ["workbench"], "description": "Pesque na costa ou no cais."},
    "house": {"title": "Casa", "cost": {"wood": 30, "stone": 10, "fiber": 10}, "requires": ["workbench"], "description": "Abrigo para descansar e recuperar saúde."},
    "dock": {"title": "Cais", "cost": {"wood": 20, "fiber": 10}, "requires": ["workbench"], "description": "Construa na praia. Ponto de pesca e embarque."},
    "boat": {"title": "Barco de fuga", "cost": {"wood": 16, "plank": 2, "rope": 1}, "requires": ["house", "dock", "fishing_rod"], "description": "Etapa 1/5: quilha. Toque no barco junto ao cais para montar casco, convés, mastro, vela e leme aos poucos."},
    "floor_panel": {"title": "Piso modular", "cost": {"plank": 2, "wood": 2}, "requires": ["workbench"], "description": "Piso 3,2 × 3,2 m. Encaixa na grade de construção."},
    "wall_panel": {"title": "Parede modular", "cost": {"plank": 2, "wood": 2, "rope": 1}, "requires": ["workbench", "floor_panel"], "description": "Parede de madeira para cercar o piso, com encaixe e rotação."},
    "door_panel": {"title": "Porta de madeira", "cost": {"plank": 3, "wood": 2, "rope": 1}, "requires": ["workbench", "floor_panel"], "description": "Abra e feche a porta tocando em Explorar; oferece passagem quando aberta."},
    "window_panel": {"title": "Parede com janela", "cost": {"plank": 3, "wood": 2, "rope": 1}, "requires": ["workbench", "floor_panel"], "description": "Janela elevada com moldura e abertura para luz e ventilação."},
    "roof_panel": {"title": "Telhado modular", "cost": {"plank": 3, "fiber": 2, "rope": 1}, "requires": ["wall_panel"], "description": "Cobertura inclinada para sua casa modular."},
    "chest": {"title": "Baú do acampamento", "cost": {"wood": 5, "plank": 4, "rope": 2}, "requires": ["workbench"], "description": "Guarde recursos e retire-os quando precisar."},
    "bed": {"title": "Cama de folhas", "cost": {"wood": 6, "fiber": 5, "rope": 2}, "requires": ["house"], "description": "Descansar recupera a saúde."},
    "rain_collector": {"title": "Coletor de chuva", "cost": {"wood": 6, "plank": 2, "rope": 3}, "requires": ["workbench"], "description": "Armazena água durante as chuvas tropicais."},
    "meal": {"title": "Assar peixe", "cost": {"raw_fish": 1}, "requires": ["campfire"], "description": "Prepare na fogueira. Recupera 38 de fome."},
    "grilled_crab": {"title": "Assar caranguejo", "cost": {"raw_crab": 1}, "requires": ["campfire"], "description": "Caranguejo coletado nas praias. Recupera 26 de fome."},
    "cooked_meat": {"title": "Assar carne", "cost": {"raw_meat": 1}, "requires": ["campfire"], "description": "Carne de javali. Recupera 48 de fome e um pouco de saúde."}
}
var equipment: Dictionary = {"main_hand":"", "utility":""}
var inventory: Dictionary = {"wood": 0, "stone": 0, "fiber": 0, "metal": 0, "rope": 0, "plank": 0, "coconut": 2, "raw_fish": 0, "meal": 0, "raw_crab": 0, "raw_meat": 0, "grilled_crab": 0, "cooked_meat": 0, "fishing_rod": 0, "stone_spear": 0, "stone_knife": 0, "stone_axe": 0, "stone_pickaxe": 0, "reinforced_axe": 0, "reinforced_pickaxe": 0, "cave_crystal": 0}
var storage: Dictionary = {"wood": 0, "stone": 0, "fiber": 0, "metal": 0, "rope": 0, "plank": 0, "coconut": 0, "raw_fish": 0, "meal": 0, "raw_crab": 0, "raw_meat": 0, "grilled_crab": 0, "cooked_meat": 0, "cave_crystal": 0}
var rain_water := 0.0
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
    if kind in TOOLS:
        return int(inventory.get(kind, 0)) > 0
    return has_structure(kind)

func boat_stage() -> int:
    for entry in buildings:
        if str(entry.get("kind","")) == "boat":
            # Unversioned boats were complete in all older releases.
            return int(entry.get("stage", 5))
    return 0

func boat_ready() -> bool:
    return boat_stage() == 5

func boat_upgrade_error() -> String:
    var stage := boat_stage()
    if stage == 0:
        return "Primeiro construa a quilha do barco no cais."
    if stage >= 5:
        return "Barco pronto para embarcar."
    var cost: Dictionary = BOAT_STAGE_COSTS[stage+1]
    for item in cost:
        if int(inventory.get(item,0)) < int(cost[item]):
            return "Para %s faltam recursos: %s (%d/%d)." % [BOAT_STAGE_NAMES[stage+1], ITEMS.get(item,item), int(inventory.get(item,0)), int(cost[item])]
    return ""

func upgrade_boat() -> bool:
    if boat_upgrade_error() != "":
        return false
    var stage := boat_stage()
    var cost: Dictionary = BOAT_STAGE_COSTS[stage+1]
    for item in cost:
        inventory[item] = int(inventory.get(item,0)) - int(cost[item])
    for entry in buildings:
        if str(entry.get("kind","")) == "boat":
            entry["stage"] = stage+1
            return true
    return false

func equip_tool(kind: String) -> bool:
    if not TOOL_SLOTS.has(kind) or not owns(kind):
        return false
    equipment[str(TOOL_SLOTS[kind])] = kind
    return true

func unequip_slot(slot: String) -> bool:
    if not equipment.has(slot):
        return false
    equipment[slot] = ""
    return true

func is_equipped(kind: String) -> bool:
    if not TOOL_SLOTS.has(kind):
        return false
    return str(equipment.get(TOOL_SLOTS[kind], "")) == kind and owns(kind)

func harvest_error(kind: String) -> String:
    if kind in ["palm", "tree"] and not (is_equipped("stone_axe") or is_equipped("reinforced_axe")):
        return "Equipe o machado de pedra em Mochila → Equipar para cortar árvores."
    if kind == "rock" and not (is_equipped("stone_pickaxe") or is_equipped("reinforced_pickaxe")):
        return "Equipe a picareta em Mochila → Equipar para minerar rochas."
    if kind == "boar" and not is_equipped("stone_spear"):
        return "Equipe a lança de pedra em Mochila → Equipar para caçar javalis."
    return ""

func craft_tool(kind: String) -> bool:
    if not kind in TOOLS or not pay_recipe(kind):
        return false
    add_item(kind, 1)
    equip_tool(kind)
    return true

func recipe_error(kind: String) -> String:
    if not RECIPES.has(kind):
        return "Receita desconhecida."
    if kind not in FOOD_RECIPES and kind not in MATERIAL_RECIPES and kind not in MODULES and owns(kind):
        return "Você já possui esse item."
    if kind == "tool_rack" and not bool(discoveries.get("east_vault", false)):
        return "Pesquise os dois selos e abra o Relicário do Leste para descobrir a estação de aprimoramento."
    if kind == "boat" and not bool(discoveries.get("sail_diagram", false)):
        return "Encontre o esquema de vela na Caverna do Leste antes de construir o barco."
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

func craft_material(kind: String) -> bool:
    if kind not in MATERIAL_RECIPES or not pay_recipe(kind):
        return false
    add_item(kind, 1)
    return true

func transfer_storage(kind: String, to_chest: bool, count: int = 1) -> bool:
    if not has_structure("chest") or kind not in STORABLE or count <= 0:
        return false
    var source: Dictionary = inventory if to_chest else storage
    var destination: Dictionary = storage if to_chest else inventory
    if int(source.get(kind, 0)) < count:
        return false
    if to_chest:
        var stored := 0
        for item in STORABLE:
            stored += int(storage.get(item, 0))
        if stored + count > 100:
            return false
    source[kind] = int(source.get(kind, 0)) - count
    destination[kind] = int(destination.get(kind, 0)) + count
    return true

func add_item(kind: String, count: int) -> void:
    inventory[kind] = int(inventory.get(kind, 0)) + count

func ready_food_count() -> int:
    return int(inventory.coconut) + int(inventory.meal) + int(inventory.grilled_crab) + int(inventory.cooked_meat)

func consume() -> String:
    if int(inventory.meal) > 0 and hunger < 99.0:
        inventory.meal -= 1
        hunger = minf(100.0, hunger + 38.0)
        health = minf(100.0, health + 6.0)
        return "Peixe assado: +38 de fome."
    if int(inventory.cooked_meat) > 0 and hunger < 99.0:
        inventory.cooked_meat -= 1
        hunger = minf(100.0, hunger + 48.0)
        health = minf(100.0, health + 8.0)
        return "Carne assada: +48 de fome e +8 de saúde."
    if int(inventory.grilled_crab) > 0 and hunger < 99.0:
        inventory.grilled_crab -= 1
        hunger = minf(100.0, hunger + 26.0)
        return "Caranguejo assado: +26 de fome."
    if int(inventory.coconut) > 0 and (thirst < 99.0 or hunger < 99.0):
        inventory.coconut -= 1
        hunger = minf(100.0, hunger + 15.0)
        thirst = minf(100.0, thirst + 30.0)
        return "Coco: +30 de água e +15 de fome."
    return "Sem alimento pronto ou necessidades já cheias."

func advance(delta: float) -> void:
    var previous_elapsed := elapsed
    elapsed += delta
    if has_structure("rain_collector") and not escaped:
        # Integrate rain along the interval; simulation and visible climate use the same function.
        # Small fixed samples also handle elapsed-time jumps without filling in dry weather.
        var duration := maxf(0.0, elapsed - previous_elapsed)
        var slices := maxi(1, ceili(duration / 5.0))
        var water_added := 0.0
        for i in range(slices):
            var at := previous_elapsed + (float(i) + 0.5) * duration / float(slices)
            water_added += SurvivorClimate.rainfall_at(at) * duration / float(slices) * 0.06
        rain_water = minf(12.0, rain_water + water_added)
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
    if not owns("stone_axe"):
        return "Pegue troncos, pedras soltas e fibras. Mochila → Construções → Machado de pedra."
    if not owns("stone_pickaxe"):
        return "Fabrique a picareta na mochila para extrair pedra das rochas."
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
    if not bool(discoveries.get("sail_diagram", false)):
        return "6/6 • Explore a Caverna do Leste e encontre o esquema da vela."
    var stage := boat_stage()
    if stage == 0:
        return "6/6 • Inicie a quilha do barco junto ao cais. A construção terá 5 etapas."
    if stage < 5:
        return "6/6 • Barco %d/5: %s. Reúna materiais e use Explorar no barco." % [stage,BOAT_STAGE_NAMES[stage+1]]
    return "O barco está pronto! Aproxime-se e toque em Embarcar."

func to_data() -> Dictionary:
    return {"version": SAVE_VERSION, "inventory": inventory, "storage": storage.duplicate(true), "rain_water": rain_water, "equipment": equipment.duplicate(true), "buildings": buildings, "harvested": harvested, "discoveries": discoveries, "health": health, "hunger": hunger, "thirst": thirst, "elapsed": elapsed, "escaped": escaped, "position": [player_position.x, player_position.z]}

static func from_data(data: Dictionary) -> SurvivalState:
    if int(data.get("version", 0)) not in [1, 2, SAVE_VERSION]:
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
    var saved_storage = data.get("storage", {})
    if not saved_storage is Dictionary:
        return null
    for key in state.storage:
        var value = saved_storage.get(key, 0)
        if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0:
            return null
        state.storage[key] = clampi(int(value), 0, 100)
    var water = data.get("rain_water", 0.0)
    if not (water is int or water is float) or not is_finite(float(water)):
        return null
    state.rain_water = clampf(float(water), 0.0, 12.0)
    var gear = data.get("equipment", null)
    if gear is Dictionary:
        for slot in state.equipment:
            var kind: String = str(gear.get(slot, ""))
            if kind != "" and (not TOOL_SLOTS.has(kind) or TOOL_SLOTS[kind] != slot or not state.owns(kind)):
                return null
            state.equipment[slot] = kind
    elif gear == null:
        # Old v1/v2 saves used every owned tool automatically.
        if state.owns("stone_axe"):
            state.equip_tool("stone_axe")
        elif state.owns("stone_pickaxe"):
            state.equip_tool("stone_pickaxe")
        elif state.owns("stone_knife"):
            state.equip_tool("stone_knife")
        if state.owns("fishing_rod"):
            state.equip_tool("fishing_rod")
    else:
        return null
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
    var stored_position := Vector3(float(coords[0]),0.0,float(coords[1]))
    if SurvivorCaves.is_cave_position(stored_position):
        state.player_position = stored_position
    else:
        state.player_position = Vector3(clampf(float(coords[0]), -220.0, 220.0), 0, clampf(float(coords[1]), -220.0, 220.0))
    var entries = data.get("buildings", [])
    if not entries is Array or entries.size() > 80:
        return null
    for entry in entries:
        if not entry is Dictionary or not RECIPES.has(str(entry.get("kind", ""))):
            return null
        var kind := str(entry.kind)
        if kind in FOOD_RECIPES or kind in TOOLS or kind in MATERIAL_RECIPES or (state.has_structure(kind) and kind not in MODULES):
            return null
        for axis in ["x", "z"]:
            var value = entry.get(axis)
            if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value)) > 240.0:
                return null
        var building := {"kind": kind, "x": float(entry.x), "z": float(entry.z)}
        if kind == "boat":
            if entry.has("stage"):
                var boat_stage_value = entry.get("stage")
                if not boat_stage_value is int or int(boat_stage_value) < 1 or int(boat_stage_value) > 5:
                    return null
                building["stage"] = int(boat_stage_value)
        if kind == "door_panel":
            var door_open = entry.get("door_open", false)
            if not door_open is bool:
                return null
            building["door_open"] = door_open
        if entry.has("rotation"):
            var angle = entry.rotation
            if not (angle is int or angle is float) or not is_finite(float(angle)) or absf(float(angle)) > TAU:
                return null
            building["rotation"] = float(angle)
        state.buildings.append(building)
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
    state.escaped = bool(data.get("escaped", false)) and state.boat_ready()
    return state
