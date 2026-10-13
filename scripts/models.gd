extends RefCounted
class_name SurvivorModels

static var materials: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
    var key := color.to_html()
    if not materials.has(key):
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.88
        materials[key] = mat
    return materials[key]

static func piece(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material(color)
    node.position = pos
    node.scale = scale3
    parent.add_child(node)
    return node

static func box(parent: Node3D, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    return piece(parent, mesh, color, pos)

static func sphere(parent: Node3D, radius: float, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 16
    mesh.rings = 8
    return piece(parent, mesh, color, pos, scale3)

static func beam(parent: Node3D, start: Vector3, end: Vector3, radius: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.87
    mesh.bottom_radius = radius
    mesh.height = start.distance_to(end)
    mesh.radial_segments = 12
    var node := piece(parent, mesh, color, (start + end) * 0.5)
    var direction := (end - start).normalized()
    var axis := Vector3.UP.cross(direction)
    if axis.length_squared() > 0.001:
        node.quaternion = Quaternion(axis.normalized(), Vector3.UP.angle_to(direction))
    elif direction.y < 0.0:
        node.rotation.x = PI
    return node

static func triangles(parent: Node3D, vertices: PackedVector3Array, color: Color) -> MeshInstance3D:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for v in vertices:
        st.add_vertex(v)
    st.generate_normals()
    var node := piece(parent, st.commit(), color, Vector3.ZERO)
    var mat := material(color).duplicate() as StandardMaterial3D
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = mat
    return node

static func palm(parent: Node3D, variant: int) -> void:
    var tall := 7.0 + float(variant % 4) * 0.7
    var bend := Vector3(1.0, 0, 0.5) * (0.6 + float(variant % 3) * 0.3)
    for i in range(8):
        var t := float(i) / 8.0
        var t2 := float(i + 1) / 8.0
        var a := Vector3(0, tall * t, 0) + bend * t * t
        var b := Vector3(0, tall * t2, 0) + bend * t2 * t2
        beam(parent, a, b, 0.38 - t * 0.17, Color(0.39 + t * 0.1, 0.27 + t * 0.07, 0.15))
    var crown := Vector3(0, tall, 0) + bend
    for f in range(9):
        var angle := f * TAU / 9.0 + variant * 0.3
        var radial := Vector3(cos(angle), 0, sin(angle))
        var side := Vector3(-sin(angle), 0, cos(angle))
        var vertices := PackedVector3Array()
        for section in range(8):
            var t := section / 8.0
            var next := (section + 1) / 8.0
            var a := crown + radial * t * 4.9 + Vector3.UP * (sin(t * PI) * 1.1 - t * t * 1.6)
            var b := crown + radial * next * 4.9 + Vector3.UP * (sin(next * PI) * 1.1 - next * next * 1.6)
            var width := sin(t * PI) * 0.72
            var width2 := sin(next * PI) * 0.72
            vertices.append_array(PackedVector3Array([a - side * width, b - side * width2, a + side * width, a + side * width, b - side * width2, b + side * width2]))
        triangles(parent, vertices, Color(0.13 + (f % 3) * 0.025, 0.35 + (f % 3) * 0.035, 0.14))
    for i in range(3):
        sphere(parent, 0.25, Color(0.41, 0.31, 0.12), crown + Vector3(cos(i * 2.1) * 0.38, -0.5, sin(i * 2.1) * 0.38))

static func stone_mesh(radius: float, variant: int) -> ArrayMesh:
    var sphere_shape := SphereMesh.new()
    sphere_shape.radius = radius
    sphere_shape.height = radius * 2.0
    sphere_shape.radial_segments = 20
    sphere_shape.rings = 12
    var arrays := sphere_shape.get_mesh_arrays()
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var colors := PackedColorArray()
    for i in range(vertices.size()):
        var p := vertices[i] / radius
        var displacement := 1.0 + sin(p.x * 5.2 + variant * 1.7) * sin(p.y * 4.3 + p.z * 2.1) * 0.16 + cos(p.z * 6.1 - variant) * 0.08
        vertices[i] *= displacement
        colors.append(Color(0.84 + displacement * 0.1, 0.84 + displacement * 0.1, 0.84 + displacement * 0.1))
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_COLOR] = colors
    var shaped := ArrayMesh.new()
    shaped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var surface := SurfaceTool.new()
    surface.create_from(shaped, 0)
    surface.generate_normals()
    return surface.commit()

static func stone(parent: Node3D, radius: float, variant: int, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    return piece(parent, stone_mesh(radius, variant), color, pos, scale3)

static func surface_family(color: Color) -> float:
    if color.g > color.r * 1.3 and color.g > color.b * 1.2:
        return 2.0 # Foliage.
    if absf(color.r - color.g) < 0.08 and absf(color.g - color.b) < 0.08:
        return 4.0 if color.r > 0.65 else 3.0 # Painted metal or stone.
    if color.r > 0.72 and color.g > 0.63:
        return 5.0 # Fabric, sail.
    if color.b > color.r * 1.1:
        return 4.0
    return 1.0 # Timber, bark and rope.

static func rock(parent: Node3D, variant: int, size: float = 1.0) -> void:
    for i in range(3):
        var node := stone(parent, (0.8 + (variant + i) % 3 * 0.25) * size, variant + i, Color(0.39 + i * 0.035, 0.43 + i * 0.03, 0.42 + i * 0.02), Vector3((i - 1) * 0.65 * size, 0.6 * size, (i % 2) * 0.4 * size), Vector3(1.2, 0.8, 1.0))
        node.rotation_degrees = Vector3(i * 21, variant * 39 + i * 15, i * 17)

static func fiber(parent: Node3D, variant: int) -> void:
    for i in range(7):
        var angle := i * TAU / 7 + variant
        var end := Vector3(cos(angle) * 1.2, 1.2 + (i % 3) * 0.25, sin(angle) * 1.2)
        var side := Vector3(-sin(angle), 0, cos(angle)) * 0.22
        triangles(parent, PackedVector3Array([Vector3.ZERO, end, end * 0.55 + side, Vector3.ZERO, end * 0.55 - side, end]), Color(0.19, 0.43 + (i % 3) * 0.04, 0.21))

static func wreck(parent: Node3D) -> void:
    var shell := CylinderMesh.new()
    shell.top_radius = 1.7
    shell.bottom_radius = 1.3
    shell.height = 8.0
    shell.radial_segments = 24
    var body := piece(parent, shell, Color(0.75, 0.79, 0.77), Vector3(0, 1.4, 0))
    body.rotation.z = PI / 2.0
    body.rotation.y = 0.2
    var nose := sphere(parent, 1.3, Color(0.74, 0.78, 0.76), Vector3(-4.5, 1.4, 0.8), Vector3(1.45, 0.85, 0.85))
    nose.rotation.y = 0.2
    sphere(parent, 0.72, Color(0.1, 0.22, 0.27), Vector3(-4.5, 2.0, 1.05), Vector3(1.35, 0.42, 0.8))
    triangles(parent, PackedVector3Array([Vector3(3.4,1.8,-0.5), Vector3(5.8,3.6,-0.5), Vector3(5.8,1.8,-0.5)]), Color(0.70,0.73,0.69))
    var broken_wing := box(parent, Vector3(2.0, 0.12, 3.3), Color(0.62,0.65,0.61), Vector3(1.5,0.35,3.2))
    broken_wing.rotation_degrees = Vector3(0, 24, -9)
    for i in range(6):
        box(parent, Vector3(0.48, 0.6, 0.08), Color(0.12, 0.25, 0.3), Vector3(-2.5 + i, 2.1, 1.45))
    var wing := box(parent, Vector3(3.3, 0.18, 7.0), Color(0.7, 0.73, 0.68), Vector3(0.8, 0.4, -2.7))
    wing.rotation_degrees.y = -18
    box(parent, Vector3(2.0, 0.5, 2.0), Color(0.64, 0.24, 0.12), Vector3(4, 0.6, 0.8))
    for i in range(4):
        box(parent, Vector3(0.9, 0.2, 0.7), Color(0.44, 0.48, 0.48), Vector3(-4.0 + i * 2.7, 0.15, 4.0 + i % 2))

static func cave(parent: Node3D) -> void:
    for i in range(5):
        var angle := PI * i / 4.0
        var pos := Vector3(cos(angle) * 5.0, sin(angle) * 4.4, -1.0)
        stone(parent, 2.3, i + 17, Color(0.29, 0.34, 0.32), pos, Vector3(1.1, 1.0, 1.4))
    for side in [-1, 1]:
        for i in range(4):
            stone(parent, 2.2, i + 23, Color(0.24, 0.29, 0.28), Vector3(side * 5.0, 1.3, -3.5 - i * 2.1))
    box(parent, Vector3(9, 0.25, 12), Color(0.27, 0.28, 0.24), Vector3(0, 0.02, -4.5))
    for side in [-1,1]:
        for i in range(3):
            beam(parent,Vector3(side*3.7,4.0,-2-i*2.5),Vector3(side*3.6,2.8,-2-i*2.5),0.16,Color(0.34,0.37,0.34))
            beam(parent,Vector3(side*4.7,3.8,-1),Vector3(side*4.3,0.3,1.5),0.08,Color(0.34,0.25,0.14))
        triangles(parent,PackedVector3Array([Vector3(side*3.9,0.1,-5),Vector3(side*3.6,1.1,-5.4),Vector3(side*4.2,0.1,-5.6)]),Color(0.37,0.56,0.55))
    stone(parent, 2.6, 31, Color(0.24, 0.29, 0.28), Vector3(0, 1.7, -11), Vector3(2, 1, 1))

static func building(parent: Node3D, kind: String) -> void:
    var wood := Color(0.4, 0.25, 0.12)
    var plank := Color(0.58, 0.39, 0.19)
    match kind:
        "campfire":
            for i in range(10):
                sphere(parent, 0.32, Color(0.38, 0.4, 0.36), Vector3(cos(i * TAU / 10) * 1.2, 0.15, sin(i * TAU / 10) * 1.2))
            for i in range(3):
                var angle := i * TAU / 3.0
                beam(parent, Vector3(cos(angle), 0.22, sin(angle)), Vector3(-cos(angle), 0.35, -sin(angle)), 0.18, wood)
            var flame := sphere(parent, 0.7, Color(1.0, 0.43, 0.08), Vector3(0, 0.9, 0), Vector3(0.6, 1.4, 0.6))
            var glow := ShaderMaterial.new()
            glow.shader = load("res://shaders/flame.gdshader")
            flame.material_override = glow
            var light := OmniLight3D.new()
            light.position.y = 1.4
            light.light_color = Color(1.0, 0.6, 0.25)
            light.light_energy = 2.0
            light.omni_range = 12.0
            parent.add_child(light)
        "workbench":
            for x in [-1.1, 1.1]:
                for z in [-0.5, 0.5]:
                    beam(parent, Vector3(x, 0, z), Vector3(x, 1.4, z), 0.14, wood)
            for i in range(5):
                box(parent, Vector3(2.8, 0.18, 0.25), plank.lightened(i * 0.015), Vector3(0, 1.5, (i - 2) * 0.26))
            box(parent, Vector3(0.8, 0.3, 0.65), Color(0.34, 0.38, 0.4), Vector3(0.5, 1.73, 0))
            beam(parent, Vector3(-0.8, 1.65, -0.2), Vector3(-0.3, 1.65, 0.2), 0.07, wood)
            box(parent,Vector3(0.22,0.14,0.16),Color(0.42,0.45,0.45),Vector3(-0.3,1.72,0.2))
            for i in range(12):
                var a := i*TAU/12.0
                var b := (i+1)*TAU/12.0
                beam(parent,Vector3(cos(a)*0.3-0.5,1.65,sin(a)*0.3),Vector3(cos(b)*0.3-0.5,1.65,sin(b)*0.3),0.035,Color(0.65,0.57,0.36))
            box(parent,Vector3(0.14,0.35,0.10),wood,Vector3(1.1,1.76,-0.35))
            box(parent,Vector3(0.09,0.27,0.10),Color(0.41,0.46,0.46),Vector3(1.1,1.78,-0.15))
        "house":
            for i in range(12):
                box(parent, Vector3(5.8, 0.18, 0.48), plank.lightened(i % 3 * 0.025), Vector3(0, 0.25, (i - 5.5) * 0.49))
            for x in [-2.7, 2.7]:
                for z in [-2.7, 2.7]:
                    beam(parent, Vector3(x, 0, z), Vector3(x, 4.2, z), 0.18, wood)
            for i in range(9):
                var y := 0.65 + i * 0.34
                box(parent, Vector3(5.5, 0.28, 0.14), plank, Vector3(0, y, -2.7))
                for x in [-2.7, 2.7]:
                    box(parent, Vector3(0.14, 0.28, 5.5), plank, Vector3(x, y, 0))
                for x in [-1.85, 1.85]:
                    box(parent, Vector3(1.75, 0.28, 0.14), plank, Vector3(x, y, 2.7))
            for side in [-1, 1]:
                var roof := box(parent, Vector3(3.7, 0.25, 6.6), Color(0.55, 0.47, 0.24), Vector3(side * 1.6, 4.05, 0))
                roof.rotation.z = side * -0.36
            for side in [-1,1]:
                beam(parent,Vector3(side*2.7,0.65,-2.6),Vector3(side*2.7,2.8,2.4),0.09,wood)
                for i in range(14):
                    var z := -3.1+i*0.47
                    var x: float = side*1.8
                    triangles(parent,PackedVector3Array([Vector3(0,4.71,z),Vector3(side*3.4,3.58,z-0.10),Vector3(side*3.4,3.58,z+0.55),Vector3(0,4.71,z),Vector3(side*3.4,3.58,z+0.55),Vector3(0,4.71,z+0.47)]),Color(0.52+(i%3)*0.025,0.47+(i%3)*0.018,0.25))
                for z in [-2.7,2.7]:
                    for i in range(8):
                        var a := i*TAU/8.0
                        var b := (i+1)*TAU/8.0
                        beam(parent,Vector3(side*2.7+cos(a)*0.24,3.5,sin(a)*0.24+z),Vector3(side*2.7+cos(b)*0.24,3.5,sin(b)*0.24+z),0.04,Color(0.67,0.58,0.37))
                    stone(parent,0.45,4,Color(0.41,0.42,0.38),Vector3(side*2.7,0.1,z),Vector3(1,0.5,1))
            box(parent, Vector3(1.6, 0.25, 1.8), wood, Vector3(0, 0.12, 3.4))
            box(parent, Vector3(1.5, 0.2, 2.6), Color(0.62, 0.68, 0.46), Vector3(-1.4, 0.6, -0.8))
        "dock":
            for i in range(5):
                var ramp := box(parent,Vector3(3.4,0.15,0.38),plank,Vector3(0,0.58-i*0.105,0.32+i*0.34))
                ramp.rotation.x = 0.3
            for i in range(18):
                box(parent, Vector3(3.4, 0.2, 0.5), plank.lightened(i % 3 * 0.02), Vector3(0, 0.6, -i * 0.53))
            for x in [-1.4, 1.4]:
                for z in [0, -4, -8.5]:
                    beam(parent, Vector3(x, -1, z), Vector3(x, 1.2, z), 0.18, wood)
        "boat":
            var vertices := PackedVector3Array()
            for i in range(12):
                var z := -4.2 + i * 0.7
                var next_z := z + 0.7
                var width := maxf(0.18, sin((i + 0.3) / 12.6 * PI) * 1.8)
                var next_width := maxf(0.18, sin((i + 1.3) / 12.6 * PI) * 1.8)
                for side in [-1.0, 1.0]:
                    var a := Vector3(side * width, 0.65, z)
                    var b := Vector3(side * next_width, 0.65, next_z)
                    var c := Vector3(0, -0.15, z)
                    var d := Vector3(0, -0.15, next_z)
                    vertices.append_array(PackedVector3Array([a, c, b, b, c, d]))
                box(parent, Vector3(width * 2, 0.12, 0.65), plank, Vector3(0, 0.5, z))
            triangles(parent, vertices, wood)
            beam(parent, Vector3(0, 0.5, 0), Vector3(0, 7.4, 0), 0.13, wood)
            beam(parent, Vector3(-0.1, 2.1, 0), Vector3(2.9, 2.1, 0), 0.09, wood)
            triangles(parent, PackedVector3Array([Vector3(0.1, 7.1, 0), Vector3(2.8, 2.3, 0.2), Vector3(0.1, 2.3, 0)]), Color(0.9, 0.85, 0.68))
            beam(parent, Vector3(0, 7.0, 0), Vector3(0, 0.8, -3.8), 0.025, Color(0.69, 0.6, 0.41))

# Static props use one vertex-colored mesh instead of dozens of draw calls.
static var merged_material: ShaderMaterial
static var mesh_cache: Dictionary = {}

static func merge_static(parent: Node3D, cache_key: String = "") -> void:
    var meshes: Array[MeshInstance3D] = []
    for child in parent.get_children():
        if child is MeshInstance3D:
            meshes.append(child)
    if meshes.is_empty():
        return
    var merged: ArrayMesh
    if cache_key != "" and mesh_cache.has(cache_key):
        merged = mesh_cache[cache_key]
    else:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for node in meshes:
            var color := Color.WHITE
            if node.material_override is StandardMaterial3D:
                color = node.material_override.albedo_color
            for surface in range(node.mesh.get_surface_count()):
                var arrays := node.mesh.surface_get_arrays(surface)
                var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
                var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
                var vertex_colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
                var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
                var total := indices.size() if not indices.is_empty() else vertices.size()
                for i in range(total):
                    var index := indices[i] if not indices.is_empty() else i
                    var tint := color * vertex_colors[index] if not vertex_colors.is_empty() else color
                    # Preserve the palette in the Compatibility renderer.
                    st.set_color(tint)
                    st.set_uv(Vector2(vertices[index].x + vertices[index].z * 0.31, vertices[index].y))
                    var family := surface_family(color)
                    if cache_key.begins_with("hero_") and not cache_key.begins_with("hero_tool_"):
                        family = 5.0
                    elif cache_key.begins_with("hero_tool_") and family == 3.0:
                        family = 4.0
                    st.set_uv2(Vector2(family,0))
                    if not normals.is_empty():
                        st.set_normal((node.transform.basis.inverse().transposed() * normals[index]).normalized())
                    st.add_vertex(node.transform * vertices[index])
        st.index()
        merged = st.commit()
        if cache_key != "":
            mesh_cache[cache_key] = merged
    for node in meshes:
        parent.remove_child(node)
        node.free()
    if merged_material == null:
        merged_material = ShaderMaterial.new()
        merged_material.shader = load("res://shaders/surfaces.gdshader")
        merged_material.set_shader_parameter("detail_noise", load("res://assets/materials/detail_noise.png"))
    var result := MeshInstance3D.new()
    result.mesh = merged
    result.material_override = merged_material
    result.visibility_range_end = 100.0
    result.visibility_range_end_margin = 12.0
    parent.add_child(result)

static func canopy_tree(parent: Node3D,variant: int) -> void:
    var trunk := Color(0.34,0.24,0.14)
    var height := 5.3+(variant%3)*0.65
    beam(parent,Vector3.ZERO,Vector3(0.2,height,0.1),0.46,trunk)
    for i in range(5):
        var a := i*TAU/5.0+variant*0.7
        var direction := Vector3(cos(a),0,sin(a))
        beam(parent,direction*2.1+Vector3(0,0.06,0),Vector3(0,0.65,0),0.13,trunk)
        var branch := direction*1.8+Vector3(0,height-0.3+(i%2)*0.6,0)
        beam(parent,Vector3(0,height*0.55,0),branch,0.15,trunk)
        stone(parent,1.7,variant+i,Color(0.16+(i%2)*0.025,0.35+(i%3)*0.025,0.18),branch+Vector3(0,0.7,0),Vector3(1.25,0.60,1.15))
    stone(parent,2.0,variant+8,Color(0.17,0.37,0.19),Vector3(0,height+1.0,0),Vector3(1.1,0.70,1.1))

static func fern(parent: Node3D,variant: int) -> void:
    for frond in range(6):
        var a := frond*TAU/6.0+variant*0.37
        var radial := Vector3(cos(a),0,sin(a))
        var side := Vector3(-sin(a),0,cos(a))
        var vertices := PackedVector3Array()
        for leaflet in range(6):
            var t := (leaflet+1)/7.0
            var center := radial*t*1.25+Vector3.UP*(sin(t*PI)*0.65+0.18)
            var width := sin(t*PI)*0.34
            for sign in [-1,1]:
                var end: Vector3 = center+side*width*sign+radial*0.06
                vertices.append_array(PackedVector3Array([center-radial*0.07,end,center+radial*0.15]))
        triangles(parent,vertices,Color(0.18,0.43+(frond%2)*0.04,0.21))

static func discovery_prop(parent: Node3D,id: String) -> void:
    match id:
        "pilot_bag":
            box(parent,Vector3(1.5,0.6,0.9),Color(0.38,0.39,0.20),Vector3(0,0.36,0))
            for x in [-0.5,0.5]:
                box(parent,Vector3(0.12,0.64,0.93),Color(0.23,0.21,0.14),Vector3(x,0.37,0))
            beam(parent,Vector3(-0.2,0.73,0),Vector3(0.2,0.73,0),0.065,Color(0.25,0.23,0.17))
        "cave_note":
            stone(parent,0.7,9,Color(0.42,0.43,0.38),Vector3(0,0.2,0),Vector3(1.3,0.38,0.9))
            box(parent,Vector3(0.62,0.06,0.80),Color(0.38,0.24,0.13),Vector3(0,0.50,0))
            box(parent,Vector3(0.48,0.03,0.67),Color(0.78,0.72,0.52),Vector3(0,0.54,0))
        "tool_crate":
            for i in range(5):
                box(parent,Vector3(1.45,0.15,0.24),Color(0.50,0.35,0.19),Vector3(0,0.8,(i-2)*0.24))
            for x in [-0.65,0.65]:
                box(parent,Vector3(0.15,0.75,1.2),Color(0.38,0.27,0.13),Vector3(x,0.4,0))
            for z in [-0.55,0.55]:
                box(parent,Vector3(1.45,0.75,0.12),Color(0.44,0.30,0.16),Vector3(0,0.4,z))
            box(parent,Vector3(0.45,0.14,0.25),Color(0.43,0.47,0.48),Vector3(0,0.95,0))
