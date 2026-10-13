shader_type spatial;
render_mode cull_disabled;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform float rain_amount = 0.0;
uniform float wind_strength = 0.45;
uniform vec3 survivor_position = vec3(9999.0);
varying vec3 world_point;
varying vec3 local_point;
void vertex() {
    local_point = VERTEX;
    vec3 p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    world_point = p;
    if (UV2.x > 1.5 && UV2.x < 2.5) {
        float bend = smoothstep(3.0,8.0,VERTEX.y);
        VERTEX.x += sin(TIME * (1.1 + wind_strength) + p.z * 0.14) * (0.04 + wind_strength * 0.13) * bend;
        VERTEX.z += cos(TIME * (0.9 + wind_strength) + p.x * 0.12) * (0.03 + wind_strength * 0.10) * bend;
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
    } else if (family < 5.5) {
        // Tight diagonal weave on weathered cotton, without extra textures.
        float weave = sin(UV.x * 104.0) * cos(UV.y * 118.0);
        grain = 0.945 + detail * 0.055 + weave * 0.012;
        rough = 0.88;
    } else {
        // Subtle pore-scale variation and less chalky skin response.
        float pores = texture(detail_noise, UV * 2.1).r;
        grain = 0.973 + (pores - 0.5) * 0.035;
        rough = 0.74;
    }
    ALPHA = 1.0;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    if (family > 1.5 && family < 2.5 && local_point.y > 3.0) {
        float cover = smoothstep(1.8,4.5,length(world_point.xz-survivor_position.xz));
        float dither = fract(52.9829*fract(dot(floor(FRAGCOORD.xy),vec2(0.06711,0.00584))));
        ALPHA = step(dither,0.12+cover*0.88);
    }
    float rain_wet = rain_amount * (family < 4.5 ? 0.18 : 0.08);
    ALBEDO = base * grain * (1.0 - rain_wet);
    ROUGHNESS = mix(rough,0.45,rain_amount * 0.55);
    METALLIC = metal;
}
