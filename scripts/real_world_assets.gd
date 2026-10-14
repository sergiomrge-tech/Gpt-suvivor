extends RefCounted
class_name SurvivorRealWorldAssets

# Textured CC0 external models are visual replacements only. All gameplay
# locations, save identifiers and collision footprints belong to SurvivorWorld.
const ROOT := "res" + "://assets/real_world/models/"
const SOURCES := {
    "palm_detailed":ROOT+"palm_detailed.glb",
    "palm_light":ROOT+"palm_light.glb",
    "airplane_propeller":ROOT+"airplane_propeller.glb",
    "workbench_carpenter":ROOT+"workbench_carpenter.glb",
    "garden_shed":ROOT+"garden_shed.glb",
    "fern":ROOT+"polyhaven/fern_02/fern_02.gltf",
    "calathea":ROOT+"polyhaven/calathea_orbifolia_01/calathea_orbifolia_01.gltf",
    "pachira":ROOT+"polyhaven/pachira_aquatica_01/pachira_aquatica_01.gltf",
    "camp_fire_grill":"res://assets/survival_props/models/camp_fire_grill.glb",
    "storage_chest":"res://assets/survival_props/models/storage_chest.glb",
    "camp_kitchen":"res://assets/survival_props/models/camp_kitchen.glb",
    "camp_chair":"res://assets/survival_props/models/camp_chair.glb",
    "canoe":"res://assets/survival_props/models/canoe.glb",
    "wooden_bucket":"res://assets/survival_props/models/polyhaven/wooden_bucket_01/wooden_bucket_01.gltf",
    "wooden_crate":"res://assets/survival_props/models/polyhaven/wooden_crate_01/wooden_crate_01.gltf",
    "island_tree_01":"res://assets/real_nature/models/island_tree_01.glb",
    "tree_stump_01":"res://assets/real_nature/models/tree_stump_01.glb",
    "dead_tree_trunk_02":"res://assets/real_nature/models/dead_tree_trunk_02.glb",
    "boulder_01":"res://assets/real_nature/models/boulder_01.glb",
    "rock_07":"res://assets/real_nature/models/rock_07.glb",
    "rock_face_01":"res://assets/real_nature/models/rock_face_01.glb",
    "wooden_ladder_02":"res://assets/real_nature/models/wooden_ladder_02.glb"
}
static var cache: Dictionary = {}
static var instances := {"palm_detailed":0,"palm_light":0,"airplane_propeller":0,"workbench_carpenter":0,"garden_shed":0,"fern":0,"calathea":0,"pachira":0,"camp_fire_grill":0,"storage_chest":0,"camp_kitchen":0,"camp_chair":0,"canoe":0,"wooden_bucket":0,"wooden_crate":0,"island_tree_01":0,"tree_stump_01":0,"dead_tree_trunk_02":0,"boulder_01":0,"rock_07":0,"rock_face_01":0,"wooden_ladder_02":0}

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
        if asset_id in ["palm_light","fern","calathea","tree_stump_01","rock_07"]:
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instances[asset_id] = int(instances.get(asset_id,0))+1
    return true

# The authored CC0 GLB has 93 separate mesh objects with wings, lamps,
# cockpit glazing and a propeller. All those original triangles remain intact
# in the imported resource; we rearrange selected instances to stage a crash.
# Rotating wing meshes around their *world origin* looked almost intact.
# Explicit fracture pivots at the actual wing roots produce a visible break.
static func _detach_airframe_part(
        part: MeshInstance3D,pivot_origin: Vector3,offset: Vector3,
        angles: Vector3,existing_pivot: Node3D=null) -> Node3D:
    var host: Node3D = part.get_parent() as Node3D
    if host == null:
        return null
    var hinge: Node3D = existing_pivot
    if hinge == null:
        hinge = Node3D.new()
        hinge.name = "BrokenOriginalGLBPart"
        host.add_child(hinge)
        hinge.position = pivot_origin
        hinge.position += offset
        hinge.rotation_degrees = angles
    # Mesh vertices are authored in the asset's absolute local coordinates.
    # Counter-translate them so the child rotates about the actual hinge.
    part.reparent(hinge,false)
    part.position = -pivot_origin
    part.rotation = Vector3.ZERO
    part.set_meta("wreck_detached",true)
    return hinge

static func fracture_airplane(model: Node3D) -> int:
    var right_wing: MeshInstance3D
    var right_tip: MeshInstance3D
    var canopy: MeshInstance3D
    var prop_blade: MeshInstance3D
    var tip_lamps: Array[MeshInstance3D] = []
    var weathered: Dictionary = {}
    for child in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D = child as MeshInstance3D
        var label: String = String(part.name).to_lower().replace(" ","").replace("_","")
        if label.contains("finitetaperedwing-1"):
            right_wing = part
        elif label.contains("colouredwingtip-1"):
            right_tip = part
        elif label.contains("tiplamp-1"):
            tip_lamps.append(part)
        elif label.contains("finitecurvedtransparentcanopy"):
            canopy = part
        elif label.contains("finitetwistedblade2"):
            prop_blade = part
        # The airplane has the distinctive white paint of a pristine prop.
        # Use original shared texture/material data, duplicate by material only,
        # and darken selectively to represent dust, scratches and soot.
        var original: Material = part.material_override
        if original == null and part.mesh != null and part.mesh.get_surface_count()>0:
            original = part.mesh.surface_get_material(0)
        if original is StandardMaterial3D and not label.contains("lamp") and not label.contains("optic"):
            var key: int = original.get_instance_id()
            if not weathered.has(key):
                var worn: StandardMaterial3D = (original as StandardMaterial3D).duplicate() as StandardMaterial3D
                var factor := 0.76 if not label.contains("fuselage") else 0.67
                worn.albedo_color = worn.albedo_color * Color(factor,factor*0.95,factor*0.88,1.0)
                worn.roughness = maxf(0.86,worn.roughness)
                weathered[key] = worn
            part.material_override = weathered[key]
    if right_wing == null:
        push_warning("Cannot detach wing: the pinned CC0 airplane structure changed")
        return 0
    var original_root := Vector3(-0.20,1.39,0.50)
    var wing_group := _detach_airframe_part(
        right_wing,original_root,Vector3(1.1,-0.72,4.1),Vector3(24,-41,38))
    if wing_group == null:
        return 0
    wing_group.name = "FracturedRightWingActualGLB"
    var pieces := 1
    if right_tip != null:
        _detach_airframe_part(right_tip,original_root,Vector3.ZERO,Vector3.ZERO,wing_group)
        pieces += 1
    for light in tip_lamps:
        _detach_airframe_part(light,original_root,Vector3.ZERO,Vector3.ZERO,wing_group)
        pieces += 1
    if canopy != null:
        # Uncovered cockpit shows actual GLB seats and instrument panel below.
        # Lift original glazing rather than hiding the cockpit completely.
        var canopy_pivot := _detach_airframe_part(
            canopy,Vector3(0,1.88,0),Vector3(-0.8,-0.50,-2.9),Vector3(-18,66,-61))
        if canopy_pivot != null:
            canopy_pivot.name = "ShatteredCockpitCanopy"
            pieces += 1
    if prop_blade != null:
        var nose_pivot := _detach_airframe_part(
            prop_blade,Vector3(3.8,1.52,0),Vector3(2.0,-1.20,-1.8),Vector3(73,-28,48))
        if nose_pivot != null:
            nose_pivot.name = "BrokenPropellerBlade"
            pieces += 1
    model.set_meta("aircraft_fracture_count",pieces)
    model.set_meta("aircraft_original_wing_broken",true)
    return pieces

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
