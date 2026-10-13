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
    # Retain harvest anchor and collision: only improve the visual silhouette.
    # Tapered segmented stem, bark scars and serrated arching crown are merged
    # to one static mesh by SurvivorWorld for mobile rendering.
    var tall := 7.1 + float(variant%4)*0.64
    var curve := Vector3(1.0,0.0,0.55)*(0.58+float(variant%3)*0.25)
    var trunk_color := Color(0.40,0.29,0.17)
    for i in range(8):
        var t := float(i)/8.0
        var t2 := float(i+1)/8.0
        var a := Vector3(0,tall*t,0)+curve*t*t
        var b := Vector3(0,tall*t2,0)+curve*t2*t2
        beam(parent,a,b,0.40-t*0.18,trunk_color.lightened(float(i%3)*0.028))
        if i > 0:
            # Short dark notches trace old bark attachment rings, not stripes.
            var ring := PackedVector3Array()
            var mid := a.lerp(b,0.15)
            var radius := (0.40-t*0.18)*1.03
            for side in range(9):
                var angle := float(side)*TAU/9.0
                var next := float(side+1)*TAU/9.0
                var first := Vector3(cos(angle),0,sin(angle))*radius
                var second := Vector3(cos(next),0,sin(next))*radius
                ring.append_array(PackedVector3Array([
                    mid+first,mid+second+Vector3.UP*0.025,mid+first+Vector3.UP*0.052
                ]))
            triangles(parent,ring,trunk_color.darkened(0.16))
    var crown := Vector3(0,tall,0)+curve
    # Continuous arching rachis and narrow leaflets create a believable
    # coconut-palm silhouette. All geometry remains cached by resource variant.
    for frond in range(11):
        var angle := float(frond)*TAU/11.0 + float(variant)*0.19
        var radial := Vector3(cos(angle),0,sin(angle))
        var side := Vector3(-sin(angle),0,cos(angle))
        var length := 4.05 + float((frond+variant)%5)*0.29
        var vertices := PackedVector3Array()
        for segment in range(12):
            var t := float(segment)/12.0
            var t2 := float(segment+1)/12.0
            var a := crown + radial*t*length + Vector3.UP*(sin(t*PI)*0.75-t*t*2.20)
            var b := crown + radial*t2*length + Vector3.UP*(sin(t2*PI)*0.75-t2*t2*2.20)
            var w := sin(t*PI)*0.085
            var w2 := sin(t2*PI)*0.085
            vertices.append_array(PackedVector3Array([
                a-side*w,b-side*w2,a+side*w,
                a+side*w,b-side*w2,b+side*w2
            ]))
            if segment > 0 and segment < 11:
                # Opposite leaflets spread laterally and droop at their tips.
                # Sparse, independent segments admit daylight through the crown.
                for sign in [-1.0,1.0]:
                    var base: Vector3 = a + side*sign*w*0.45
                    var next_base: Vector3 = b + side*sign*w2*0.42
                    var reach := sin(t*PI)*0.70 + 0.14
                    var leaf_tip: Vector3 = base + side*sign*reach + radial*(0.09+0.11*t) - Vector3.UP*(0.12+0.34*t)
                    vertices.append_array(PackedVector3Array([
                        base,leaf_tip,next_base
                    ]))
        triangles(parent,vertices,Color(
            0.13+float(frond%3)*0.019,
            0.32+float((frond+variant)%4)*0.027,
            0.11+float(frond%2)*0.013
        ))
    for i in range(4):
        var a := float(i)*TAU/4.0
        sphere(parent,0.22,Color(0.44,0.32,0.12),
            crown+Vector3(cos(a)*0.40,-0.51+float(i%2)*0.12,sin(a)*0.40))

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
    # Fractured granite mass with strata and smaller weathered fragments.
    # No collision radius or resource yield changes.
    for i in range(3):
        var width := (0.76 + float((variant+i)%3)*0.23)*size
        var tint := Color(0.37+float(i%3)*0.033,0.41+float(i%3)*0.026,0.39+float(i%2)*0.035)
        var chunk := stone(parent,width,variant+i,tint,
            Vector3((float(i)-1.5)*0.49*size,(0.41+float(i%2)*0.19)*size,float(i%3)*0.25*size),
            Vector3(1.23,0.70+float(i%2)*0.07,0.90))
        chunk.rotation_degrees = Vector3(i*14,variant*27+i*29,i*11)
    for i in range(2):
        var a := float(i)*TAU/2.0+float(variant)*0.33
        var pebble := stone(parent,(0.19+float(i%2)*0.07)*size,variant+30+i,
            Color(0.43+float(i%3)*0.032,0.45+float(i%2)*0.025,0.40),
            Vector3(cos(a)*1.38*size,0.17*size,sin(a)*0.95*size),
            Vector3(1.25,0.58,0.83))
        pebble.rotation_degrees.y = i*31

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
        "tool_rack":
            # A distinct second-tier workshop: framed rack, steel tools and a luminous crystal.
            for x in [-1.3,1.3]:
                for depth in [-0.48,0.48]:
                    beam(parent,Vector3(x,0,depth),Vector3(x,2.75,depth),0.14,wood)
            for level in [0.30,1.50,2.63]:
                box(parent,Vector3(2.9,0.17,1.25),plank,Vector3(0,level,0))
            for i in range(5):
                var x := -1.00+float(i)*0.5
                beam(parent,Vector3(x,1.57,-0.27),Vector3(x,2.35,-0.27),0.06,Color(0.48,0.53,0.53))
                box(parent,Vector3(0.27,0.20,0.14),Color(0.62,0.66,0.62),Vector3(x,2.27,-0.27))
            for x in [-1.03,1.03]:
                beam(parent,Vector3(x,0.45,0.55),Vector3(x,2.63,0.55),0.08,wood)
            var gem := stone(parent,0.35,5,Color(0.24,0.68,0.78),Vector3(0.0,1.88,0),Vector3(0.75,1.25,0.75))
            gem.rotation.z = 0.15
            box(parent,Vector3(0.90,0.10,0.58),Color(0.55,0.55,0.50),Vector3(0,1.68,0))
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
        "floor_panel":
            # Low foundation with beams below individual weathered plank strips.
            for z in [-1.2,1.2]:
                beam(parent,Vector3(-1.68,0.21,z),Vector3(1.68,0.21,z),0.15,wood)
            for i in range(8):
                var x := (float(i)-3.5)*0.40
                box(parent,Vector3(0.38,0.16,3.2),plank.lightened(float(i%4)*0.022),Vector3(x,0.39,0))
                beam(parent,Vector3(x,0.48,-1.4),Vector3(x,0.48,1.4),0.009,Color(0.38,0.23,0.12))
            for x in [-1.51,1.51]:
                beam(parent,Vector3(x,0.0,-1.55),Vector3(x,0.30,1.55),0.12,wood)
        "wall_panel":
            # Full panel on the local X axis. The rotated instance preserves the snap orientation.
            for x in [-1.57,1.57]:
                beam(parent,Vector3(x,0,0),Vector3(x,3.15,0),0.15,wood)
            beam(parent,Vector3(-1.57,3.1,0),Vector3(1.57,3.1,0),0.16,wood)
            beam(parent,Vector3(-1.57,0.20,0),Vector3(1.57,0.20,0),0.15,wood)
            for i in range(8):
                var x := (float(i)-3.5)*0.38
                box(parent,Vector3(0.365,2.68,0.17),plank.lightened(float(i%3)*0.022),Vector3(x,1.64,0))
            for y in [0.93,2.23]:
                beam(parent,Vector3(-1.44,y,0.13),Vector3(1.44,y,0.13),0.085,Color(0.30,0.21,0.13))
            beam(parent,Vector3(-1.31,0.25,0.17),Vector3(1.31,3.00,0.17),0.07,wood)
        "door_panel":
            # Full modular frame, with an actual hinged leaf (kept separate from static batching).
            for x in [-1.56, 1.56]:
                beam(parent, Vector3(x, 0, 0), Vector3(x, 3.18, 0), 0.17, wood)
            beam(parent, Vector3(-1.56, 3.12, 0), Vector3(1.56, 3.12, 0), 0.17, wood)
            for x in [-1.55, 1.55]:
                box(parent, Vector3(0.14, 3.0, 0.24), plank, Vector3(x, 1.5, 0))
            var hinge := Node3D.new()
            hinge.name = "DoorLeaf"
            hinge.position = Vector3(-1.39, 0, 0)
            parent.add_child(hinge)
            for i in range(7):
                var x := 0.19 + float(i) * 0.39
                box(hinge, Vector3(0.38, 2.58, 0.15), plank.lightened(float(i % 3) * 0.028), Vector3(x, 1.42, 0))
            for y in [0.47, 1.42, 2.36]:
                box(hinge, Vector3(2.65, 0.12, 0.09), wood, Vector3(1.37, y, -0.12))
            sphere(hinge, 0.105, Color(0.78, 0.65, 0.30), Vector3(2.42, 1.28, 0.16))
        "window_panel":
            # Solid knee wall with open upper window; fixed rain-resistant wooden lattice.
            for x in [-1.56, 1.56]:
                beam(parent, Vector3(x, 0, 0), Vector3(x, 3.17, 0), 0.16, wood)
            for y in [0.21, 3.10]:
                beam(parent, Vector3(-1.56, y, 0), Vector3(1.56, y, 0), 0.14, wood)
            for i in range(8):
                var x := (float(i) - 3.5) * 0.38
                box(parent, Vector3(0.365, 1.03, 0.17), plank.lightened(float(i % 3) * 0.028), Vector3(x, 0.74, 0))
                box(parent, Vector3(0.365, 0.39, 0.17), plank.lightened(float(i % 2) * 0.03), Vector3(x, 2.85, 0))
            for y in [1.32, 2.62]:
                beam(parent, Vector3(-1.54, y, 0), Vector3(1.54, y, 0), 0.12, wood)
            beam(parent, Vector3(0, 1.32, 0), Vector3(0, 2.62, 0), 0.09, wood)
            box(parent, Vector3(3.37, 0.14, 0.46), plank, Vector3(0, 1.31, 0.18))
        "roof_panel":
            # Raised pitched thatch leaves a visible cavity below the roof.
            for side in [-1,1]:
                beam(parent,Vector3(0,3.65,-1.75),Vector3(side*1.75,2.55,-1.75),0.12,wood)
                beam(parent,Vector3(0,3.65,1.75),Vector3(side*1.75,2.55,1.75),0.12,wood)
                for i in range(10):
                    var z := (float(i)-4.5)*0.36
                    var high := Vector3(0,3.68,z)
                    var low := Vector3(side*1.83,2.50,z)
                    var strip := box(parent,Vector3(2.16,0.075,0.35),Color(0.53+float(i%3)*0.025,0.47+float(i%2)*0.02,0.26),high.lerp(low,0.52))
                    strip.rotation.z = -side*0.57
            beam(parent,Vector3(0,3.7,-1.85),Vector3(0,3.7,1.85),0.13,wood)
        "reinforced_wall":
            # Premium stone-footed timber wall, ribbed steel bracing and visible joints.
            var granite := Color(0.43,0.45,0.43)
            var steel := Color(0.54,0.60,0.59)
            var dark_plank := Color(0.39,0.29,0.19)
            for x in [-1.58,1.58]:
                beam(parent,Vector3(x,0,0),Vector3(x,3.27,0),0.19,dark_plank)
                stone(parent,0.46,3,granite,Vector3(x,0.28,0),Vector3(0.8,0.62,0.82))
            for i in range(8):
                var x := (float(i)-3.5)*0.385
                box(parent,Vector3(0.365,2.46,0.22),dark_plank.lightened(float(i%4)*0.042),Vector3(x,1.85,0))
                box(parent,Vector3(0.37,0.58,0.39),granite.lightened(float(i%3)*0.037),Vector3(x,0.32,0))
            for y in [0.63,1.76,3.12]:
                beam(parent,Vector3(-1.53,y,0.17),Vector3(1.53,y,0.17),0.085,steel)
            for side in [-1.0,1.0]:
                beam(parent,Vector3(side*1.36,0.72,0.21),Vector3(-side*1.36,3.0,0.21),0.068,steel)
            for x in [-1.39,0,1.39]:
                for y in [0.72,1.76,3.08]:
                    sphere(parent,0.082,steel.lightened(0.16),Vector3(x,y,0.29))
        "reinforced_roof":
            # Cladded roof panels and slate tiles replace the thatch silhouette.
            var slate := Color(0.35,0.40,0.43)
            var rib := Color(0.40,0.33,0.23)
            var steel := Color(0.59,0.61,0.57)
            for side in [-1.0,1.0]:
                for z in [-1.62,1.62]:
                    beam(parent,Vector3(0,3.92,z),Vector3(side*1.89,2.58,z),0.15,rib)
                for i in range(10):
                    var zz := (float(i)-4.5)*0.35
                    var upper := Vector3(0,3.93,zz)
                    var lower := Vector3(side*1.90,2.59,zz)
                    var strip := box(parent,Vector3(2.36,0.095,0.345),slate.lightened(float(i%4)*0.028),upper.lerp(lower,0.5))
                    strip.rotation.z = -side*0.61
                    box(parent,Vector3(0.16,0.12,0.11),steel,Vector3(side*1.75,2.65,zz))
            beam(parent,Vector3(0,3.96,-1.83),Vector3(0,3.96,1.83),0.12,steel)
        "chest":
            # Wooden storage chest with brass hinges and edge reinforcements.
            for i in range(6):
                box(parent,Vector3(2.4,0.17,0.35),plank.lightened(float(i%3)*0.035),Vector3(0,0.26+float(i)*0.16,-0.45))
                box(parent,Vector3(2.4,0.17,0.35),plank.lightened(float((i+1)%3)*0.035),Vector3(0,0.26+float(i)*0.16,0.45))
            for i in range(3):
                box(parent,Vector3(2.5,0.12,0.44),plank.lightened(float(i)*0.02),Vector3(0,1.32,(float(i)-1.0)*0.41))
            for x in [-1.12,1.12]:
                box(parent,Vector3(0.11,1.12,1.25),wood,Vector3(x,0.72,0))
                for z in [-0.52,0.52]:
                    box(parent,Vector3(0.16,1.17,0.08),Color(0.56,0.49,0.29),Vector3(x,0.73,z))
            box(parent,Vector3(0.26,0.32,0.12),Color(0.78,0.67,0.37),Vector3(0,0.91,0.64))
        "bed":
            for x in [-1.25,1.25]:
                for z in [-1.8,1.8]:
                    beam(parent,Vector3(x,0,z),Vector3(x,0.82,z),0.18,wood)
            for i in range(6):
                box(parent,Vector3(2.75,0.18,0.65),plank.lightened(float(i%2)*0.025),Vector3(0,0.59,(float(i)-2.5)*0.64))
            box(parent,Vector3(2.52,0.29,2.9),Color(0.48,0.59,0.36),Vector3(0,0.86,-0.18))
            box(parent,Vector3(2.35,0.15,2.5),Color(0.76,0.73,0.49),Vector3(0,1.02,-0.27))
            box(parent,Vector3(2.0,0.31,0.76),Color(0.84,0.81,0.65),Vector3(0,1.17,1.05))
        "rain_collector":
            # Raised basin, canvas funnel, intake and a latched storage barrel.
            for x in [-1.3,1.3]:
                for z in [-1.3,1.3]:
                    beam(parent,Vector3(x,0,z),Vector3(x,2.5,z),0.13,wood)
            triangles(parent,PackedVector3Array([
                Vector3(-1.4,2.32,-1.4),Vector3(1.4,2.32,-1.4),Vector3(0,1.5,0),
                Vector3(1.4,2.32,-1.4),Vector3(1.4,2.32,1.4),Vector3(0,1.5,0),
                Vector3(1.4,2.32,1.4),Vector3(-1.4,2.32,1.4),Vector3(0,1.5,0),
                Vector3(-1.4,2.32,1.4),Vector3(-1.4,2.32,-1.4),Vector3(0,1.5,0)
            ]),Color(0.66,0.71,0.55))
            box(parent,Vector3(1.16,1.1,1.16),Color(0.43,0.29,0.17),Vector3(0,0.65,0))
            for y in [0.2,0.85,1.2]:
                box(parent,Vector3(1.3,0.09,1.3),Color(0.55,0.61,0.54),Vector3(0,y,0))
            sphere(parent,0.62,Color(0.18,0.43,0.49),Vector3(0,1.22,0),Vector3(1,0.12,1))
            beam(parent,Vector3(0,1.5,0),Vector3(0,1.3,0),0.14,Color(0.41,0.45,0.43))
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
            boat_stage(parent,5)

# Dynamic construction preview and structure share the same modular 3D geometry.
# Each phase adds new hull elements while retaining the earlier visible parts.
static func boat_stage(parent: Node3D, stage: int) -> void:
    stage = clampi(stage,1,5)
    var timber := Color(0.39,0.25,0.12)
    var plank := Color(0.64,0.45,0.23)
    var iron := Color(0.43,0.47,0.46)
    # 1/5: timber keel, upward-curving bow and five cross ribs.
    beam(parent,Vector3(0,-0.18,-4.45),Vector3(0,-0.18,4.40),0.22,timber)
    beam(parent,Vector3(0,-0.18,-4.45),Vector3(0,1.12,-5.15),0.17,timber)
    beam(parent,Vector3(0,-0.18,4.40),Vector3(0,0.75,4.66),0.15,timber)
    for i in range(5):
        var z := -3.6 + float(i)*1.75
        var width := 1.15 + 0.55 * sin(float(i+1)/6.0*PI)
        for side in [-1.0,1.0]:
            beam(parent,Vector3(0,-0.12,z),Vector3(side*width,0.82,z),0.12,timber)
            beam(parent,Vector3(side*width,0.82,z),Vector3(side*(width+0.06),1.15,z),0.095,timber)
        beam(parent,Vector3(-width,0.76,z),Vector3(width,0.76,z),0.09,timber)
    if stage >= 2:
        # 2/5: overlapping hull strakes with a pointed bow.
        var hull := PackedVector3Array()
        for i in range(12):
            var z := -4.2 + float(i)*0.7
            var next_z := z + 0.7
            var width := maxf(0.15,sin((float(i)+0.3)/12.6*PI)*1.85)
            var next_width := maxf(0.15,sin((float(i)+1.3)/12.6*PI)*1.85)
            for side in [-1.0,1.0]:
                var a := Vector3(side*width,0.79,z)
                var b := Vector3(side*next_width,0.79,next_z)
                var c := Vector3(0,-0.19,z)
                var d := Vector3(0,-0.19,next_z)
                hull.append_array(PackedVector3Array([a,c,b,b,c,d]))
        triangles(parent,hull,timber.lightened(0.08))
        for side in [-1.0,1.0]:
            beam(parent,Vector3(side*0.15,0.47,-4.33),
                Vector3(side*0.15,0.60,4.20),0.05,plank)
    if stage >= 3:
        # 3/5: visible deck timbers and cross ties.
        for i in range(12):
            var z := -4.05 + float(i)*0.69
            var width := maxf(0.45,sin((float(i)+0.5)/12.6*PI)*1.76)
            box(parent,Vector3(width*1.9,0.13,0.62),
                plank.lightened(float(i%3)*0.032),Vector3(0,0.67,z))
        for side in [-1.0,1.0]:
            beam(parent,Vector3(side*1.05,0.91,-2.75),
                Vector3(side*1.05,0.91,2.80),0.062,iron)
    if stage >= 4:
        # 4/5: mast, spars and diagonal lashings.
        beam(parent,Vector3(0,0.71,0),Vector3(0,7.35,0),0.15,timber)
        beam(parent,Vector3(0,2.05,0),Vector3(2.72,2.05,0),0.095,timber)
        beam(parent,Vector3(0,5.20,0),Vector3(2.05,5.20,0),0.065,timber)
        for side in [-1.0,1.0]:
            beam(parent,Vector3(0,6.80,0),Vector3(side*1.60,0.86,-2.12),
                0.027,Color(0.64,0.55,0.38))
    if stage >= 5:
        # 5/5: sail, rudder and final coastal rigging; only then can one escape.
        triangles(parent,PackedVector3Array([
            Vector3(0.15,7.08,0),Vector3(2.63,2.24,0.07),Vector3(0.15,2.24,0),
            Vector3(0.15,7.08,0),Vector3(2.03,5.02,0.07),Vector3(2.63,2.24,0.07)
        ]),Color(0.92,0.88,0.69))
        beam(parent,Vector3(0,6.93,0),Vector3(0,0.95,-3.82),
            0.024,Color(0.71,0.60,0.41))
        beam(parent,Vector3(0,0.53,4.10),Vector3(0,0.38,5.23),
            0.11,timber)
        box(parent,Vector3(0.18,1.28,0.95),plank.lightened(0.04),
            Vector3(0,-0.04,5.00))
        for side in [-1.0,1.0]:
            box(parent,Vector3(0.07,0.09,0.44),iron,
                Vector3(side*0.22,0.81,4.00))

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
                        # Keep epidermis and cloth distinct in one merged mesh.
                        # Only the hero uses palette family 6 (skin); tools retain
                        # their own metal/wood grading and geometry.
                        var skin_tone: bool = color.r > 0.54 and color.r < 0.74 and color.g > 0.34 and color.g < 0.56 and color.b > 0.23 and color.b < 0.37
                        var hide_tone: bool = color.r > color.g * 1.14 and color.g > color.b * 1.10 and color.r < 0.54
                        var hair_tone: bool = cache_key.begins_with("hero_head_") and color.r < 0.26 and color.g < 0.25 and color.b < 0.23
                        family = 8.0 if hair_tone else (6.0 if skin_tone else (7.0 if hide_tone else 5.0))
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
    # True branching broadleaf silhouette, replacing the old stacked
    # spherical green rock crowns. Every leaf is real 3D geometry, colored in
    # three green palettes and merged into a cached mesh for mobile drawing.
    var trunk := Color(0.33,0.245,0.16)
    var height := 5.3 + float(variant % 3) * 0.65
    var lean := Vector3(0.19,0,0.13)
    beam(parent,Vector3.ZERO,Vector3(0,height*0.49,0),0.43,trunk)
    beam(parent,Vector3(0,height*0.49,0),lean+Vector3.UP*height*0.83,0.34,trunk.lightened(0.026))
    beam(parent,lean+Vector3.UP*height*0.83,lean*1.32+Vector3.UP*height,0.22,trunk)
    for root in range(5):
        var angle := float(root)*TAU/5.0
        var outward := Vector3(cos(angle),0,sin(angle))
        beam(parent,outward*0.55+Vector3.UP*0.02,Vector3(0,height*0.22,0),0.12,trunk.darkened(0.09))
    var leaves_dark := PackedVector3Array()
    var leaves_mid := PackedVector3Array()
    var leaves_sun := PackedVector3Array()
    for branch_id in range(10):
        var a := float(branch_id)*TAU/10.0+float(variant)*0.17
        var radial := Vector3(cos(a),0,sin(a))
        var side := Vector3(-radial.z,0,radial.x)
        var start_point := Vector3(0,height*(0.54+float(branch_id%3)*0.06),0)
        var end_point := radial*(2.05+float((branch_id+variant)%4)*0.31) + Vector3.UP*(height+float(branch_id%3)*0.35-0.38)
        beam(parent,start_point,end_point,0.12 if branch_id%2==0 else 0.105,trunk)
        for leaflet in range(18):
            var t := 0.33+float(leaflet%9)*0.075
            var center := start_point.lerp(end_point,t)
            center += side*((float((leaflet*7+branch_id)%7)-3.0)*0.19)
            center.y += sin(float(leaflet)*2.4+float(branch_id))*0.29
            var leaf_a := float(leaflet)*2.39996+float(branch_id)*0.13
            var heading := radial*0.68 + side*sin(leaf_a)*0.74
            heading = heading.normalized()
            var lateral := Vector3(-heading.z,0,heading.x)
            var length := 0.23 + float((leaflet+branch_id)%5)*0.055
            var width := length * (0.29+float(leaflet%3)*0.05)
            var tip := center + heading*length + Vector3.UP*(0.08+float(leaflet%2)*0.07)
            var mid := center.lerp(tip,0.56)+Vector3.UP*0.035
            var leaflet_triangles := PackedVector3Array([
                center, mid+lateral*width, tip,
                center, tip, mid-lateral*width
            ])
            match (leaflet+branch_id+variant)%3:
                0: leaves_dark.append_array(leaflet_triangles)
                1: leaves_mid.append_array(leaflet_triangles)
                _: leaves_sun.append_array(leaflet_triangles)
    triangles(parent,leaves_dark,Color(0.135,0.315,0.16))
    triangles(parent,leaves_mid,Color(0.17,0.385,0.18))
    triangles(parent,leaves_sun,Color(0.23,0.43,0.19))


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
