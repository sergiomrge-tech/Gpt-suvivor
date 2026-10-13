extends Control
class_name SurvivorMinimap

var terrain: SurvivorTerrain
var world: SurvivorWorld
var player: SurvivorPlayer

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
    queue_redraw()

func map_point(p: Vector3) -> Vector2:
    return size * 0.5 + Vector2(p.x, p.z) / 480.0 * size

func _draw() -> void:
    if terrain == null or world == null:
        return
    draw_style_box(_background(), Rect2(Vector2.ZERO, size))
    if player != null and world.caves != null and world.caves.is_inside(player.position):
        var id := SurvivorCaves.cave_at(player.position)
        var center: Vector3 = SurvivorCaves.CENTERS[id]
        var frame := Rect2(size*Vector2(0.10,0.12),size*Vector2(0.80,0.76))
        draw_rect(frame,Color(0.30,0.33,0.31),true)
        draw_rect(frame,Color(0.72,0.60,0.42),false,2.0)
        var to_map := func(p: Vector3) -> Vector2:
            return Vector2(size.x*0.5 + (p.x-center.x)/37.0*frame.size.x,size.y*0.5 + (p.z-center.z)/30.0*frame.size.y)
        if world.caves.puzzles != null:
            for entry in world.caves.puzzles.mechanisms:
                if entry.cave != id or bool(world.state.discoveries.get(entry.id,false)):
                    continue
                draw_circle(to_map.call(entry.position),4.3,Color(0.24,0.86,0.89) if entry.kind == "cave_seal" else Color(1.0,0.63,0.30))
        draw_circle(to_map.call(SurvivorCaves.exit_position(id)),4.0,Color(0.39,0.83,0.73))
        for cache in world.caves.caches:
            if cache.cave == id and cache.node.visible:
                draw_circle(to_map.call(cache.position),3.5,Color(1.0,0.79,0.34))
        draw_circle(to_map.call(player.position),5.0,Color(1.0,1.0,0.90))
        return
    var outline := PackedVector2Array()
    for i in range(80):
        var a := i * TAU / 80.0
        var radius := terrain.radius_at_angle(a) * 0.97
        outline.append(map_point(Vector3(cos(a) * radius, 0, sin(a) * radius)))
    draw_colored_polygon(outline, Color(0.25, 0.43, 0.28))
    outline.append(outline[0])
    draw_polyline(outline, Color(0.78, 0.7, 0.43), 3, true)
    if world.trails != null:
        for path in world.trails.paths:
            var line := PackedVector2Array()
            for point in path:
                line.append(map_point(Vector3(point.x,0,point.y)))
            if line.size()>1:
                draw_polyline(line,Color(0.69,0.64,0.38),1,true)
    for entry in world.landmarks:
        draw_circle(map_point(entry.position), 3.5, Color(0.3, 0.88, 1.0) if entry.kind == "spring" else Color(0.87, 0.75, 0.48))
    for entry in world.structures:
        draw_rect(Rect2(map_point(entry.position) - Vector2(2.5, 2.5), Vector2(5, 5)), Color(1, 0.73, 0.3))
    if player != null:
        var point := map_point(player.position)
        draw_circle(point, 5, Color(1, 1, 0.88))
        draw_arc(point, 7, 0, TAU, 16, Color(0.1, 0.16, 0.14), 2, true)

func _background() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.21, 0.29, 0.93)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    return style
