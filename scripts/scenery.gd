extends Node3D
class_name SurvivorScenery

const CHUNK_SIZE := 48.0
var terrain: SurvivorTerrain
var world: SurvivorWorld
var batches: Array[Dictionary] = []
var cover_count := 0
var detail_batches: Array[Dictionary] = []
var coastal_detail_count := 0
var forest_detail_count := 0
var details_material: ShaderMaterial
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
    _generate_surface_details()
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
    for batch in batches + detail_batches:
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
    if details_material != null:
        details_material.set_shader_parameter("rain_amount",rain)

func set_light_mode(value: bool) -> void:
    light_mode = value
    for batch in batches:
        batch.node.multimesh.visible_instance_count = batch.entries.size() / 3 if value else -1
    for batch in detail_batches:
        batch.node.multimesh.visible_instance_count = batch.entries.size() / 4 if value else -1

# Two deterministic debris families. Small meshes are batched by spatial chunk
# rather than creating thousands of Godot nodes and draw calls.
func _generate_surface_details() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 771403
    var noise := FastNoiseLite.new()
    noise.seed = 44102
    noise.frequency = 0.067
    var buckets: Dictionary = {}
    for i in range(9200):
        var p := Vector2(rng.randf_range(-207.0,207.0),rng.randf_range(-207.0,207.0))
        var h := terrain.height_at(p.x,p.y)
        if not terrain.is_land(p.x,p.y) or _protected(p):
            continue
        var family := -1
        if h > 0.25 and h < 2.65 and noise.get_noise_2d(p.x,p.y) > -0.44:
            family = 0 # Wind-scoured coast: pebbles, broken shells, tiny coral
        elif h > 4.2 and h < 24.0 and noise.get_noise_2d(p.x,p.y) > -0.34:
            family = 1 # Forest: fallen leaves and driftwood twigs
        if family < 0:
            continue
        var key := Vector3i(floori(p.x/CHUNK_SIZE),floori(p.y/CHUNK_SIZE),family)
        if not buckets.has(key):
            buckets[key] = []
        var tone := rng.randf_range(0.78,0.99)
        var tint := Color(tone,tone*rng.randf_range(0.91,1.0),tone*rng.randf_range(0.84,0.99))
        buckets[key].append({
            "position":Vector3(p.x,h+0.027,p.y),
            "angle":rng.randf_range(0.0,TAU),
            "size":rng.randf_range(0.62,1.50) if family == 0 else rng.randf_range(0.82,1.62),
            "tint":tint
        })
        if family == 0:
            coastal_detail_count += 1
        else:
            forest_detail_count += 1
    var shore_mesh := _shore_debris_mesh()
    var leaf_mesh := _forest_litter_mesh()
    details_material = ShaderMaterial.new()
    details_material.shader = load("res://shaders/surface_details.gdshader")
    for key in buckets:
        var entries: Array = buckets[key]
        var center := Vector3((key.x+0.5)*CHUNK_SIZE,0,(key.y+0.5)*CHUNK_SIZE)
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.use_custom_data = true
        multi.mesh = shore_mesh if key.z == 0 else leaf_mesh
        multi.instance_count = entries.size()
        for i in range(entries.size()):
            var entry: Dictionary = entries[i]
            var basis := Basis(Vector3.UP,float(entry.angle)).scaled(Vector3.ONE*float(entry.size))
            multi.set_instance_transform(i,Transform3D(basis,entry.position-center))
            multi.set_instance_custom_data(i,entry.tint)
        var node := MultiMeshInstance3D.new()
        node.name = "ShorePebbles" if key.z == 0 else "ForestLeafLitter"
        node.position = center
        node.multimesh = multi
        node.material_override = details_material
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        node.visibility_range_end = 62.0
        add_child(node)
        detail_batches.append({"node":node,"entries":entries,"family":key.z})

static func _detail_triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

func _shore_debris_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Four individually shaped beach stones, each with multifaceted top.
    for pebble in range(4):
        var x := -0.30+float(pebble%3)*0.25
        var z := -0.15+float(pebble/3)*0.28
        var radius := 0.072+float(pebble%3)*0.036
        var height := 0.065+float(pebble%2)*0.038
        var stone := Color(0.44,0.46,0.41).lerp(Color(0.69,0.63,0.51),float(pebble)/4.0)
        for side in range(9):
            var a := TAU*float(side)/9.0
            var n := TAU*float(side+1)/9.0
            var outer := Vector3(x+cos(a)*radius,0.014,z+sin(a)*radius*0.76)
            var outer_next := Vector3(x+cos(n)*radius,0.014,z+sin(n)*radius*0.76)
            _detail_triangle(st,Vector3(x,height,z),outer,outer_next,stone.lightened(float(side%3)*0.055))
    # Fragmented shell fan with a subtle lip, resting flat on the sand.
    for side in range(7):
        var a := -0.9+float(side)*1.8/7.0
        var n := -0.9+float(side+1)*1.8/7.0
        _detail_triangle(st,Vector3(0.15,0.026,0.34),
            Vector3(0.15+cos(a)*0.26,0.022,0.34+sin(a)*0.16),
            Vector3(0.15+cos(n)*0.26,0.022,0.34+sin(n)*0.16),
            Color(0.88,0.83,0.67).darkened(float(side%3)*0.06))
    st.generate_normals()
    return st.commit()

func _forest_litter_mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for leaf in range(5):
        var angle := float(leaf)*2.39996+0.3
        var outward := Vector3(cos(angle),0,sin(angle))
        var sideways := Vector3(-outward.z,0,outward.x)
        var base := outward * (0.13+float(leaf%2)*0.08) + Vector3(0,0.017,0)
        var tip := base+outward*(0.30+float(leaf%3)*0.08)
        var mid := base.lerp(tip,0.48)+Vector3(0,0.026,0)
        var width := (0.067+float(leaf%2)*0.031)
        var leaf_tone := Color(0.37,0.32,0.17).lerp(Color(0.49,0.37,0.18),float(leaf%3)*0.30)
        _detail_triangle(st,base,mid+sideways*width,tip,leaf_tone)
        _detail_triangle(st,base,tip,mid-sideways*width,leaf_tone.lightened(0.07))
    for twig in range(2):
        var x := -0.39+float(twig)*0.47
        var stem := Color(0.31,0.24,0.15)
        _detail_triangle(st,Vector3(x,0.018,-0.13),Vector3(x+0.025,0.022,0.27),
            Vector3(x-0.028,0.022,0.23),stem)
    st.generate_normals()
    return st.commit()
