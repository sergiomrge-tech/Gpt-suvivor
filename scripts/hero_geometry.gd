extends RefCounted
class_name SurvivorHeroGeometry

# v1.4: closed-form lofts replace the stacked cylinders of the survivor.
# Profiles contain (height, half-width, half-depth, depth-offset). The geometry
# stays parented to the original animated joints, preserving tools and saves.
static func _ring_point(profile: Vector4, theta: float) -> Vector3:
    return Vector3(cos(theta) * profile.y, profile.x, sin(theta) * profile.z + profile.w)

# Smooth anatomical contour transitions without adding separate spheres or
# disconnected seams. Catmull-Rom interpolation uses the original ordered
# profiles as the exact boundaries of the mesh.
static func resample_profile(profile: PackedVector4Array, subdivisions: int = 2) -> PackedVector4Array:
    assert(profile.size() >= 2)
    var count := maxi(1,subdivisions)
    var result := PackedVector4Array()
    for index in range(profile.size()-1):
        var before: Vector4 = profile[maxi(0,index-1)]
        var a: Vector4 = profile[index]
        var b: Vector4 = profile[index+1]
        var after: Vector4 = profile[mini(profile.size()-1,index+2)]
        for sub in range(count):
            var t := float(sub)/float(count)
            var t2 := t*t
            var t3 := t2*t
            var smoothed: Vector4 = (2.0*a + (b-before)*t +
                (2.0*before-5.0*a+4.0*b-after)*t2 +
                (-before+3.0*a-3.0*b+after)*t3)*0.5
            # Spline interpolation must not invert anatomy or run beyond its
            # original silhouette at joints. Preserve monotonic height.
            smoothed.x = lerpf(a.x,b.x,t)
            smoothed.y = clampf(smoothed.y,0.008,maxf(a.y,b.y)*1.07)
            smoothed.z = clampf(smoothed.z,0.008,maxf(a.z,b.z)*1.07)
            result.append(smoothed)
    result.append(profile[profile.size()-1])
    return result

static func loft(parent: Node3D, profile: PackedVector4Array, color: Color, sides: int = 20) -> MeshInstance3D:
    assert(profile.size() >= 2)
    var divisions: int = maxi(12, sides)
    # Two smoothly interpolated rings between sculpted control contours.
    # For an 18-sided limb this remains inexpensive on mobile hardware.
    var shape: PackedVector4Array = resample_profile(profile,2)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(0)
    for level in range(shape.size() - 1):
        var upper: Vector4 = shape[level]
        var lower: Vector4 = shape[level + 1]
        for side in range(divisions):
            var angle0 := TAU * float(side) / float(divisions)
            var angle1 := TAU * float(side + 1) / float(divisions)
            var a := _ring_point(upper, angle0)
            var b := _ring_point(upper, angle1)
            var c := _ring_point(lower, angle0)
            var d := _ring_point(lower, angle1)
            # Profiles are ordered top -> bottom. Consistent outward winding
            # prevents the body from vanishing with back-face culling enabled.
            st.set_uv(Vector2(float(side) / float(divisions), float(level) / float(shape.size()-1)))
            st.add_vertex(a)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level) / float(shape.size()-1)))
            st.add_vertex(b)
            st.set_uv(Vector2(float(side) / float(divisions), float(level + 1) / float(shape.size()-1)))
            st.add_vertex(c)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level) / float(shape.size()-1)))
            st.add_vertex(b)
            st.set_uv(Vector2(float(side + 1) / float(divisions), float(level + 1) / float(shape.size()-1)))
            st.add_vertex(d)
            st.set_uv(Vector2(float(side) / float(divisions), float(level + 1) / float(shape.size()-1)))
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

# v1.7: sculpted footwear uses continuous volume along the direction of
# walking. This removes the old ankle-attached rectangular shoe blocks.
# It is entirely visual: the walking/raycast footprint remains identical.
static func _foot_volume(parent: Node3D, color: Color, sole: bool) -> MeshInstance3D:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(0)
    var profile := PackedVector4Array([
        Vector4(-0.28, 0.025, 0.026, -0.145),
        Vector4(-0.21, 0.137, 0.083, -0.140),
        Vector4(-0.03, 0.164, 0.107, -0.132),
        Vector4(0.20, 0.171, 0.112, -0.129),
        Vector4(0.42, 0.186, 0.092, -0.142),
        Vector4(0.56, 0.149, 0.073, -0.149),
        Vector4(0.62, 0.025, 0.020, -0.147)
    ])
    var sides := 18
    for ring in range(profile.size() - 1):
        var p0: Vector4 = profile[ring]
        var p1: Vector4 = profile[ring+1]
        for side in range(sides):
            var theta0 := TAU * float(side) / float(sides)
            var theta1 := TAU * float(side+1) / float(sides)
            var v00 := Vector3(cos(theta0)*p0.y, p0.w + sin(theta0)*p0.z, p0.x)
            var v01 := Vector3(cos(theta1)*p0.y, p0.w + sin(theta1)*p0.z, p0.x)
            var v10 := Vector3(cos(theta0)*p1.y, p1.w + sin(theta0)*p1.z, p1.x)
            var v11 := Vector3(cos(theta1)*p1.y, p1.w + sin(theta1)*p1.z, p1.x)
            # Physical close-up revealed clown-sized shoes. Reduce the toe
            # overhang and sole width while keeping the ankle at ground height.
            v00.x *= 0.81
            v01.x *= 0.81
            v10.x *= 0.81
            v11.x *= 0.81
            v00.z *= 0.68
            v01.z *= 0.68
            v10.z *= 0.68
            v11.z *= 0.68
            if sole:
                # Thin layered rubber edge underneath the boot, sharing the
                # exact topological shape without a cuboid protruding at the toe.
                v00.y = minf(v00.y, -0.195) - 0.02
                v01.y = minf(v01.y, -0.195) - 0.02
                v10.y = minf(v10.y, -0.195) - 0.02
                v11.y = minf(v11.y, -0.195) - 0.02
            st.set_uv(Vector2(float(side)/float(sides), float(ring)/float(profile.size())))
            st.add_vertex(v00)
            st.set_uv(Vector2(float(side+1)/float(sides), float(ring)/float(profile.size())))
            st.add_vertex(v01)
            st.set_uv(Vector2(float(side)/float(sides), float(ring+1)/float(profile.size())))
            st.add_vertex(v10)
            st.set_uv(Vector2(float(side+1)/float(sides), float(ring)/float(profile.size())))
            st.add_vertex(v01)
            st.set_uv(Vector2(float(side+1)/float(sides), float(ring+1)/float(profile.size())))
            st.add_vertex(v11)
            st.set_uv(Vector2(float(side)/float(sides), float(ring+1)/float(profile.size())))
            st.add_vertex(v10)
    st.index()
    st.generate_normals()
    return SurvivorModels.piece(parent, st.commit(), color, Vector3.ZERO)

static func boot(parent: Node3D, leather: Color, sole_color: Color) -> void:
    # Mid-cut boot collar + rounded organic shoe, heel, sole seam and laces.
    loft(parent, PackedVector4Array([
        Vector4(0.125,0.105,0.113,-0.015),
        Vector4(0.06,0.145,0.153,0.008),
        Vector4(-0.07,0.164,0.169,0.018),
        Vector4(-0.153,0.144,0.154,0.048)
    ]), leather.darkened(0.05), 20)
    _foot_volume(parent, leather, false)
    _foot_volume(parent, sole_color, true)
    # Individual lace bars make the top readable at the game camera distance.
    for lace in range(4):
        var z := 0.015 + float(lace)*0.061
        var y := -0.014 - float(lace)*0.019
        SurvivorModels.beam(parent,Vector3(-0.108,y,z),Vector3(0.108,y,z+0.022),0.010,Color(0.58,0.52,0.39))
    SurvivorModels.beam(parent,Vector3(-0.11,0.070,-0.08),Vector3(0.11,0.070,-0.08),0.016,sole_color.lightened(0.22))
