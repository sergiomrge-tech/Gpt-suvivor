extends Node3D
class_name SurvivorFauna

# Procedural wildlife: crabs and boars provide optional food. Turtles, birds and
# visible fish remain non-harvestable; existing progression and saves are preserved.
var terrain: SurvivorTerrain
var state: SurvivalState
var player: SurvivorPlayer
var animals: Array[Dictionary] = []
var light_mode := false
var _rng := RandomNumberGenerator.new()
var _tick := 0.0
var _motion_time := 0.0

func generate() -> void:
    _rng.seed = 701307
    for spec in [["crab", 12], ["turtle", 5], ["boar", 8], ["bird", 11], ["fish", 12]]:
        var kind: String = spec[0]
        for index in range(int(spec[1])):
            for attempt in range(260):
                var angle := _rng.randf_range(0.0, TAU)
                var radius := _rng.randf_range(140.0, 195.0) if kind in ["crab", "turtle", "fish"] else _rng.randf_range(24.0, 165.0)
                var point := Vector2(cos(angle), sin(angle)) * radius
                if not _habitat(kind, point):
                    continue
                var node := Node3D.new()
                node.name = "%s_%d" % [kind, index]
                node.position = Vector3(point.x, _surface_height(kind, point), point.y)
                node.rotation.y = angle
                add_child(node)
                _model(node, kind)
                SurvivorModels.merge_static(node, "survivor_fauna_" + kind)
                animals.append({
                    "kind": kind,
                    "id": "wild_%s_%d" % [kind, index],
                    "position": node.position,
                    "radius": 1.1 if kind == "boar" else 0.65,
                    "node": node,
                    "heading": angle,
                    "timer": _rng.randf_range(1.0, 4.0),
                    "phase": _rng.randf_range(0.0, TAU)
                })
                break

func set_light_mode(enabled: bool) -> void:
    light_mode = enabled

func _available(animal: Dictionary) -> bool:
    if state == null:
        return true
    return state.elapsed >= float(state.harvested.get(str(animal.id), -1.0))

func nearest_prey(pos: Vector3, reach: float = 5.0) -> Dictionary:
    var result: Dictionary = {}
    var closest := reach
    for animal in animals:
        if animal.kind not in ["crab", "boar"] or not _available(animal):
            continue
        var node: Node3D = animal.node
        if not is_instance_valid(node) or not node.visible:
            continue
        var d := Vector2(pos.x - node.position.x, pos.z - node.position.z).length()
        if d < closest:
            closest = d
            result = animal
    return result

func harvest_prey(entry: Dictionary) -> String:
    if state == null or entry.is_empty() or entry.kind not in ["crab", "boar"]:
        return "Animal indisponível."
    if not _available(entry):
        return "O animal já foi coletado."
    var error := state.harvest_error(str(entry.kind))
    if error != "":
        return error
    var meat := "raw_crab" if entry.kind == "crab" else "raw_meat"
    var amount := 1 if entry.kind == "crab" else 2
    state.add_item(meat, amount)
    # Uses the existing v3 harvested-ID map; no migration or save field required.
    state.harvested[str(entry.id)] = state.elapsed + 900.0
    var node: Node3D = entry.node
    if is_instance_valid(node):
        node.visible = false
    return "+%d %s • prepare na fogueira." % [amount, SurvivalState.ITEMS[meat]]

func _habitat(kind: String, point: Vector2) -> bool:
    if point.distance_to(Vector2(0.0, 170.0)) < 28.0:
        return false
    var height := terrain.height_at(point.x, point.y)
    if kind == "fish":
        return height < terrain.sea_level - 0.3 and height > terrain.sea_level - 9.0
    if kind in ["crab", "turtle"]:
        return terrain.is_shore(point.x, point.y)
    if kind == "boar":
        return terrain.is_land(point.x, point.y) and height > 3.5 and height < 25.0
    return terrain.is_land(point.x, point.y) and height > 1.5

func _surface_height(kind: String, point: Vector2) -> float:
    if kind == "fish":
        return terrain.sea_level - 0.34
    var height := terrain.height_at(point.x, point.y)
    return height + (5.5 if kind == "bird" else 0.0)

func _process(delta: float) -> void:
    if not is_instance_valid(player) or not player.enabled:
        return
    _tick += delta
    if _tick < 0.12:
        return
    var step := minf(_tick, 0.35)
    _tick = 0.0
    _motion_time += step
    for index in range(animals.size()):
        var animal: Dictionary = animals[index]
        var node: Node3D = animal.node
        var distance_vec := Vector2(node.position.x - player.position.x, node.position.z - player.position.z)
        var distance := distance_vec.length()
        node.visible = _available(animal) and distance < 82.0 and (not light_mode or index % 2 == 0)
        if not node.visible:
            continue
        var kind: String = animal.kind
        var fear_radius := 15.0 if kind == "bird" else (11.0 if kind in ["boar", "turtle"] else 6.5)
        var fleeing := distance < fear_radius and distance > 0.01
        var direction := Vector2.ZERO
        if fleeing:
            direction = distance_vec.normalized()
            animal["heading"] = direction.angle()
            animal["timer"] = 0.8
        else:
            animal["timer"] = float(animal.timer) - step
            if float(animal.timer) <= 0.0:
                animal["heading"] = _rng.randf_range(-PI, PI)
                animal["timer"] = _rng.randf_range(1.5, 4.5)
            direction = Vector2.RIGHT.rotated(float(animal.heading))
            # Rest periods alternate with short foraging movements.
            if int(_motion_time + float(animal.phase)) % 9 < 3:
                direction = Vector2.ZERO
        var speed := 3.8 if fleeing else (2.1 if kind in ["bird", "fish"] else 0.9)
        var next := Vector2(node.position.x, node.position.z) + direction * speed * step
        if _habitat(kind, next):
            node.position.x = next.x
            node.position.z = next.y
            if direction.length_squared() > 0.01:
                node.rotation.y = atan2(direction.x, direction.y)
        else:
            animal["timer"] = 0.0
        node.position.y = _surface_height(kind, Vector2(node.position.x, node.position.z))
        if kind in ["bird", "fish"]:
            node.position.y += sin(_motion_time * 2.8 + float(animal.phase)) * (0.38 if kind == "bird" else 0.10)
        animal["position"] = node.position
        animals[index] = animal

func _model(node: Node3D, kind: String) -> void:
    match kind:
        "crab":
            SurvivorModels.sphere(node, 0.55, Color(0.76, 0.24, 0.13), Vector3(0, 0.27, 0), Vector3(1.0, 0.43, 0.75))
            for side in [-1, 1]:
                SurvivorModels.sphere(node, 0.09, Color(0.91, 0.69, 0.41), Vector3(float(side) * 0.30, 0.49, 0.35))
                for i in range(3):
                    var z := (float(i) - 1.0) * 0.35
                    SurvivorModels.beam(node, Vector3(float(side) * 0.32, 0.24, z), Vector3(float(side) * 0.83, 0.10, z + 0.12), 0.055, Color(0.67, 0.20, 0.12))
                SurvivorModels.beam(node, Vector3(float(side) * 0.37, 0.35, 0.34), Vector3(float(side) * 0.92, 0.40, 0.53), 0.09, Color(0.84, 0.27, 0.14))
                SurvivorModels.sphere(node, 0.19, Color(0.87, 0.31, 0.15), Vector3(float(side) * 0.96, 0.4, 0.56), Vector3(1.0, 0.55, 0.8))
        "turtle":
            SurvivorModels.sphere(node, 0.92, Color(0.30, 0.41, 0.24), Vector3(0, 0.45, 0), Vector3(1.06, 0.50, 1.20))
            SurvivorModels.sphere(node, 0.91, Color(0.26, 0.33, 0.18), Vector3(0, 0.57, 0), Vector3(1.02, 0.40, 1.05))
            SurvivorModels.sphere(node, 0.31, Color(0.47, 0.57, 0.33), Vector3(0, 0.37, 1.05))
            for x in [-0.8, 0.8]:
                for z in [-0.72, 0.72]:
                    SurvivorModels.sphere(node, 0.33, Color(0.45, 0.55, 0.32), Vector3(x, 0.16, z), Vector3(1.0, 0.40, 1.2))
        "boar":
            SurvivorModels.sphere(node, 0.92, Color(0.34, 0.22, 0.16), Vector3(0, 0.89, 0), Vector3(0.76, 0.77, 1.25))
            SurvivorModels.sphere(node, 0.47, Color(0.42, 0.26, 0.16), Vector3(0, 0.86, 0.89), Vector3(0.95, 0.84, 1.0))
            SurvivorModels.sphere(node, 0.27, Color(0.63, 0.35, 0.25), Vector3(0, 0.72, 1.31), Vector3(1.15, 0.80, 0.46))
            for x in [-0.53, 0.53]:
                for z in [-0.70, 0.70]:
                    SurvivorModels.beam(node, Vector3(x, 0.65, z), Vector3(x, 0.07, z + 0.07), 0.13, Color(0.31, 0.20, 0.14))
                SurvivorModels.beam(node, Vector3(x * 0.55, 0.78, 1.10), Vector3(x * 0.85, 0.64, 1.47), 0.09, Color(0.90, 0.83, 0.65))
                SurvivorModels.sphere(node, 0.11, Color(0.17, 0.12, 0.10), Vector3(x * 0.58, 1.02, 1.17))
        "bird":
            SurvivorModels.sphere(node, 0.28, Color(0.84, 0.84, 0.76), Vector3(0, 0, 0), Vector3(0.60, 0.49, 1.15))
            SurvivorModels.sphere(node, 0.14, Color(0.81, 0.82, 0.74), Vector3(0, 0.14, 0.26))
            for side in [-1, 1]:
                SurvivorModels.beam(node, Vector3(float(side) * 0.13, 0.02, -0.07), Vector3(float(side) * 1.08, 0.09, -0.34), 0.11, Color(0.64, 0.71, 0.72))
            SurvivorModels.beam(node, Vector3(0, 0.05, 0.30), Vector3(0, 0.01, 0.55), 0.045, Color(0.84, 0.61, 0.19))
        "fish":
            SurvivorModels.sphere(node, 0.37, Color(0.34, 0.65, 0.67), Vector3(0, 0, 0), Vector3(0.60, 0.62, 1.5))
            SurvivorModels.triangles(node, PackedVector3Array([
                Vector3(0, 0, -0.47), Vector3(-0.34, 0.29, -0.96), Vector3(0.34, -0.25, -0.96),
                Vector3(0, 0, -0.47), Vector3(0.34, -0.25, -0.96), Vector3(-0.34, 0.29, -0.96)
            ]), Color(0.22, 0.54, 0.64))
            SurvivorModels.sphere(node, 0.05, Color(0.06, 0.12, 0.13), Vector3(0.17, 0.11, 0.36))
