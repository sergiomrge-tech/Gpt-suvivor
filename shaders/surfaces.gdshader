shader_type spatial;
render_mode cull_disabled;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform vec3 survivor_position = vec3(9999.0);
varying vec3 world_point;
varying vec3 local_point;
void vertex() {
    local_point = VERTEX;
    vec3 p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    world_point = p;
    if (UV2.x > 1.5 && UV2.x < 2.5) {
        float bend = smoothstep(3.0,8.0,VERTEX.y);
        VERTEX.x += sin(TIME * 1.3 + p.z * 0.14) * 0.10 * bend;
        VERTEX.z += cos(TIME * 1.1 + p.x * 0.12) * 0.06 * bend;
    }
}
void fragment() {
    vec3 base = COLOR.rgb;
    float family = UV2.x;
    float grain = 1.0;
    float rough = 0.87;
    float metal = 0.0;
    float detail = texture(detail_noise,UV * 0.37).g;
    if (family < 1.5) {
        float lines = sin(UV.x * 34.0 + detail * 4.0);
        grain = 0.94 + lines * 0.035 + detail * 0.04;
        rough = 0.90;
    } else if (family < 2.5) {
        grain = 0.94 + detail * 0.06;
        rough = 0.83;
    } else if (family < 3.5) {
        float flecks = texture(detail_noise,UV * 3.0).b;
        grain = 0.88 + detail * 0.17 + flecks * 0.06;
        rough = 0.94;
    } else if (family < 4.5) {
        grain = 0.95 + detail * 0.06;
        rough = 0.55;
        metal = 0.22;
    } else {
        grain = 0.98 + sin(UV.x*95.0) * sin(UV.y*95.0) * 0.015;
        rough = 0.91;
    }
    ALPHA = 1.0;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    if (family > 1.5 && family < 2.5 && local_point.y > 3.0) {
        float cover = smoothstep(1.8,4.5,length(world_point.xz-survivor_position.xz));
        float dither = fract(52.9829*fract(dot(floor(FRAGCOORD.xy),vec2(0.06711,0.00584))));
        ALPHA = step(dither,0.12+cover*0.88);
    }
    ALBEDO = base * grain;
    ROUGHNESS = rough;
    METALLIC = metal;
}
