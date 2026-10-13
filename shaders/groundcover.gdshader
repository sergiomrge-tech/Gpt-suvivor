shader_type spatial;
render_mode cull_disabled;
varying float tip;
varying vec4 tint;
void vertex() {
    vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    tip = clamp(VERTEX.y / 0.55, 0.0, 1.0);
    tint = INSTANCE_CUSTOM;
    VERTEX.x += sin(TIME * 1.2 + p.x * 0.6 + p.z * 0.4) * 0.07 * tip * tip;
}
void fragment() {
    ALBEDO = mix(tint.rgb * 0.64, tint.rgb, tip);
    ROUGHNESS = 0.95;
}
