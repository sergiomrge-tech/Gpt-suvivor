shader_type spatial;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D trail_mask : filter_linear_mipmap, repeat_disable;
uniform bool show_trails = false;
varying vec3 world_point;
varying vec3 world_normal;
uniform float sea_level = -0.48;
void vertex() {
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    float h = world_point.y;
    vec2 p = world_point.xz;
    float macro = texture(detail_noise, p / 64.0).r;
    float grain = texture(detail_noise, p / 2.0).b;
    float grass = smoothstep(2.35, 5.4, h + (macro - 0.5) * 1.5);
    vec3 sand = mix(vec3(0.73,0.63,0.44), vec3(0.87,0.78,0.56), 0.2 + macro * 0.6);
    vec3 turf = mix(vec3(0.20,0.38,0.21), vec3(0.29,0.46,0.26), macro);
    float dry_patch = smoothstep(0.65,0.83,texture(detail_noise,p / 47.0 + vec2(0.2,0.3)).g);
    turf = mix(turf,vec3(0.35,0.37,0.23),dry_patch * 0.35);
    vec3 ground = mix(sand,turf,grass);
    float wet = 1.0 - smoothstep(sea_level + 0.15,sea_level + 1.65,h);
    ground *= mix(1.0,0.77,wet);
    ground *= 0.975 + grain * 0.05;
    float ridges = sin(p.x * 3.8 + macro * 3.0) * 0.012;
    ground += vec3(ridges) * (1.0 - grass);
    float rock_exposure = smoothstep(0.34,0.67,1.0-world_normal.y) * smoothstep(9.0,20.0,h);
    if (show_trails) {
        float path = texture(trail_mask,(p+vec2(258.0))/516.0).r;
        ground = mix(ground,vec3(0.46,0.40,0.27)*(0.96+grain*0.08),path*grass*0.78);
    }
    ALBEDO = mix(ground,vec3(0.39,0.41,0.34) * (0.92+macro*0.13),rock_exposure);
    ROUGHNESS = mix(0.95,0.68,wet);
}
