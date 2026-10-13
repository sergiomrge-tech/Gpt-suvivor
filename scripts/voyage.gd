extends Node3D
class_name SurvivorVoyage

# Playable short final sail. Boat really moves through ocean space with
# fixed reef hazards; tap left/right or use keyboard to steer into safe lanes.
signal reached_channel
signal vessel_lost

const JOURNEY_LENGTH := 104.0
const SPEED := 6.0
const REEFS := [{"at":24.0,"lane":0.0},{"at":50.0,"lane":0.0},{"at":78.0,"lane":0.0}]
var active := false
var boat_node: Node3D
var start_point := Vector3.ZERO
var outward := Vector3.FORWARD
var sideways := Vector3.RIGHT
var distance := 0.0
var target_lane := 0.0
var current_lane := 0.0
var hull := 100.0
var hit_reefs: Dictionary = {}
var reefs: Array[Node3D] = []
var last_event := ""
var event_timer := 0.0

func begin(boat: Node3D) -> void:
    clear_course()
    boat_node = boat
    start_point = boat.position
    outward = Vector3(start_point.x,0,start_point.z).normalized()
    if outward.length_squared() < 0.3:
        outward = Vector3.FORWARD
    sideways = Vector3(-outward.z,0,outward.x)
    distance = 0.0
    target_lane = 0.0
    current_lane = 0.0
    hull = 100.0
    hit_reefs.clear()
    last_event = "Evite os recifes à frente! Use as setas para manobrar."
    event_timer = 4.0
    for hazard in REEFS:
        var rock := Node3D.new()
        rock.position = start_point + outward*float(hazard.at) + sideways*float(hazard.lane)
        rock.position.y = start_point.y - 0.23
        SurvivorModels.rock(rock,13,1.55)
        SurvivorModels.merge_static(rock,"voyage_reef")
        add_child(rock)
        reefs.append(rock)
    active = true

func steer(amount: int) -> void:
    if not active:
        return
    target_lane = clampf(target_lane + float(clampi(amount,-1,1))*4.0,-8.0,8.0)

func step(delta: float) -> void:
    if not active or boat_node == null:
        return
    var dt := clampf(delta,0.0,0.15)
    var old_distance := distance
    distance += SPEED*dt
    current_lane = move_toward(current_lane,target_lane,dt*3.7)
    boat_node.position = start_point + outward*distance + sideways*current_lane
    boat_node.position.y = start_point.y + sin(distance*0.42)*0.12 + sin(distance*0.23)*0.065
    boat_node.rotation.y = atan2(outward.x,outward.z) + (target_lane-current_lane)*0.035
    boat_node.rotation.x = sin(distance*0.31)*0.027
    boat_node.rotation.z = sin(distance*0.26)*0.022
    event_timer = maxf(0.0,event_timer-dt)
    if event_timer <= 0.0:
        last_event = ""
    for index in range(REEFS.size()):
        var hazard: Dictionary = REEFS[index]
        var at: float = hazard.at
        if old_distance < at and distance >= at and not hit_reefs.has(index):
            hit_reefs[index] = true
            if absf(current_lane-float(hazard.lane)) < 2.7:
                hull = maxf(0.0,hull-38.0)
                last_event = "Colisão com recife! Casco %d%%." % int(hull)
                event_timer = 3.0
            else:
                last_event = "Recife evitado. Continue no canal!"
                event_timer = 2.3
    if hull <= 0.0:
        active = false
        vessel_lost.emit()
    elif distance >= JOURNEY_LENGTH:
        active = false
        reached_channel.emit()

func progress() -> float:
    return clampf(distance/JOURNEY_LENGTH,0.0,1.0)

func next_reef() -> Dictionary:
    if not active:
        return {}
    for index in range(REEFS.size()):
        if hit_reefs.has(index):
            continue
        var reef: Dictionary = REEFS[index]
        var ahead := float(reef.at)-distance
        if ahead >= 0.0:
            return {"index":index,"distance":ahead,"lane":float(reef.lane)}
    return {}

func reef_hint() -> String:
    var ahead := next_reef()
    if ahead.is_empty():
        return "ÁGUAS LIVRES • avance até o canal de saída"
    var meters := int(ceil(float(ahead.distance)))
    var reef_lane := float(ahead.lane)
    if absf(target_lane-reef_lane) >= 3.0:
        return "RECIFE A %d m • faixa escolhida segura" % meters
    return "RECIFE A %d m • toque BOMBORDO ou ESTIBORDO" % meters

func clear_course() -> void:
    active = false
    for rock in reefs:
        if is_instance_valid(rock):
            remove_child(rock)
            rock.queue_free()
    reefs.clear()
    boat_node = null
