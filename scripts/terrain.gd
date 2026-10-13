extends Node3D
class_name SurvivorTerrain

const HALF_SIZE := 258.0
const SEGMENTS := 256
var coast_noise: FastNoiseLite
var hill_noise: FastNoiseLite
var sea_level := -0.48
var sun: DirectionalLight3D
var atmosphere: Environment
var ground_material: ShaderMaterial
var ocean_material: ShaderMaterial
var daylight_amount := 1.0
var rainfall_amount := 0.0
var storm_amount := 0.0

func _init() -> void:
    coast_noise = FastNoiseLite.new()
    coast_noise.seed = 1712
    coast_noise.frequency = 0.023
    hill_noise = FastNoiseLite.new()
    hill_noise.seed = 943
    hill_noise.frequency = 0.014
    hill_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    hill_noise.fractal_octaves = 3

func radius_at_angle(a: float) -> float:
    return 201.0 + 13.0 * sin(a * 5.0 + 0.6) + 10.0 * cos(a * 9.0 - 0.4)

func natural_height_at(x: float, z: float) -> float:
    var radius := Vector2(x, z).length()
    var a := atan2(z, x)
    var normalized := radius / radius_at_angle(a)
    var inland := clampf(1.0 - normalized, 0.0, 1.0)
    var beach_rise := minf(1.0, inland * 27.0) * 3.85
    var hills := pow(inland, 1.8) * 30.0
    var noise := hill_noise.get_noise_2d(x, z) * inland * 11.0
    return -3.0 + beach_rise + hills + noise

func height_at(x: float,z: float) -> float:
    var height := natural_height_at(x,z)
    for center in [Vector2(80,20),Vector2(-90,-60)]:
        var local: Vector2 = Vector2(x,z)-center-Vector2(0,-4.0)
        var extent := maxf(absf(local.x)/6.0,absf(local.y)/7.5)
        if extent < 1.35:
            var blend := 1-smoothstep(0.8,1.35,extent)
            height = lerpf(height,natural_height_at(center.x,center.y),blend)
    return height

func set_surface_detail(enabled: bool) -> void:
    # Micro-normal texture samples are skipped on the low-power mobile preset.
    if ground_material != null:
        ground_material.set_shader_parameter("surface_microdetail", 1.0 if enabled else 0.0)
        ground_material.set_shader_parameter("real_pbr_full_detail",enabled)

func set_trail_mask(mask: Texture2D) -> void:
    var material := get_node("IslandTerrain").material_override as ShaderMaterial
    material.set_shader_parameter("trail_mask",mask)
    material.set_shader_parameter("show_trails",true)

func is_land(x: float, z: float) -> bool:
    return height_at(x, z) > sea_level + 0.3

func is_shore(x: float, z: float) -> bool:
    var h := height_at(x, z)
    var angle := atan2(z, x)
    var coastal_band := Vector2(x, z).length() > radius_at_angle(angle) * 0.962
    return coastal_band and h >= sea_level + 0.3 and h < 2.7

func _ready() -> void:
    _build_terrain()
    _build_ocean()
    _build_lighting()

func terrain_color(h: float, x: float, z: float) -> Color:
    if h < -0.5:
        return Color(0.16, 0.54, 0.5)
    if h < 2.6:
        return Color(0.84, 0.73, 0.49).lerp(Color(0.9, 0.82, 0.61), clampf((h + 0.5) / 4.0, 0.0, 1.0))
    if h < 14.0:
        var blend := clampf((h - 2.6) / 4.0, 0.0, 1.0)
        return Color(0.76, 0.68, 0.42).lerp(Color(0.19, 0.43, 0.26), blend)
    return Color(0.19, 0.4, 0.25).lerp(Color(0.4, 0.42, 0.32), clampf((h - 20.0) / 25.0, 0.0, 1.0))

func _terrain_vertex(st: SurfaceTool, x: float, z: float) -> void:
    var h := height_at(x, z)
    st.set_color(terrain_color(h, x, z))
    st.set_uv(Vector2(x, z) / 30.0)
    st.add_vertex(Vector3(x, h, z))

func _terrain_cell(st: SurfaceTool,x: float,z: float,step: float) -> void:
    # Godot's clockwise faces point upward from the island surface.
    _terrain_vertex(st,x,z)
    _terrain_vertex(st,x+step,z)
    _terrain_vertex(st,x,z+step)
    _terrain_vertex(st,x+step,z)
    _terrain_vertex(st,x+step,z+step)
    _terrain_vertex(st,x,z+step)

func _build_terrain() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var spacing := HALF_SIZE * 2.0 / float(SEGMENTS)
    for xi in range(SEGMENTS):
        for zi in range(SEGMENTS):
            var x := -HALF_SIZE + xi * spacing
            var z := -HALF_SIZE + zi * spacing
            var center := Vector2(x + spacing * 0.5,z + spacing * 0.5)
            var normalized := center.length() / radius_at_angle(atan2(center.y,center.x))
            # A shared, uniform grid prevents cracks between different edge
            # tessellations. Omit the invisible distant seabed to save triangles.
            if normalized > 1.04:
                continue
            _terrain_cell(st,x,z,spacing)
    st.index()
    st.generate_normals()
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "IslandTerrain"
    mesh_instance.mesh = st.commit()
    var material := ShaderMaterial.new()
    material.shader = load("res://shaders/ground.gdshader")
    material.set_shader_parameter("detail_noise", load("res://assets/materials/detail_noise.png"))
    # A = beach, B = dense forest floor, C = exposed coastal rock.
    var root := "res://assets/real_world/textures/"
    var scans := {
        "pbr_sand_diff":root+"aerial_beach_01/aerial_beach_01_diff.jpg",
        "pbr_sand_normal":root+"aerial_beach_01/aerial_beach_01_nor_gl.jpg",
        "pbr_sand_rough":root+"aerial_beach_01/aerial_beach_01_rough.jpg",
        "pbr_jungle_diff":root+"coast_sand_05/coast_sand_05_diff.jpg",
        "pbr_jungle_normal":root+"coast_sand_05/coast_sand_05_nor_gl.jpg",
        "pbr_jungle_rough":root+"coast_sand_05/coast_sand_05_rough.jpg",
        "pbr_rock_diff":root+"seaside_rock/seaside_rock_diff.jpg",
        "pbr_rock_normal":root+"seaside_rock/seaside_rock_nor_gl.jpg",
        "pbr_rock_rough":root+"seaside_rock/seaside_rock_rough.jpg"
    }
    var scans_ready := true
    for shader_key in scans:
        if not ResourceLoader.exists(scans[shader_key]):
            scans_ready = false
            break
    if scans_ready:
        for shader_key in scans:
            material.set_shader_parameter(shader_key,load(scans[shader_key]))
    material.set_shader_parameter("real_pbr_assets_ready",scans_ready)
    material.set_shader_parameter("real_pbr_full_detail",true)
    ground_material = material
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _build_ocean() -> void:
    var ocean := MeshInstance3D.new()
    ocean.name = "TropicalOcean"
    var plane := PlaneMesh.new()
    plane.size = Vector2(1200.0, 1200.0)
    plane.subdivide_width = 96
    plane.subdivide_depth = 96
    ocean.mesh = plane
    ocean.position.y = sea_level
    var water := ShaderMaterial.new()
    water.shader = load("res://shaders/ocean.gdshader")
    ocean_material = water
    ocean.material_override = water
    add_child(ocean)

func _build_lighting() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.52, 0.78, 0.93)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.76, 0.87, 1.0)
    env.ambient_light_energy = 0.28
    env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    # Thin distance haze adds scale without forcing expensive volumetric fog.
    env.fog_enabled = true
    env.fog_light_color = Color(0.68,0.78,0.82)
    env.fog_density = 0.0026
    env.fog_sun_scatter = 0.07
    env_node.environment = env
    atmosphere = env
    add_child(env_node)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-58, 35, -8)
    sun.light_energy = 0.75
    sun.light_color = Color(1.0, 0.92, 0.75)
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 100.0
    add_child(sun)

func set_time_of_day(time_fraction: float) -> void:
    # Dawn and dusk use a broad warm transition; night keeps a readable cool fill.
    var sun_height := sin((time_fraction - 0.25) * TAU)
    daylight_amount = smoothstep(-0.17, 0.52, sun_height)
    var dusk := (1.0 - smoothstep(0.09, 0.52, absf(sun_height))) * daylight_amount
    sun.rotation_degrees.x = -8.0 - maxf(sun_height,0.0) * 65.0
    sun.rotation_degrees.y = 35.0 + cos(time_fraction * TAU) * 28.0
    sun.light_color = Color(1.0, 0.93, 0.77).lerp(Color(1.0,0.60,0.39),dusk*0.60)
    _update_atmosphere()

func set_weather(rain: float, storm: float) -> void:
    rainfall_amount = clampf(rain, 0.0, 1.0)
    storm_amount = clampf(storm, 0.0, 1.0)
    if ground_material != null:
        ground_material.set_shader_parameter("rain_amount",rainfall_amount)
    if ocean_material != null:
        ocean_material.set_shader_parameter("wind_strength",0.35 + rainfall_amount * 0.3 + storm_amount * 0.55)
    if SurvivorModels.merged_material != null:
        SurvivorModels.merged_material.set_shader_parameter("rain_amount",rainfall_amount)
        SurvivorModels.merged_material.set_shader_parameter("wind_strength",0.45 + rainfall_amount * 0.60 + storm_amount * 0.35)
    _update_atmosphere()

func _update_atmosphere() -> void:
    if atmosphere == null or sun == null:
        return
    var cloud := rainfall_amount * 0.24 + storm_amount * 0.35
    sun.light_energy = (0.055 + daylight_amount * 0.82) * (1.0 - cloud)
    atmosphere.ambient_light_energy = (0.13 + daylight_amount * 0.26) * (1.0 - cloud * 0.45)
    var night := Color(0.045,0.085,0.16)
    var daytime := Color(0.49,0.72,0.88)
    atmosphere.background_color = night.lerp(daytime,daylight_amount).lerp(Color(0.22,0.31,0.39),cloud)
    atmosphere.ambient_light_color = Color(0.36,0.50,0.67).lerp(Color(0.80,0.88,0.98),daylight_amount)
    atmosphere.fog_density = 0.0026 + rainfall_amount*0.0034 + storm_amount*0.0052
    atmosphere.fog_light_color = Color(0.09,0.14,0.23).lerp(Color(0.69,0.79,0.82),daylight_amount).lerp(Color(0.36,0.43,0.47),cloud)

