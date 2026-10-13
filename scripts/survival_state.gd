extends RefCounted
class_name SurvivorState

const SAVE_PATH = "user://survivor_save_v1.json"
const RECIPES = {
    "spear": {"wood": 3, "stone": 1, "fiber": 2},
    "campfire": {"wood": 3, "stone": 2},
    "shelter": {"wood": 8, "palm_leaf": 5, "fiber": 3},
    "collector": {"wood": 5, "palm_leaf": 2, "stone": 2},
    "workbench": {"wood": 6, "stone": 4},
    "raft": {"wood": 12, "palm_leaf": 8, "fiber": 5}
}
const ITEM_NAMES = {
    "wood": "Madeira", "stone": "Pedra", "fiber": "Fibra",
    "palm_leaf": "Folha", "fruit": "Fruta", "fish": "Peixe",
    "water": "Água", "spear": "Lança"
}

var health := 100.0
var hunger := 85.0
var thirst := 82.0
var energy := 100.0
var clock := 0.29
var days := 1
var inventory: Dictionary = {}
var crafted: Dictionary = {}
var dead := false

func _init() -> void:
    reset()

func reset() -> void:
    health = 100.0
    hunger = 85.0
    thirst = 82.0
    energy = 100.0
    clock = 0.29
    days = 1
    dead = false
    inventory = {"wood": 2, "stone": 1, "fiber": 0, "palm_leaf": 0, "fruit": 2, "fish": 0, "water": 1}
    crafted = {}

func tick(delta: float) -> void:
    if dead:
        return
    # Um dia no jogo dura aproximadamente 20 minutos de tempo real.
    clock += delta / 1200.0
    if clock >= 1.0:
        clock -= 1.0
        days += 1
    hunger = maxf(0.0, hunger - delta * 0.066)
    thirst = maxf(0.0, thirst - delta * 0.095)
    if hunger <= 0.0 or thirst <= 0.0:
        health = maxf(0.0, health - delta * 1.0)
    elif hunger > 70.0 and thirst > 70.0:
        health = minf(100.0, health + delta * 0.08)
    if health <= 0.0:
        dead = true

func item_count(item: String) -> int:
    return int(inventory.get(item, 0))

func add_item(item: String, count: int) -> void:
    inventory[item] = item_count(item) + maxi(0, count)

func consume_item(item: String, count: int) -> bool:
    if item_count(item) < count:
        return false
    inventory[item] = item_count(item) - count
    return true

func can_craft(recipe: String) -> bool:
    if not RECIPES.has(recipe):
        return false
    var cost: Dictionary = RECIPES[recipe]
    for item in cost:
        if item_count(str(item)) < int(cost[item]):
            return false
    return true

func craft(recipe: String) -> bool:
    if not can_craft(recipe):
        return false
    var cost: Dictionary = RECIPES[recipe]
    for item in cost:
        consume_item(str(item), int(cost[item]))
    if recipe == "spear":
        add_item("spear", 1)
    else:
        crafted[recipe] = int(crafted.get(recipe, 0)) + 1
    return true

func eat() -> String:
    if consume_item("fruit", 1):
        hunger = minf(100.0, hunger + 25.0)
        thirst = minf(100.0, thirst + 9.0)
        return "Você comeu uma fruta."
    if consume_item("fish", 1):
        hunger = minf(100.0, hunger + 33.0)
        return "Você comeu o peixe."
    return "Sem alimentos. Procure frutas ou pesque."

func drink() -> String:
    if consume_item("water", 1):
        thirst = minf(100.0, thirst + 45.0)
        return "Água potável consumida."
    return "Você precisa coletar água doce."

func to_dict() -> Dictionary:
    return {"version": 1, "health": health, "hunger": hunger, "thirst": thirst,
        "energy": energy, "clock": clock, "days": days, "inventory": inventory.duplicate(true),
        "crafted": crafted.duplicate(true), "dead": dead}

func from_dict(data: Dictionary) -> bool:
    if int(data.get("version", -1)) != 1:
        return false
    if not (data.get("inventory") is Dictionary) or not (data.get("crafted") is Dictionary):
        return false
    reset()
    health = clampf(float(data.get("health", 100.0)), 0.0, 100.0)
    hunger = clampf(float(data.get("hunger", 85.0)), 0.0, 100.0)
    thirst = clampf(float(data.get("thirst", 82.0)), 0.0, 100.0)
    energy = clampf(float(data.get("energy", 100.0)), 0.0, 100.0)
    clock = clampf(float(data.get("clock", 0.29)), 0.0, 0.9999)
    days = maxi(1, int(data.get("days", 1)))
    inventory = data["inventory"].duplicate(true)
    crafted = data["crafted"].duplicate(true)
    dead = bool(data.get("dead", false))
    return true

static func save_exists() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func save_game(world_data: Dictionary, player_position: Vector3) -> bool:
    var data: Dictionary = to_dict()
    data["world"] = world_data
    data["player"] = [player_position.x, player_position.z]
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    return true

static func read_save() -> Dictionary:
    if not save_exists():
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        return parsed
    return {}
