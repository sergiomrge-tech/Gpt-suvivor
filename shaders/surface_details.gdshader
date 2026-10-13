shader_type spatial;
render_mode cull_disabled;
uniform float rain_amount = 0.0;
varying vec3 fragment_color;
varying vec3 fragment_tint;

void vertex() {
    fragment_color = COLOR.rgb;
    fragment_tint = INSTANCE_CUSTOM.rgb;
}
void fragment() {
    ALBEDO = fragment_color * fragment_tint * (1.0 - rain_amount * 0.12);
    ROUGHNESS = mix(0.95,0.70,rain_amount*0.46);
}
