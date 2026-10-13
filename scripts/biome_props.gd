extends RefCounted
class_name SurvivorBiomeProps

# Original, reproducible microhabitats. Low-profile decorative meshes are
# deliberately non-colliding: saved traversal, resources and building sockets
# keep the same coordinates and collision rules in every save version.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color, plant: bool = true) -> void:
    st.set_color(tint)
    st.set_uv2(Vector2(1.0 if plant else 0.0, 0.0))
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _finish(st: SurfaceTool) -> ArrayMesh:
    st.generate_normals()
    st.index()
    return st.commit()

static func dune_reeds() -> ArrayMesh:
    # Curved rows of beach plants, not three crossed rectangular billboards.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for tuft in range(9):
        var angle := float(tuft) * 2.39996
        var axis := Vector3(cos(angle), 0, sin(angle))
        var side := Vector3(-axis.z, 0, axis.x)
        var base := axis * (0.09 + float(tuft % 3) * 0.07)
        var tall := 0.54 + float(tuft % 4) * 0.13
        var width := 0.05 + float(tuft % 3) * 0.008
        var mid := base + axis * 0.075 + Vector3.UP * (tall * 0.55)
        var tip := base + axis * (0.26 + tall * 0.13) + Vector3.UP * tall
        var hue := Color(0.39, 0.42, 0.21) if tuft % 3 == 0 else Color(0.52, 0.49, 0.25)
        _tri(st, base - side * width, mid - side * (width * 0.61), mid + side * (width * 0.61), hue)
        _tri(st, base - side * width, mid + side * (width * 0.61), base + side * width, hue.darkened(0.07))
        _tri(st, mid - side * width * 0.61, tip, mid + side * width * 0.61, hue.lightened(0.08))
    return _finish(st)

static func forest_seedlings() -> ArrayMesh:
    # Layered native understory: individually tapered fern leaflets and stems.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for frond in range(7):
        var angle := float(frond) * TAU / 7.0 + 0.19
        var radial := Vector3(cos(angle), 0, sin(angle))
        var side := Vector3(-radial.z, 0, radial.x)
        var length := 0.82 + float(frond % 3) * 0.19
        var top := radial * (0.48 + float(frond % 2) * 0.12) + Vector3.UP * length
        var start := Vector3(0.0, 0.05, 0.0)
        for section in range(7):
            var t := float(section) / 7.0
            var next_t := float(section + 1) / 7.0
            var a := start.lerp(top, t) + Vector3.UP * sin(t * PI) * 0.13
            var b := start.lerp(top, next_t) + Vector3.UP * sin(next_t * PI) * 0.13
            var stem_tint := Color(0.18, 0.27, 0.13)
            _tri(st, a - side * 0.013, b, a + side * 0.013, stem_tint)
            if section >= 1 and section <= 5:
                var reach := sin(t * PI) * (0.28 + float(frond % 2) * 0.05)
                for direction in [-1.0, 1.0]:
                    var leaf_end: Vector3 = a + side * direction * reach + radial * 0.11 + Vector3.UP * (0.01 - t * 0.09)
                    var leaf_tint := Color(0.16, 0.39, 0.20) if frond % 2 == 0 else Color(0.22, 0.45, 0.20)
                    _tri(st, a, leaf_end, b, leaf_tint)
    return _finish(st)

static func coastal_stones() -> ArrayMesh:
    # Three squat, irregular rock fragments per instance. Varied heights and
    # side faces add real world-space relief without dynamic shadows.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for rock in range(3):
        var center := Vector3(-0.34 + float(rock) * 0.32, 0.0, 0.13 * float(rock % 2))
        var radius := 0.22 + float(rock % 2) * 0.07
        var height := 0.16 + float(rock % 3) * 0.045
        var color := Color(0.40, 0.44, 0.40).lerp(Color(0.52, 0.49, 0.42), float(rock) * 0.27)
        var crown := center + Vector3(0.04, height, -0.018)
        for edge in range(9):
            var theta := TAU * float(edge) / 9.0
            var theta2 := TAU * float(edge + 1) / 9.0
            var irregular := 0.88 + float((edge * 7 + rock * 3) % 5) * 0.065
            var next_irregular := 0.88 + float(((edge + 1) * 7 + rock * 3) % 5) * 0.065
            var a := center + Vector3(cos(theta) * radius * irregular, 0.016, sin(theta) * radius * irregular * 0.82)
            var b := center + Vector3(cos(theta2) * radius * next_irregular, 0.016, sin(theta2) * radius * next_irregular * 0.82)
            var shoulder := center + Vector3(cos(theta) * radius * irregular * 0.80, height * 0.62, sin(theta) * radius * irregular * 0.65)
            var next_shoulder := center + Vector3(cos(theta2) * radius * next_irregular * 0.80, height * 0.62, sin(theta2) * radius * next_irregular * 0.65)
            _tri(st, shoulder, crown, next_shoulder, color.lightened(float(edge % 3) * 0.06), false)
            _tri(st, a, shoulder, b, color.darkened(float(edge % 2) * 0.10), false)
            _tri(st, b, shoulder, next_shoulder, color.darkened(float(edge % 3) * 0.04), false)
    return _finish(st)
