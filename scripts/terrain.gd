extends Node3D
class_name SurvivorTerrain

const HALF_SIZE = 256.0
const SEGMENTS = 128
const SEA_LEVEL = -0.48

var hill_noise: FastNoiseLite
var sun: DirectionalLight3D
var ocean: MeshInstance3D

func _init() -> void:
    hill_noise = FastNoiseLite.new()
    hill_noise.seed = 943
    hill_noise.frequency = 0.014
    hill_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    hill_noise.fractal_octaves = 3

func radius_at_angle(a: float) -> float:
    return 199.0 + 13.0 * sin(a * 5.0 + 0.6) + 10.0 * cos(a * 9.0 - 0.4)

func height_at(x: float, z: float) -> float:
    var radius: float = Vector2(x, z).length()
    var a: float = atan2(z, x)
    var inland: float = clampf(1.0 - radius / radius_at_angle(a), 0.0, 1.0)
    var beach_rise: float = minf(1.0, inland * 27.0) * 3.85
    var hills: float = pow(inland, 1.8) * 30.0
    var noise: float = hill_noise.get_noise_2d(x, z) * inland * 11.0
    return -3.0 + beach_rise + hills + noise

func is_land(x: float, z: float) -> bool:
    return height_at(x, z) > SEA_LEVEL + 0.3

func is_shore(x: float, z: float) -> bool:
    var h: float = height_at(x, z)
    return h > SEA_LEVEL + 0.3 and h < 2.7

func is_fishing_spot(x: float, z: float) -> bool:
    # Shallow coastal land, including the grassy edge beside the beach.
    var h: float = height_at(x, z)
    return h > SEA_LEVEL + 0.3 and h < 5.0

func _ready() -> void:
    _build_terrain()
    _build_ocean()
    _build_lighting()

func _terrain_color(h: float) -> Color:
    if h < SEA_LEVEL:
        return Color(0.17, 0.51, 0.46)
    if h < 2.6:
        return Color(0.84, 0.73, 0.49).lerp(Color(0.91, 0.83, 0.61), clampf((h + 0.5) / 4.0, 0.0, 1.0))
    if h < 14.0:
        return Color(0.76, 0.68, 0.42).lerp(Color(0.19, 0.43, 0.26), clampf((h - 2.6) / 4.0, 0.0, 1.0))
    return Color(0.19, 0.40, 0.25).lerp(Color(0.40, 0.42, 0.32), clampf((h - 20.0) / 25.0, 0.0, 1.0))

func _add_vertex(st: SurfaceTool, x: float, z: float) -> void:
    var h: float = height_at(x, z)
    st.set_color(_terrain_color(h))
    st.set_uv(Vector2(x, z) / 30.0)
    st.add_vertex(Vector3(x, h, z))

func _build_terrain() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var spacing: float = HALF_SIZE * 2.0 / float(SEGMENTS)
    for xi in range(SEGMENTS):
        for zi in range(SEGMENTS):
            var x: float = -HALF_SIZE + float(xi) * spacing
            var z: float = -HALF_SIZE + float(zi) * spacing
            _add_vertex(st, x, z)
            _add_vertex(st, x, z + spacing)
            _add_vertex(st, x + spacing, z)
            _add_vertex(st, x + spacing, z)
            _add_vertex(st, x, z + spacing)
            _add_vertex(st, x + spacing, z + spacing)
    st.generate_normals()
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "IslandTerrain"
    mesh_instance.mesh = st.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.95
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _build_ocean() -> void:
    ocean = MeshInstance3D.new()
    ocean.name = "TropicalOcean"
    var plane := PlaneMesh.new()
    plane.size = Vector2(1200.0, 1200.0)
    ocean.mesh = plane
    ocean.position.y = SEA_LEVEL
    var water := StandardMaterial3D.new()
    water.albedo_color = Color(0.035, 0.38, 0.52, 0.94)
    water.metallic = 0.16
    water.roughness = 0.31
    water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ocean.material_override = water
    add_child(ocean)

func _build_lighting() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.52, 0.78, 0.93)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.76, 0.87, 1.0)
    env.ambient_light_energy = 0.75
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58.0, 35.0, -8.0)
    sun.light_energy = 1.3
    sun.light_color = Color(1.0, 0.92, 0.75)
    sun.shadow_enabled = true
    add_child(sun)

func set_time_of_day(fraction: float) -> void:
    var sun_strength: float = clampf(0.5 + 0.5 * cos(fraction * TAU - PI), 0.17, 1.0)
    sun.rotation_degrees.x = -15.0 - sun_strength * 58.0
    sun.light_energy = 0.32 + sun_strength * 1.1
