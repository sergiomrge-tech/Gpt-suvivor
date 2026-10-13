extends Node3D
class_name SurvivorWorld

var terrain: SurvivorTerrain
var resource_root: Node3D
var structures_root: Node3D
var resources: Array[Node3D] = []
var harvested_ids: Dictionary = {}
var structure_records: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var serial_id := 0

const COLORS = {
    "wood": Color(0.43, 0.27, 0.13),
    "trunk": Color(0.47, 0.32, 0.17),
    "leaf": Color(0.16, 0.43, 0.20),
    "leaf_light": Color(0.22, 0.54, 0.25),
    "rock": Color(0.45, 0.47, 0.44),
    "fiber": Color(0.67, 0.57, 0.32),
    "fruit": Color(0.92, 0.38, 0.14),
    "water": Color(0.10, 0.62, 0.77),
    "fire": Color(1.0, 0.42, 0.08)
}

func _ready() -> void:
    resource_root = Node3D.new()
    resource_root.name = "HarvestableResources"
    add_child(resource_root)
    structures_root = Node3D.new()
    structures_root.name = "PlayerStructures"
    add_child(structures_root)
    reset_world()

func _make_material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    mat.metallic = metallic
    return mat

func _mesh(parent: Node3D, primitive: Mesh, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = primitive
    instance.position = pos
    instance.scale = scale3
    instance.material_override = _make_material(color)
    parent.add_child(instance)
    return instance

func _box(parent: Node3D, size3: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
    var b := BoxMesh.new()
    b.size = size3
    return _mesh(parent, b, color, pos)

func _sphere(parent: Node3D, radius: float, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    sphere.radial_segments = 12
    sphere.rings = 6
    return _mesh(parent, sphere, color, pos, scale3)

func _segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
    var direction: Vector3 = b - a
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.72
    mesh.bottom_radius = radius
    mesh.height = direction.length()
    mesh.radial_segments = 7
    var part := _mesh(parent, mesh, color, (a + b) / 2.0)
    part.quaternion = Quaternion(Vector3.UP, direction.normalized())
    return part

func _leaf_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var steps := 6
    for i in range(steps):
        var t: float = float(i) / float(steps)
        var t2: float = float(i + 1) / float(steps)
        var w: float = sin(t * PI) * 0.70
        var w2: float = sin(t2 * PI) * 0.70
        var z: float = 0.6 + t * 4.6
        var z2: float = 0.6 + t2 * 4.6
        var y: float = 0.15 + sin(t * PI) * 0.65 - pow(t, 2.0) * 1.55
        var y2: float = 0.15 + sin(t2 * PI) * 0.65 - pow(t2, 2.0) * 1.55
        st.add_vertex(Vector3(-w, y, z))
        st.add_vertex(Vector3(w, y, z))
        st.add_vertex(Vector3(w2, y2, z2))
        st.add_vertex(Vector3(-w, y, z))
        st.add_vertex(Vector3(w2, y2, z2))
        st.add_vertex(Vector3(-w2, y2, z2))
    st.generate_normals()
    return st.commit()

func _palm(parent: Node3D) -> void:
    var points := [Vector3.ZERO, Vector3(0.20, 1.8, 0.05), Vector3(0.45, 3.9, 0.10), Vector3(0.38, 6.3, 0.0)]
    for i in range(points.size() - 1):
        _segment(parent, points[i], points[i + 1], 0.39 - float(i) * 0.065, COLORS["trunk"])
    var crown := Node3D.new()
    crown.position = points[3]
    parent.add_child(crown)
    var leaf := _leaf_mesh()
    for i in range(9):
        var leaf_pivot := Node3D.new()
        leaf_pivot.rotation.y = float(i) * TAU / 9.0
        crown.add_child(leaf_pivot)
        _mesh(leaf_pivot, leaf, COLORS["leaf_light"] if i % 3 == 0 else COLORS["leaf"], Vector3.ZERO)
    for i in range(3):
        _sphere(crown, 0.27, Color(0.38, 0.30, 0.16), Vector3(sin(float(i) * TAU / 3.0) * 0.37, -0.25, cos(float(i) * TAU / 3.0) * 0.37))

func _tree(parent: Node3D) -> void:
    _segment(parent, Vector3.ZERO, Vector3(0.1, 4.4, 0.0), 0.50, COLORS["wood"])
    _sphere(parent, 2.1, Color(0.16, 0.37, 0.19), Vector3(0.0, 5.2, 0.0), Vector3(1.0, 0.80, 0.90))
    _sphere(parent, 1.6, COLORS["leaf_light"], Vector3(-0.8, 4.9, 0.5), Vector3(0.75, 0.70, 0.8))
    _sphere(parent, 1.65, Color(0.13, 0.32, 0.18), Vector3(0.8, 5.0, -0.5))

func _build_resource_visual(root: Node3D, kind: String) -> void:
    match kind:
        "palm":
            _palm(root)
        "tree":
            _tree(root)
        "rock":
            _sphere(root, 0.95, COLORS["rock"], Vector3(0, 0.49, 0), Vector3(1.2, 0.62, 0.93))
            _sphere(root, 0.45, Color(0.40, 0.42, 0.41), Vector3(-0.7, 0.25, 0.3))
        "driftwood":
            _segment(root, Vector3(-1.7, 0.37, 0.0), Vector3(1.5, 0.44, 0.0), 0.33, COLORS["wood"])
            _segment(root, Vector3(-0.4, 0.48, 0), Vector3(0.2, 1.2, 0.65), 0.12, COLORS["trunk"])
        "fiber_bundle":
            for i in range(5):
                var a: float = float(i) * TAU / 5.0
                _segment(root, Vector3(sin(a) * 0.55, 0.08, cos(a) * 0.55), Vector3(sin(a) * 0.55, 0.60, cos(a) * 0.55), 0.08, COLORS["fiber"])
        "pebbles":
            for i in range(4):
                _sphere(root, 0.27, COLORS["rock"], Vector3(float(i % 2) * 0.5 - 0.25, 0.17, float(i / 2) * 0.45 - 0.20))
        "berry":
            _sphere(root, 1.0, Color(0.17, 0.48, 0.24), Vector3(0.0, 0.9, 0.0), Vector3(1.1, 0.72, 1.1))
            for i in range(5):
                var a: float = float(i) * TAU / 5.0
                _sphere(root, 0.20, COLORS["fruit"], Vector3(sin(a) * 0.8, 1.0, cos(a) * 0.8))
        "spring":
            var pool := CylinderMesh.new()
            pool.height = 0.09
            pool.top_radius = 2.6
            pool.bottom_radius = 2.6
            _mesh(root, pool, COLORS["water"], Vector3(0.0, 0.03, 0.0))
            for i in range(8):
                var a: float = float(i) * TAU / 8.0
                _sphere(root, 0.55, COLORS["rock"], Vector3(sin(a) * 2.5, 0.32, cos(a) * 2.5), Vector3(1.2, 0.6, 0.9))

func _spawn_resource(kind: String, x: float, z: float) -> void:
    serial_id += 1
    var node := Node3D.new()
    node.name = kind.capitalize() + "_%03d" % serial_id
    node.position = Vector3(x, terrain.height_at(x, z), z)
    node.set_meta("resource_id", serial_id)
    node.set_meta("resource_kind", kind)
    resource_root.add_child(node)
    _build_resource_visual(node, kind)
    resources.append(node)
    if harvested_ids.has(str(serial_id)):
        node.hide()

func _scatter(kind: String, count: int, min_radius: float, max_radius: float, only_beach: bool = false) -> void:
    var added := 0
    var attempts := 0
    while added < count and attempts < count * 70:
        attempts += 1
        var angle: float = rng.randf_range(-PI, PI)
        var radius: float = sqrt(rng.randf_range(min_radius * min_radius, max_radius * max_radius))
        var x: float = cos(angle) * radius
        var z: float = sin(angle) * radius
        if not terrain.is_land(x, z):
            continue
        if only_beach and not terrain.is_shore(x, z):
            continue
        if Vector2(x - 139.0, z - 1.0).length() < 9.0:
            continue
        _spawn_resource(kind, x, z)
        added += 1

func reset_world() -> void:
    if resource_root == null:
        return
    for node in resource_root.get_children():
        node.free()
    for node in structures_root.get_children():
        node.free()
    resources.clear()
    harvested_ids.clear()
    structure_records.clear()
    rng.seed = 195824
    serial_id = 0
    # Existing order is stable: harvested_ids from v0.2 refer to serial IDs.
    _scatter("palm", 38, 120.0, 204.0)
    _scatter("tree", 34, 15.0, 173.0)
    _scatter("rock", 54, 30.0, 185.0)
    _scatter("driftwood", 32, 140.0, 210.0, true)
    _scatter("berry", 26, 30.0, 175.0)
    _scatter("spring", 8, 15.0, 149.0)
    _spawn_resource("driftwood", 137.0, 4.0)
    _spawn_resource("rock", 143.0, 5.0)
    _spawn_resource("berry", 138.0, -6.0)
    # Append the new beach loot AFTER original spawns for save compatibility.
    _scatter("fiber_bundle", 35, 135.0, 210.0, true)
    _scatter("pebbles", 35, 130.0, 210.0, true)
    _spawn_resource("driftwood", 135.0, -3.0)
    _spawn_resource("fiber_bundle", 141.0, 3.0)
    _spawn_resource("fiber_bundle", 135.0, 6.0)
    _spawn_resource("pebbles", 143.0, 5.0)
    _spawn_resource("pebbles", 136.0, -5.0)

func nearest_resource(player_pos: Vector3, radius: float = 5.2) -> Node3D:
    var best: Node3D = null
    var best_dist: float = radius * radius
    for res in resources:
        if not res.visible:
            continue
        var dx: float = res.position.x - player_pos.x
        var dz: float = res.position.z - player_pos.z
        var dist: float = dx * dx + dz * dz
        if dist < best_dist:
            best = res
            best_dist = dist
    return best

func resource_title(kind: String) -> String:
    match kind:
        "palm": return "Coqueiro"
        "tree": return "Árvore"
        "rock": return "Rocha (picareta)"
        "pebbles": return "Pedras soltas"
        "fiber_bundle": return "Fibras no chão"
        "driftwood": return "Madeira na praia"
        "berry": return "Arbusto de frutas"
        "spring": return "Fonte de água doce"
    return "Recurso"

func harvest(resource: Node3D) -> Dictionary:
    if resource == null or not resource.visible:
        return {}
    var kind: String = str(resource.get_meta("resource_kind"))
    var loot: Dictionary = {}
    match kind:
        "palm": loot = {"palm_leaf": 3, "fiber": 2, "fruit": 1}
        "tree": loot = {"wood": 4, "fiber": 1}
        "rock": loot = {"stone": 3}
        "driftwood": loot = {"wood": 3}
        "fiber_bundle": loot = {"fiber": 3}
        "pebbles": loot = {"stone": 2}
        "berry": loot = {"fruit": 3}
        "spring": loot = {"water": 3}
    resource.hide()
    harvested_ids[str(resource.get_meta("resource_id"))] = true
    return loot

func _render_structure(kind: String, root: Node3D) -> void:
    match kind:
        "campfire":
            for i in range(8):
                var a: float = float(i) * TAU / 8.0
                _sphere(root, 0.37, COLORS["rock"], Vector3(sin(a) * 1.3, 0.26, cos(a) * 1.3))
            _segment(root, Vector3(-0.7, 0.2, -0.5), Vector3(0.7, 0.2, 0.5), 0.18, COLORS["wood"])
            _segment(root, Vector3(-0.7, 0.2, 0.5), Vector3(0.7, 0.2, -0.5), 0.18, COLORS["wood"])
            _sphere(root, 0.62, COLORS["fire"], Vector3(0.0, 0.85, 0.0), Vector3(0.55, 1.4, 0.55))
            var light := OmniLight3D.new()
            light.position.y = 1.7
            light.light_color = Color(1.0, 0.48, 0.15)
            light.light_energy = 0.65
            light.omni_range = 6.0
            root.add_child(light)
        "shelter":
            for x in [-2.0, 2.0]:
                for z in [-1.5, 1.5]:
                    _segment(root, Vector3(x, 0.0, z), Vector3(x, 2.5, z), 0.18, COLORS["wood"])
            var roof := _box(root, Vector3(5.1, 0.27, 4.2), COLORS["leaf"], Vector3(0.0, 3.0, 0.0))
            roof.rotation.z = -0.19
            _box(root, Vector3(4.0, 0.25, 2.9), COLORS["wood"], Vector3(0.0, 0.16, 0.0))
        "collector":
            for x in [-0.9, 0.9]:
                for z in [-0.9, 0.9]:
                    _segment(root, Vector3(x, 0.0, z), Vector3(x, 1.3, z), 0.12, COLORS["wood"])
            var bowl := CylinderMesh.new()
            bowl.top_radius = 1.40
            bowl.bottom_radius = 1.00
            bowl.height = 0.36
            _mesh(root, bowl, Color(0.38, 0.30, 0.19), Vector3(0.0, 1.40, 0.0))
            _box(root, Vector3(2.2, 0.06, 2.2), COLORS["water"], Vector3(0.0, 1.61, 0.0))
        "workbench":
            _box(root, Vector3(3.2, 0.25, 1.7), COLORS["wood"], Vector3(0.0, 1.3, 0.0))
            for x in [-1.2, 1.2]:
                for z in [-0.60, 0.60]:
                    _segment(root, Vector3(x, 0.0, z), Vector3(x, 1.25, z), 0.13, COLORS["trunk"])
        "raft":
            for i in range(6):
                var z: float = float(i - 3) * 0.8
                _segment(root, Vector3(-2.6, 0.43, z), Vector3(2.6, 0.43, z), 0.37, COLORS["wood"])
            _segment(root, Vector3(0.0, 0.5, 0.0), Vector3(0.0, 4.0, 0.0), 0.19, COLORS["trunk"])
            _box(root, Vector3(2.4, 2.65, 0.12), Color(0.87, 0.79, 0.56), Vector3(1.25, 2.6, 0.0))

func place_structure(kind: String, pos: Vector3, record: bool = true) -> void:
    var root := Node3D.new()
    root.name = "Built_" + kind.capitalize()
    root.position = Vector3(pos.x, terrain.height_at(pos.x, pos.z), pos.z)
    structures_root.add_child(root)
    _render_structure(kind, root)
    if record:
        structure_records.append({"kind": kind, "x": pos.x, "z": pos.z})

func to_dict() -> Dictionary:
    return {"harvested_ids": harvested_ids.keys(), "structures": structure_records.duplicate(true)}

func restore(data: Dictionary) -> void:
    reset_world()
    var ids: Variant = data.get("harvested_ids", [])
    if ids is Array:
        for id in ids:
            harvested_ids[str(id)] = true
        for res in resources:
            if harvested_ids.has(str(res.get_meta("resource_id"))):
                res.hide()
    var builds: Variant = data.get("structures", [])
    if builds is Array:
        for entry in builds:
            if not (entry is Dictionary):
                continue
            var kind: String = str(entry.get("kind", ""))
            if not SurvivorState.BUILDING_RECIPES.has(kind):
                continue
            var x: float = clampf(float(entry.get("x", 0.0)), -210.0, 210.0)
            var z: float = clampf(float(entry.get("z", 0.0)), -210.0, 210.0)
            place_structure(kind, Vector3(x, 0.0, z), true)
