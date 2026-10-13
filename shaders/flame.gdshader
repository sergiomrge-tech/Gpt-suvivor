shader_type spatial;
render_mode unshaded, cull_disabled;
varying float heat;
void vertex() {
    heat = clamp((VERTEX.y + 0.7) / 1.4, 0.0, 1.0);
    float flicker = sin(TIME * 8.0 + VERTEX.y * 3.0);
    VERTEX.x += heat * heat * flicker * 0.13;
    VERTEX.z += heat * heat * cos(TIME * 7.0) * 0.10;
    VERTEX.y *= 0.90 + sin(TIME * 6.0) * 0.07;
}
void fragment() {
    ALBEDO = mix(vec3(1.0,0.83,0.27), vec3(0.94,0.22,0.025), heat);
    EMISSION = ALBEDO * 0.35;
}
