extends RefCounted
class_name SurvivorTrails

var paths: Array[PackedVector2Array] = []
var terrain: SurvivorTerrain
var world: SurvivorWorld
var mask: ImageTexture
const GRID_STEP := 4.0
const MASK_SIZE := 512

func generate() -> void:
    var grid := AStarGrid2D.new()
    grid.region = Rect2i(-56,-56,112,112)
    grid.cell_size = Vector2.ONE*GRID_STEP
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    for x in range(-56,56):
        for y in range(-56,56):
            var p := Vector2(x,y)*GRID_STEP
            var point := Vector3(p.x,terrain.height_at(p.x,p.y),p.y)
            var solid := not world.walkable(point,point)
            if not solid:
                for entry in world.resources:
                    if entry.radius > 0 and p.distance_to(Vector2(entry.position.x,entry.position.z)) < entry.radius+2.1:
                        solid = true
                        break
            grid.set_point_solid(Vector2i(x,y),solid)
            if not solid:
                grid.set_point_weight_scale(Vector2i(x,y),1+maxf(0,point.y)*0.018)
    var start := _open_point(grid,Vector2(0,164))
    var spring := _open_point(grid,Vector2(-26,96))
    for pair in [[start,spring],[spring,_open_point(grid,Vector2(80,28))],[spring,_open_point(grid,Vector2(-90,-52))]]:
        var raw := grid.get_point_path(pair[0],pair[1])
        if raw.size() > 1:
            var compact := PackedVector2Array([raw[0]])
            for i in range(1,raw.size()-1):
                if (raw[i]-raw[i-1]).normalized().dot((raw[i+1]-raw[i]).normalized()) < 0.999:
                    compact.append(raw[i])
            compact.append(raw[-1])
            paths.append(compact)
    _bake_mask()

func _open_point(grid: AStarGrid2D,point: Vector2) -> Vector2i:
    var origin := Vector2i(roundi(point.x/GRID_STEP),roundi(point.y/GRID_STEP))
    for radius in range(10):
        for x in range(-radius,radius+1):
            for y in range(-radius,radius+1):
                var candidate := origin+Vector2i(x,y)
                if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
                    return candidate
    return origin

func distance_to(point: Vector2) -> float:
    var closest := 9999.0
    for path in paths:
        for i in range(path.size()-1):
            var segment := path[i+1]-path[i]
            var t := clampf((point-path[i]).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
            closest = minf(closest,point.distance_to(path[i]+segment*t))
    return closest

func _bake_mask() -> void:
    var image := Image.create(MASK_SIZE,MASK_SIZE,false,Image.FORMAT_L8)
    image.fill(Color.BLACK)
    var scale := float(MASK_SIZE)/(terrain.HALF_SIZE*2)
    for path in paths:
        for i in range(path.size()-1):
            var a := (path[i]+Vector2.ONE*terrain.HALF_SIZE)*scale
            var b := (path[i+1]+Vector2.ONE*terrain.HALF_SIZE)*scale
            var segment := b-a
            var minimum := (a.min(b)-Vector2.ONE*3).floor()
            var maximum := (a.max(b)+Vector2.ONE*3).ceil()
            for x in range(maxi(0,int(minimum.x)),mini(MASK_SIZE,int(maximum.x)+1)):
                for y in range(maxi(0,int(minimum.y)),mini(MASK_SIZE,int(maximum.y)+1)):
                    var p := Vector2(x+0.5,y+0.5)
                    var t := clampf((p-a).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
                    var distance := p.distance_to(a+segment*t)/scale
                    var value := 1-smoothstep(0.65,1.6,distance)
                    if value > image.get_pixel(x,y).r:
                        image.set_pixel(x,y,Color(value,value,value))
    image.generate_mipmaps()
    mask = ImageTexture.create_from_image(image)
