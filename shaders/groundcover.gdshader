shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 0.3;
uniform float rain_amount = 0.0;
varying float tip;
varying vec4 tint;
void vertex() {
    vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    tip = clamp(VERTEX.y / 0.55, 0.0, 1.0);
    tint = INSTANCE_CUSTOM;
    VERTEX.x += sin(TIME * (1.0 + wind_strength * 2.0) + p.x * 0.6 + p.z * 0.4) * (0.05 + wind_strength * 0.15) * tip * tip;
}
void fragment() {
    ALBEDO = mix(tint.rgb * 0.64, tint.rgb, tip) * (1.0 - rain_amount * 0.16);
    ROUGHNESS = 0.95;
}
