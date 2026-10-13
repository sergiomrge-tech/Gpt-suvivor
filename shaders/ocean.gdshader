shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 0.35;
uniform vec4 deep_color : source_color = vec4(0.025, 0.25, 0.36, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.10, 0.58, 0.57, 1.0);
varying vec3 world_point;
void vertex() {
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX.y += sin(VERTEX.x * 0.14 + TIME * 0.8) * (0.045 + wind_strength * 0.12) + cos(VERTEX.z * 0.18 + TIME * 0.6) * (0.035 + wind_strength * 0.08);
}
void fragment() {
    vec2 p = world_point.xz;
    float a = atan(p.y, p.x);
    // The coastline follows the same deterministic radial island function.
    float island_radius = 201.0 + 13.0 * sin(a * 5.0 + 0.6) + 10.0 * cos(a * 9.0 - 0.4);
    float sea_edge = island_radius * 0.9757;
    float distance_out = length(p) - sea_edge;
    float shallows = 1.0 - smoothstep(1.0, 18.0, distance_out);
    float ripple = sin(p.x * 1.7 + TIME * 0.8) * cos(p.y * 1.1 - TIME * 0.5);
    vec3 water = mix(deep_color.rgb, shallow_color.rgb, shallows * 0.85);
    water += vec3(0.006,0.012,0.015) * ripple;
    water = mix(water,water * vec3(0.78,0.84,0.88),clamp(wind_strength - 0.35,0.0,1.0) * 0.22);
    float breaking_wave = 0.5 + 0.5 * sin(distance_out * 2.2 - TIME * 1.2 + sin(a * 22.0) * 0.7);
    float foam = (1.0 - smoothstep(0.2, 2.2 + wind_strength * 2.0, max(distance_out, 0.0))) * smoothstep(0.40, 0.91, breaking_wave);
    ALBEDO = mix(water, vec3(0.76,0.87,0.80), foam * 0.68);
    ROUGHNESS = mix(0.34, 0.73, foam);
    METALLIC = 0.05;
    NORMAL_MAP = vec3(0.5 + ripple * 0.035, 0.5 + sin(p.x * 1.3 + TIME) * 0.028, 1.0);
}
