shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 0.3;
uniform float rain_amount = 0.0;
varying vec3 original_tint;
varying vec3 cluster_tint;
varying float foliage;

void vertex() {
    // UV2.x=0 for stone. Geology never sways in the wind.
    foliage = UV2.x;
    original_tint = COLOR.rgb;
    cluster_tint = INSTANCE_CUSTOM.rgb;
    float bend = foliage * smoothstep(0.08, 0.95, VERTEX.y);
    vec3 origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX.x += (sin(TIME * (0.87 + wind_strength) + origin.x * 0.36 + origin.z * 0.22) * 0.045 * wind_strength) * bend;
    VERTEX.z += (cos(TIME * 0.64 + origin.z * 0.28) * 0.028 * wind_strength) * bend;
}
void fragment() {
    float wetness = mix(0.20, 0.095, foliage);
    ALBEDO = original_tint * cluster_tint * (1.0 - rain_amount * wetness);
    ROUGHNESS = mix(0.87, 0.95, foliage) - rain_amount * 0.10;
    METALLIC = 0.0;
}
