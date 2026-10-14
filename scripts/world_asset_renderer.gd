extends RefCounted
class_name SurvivorWorldAssetRenderer

# Shared, normalized source geometry. Preserve authored UVs, normals and PBR
# materials; never feed scanned meshes through the vertex-color placeholder merger.
static var geometry: Dictionary = {}
static var collision_boxes: Dictionary = {}

static func relative_transform(node: Node3D, root: Node3D) -> Transform3D:
    var result := node.transform
    var ancestor := node.get_parent()
    while ancestor != null and ancestor != root:
        if ancestor is Node3D:
            result = (ancestor as Node3D).transform*result
        ancestor = ancestor.get_parent()
    return result

static func parts(asset_id: String) -> Array:
    if geometry.has(asset_id):
        return geometry[asset_id]
    var baked_path := "res"+"://assets/optimized_world/"+asset_id+".scn"
    if ResourceLoader.exists(baked_path):
        var baked := (load(baked_path) as PackedScene).instantiate() as Node3D
        if baked.has_meta("collision_bounds"):
            collision_boxes[asset_id] = baked.get_meta("collision_bounds")
        var cached: Array = []
        for child in baked.get_children():
            if child is MeshInstance3D:
                cached.append({"mesh":child.mesh,"material":child.mesh.surface_get_material(0)})
        baked.free()
        geometry[asset_id] = cached
        return cached
    if not SurvivorRealWorldAssets.available(asset_id):
        return []
    var scene := load(SurvivorRealWorldAssets.SOURCES[asset_id]) as PackedScene
    var root := scene.instantiate() as Node3D
    var low := Vector3(INF,INF,INF)
    var high := Vector3(-INF,-INF,-INF)
    for child in root.find_children("*","MeshInstance3D",true,false):
        var node := child as MeshInstance3D
        if node.mesh == null:
            continue
        var transform := relative_transform(node,root)
        for corner in range(8):
            var point := transform*node.mesh.get_aabb().get_endpoint(corner)
            low = low.min(point)
            high = high.max(point)
    var height := high.y-low.y
    if not is_finite(height) or height<0.005:
        root.free()
        return []
    if asset_id == "garden_shed":
        # Original door is opened in its authored hinge frame before batching,
        # matching the accessible shelter entrance instead of a solid doorway.
        var door := root.find_child("*original*access*door*",true,false) as Node3D
        if door != null:
            door.rotation.y += -PI*0.48
    var normalized := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE/height),Vector3(-(low.x+high.x)*0.5,-low.y,-(low.z+high.z)*0.5)/height)
    if asset_id=="garden_shed":
        var body := AABB()
        var first_board := true
        for child in root.find_children("*","MeshInstance3D",true,false):
            var node := child as MeshInstance3D
            var label := String(node.name).to_lower()
            if not ("enclosure" in label or "vertical" in label):
                continue
            var box := relative_transform(node,root)*node.mesh.get_aabb()
            body = box if first_board else body.merge(box)
            first_board = false
        if not first_board:
            collision_boxes[asset_id] = normalized*body
    var result := combined_parts(root,normalized)
    if asset_id in ["palm_detailed","palm_light"]:
        for part in result:
            var original := part.material as StandardMaterial3D
            if original!=null:
                var graded := original.duplicate() as StandardMaterial3D
                graded.albedo_color *= Color(0.68,0.77,0.61)
                graded.roughness = 0.95
                graded.metallic_specular = 0.16
                part.material = graded
                part.mesh.surface_set_material(0,graded)
    root.free()
    geometry[asset_id] = result
    return result

static func combined_parts(root: Node3D, normalization: Transform3D=Transform3D.IDENTITY) -> Array:
    var groups: Dictionary = {}
    for child in root.find_children("*","MeshInstance3D",true,false):
        var node := child as MeshInstance3D
        if node.mesh == null:
            continue
        var transform := normalization*relative_transform(node,root)
        for surface in range(node.mesh.get_surface_count()):
            var material := node.get_active_material(surface)
            var key := material.get_instance_id() if material != null else 0
            if not groups.has(key):
                var builder := SurfaceTool.new()
                builder.begin(Mesh.PRIMITIVE_TRIANGLES)
                groups[key] = {"builder":builder,"material":material}
            var builder: SurfaceTool = groups[key].builder
            builder.append_from(node.mesh,surface,transform)
    var result: Array = []
    for key in groups:
        var builder: SurfaceTool = groups[key].builder
        builder.index()
        var mesh := builder.commit()
        mesh.surface_set_material(0,groups[key].material)
        # Material batching discards source LOD tables. Regenerate them for
        # mobile distance rendering instead of drawing scan detail at any size.
        if OS.has_feature("editor") and ClassDB.class_exists("ImporterMesh"):
            var lod: Object = ClassDB.instantiate("ImporterMesh")
            lod.add_surface(Mesh.PRIMITIVE_TRIANGLES,mesh.surface_get_arrays(0),[],{},groups[key].material)
            lod.generate_lods(25.0,60.0,[])
            mesh = lod.get_mesh()
        result.append({"mesh":mesh,"material":groups[key].material})
    return result

static func attach(parent: Node3D, asset_id: String, height: float, draw_range: float) -> bool:
    var components := parts(asset_id)
    if components.is_empty():
        return false
    var model := Node3D.new()
    model.name = "CC0_"+asset_id
    model.set_meta("source_asset",asset_id)
    model.set_meta("target_height",height)
    model.scale = Vector3.ONE*height
    parent.add_child(model)
    for part in components:
        var node := MeshInstance3D.new()
        node.mesh = part.mesh
        node.visibility_range_end = draw_range
        node.visibility_range_end_margin = 10.0
        if asset_id in ["palm_light","fern","calathea","tree_stump_01","rock_07"]:
            node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        model.add_child(node)
    return true

static func batch(parent: Node3D, asset_id: String, entries: Array, center: Vector3, height: float, draw_range: float) -> Array:
    var result: Array = []
    for part in parts(asset_id):
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.use_custom_data = true
        multi.mesh = part.mesh
        multi.instance_count = entries.size()
        for i in range(entries.size()):
            var item: Dictionary = entries[i]
            var scale: float = float(item.get("size",item.get("scale",1.0)))*height
            multi.set_instance_transform(i,Transform3D(Basis(Vector3.UP,float(item.angle)).scaled(Vector3.ONE*scale),item.position-center))
            multi.set_instance_custom_data(i,item.get("tint",Color.WHITE))
        var node := MultiMeshInstance3D.new()
        node.name = "Scanned_"+asset_id
        node.set_meta("source_asset",asset_id)
        node.position = center
        node.multimesh = multi
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        node.visibility_range_end = draw_range
        node.visibility_range_end_margin = 8.0
        parent.add_child(node)
        result.append({"node":node,"entries":entries,"source_asset":asset_id,"family":-1})
    return result

static var surface_materials: Dictionary = {}
static func surface_material(kind: String) -> StandardMaterial3D:
    if surface_materials.has(kind):
        return surface_materials[kind]
    var material := StandardMaterial3D.new()
    var prefix := "res"+"://assets/real_world/textures/seaside_rock/seaside_rock"
    if kind == "wood":
        prefix = "res"+"://assets/survival_props/textures/wooden_floor_01/wooden_floor_01"
    material.albedo_texture = load(prefix+"_diff.jpg")
    material.normal_enabled = true
    material.normal_texture = load(prefix+"_nor_gl.jpg")
    material.normal_scale = 0.55
    material.roughness_texture = load(prefix+"_rough.jpg")
    material.roughness = 0.90
    material.uv1_scale = Vector3(7.0,7.0,1.0)
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    surface_materials[kind] = material
    return material

static func compact_aircraft(model: Node3D) -> void:
    # Keep detached named parts for audit/history, but render their rearranged
    # geometry by material: 93 original objects become ~16 textured draws.
    var components := combined_parts(model)
    for child in model.find_children("*","MeshInstance3D",true,false):
        child.visible = false
    for component in components:
        var node := MeshInstance3D.new()
        node.name = "BatchedCrashMaterial"
        node.mesh = component.mesh
        node.visibility_range_end = 130.0
        model.add_child(node)

static func collision_bounds(asset_id: String) -> AABB:
    var components := parts(asset_id)
    if collision_boxes.has(asset_id):
        return collision_boxes[asset_id]
    var first := true
    var bounds := AABB()
    for part in components:
        bounds = part.mesh.get_aabb() if first else bounds.merge(part.mesh.get_aabb())
        first = false
    return bounds
