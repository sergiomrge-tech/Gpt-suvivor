shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
void fragment() {
    vec2 p = vec2(UV.x-0.5,1.0-UV.y);
    float flicker = sin(p.y*17.0-TIME*5.3)+0.5*sin(p.y*31.0-TIME*8.7);
    float width = (1.0-p.y)*0.31;
    float shape = 1.0-smoothstep(width*0.48,width+0.035,abs(p.x+flicker*0.028*p.y));
    float edge = smoothstep(0.0,0.09,p.y)*(1.0-smoothstep(0.72,1.0,p.y));
    float pulse = 0.76+0.12*sin(TIME*5.7)+0.08*sin(TIME*9.1+p.y*10.0);
    ALBEDO = mix(vec3(1.0,0.79,0.24),vec3(1.0,0.13,0.015),p.y);
    ALPHA = shape*edge*pulse*0.65;
}
