extends RefCounted
class_name SurvivorRealWorldAssets

# Textured CC0 external models are visual replacements only. All gameplay
# locations, save identifiers and collision footprints belong to SurvivorWorld.
const ROOT := "res://assets/real_world/models/"
const SOURCES := {
    "palm_detailed":ROOT+"palm_detailed.glb",
    "palm_light":ROOT+"palm_light.glb",
    "airplane_propeller":ROOT+"airplane_propeller.glb",
    "workbench_carpenter":ROOT+"workbench_carpenter.glb",
    "garden_shed":ROOT+"garden_shed.glb",
    "fern":ROOT+"polyhaven/fern_02/fern_02.gltf",
    "calathea":ROOT+"polyhaven/calathea_orbifolia_01/calathea_orbifolia_01.gltf",
    "pachira":ROOT+"polyhaven/pachira_aquatica_01/pachira_aquatica_01.gltf"
}
static var cache: Dictionary = {}
static var instances := {"palm_detailed":0,"palm_light":0,"airplane_propeller":0,"workbench_carpenter":0,"garden_shed":0,"fern":0,"calathea":0,"pachira":0}

static func available(asset_id: String) -> bool:
    return SOURCES.has(asset_id) and ResourceLoader.exists(SOURCES[asset_id])

static func attach(parent: Node3D,asset_id: String,target_height: float,draw_range: float=90.0) -> bool:
    if not available(asset_id):
        return false
    var packed: PackedScene = cache.get(asset_id) as PackedScene
    if packed == null:
        packed = load(SOURCES[asset_id]) as PackedScene
        if packed == null:
            return false
        cache[asset_id] = packed
    var model := packed.instantiate() as Node3D
    if model == null:
        return false
    model.name = "CC0_"+asset_id
    parent.add_child(model)
    var minimum := Vector3(INF,INF,INF)
    var maximum := Vector3(-INF,-INF,-INF)
    var meshes := model.find_children("*","MeshInstance3D",true,false)
    var found := false
    for child in meshes:
        var node: MeshInstance3D = child as MeshInstance3D
        if node.mesh == null:
            continue
        found = true
        var bounds := node.mesh.get_aabb()
        for i in range(8):
            var endpoint: Vector3 = model.to_local(node.global_transform*bounds.get_endpoint(i))
            minimum = minimum.min(endpoint)
            maximum = maximum.max(endpoint)
    if not found or maximum.y-minimum.y < 0.005:
        model.queue_free()
        return false
    var height := maximum.y-minimum.y
    var factor := clampf(target_height / height,0.04,28.0)
    model.scale = Vector3.ONE * factor
    model.position = Vector3(-(minimum.x+maximum.x)*0.5*factor,-minimum.y*factor,-(minimum.z+maximum.z)*0.5*factor)
    for child in meshes:
        var node: MeshInstance3D = child as MeshInstance3D
        node.visibility_range_end = draw_range
        node.visibility_range_end_margin = 8.0
        if asset_id in ["palm_light","fern","calathea"]:
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instances[asset_id] = int(instances.get(asset_id,0))+1
    return true

static func add_crash_damage(parent: Node3D) -> void:
    # Original airframe remains the imported authored GLB. Debris is a separate
    # authored-in-code overlay to tell the crash story without "cube airplane."
    var rng := RandomNumberGenerator.new()
    rng.seed = 779123
    for i in range(13):
        var spread := Vector3(rng.randf_range(-7.8,7.8),rng.randf_range(0.05,0.28),rng.randf_range(-5.4,5.4))
        var size := Vector3(rng.randf_range(0.45,1.45),rng.randf_range(0.035,0.11),rng.randf_range(0.15,0.48))
        var tint := Color(0.34,0.34,0.32).lerp(Color(0.53,0.24,0.16),rng.randf_range(0.06,0.42))
        var shard := SurvivorModels.box(parent,size,tint,spread)
        shard.rotation_degrees = Vector3(rng.randf_range(-24,24),rng.randf_range(-90,90),rng.randf_range(-34,34))
    var scar := SurvivorModels.stone(parent,2.45,78,Color(0.31,0.27,0.24),Vector3(5.1,0.12,3.15),Vector3(1.8,0.27,0.7))
    scar.rotation.y = -0.56
    for i in range(4):
        var wing_fragment := SurvivorModels.box(parent,Vector3(1.35,0.06,2.1),Color(0.52,0.56,0.55),Vector3(-5.4+float(i)*1.7,0.2,3.5-float(i%2)*1.3))
        wing_fragment.rotation_degrees = Vector3(-5,24+25*i,8)
