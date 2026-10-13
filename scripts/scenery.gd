extends Node3D
class_name SurvivorScenery

const CHUNK_SIZE := 48.0
var terrain: SurvivorTerrain
var world: SurvivorWorld
var batches: Array[Dictionary] = []
var cover_count := 0
var light_mode := false
var grass_material: ShaderMaterial

func generate() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 902107
    var noise := FastNoiseLite.new()
    noise.seed = 983
    noise.frequency = 0.045
    var buckets: Dictionary = {}
    for i in range(13000):
        var p := Vector2(rng.randf_range(-184, 184), rng.randf_range(-184, 184))
        var h := terrain.height_at(p.x, p.y)
        if h < 3.0 or h > 25.0 or noise.get_noise_2d(p.x, p.y) < -0.28 or _protected(p):
            continue
        var key := Vector2i(floori(p.x / CHUNK_SIZE), floori(p.y / CHUNK_SIZE))
        if not buckets.has(key):
            buckets[key] = []
        buckets[key].append({"position": Vector3(p.x, h + 0.01, p.y), "angle": rng.randf_range(0, TAU), "size": rng.randf_range(0.65, 1.4), "tint": Color(0.20 + rng.randf() * 0.08, 0.35 + rng.randf() * 0.10, 0.13 + rng.randf() * 0.06)})
    var mesh := _grass_mesh()
    var material := ShaderMaterial.new()
    material.shader = load("res://shaders/groundcover.gdshader")
    grass_material = material
    for key in buckets:
        var entries: Array = buckets[key]
        var center := Vector3((key.x + 0.5) * CHUNK_SIZE, 0, (key.y + 0.5) * CHUNK_SIZE)
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.use_custom_data = true
        multi.mesh = mesh
        multi.instance_count = entries.size()
        for i in range(entries.size()):
            var entry: Dictionary = entries[i]
            var basis := Basis(Vector3.UP, entry.angle).scaled(Vector3.ONE * entry.size)
            multi.set_instance_transform(i, Transform3D(basis, entry.position - center))
            multi.set_instance_custom_data(i, entry.tint)
        var node := MultiMeshInstance3D.new()
        node.position = center
        node.multimesh = multi
        node.material_override = material
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        node.visibility_range_end = 82.0
        add_child(node)
        batches.append({"node": node, "entries": entries})
        cover_count += entries.size()
    set_light_mode(light_mode)

func _protected(p: Vector2) -> bool:
    if world.trails != null and world.trails.distance_to(p)<2.2:
        return true
    # Keep the crash scene and landmark approaches readable.
    for entry in world.landmarks:
        if p.distance_to(Vector2(entry.position.x, entry.position.z)) < 9.0:
            return true
    for entry in world.structures:
        if p.distance_to(Vector2(entry.position.x, entry.position.z)) < (5.0 if entry.kind == "house" else 2.5):
            return true
    for entry in world.resources:
        if entry.radius > 0.0 and p.distance_to(Vector2(entry.position.x, entry.position.z)) < entry.radius + 0.3:
            return true
    return false

func _grass_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for blade in range(3):
        var angle := blade * TAU / 3.0
        var side := Vector3(cos(angle), 0, sin(angle)) * 0.065
        var base := Vector3(sin(angle), 0, cos(angle)) * 0.06
        var tip := base + Vector3(sin(angle) * 0.18, 0.48 + blade * 0.05, cos(angle) * 0.18)
        st.add_vertex(base - side)
        st.add_vertex(tip)
        st.add_vertex(base + side)
    st.generate_normals()
    return st.commit()

func clear_area(pos: Vector3, radius: float) -> void:
    for batch in batches:
        for i in range(batch.entries.size()):
            var point: Vector3 = batch.entries[i].position
            if Vector2(point.x - pos.x, point.z - pos.z).length_squared() < radius * radius:
                var transform: Transform3D = batch.node.multimesh.get_instance_transform(i)
                transform.basis = Basis.IDENTITY.scaled(Vector3.ZERO)
                batch.node.multimesh.set_instance_transform(i, transform)

func set_weather(wind: float, rain: float) -> void:
    if grass_material != null:
        grass_material.set_shader_parameter("wind_strength",wind)
        grass_material.set_shader_parameter("rain_amount",rain)

func set_light_mode(value: bool) -> void:
    light_mode = value
    for batch in batches:
        batch.node.multimesh.visible_instance_count = batch.entries.size() / 3 if value else -1
