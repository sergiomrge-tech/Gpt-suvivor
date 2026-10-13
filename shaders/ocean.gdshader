shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 0.35;
uniform vec4 deep_color : source_color = vec4(0.025, 0.25, 0.36, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.10, 0.58, 0.57, 1.0);
varying vec3 world_point;
void vertex() {
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX.y += sin(VERTEX.x * 0.14 + TIME * 0.8) * (0.045 + wind_strength * 0.12) + cos(VERTEX.z * 0.18 + TIME * 0.6) * (0.035 + wind_strength * 0.08);
}
void fragment() {
    vec2 p = world_point.xz;
    float a = atan(p.y,p.x);
    // Same coastline equation as the terrain: paint follows actual beaches.
    float island_radius = 201.0 + 13.0*sin(a*5.0+0.6)+10.0*cos(a*9.0-0.4);
    float shore = island_radius*0.9757;
    float distance_out = length(p)-shore;
    float shallows = 1.0-smoothstep(-0.4,22.0,distance_out);

    // Layered directional swells make the lagoon less like a flat color plane.
    float long_swell = sin(p.x*0.27+p.y*0.18-TIME*0.63);
    float crossing = sin(p.x*0.73-p.y*0.48+TIME*0.88);
    float ripples = sin(p.x*1.68+TIME*0.94)*cos(p.y*1.18-TIME*0.53);
    float light_ripple = long_swell*0.35+crossing*0.22+ripples*0.43;
    vec3 water = mix(deep_color.rgb,shallow_color.rgb,shallows*0.86);
    water *= 0.955+light_ripple*0.041;
    float quiet_sea = clamp(wind_strength-0.35,0.0,1.0);
    water = mix(water,water*vec3(0.82,0.88,0.91),quiet_sea*0.22);

    // Irregular lapping shore foam, never a perfectly concentric white ring.
    float coast_jitter = sin(a*33.0+sin(a*13.0)*0.75)*0.60;
    float phase = distance_out*2.15-TIME*(1.10+wind_strength*0.54)+coast_jitter;
    float whitecap = smoothstep(0.54,0.93,sin(phase)*0.5+0.5);
    float backwash = smoothstep(0.61,0.96,sin(phase*0.65+1.8)*0.5+0.5);
    float surf_band = 1.0-smoothstep(0.55,3.8+wind_strength*2.3,max(distance_out,0.0));
    float foam = max(whitecap*0.73,backwash*0.30)*surf_band;
    float distant_foam = smoothstep(0.78,0.98,0.5+0.5*crossing) *
        smoothstep(0.72,1.0,quiet_sea)*0.04;
    vec3 pearl = vec3(0.80,0.89,0.84);
    ALBEDO = mix(water,pearl,clamp(foam*0.78+distant_foam,0.0,0.90));
    ROUGHNESS = mix(0.32,0.80,foam);
    METALLIC = 0.03;
    NORMAL_MAP = vec3(0.5+ripples*0.032,0.5+crossing*0.028,1.0);
}
