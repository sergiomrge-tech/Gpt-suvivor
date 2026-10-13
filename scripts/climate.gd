extends Node3D
class_name SurvivorClimate

# Deterministic weather shared with survival simulation and rendering.
# Eight hundred seconds per loop: a rainy window with a short storm peak.
const CYCLE_SECONDS := 800.0
const RAIN_START := 200.0
const RAIN_END := 400.0

var particles: CPUParticles3D
var light_mode := false
var intensity := 0.0
var wind_strength := 0.2

static func rainfall_at(elapsed: float) -> float:
    var phase := fposmod(maxf(elapsed, 0.0), CYCLE_SECONDS)
    if phase <= RAIN_START or phase >= RAIN_END:
        return 0.0
    return smoothstep(RAIN_START, RAIN_START + 24.0, phase) * (1.0 - smoothstep(RAIN_END - 27.0, RAIN_END, phase))

static func storm_at(elapsed: float) -> float:
    var phase := fposmod(maxf(elapsed, 0.0), CYCLE_SECONDS)
    return rainfall_at(elapsed) * smoothstep(260.0, 290.0, phase) * (1.0 - smoothstep(334.0, 362.0, phase))

static func wind_at(elapsed: float) -> float:
    return clampf(0.25 + sin(elapsed * 0.015) * 0.12 + rainfall_at(elapsed) * 0.38 + storm_at(elapsed) * 0.34, 0.08, 1.0)

static func label_at(elapsed: float) -> String:
    var storm := storm_at(elapsed)
    var rain := rainfall_at(elapsed)
    if storm > 0.5:
        return "Temporal"
    if rain > 0.12:
        return "Chuva"
    return "Céu limpo"

func _ready() -> void:
    particles = CPUParticles3D.new()
    particles.name = "TropicalRain"
    particles.amount = 280
    particles.lifetime = 1.6
    particles.explosiveness = 0.0
    particles.randomness = 0.15
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    particles.emission_box_extents = Vector3(18.0, 3.0, 18.0)
    particles.direction = Vector3(0.12, -1.0, 0.05)
    particles.spread = 7.0
    particles.gravity = Vector3(0.0, -9.0, 0.0)
    particles.initial_velocity_min = 16.0
    particles.initial_velocity_max = 21.0
    particles.emitting = false
    var streak := QuadMesh.new()
    streak.size = Vector2(0.035, 0.57)
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(0.71, 0.84, 0.95, 0.52)
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    streak.material = material
    particles.mesh = streak
    add_child(particles)

func set_light_mode(value: bool) -> void:
    light_mode = value
    if is_instance_valid(particles):
        particles.amount = 90 if value else 280

func update_weather(elapsed: float, player_position: Vector3, terrain: SurvivorTerrain, scenery: SurvivorScenery) -> void:
    intensity = rainfall_at(elapsed)
    wind_strength = wind_at(elapsed)
    if is_instance_valid(particles):
        particles.position = player_position + Vector3(0.0, 14.0, 0.0)
        particles.direction = Vector3(0.14 + wind_strength * 0.22, -1.0, 0.05)
        particles.emitting = intensity > 0.1
        particles.speed_scale = 0.5 + intensity * 0.5
    terrain.set_weather(intensity, storm_at(elapsed))
    if scenery != null:
        scenery.set_weather(wind_strength, intensity)
