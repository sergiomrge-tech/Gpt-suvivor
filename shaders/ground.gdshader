shader_type spatial;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D trail_mask : filter_linear_mipmap, repeat_disable;
uniform bool show_trails = false;
varying vec3 world_point;
varying vec3 world_normal;
uniform float sea_level = -0.48;
uniform float rain_amount = 0.0;
uniform float surface_microdetail = 1.0;
void vertex() {
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    float h = world_point.y;
    vec2 p = world_point.xz;
    // Keep geometry, collisions and saved world locations untouched.
    // All biome variation lives in material space, so beaches read as continuous.
    vec3 broad = texture(detail_noise, p / 65.0).rgb;
    vec3 middle = texture(detail_noise, p / 13.0 + vec2(0.17,0.31)).rgb;
    vec3 fine = texture(detail_noise, p / 1.85).rgb;
    float macro = broad.r;
    float sand_to_vegetation = smoothstep(2.25,5.15,h + (macro - 0.5) * 1.8 + (middle.g - 0.5) * 0.85);
    float grain = fine.b * 0.55 + middle.r * 0.45;

    // Light dry sand above a darker compact tideline and granular footpath edges.
    vec3 honey = vec3(0.80,0.70,0.52);
    vec3 pale = vec3(0.90,0.81,0.63);
    vec3 sand = mix(honey,pale,clamp(0.20 + macro * 0.64 + (fine.g-0.5)*0.16,0.0,1.0));
    float tide = 1.0-smoothstep(sea_level+0.23,sea_level+1.65,h);
    float fringe = smoothstep(sea_level+0.6,sea_level+1.22,h) * (1.0-smoothstep(sea_level+2.1,sea_level+3.3,h));
    sand *= 1.0 - tide * 0.24;
    sand *= 1.0 - fringe * middle.b * 0.055;
    float tiny_shells = smoothstep(0.82,0.97,fine.r)* (1.0-sand_to_vegetation);
    sand = mix(sand,vec3(0.94,0.85,0.67),tiny_shells * 0.11);

    // Multiple vegetation hues form patchwork instead of a flat green paint.
    vec3 undergrowth = mix(vec3(0.19,0.36,0.20),vec3(0.27,0.43,0.24),macro);
    undergrowth = mix(undergrowth,vec3(0.34,0.39,0.21),smoothstep(0.58,0.82,middle.g)*0.28);
    float loam = smoothstep(0.61,0.84,broad.g * 0.68+middle.r * 0.32);
    undergrowth = mix(undergrowth,vec3(0.30,0.28,0.20),loam*0.27);
    float moss = smoothstep(0.65,0.86,middle.b) * (1.0-loam);
    undergrowth = mix(undergrowth,vec3(0.20,0.38,0.26),moss*0.17);

    float slope = 1.0 - clamp(world_normal.y,0.0,1.0);
    float rock_exposure = smoothstep(0.20,0.60,slope) * smoothstep(6.0,17.0,h);
    float stone_fleck = smoothstep(0.80,0.94,fine.r) * smoothstep(0.32,0.70,middle.r);
    vec3 stone = mix(vec3(0.37,0.40,0.36),vec3(0.48,0.48,0.40),broad.b);
    stone *= 0.92+0.13*grain;

    vec3 ground = mix(sand,undergrowth,sand_to_vegetation);
    if (show_trails) {
        float path = texture(trail_mask,(p+vec2(258.0))/516.0).r;
        vec3 earth = mix(vec3(0.40,0.35,0.25),vec3(0.49,0.43,0.30),grain);
        ground = mix(ground,earth,path * sand_to_vegetation * 0.80);
    }
    ground = mix(ground,stone,stone_fleck * (0.10 + sand_to_vegetation * 0.12));
    ground = mix(ground,stone,rock_exposure);
    ground *= 0.967 + grain*0.066;
    float damp = rain_amount * (0.10 + macro * 0.085);
    ALBEDO = ground * (1.0-damp);
    // Physically varied roughness: damp intertidal sand, dusty soil and stone.
    float gravel = smoothstep(0.72,0.93,middle.b) * sand_to_vegetation;
    ROUGHNESS = mix(0.96,0.78,tide);
    ROUGHNESS = mix(ROUGHNESS,0.90,gravel*0.45);
    ROUGHNESS = mix(ROUGHNESS,0.60,rain_amount*0.56);

    // A small two-sample bump is reserved for the Complete mode.
    // No terrain vertex displacement, collision or saved coordinates change.
    if (surface_microdetail > 0.5) {
        vec2 sample_uv = p / 1.85;
        vec2 gradient = vec2(
            texture(detail_noise,sample_uv+vec2(0.016,0.0)).b - fine.b,
            texture(detail_noise,sample_uv+vec2(0.0,0.016)).b - fine.b
        );
        float bump = mix(0.53,0.37,sand_to_vegetation) * (1.0-rain_amount*0.36);
        vec3 micro_normal = normalize(world_normal+vec3(-gradient.x*bump,0.0,-gradient.y*bump));
        NORMAL = normalize(mat3(VIEW_MATRIX) * micro_normal);
    }
}
