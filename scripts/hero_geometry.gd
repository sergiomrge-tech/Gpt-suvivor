extends RefCounted
class_name SurvivorHeroGeometry

# v1.4: closed-form lofts replace the stacked cylinders of the survivor.
# Profiles contain (height, half-width, half-depth, depth-offset). The geometry
# stays parented to the original animated joints, preserving tools and saves.
static func _ring_point(profile: Vector4, theta: float) -> Vector3:
    return Vector3(cos(theta) * profile.y, profile.x, sin(theta) * profile.z + profile.w)

static func loft(parent: Node3D, profile: PackedVector4Array, color: Color, sides: int = 20) -> MeshInstance3D:
    assert(profile.size() >= 2)
    var divisions: int = maxi(12, sides)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(0)
    for level in range(profile.size() - 1):
        var upper: Vector4 = profile[level]
        var lower: Vector4 = profile[level + 1]
        for side in range(divisions):
            var angle0 := TAU * float(side) / float(divisions)
            var angle1 := TAU * float(side + 1) / float(divisions)
            var a := _ring_point(upper, angle0)
            var b := _ring_point(upper, angle1)
            var c := _ring_point(lower, angle0)
            var d := _ring_point(lower, angle1)
            # Profiles are ordered top -> bottom. Consistent outward winding
            # prevents the body from vanishing with back-face culling enabled.
            st.set_uv(Vector2(float(side) / float(divisions), float(level) / float(profile.size())))
            st.add_vertex(a)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level) / float(profile.size())))
            st.add_vertex(b)
            st.set_uv(Vector2(float(side) / float(divisions), float(level + 1) / float(profile.size())))
            st.add_vertex(c)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level) / float(profile.size())))
            st.add_vertex(b)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level + 1) / float(profile.size())))
            st.add_vertex(d)
            st.set_uv(Vector2(float(side) / float(divisions), float(level + 1) / float(profile.size())))
            st.add_vertex(c)
    st.index()
    st.generate_normals()
    return SurvivorModels.piece(parent, st.commit(), color, Vector3.ZERO)

static func shaped_limb(parent: Node3D, length: float, upper: float, lower: float, color: Color, depth: float = 0.94) -> MeshInstance3D:
    # Rounded joint taper instead of a constant-radius cylindrical forearm/leg.
    return loft(parent, PackedVector4Array([
        Vector4(0.025, upper * 0.70, upper * depth * 0.72, 0.0),
        Vector4(-0.045, upper, upper * depth, 0.0),
        Vector4(-length * 0.38, lerpf(upper, lower, 0.35), lerpf(upper, lower, 0.35) * depth, 0.0),
        Vector4(-length * 0.85, lower, lower * depth, 0.0),
        Vector4(-length, lower * 0.82, lower * depth * 0.84, 0.0)
    ]), color, 16)
