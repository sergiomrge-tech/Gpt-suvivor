shader_type spatial;
uniform sampler2D detail_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D trail_mask : filter_linear_mipmap, repeat_disable;
uniform bool show_trails = false;
varying vec3 world_point;
varying vec3 world_normal;
uniform float sea_level = -0.48;
uniform float rain_amount = 0.0;
uniform float surface_microdetail = 1.0;
// CC0 Poly Haven 1K albedo/normal/roughness maps: B jungle dominates, A
// coastal beaches and C steep rock faces. Loaded only when source exists.
uniform bool real_pbr_assets_ready = false;
uniform bool real_pbr_full_detail = true;
uniform sampler2D pbr_sand_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_jungle_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_rock_diff : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_sand_normal : filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_jungle_normal : filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_rock_normal : filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_sand_rough : filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_jungle_rough : filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_rock_rough : filter_linear_mipmap, repeat_enable;
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
    // Moisture rides the actual waterline; irregular slow wavelets leave a
    // moving dark ribbon rather than an immobile concentric painted border.
    float beach_angle = atan(p.y, p.x);
    float swash = 0.16 * sin(TIME * 0.58 + beach_angle * 21.0 + middle.b * 2.8);
    float damp_band = 1.0 - smoothstep(sea_level + 0.54 + swash, sea_level + 1.62 + swash, h);
    sand *= 1.0 - tide * 0.17 - damp_band * 0.085;
    sand *= 1.0 - fringe * middle.b * 0.055;
    // Wind-cut sand striations shift direction and fade in the grass belt.
    float ripple = sin(p.x * 13.5 + p.y * 8.3 + middle.r * 3.9 + 1.3 * sin(p.y * 0.20));
    float dune_strength = (1.0 - sand_to_vegetation) * (1.0 - damp_band * 0.72);
    sand *= 1.0 + ripple * 0.012 * dune_strength;
    // Salt-crust and broken shell flecks preferentially accumulate higher
    // than the wet intertidal sand, not as uniformly scattered noise.
    float tiny_shells = smoothstep(0.82,0.97,fine.r)* (1.0-sand_to_vegetation) * (1.0-damp_band*0.76);
    sand = mix(sand,vec3(0.94,0.85,0.67),tiny_shells * 0.11);

    // Multiple vegetation hues form patchwork instead of a flat green paint.
    vec3 undergrowth = mix(vec3(0.19,0.36,0.20),vec3(0.27,0.43,0.24),macro);
    undergrowth = mix(undergrowth,vec3(0.34,0.39,0.21),smoothstep(0.58,0.82,middle.g)*0.28);
    float loam = smoothstep(0.61,0.84,broad.g * 0.68+middle.r * 0.32);
    undergrowth = mix(undergrowth,vec3(0.30,0.28,0.20),loam*0.27);
    float moss = smoothstep(0.65,0.86,middle.b) * (1.0-loam);
    undergrowth = mix(undergrowth,vec3(0.20,0.38,0.26),moss*0.17);
    // A thin mottled organic horizon accumulates in sheltered forest pockets.
    // Reuse the existing three noise octaves; no fourth texture fetch.
    float humus = smoothstep(0.48,0.86,broad.b * 0.45+middle.g * 0.42+fine.r * 0.13);
    float forest_floor = sand_to_vegetation * (1.0-smoothstep(20.0,29.0,h));
    undergrowth = mix(undergrowth,vec3(0.215,0.255,0.165),humus*forest_floor*0.24);

    float slope = 1.0 - clamp(world_normal.y,0.0,1.0);
    // Patchy rock faces interrupt forest soil on actual steep terrain.
    float geological_band = smoothstep(0.10,0.42,slope + (middle.b-0.5)*0.14);
    float rock_exposure = geological_band * smoothstep(9.0,22.0,h) * (0.58+0.42*broad.b);
    float stone_fleck = smoothstep(0.80,0.94,fine.r) * smoothstep(0.32,0.70,middle.r);
    vec3 stone = mix(vec3(0.37,0.40,0.36),vec3(0.48,0.48,0.40),broad.b);
    // Mineral banding is visible on exposed rock rather than uniform grey.
    float stratum = sin(h * 2.75 + middle.r * 6.0 + broad.b * 3.8);
    float mineral = smoothstep(0.62,0.91,middle.b*0.62+fine.g*0.38);
    stone *= 0.88 + 0.08*grain + 0.035*stratum;
    stone = mix(stone,vec3(0.37,0.35,0.30),mineral*0.19);
    stone = mix(stone,vec3(0.30,0.39,0.34),moss*0.09);

    vec3 ground = mix(sand,undergrowth,sand_to_vegetation);
    if (show_trails) {
        float path = texture(trail_mask,(p+vec2(258.0))/516.0).r;
        vec3 earth = mix(vec3(0.40,0.35,0.25),vec3(0.49,0.43,0.30),grain);
        ground = mix(ground,earth,path * sand_to_vegetation * 0.80);
    }
    ground = mix(ground,stone,stone_fleck * (0.10 + sand_to_vegetation * 0.12));
    ground = mix(ground,stone,rock_exposure);
    // Photographed materials replace the old flat colors without altering
    // geometry, collision, trail masks, wave height or saved world locations.
    vec2 pbr_uv = p * 0.19;
    if (real_pbr_assets_ready) {
        vec3 scanned_sand = texture(pbr_sand_diff,pbr_uv * 0.75).rgb;
        vec3 scanned_jungle = texture(pbr_jungle_diff,pbr_uv).rgb;
        vec3 scanned_rock = texture(pbr_rock_diff,pbr_uv * 0.65).rgb;
        // Preserve the island palette to avoid fluorescent texture seams.
        ground = mix(ground,scanned_sand,0.63 * (1.0-sand_to_vegetation));
        ground = mix(ground,scanned_jungle,0.67 * sand_to_vegetation * (1.0-rock_exposure));
        ground = mix(ground,scanned_rock,0.75 * rock_exposure);
    }
    ground *= 0.967 + grain*0.066;
    float damp = rain_amount * (0.10 + macro * 0.085);
    ALBEDO = ground * (1.0-damp);
    // Physically varied roughness: damp intertidal sand, dusty soil and stone.
    float gravel = smoothstep(0.72,0.93,middle.b) * sand_to_vegetation;
    ROUGHNESS = mix(0.96,0.78,tide);
    ROUGHNESS = mix(ROUGHNESS,0.90,gravel*0.45);
    ROUGHNESS = mix(ROUGHNESS,0.86,rock_exposure*0.50);
    ROUGHNESS = mix(ROUGHNESS,0.60,rain_amount*0.56);
    if (real_pbr_assets_ready && real_pbr_full_detail) {
        float sand_rough = texture(pbr_sand_rough,pbr_uv * 0.75).r;
        float soil_rough = texture(pbr_jungle_rough,pbr_uv).r;
        float rock_rough = texture(pbr_rock_rough,pbr_uv * 0.65).r;
        float real_rough = mix(mix(sand_rough,soil_rough,sand_to_vegetation),rock_rough,rock_exposure);
        ROUGHNESS = mix(ROUGHNESS,real_rough,0.38);
        vec3 sand_n = texture(pbr_sand_normal,pbr_uv*0.75).rgb*2.0-1.0;
        vec3 soil_n = texture(pbr_jungle_normal,pbr_uv).rgb*2.0-1.0;
        vec3 cliff_n = texture(pbr_rock_normal,pbr_uv*0.65).rgb*2.0-1.0;
        vec3 detail_n = mix(mix(sand_n,soil_n,sand_to_vegetation),cliff_n,rock_exposure);
        // Respect the actual mesh slope; slight XY perturbation only.
        vec3 pbr_world_normal = normalize(world_normal + vec3(detail_n.x,0.0,detail_n.y) * 0.12);
        NORMAL = normalize(mat3(VIEW_MATRIX)*pbr_world_normal);
    }

    // A small two-sample bump is reserved for the Complete mode.
    // No terrain vertex displacement, collision or saved coordinates change.
    if (surface_microdetail > 0.5 && !(real_pbr_assets_ready && real_pbr_full_detail)) {
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
