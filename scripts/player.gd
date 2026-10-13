extends Node3D
class_name SurvivorPlayer

signal action_contact(kind: String, point: Vector3)
signal action_finished(kind: String)
signal footstep(surface: String, point: Vector3)

var terrain: SurvivorTerrain
var world: SurvivorWorld
var move_vector := Vector2.ZERO
var speed := 8.5
var sprint_enabled := false
var locomotion_blend := 0.0
var walking := false
var enabled := false
var body_pivot: Node3D
var torso: Node3D
var head_pivot: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var right_hand: Node3D
var tools: Dictionary = {}
var animation_clock := 0.0
var action_remaining := 0.0
var action_duration := 1.0
var action_kind := ""
var action_point := Vector3.ZERO
var contact_sent := false
var step_distance := 0.0
var fishing_line: MeshInstance3D
var fishing_mesh: ImmediateMesh
var bobber: MeshInstance3D

func _ready() -> void:
    _build_character()
    var listener := AudioListener3D.new()
    listener.position.y = 1.6
    add_child(listener)
    listener.make_current()

func is_busy() -> bool:
    return action_remaining > 0.0

func _physics_process(delta: float) -> void:
    if terrain == null or not enabled:
        walking = false
        return
    var previous := position
    var vec := move_vector.limit_length(1.0)
    walking = vec.length_squared() > 0.012 and not is_busy()
    var sprinting := walking and sprint_enabled and vec.length() > 0.68
    if walking:
        var offset := Vector3(vec.x,0,vec.y) * (speed * (1.36 if sprinting else 1.0)) * delta
        for axis in [Vector3(offset.x,0,0),Vector3(0,0,offset.z)]:
            var candidate: Vector3 = position + axis
            if world.walkable(candidate,position):
                position = candidate
        body_pivot.rotation.y = lerp_angle(body_pivot.rotation.y,atan2(vec.x,vec.y),minf(1.0,delta*12))
    position.y = world.surface_height(position)
    var moved := Vector2(position.x-previous.x,position.z-previous.z).length()
    walking = walking and moved > 0.001
    locomotion_blend = move_toward(locomotion_blend, 1.0 if sprinting and walking else 0.0,delta * 3.2)
    animation_clock += delta * ((11.0 + locomotion_blend * 4.6) if walking else 1.9)
    step_distance += moved
    var stride := lerpf(1.55,1.95,locomotion_blend)
    if step_distance > stride:
        step_distance = fmod(step_distance,stride)
        footstep.emit("wood" if world.is_on_dock(position) else ("sand" if position.y<3.1 else "grass"),position)
    _base_pose()
    if is_busy():
        action_remaining = maxf(0,action_remaining-delta)
        var progress := 1.0-action_remaining/action_duration
        pose_action(progress)
        if action_kind == "fish": _update_fishing_line()
        if progress >= 0.47 and not contact_sent:
            contact_sent = true
            action_contact.emit(action_kind,action_point)
        if action_remaining <= 0:
            var completed := action_kind
            cancel_action()
            action_finished.emit(completed)

func _base_pose() -> void:
    var swing := sin(animation_clock) * (lerpf(0.58,0.83,locomotion_blend) if walking else 0.012)
    left_leg.rotation.x = swing
    right_leg.rotation.x = -swing
    left_knee.rotation.x = maxf(0,-swing)*lerpf(0.9,1.18,locomotion_blend)
    right_knee.rotation.x = maxf(0,swing)*lerpf(0.9,1.18,locomotion_blend)
    left_arm.rotation = Vector3(-swing*lerpf(0.65,0.78,locomotion_blend)-locomotion_blend*0.22,0,0.04)
    right_arm.rotation = Vector3(swing*lerpf(0.65,0.78,locomotion_blend)-locomotion_blend*0.22,0,-0.04)
    left_elbow.rotation.x = -0.15
    right_elbow.rotation.x = -0.15
    torso.rotation = Vector3((0.03 + locomotion_blend * 0.21) if walking else 0, sin(animation_clock) * 0.025 if walking else 0, -sin(animation_clock)*0.022 if walking else 0)
    head_pivot.rotation = Vector3.ZERO
    body_pivot.rotation.x = 0
    body_pivot.position.y = absf(sin(animation_clock))*lerpf(0.065,0.10,locomotion_blend) if walking else sin(animation_clock)*0.018

func perform_action(kind: String = "gather",duration: float = 0.75,point: Vector3 = Vector3.ZERO) -> void:
    cancel_action()
    action_kind = kind
    action_duration = maxf(0.1,duration)
    action_remaining = action_duration
    action_point = point
    contact_sent = false
    move_vector = Vector2.ZERO
    var direction := Vector2(point.x-position.x,point.z-position.z)
    if direction.length_squared() > 0.02:
        body_pivot.rotation.y = atan2(direction.x,direction.y)
    var tool: String = {"chop":"axe","mine":"pick","cut":"knife","spear":"spear","fish":"rod","build":"hammer","craft":"hammer","eat":"food","cook":"skewer"}.get(kind,"")
    if tools.has(tool):
        tools[tool].visible = true
    if kind == "fish":
        fishing_line.visible = true
        bobber.visible = true
    pose_action(0)

func cancel_action() -> void:
    action_remaining = 0
    action_kind = ""
    contact_sent = false
    for node in tools.values():
        node.visible = false
    if fishing_line != null: fishing_line.visible = false
    if bobber != null: bobber.visible = false
    if body_pivot != null:
        _base_pose()

func pose_action(progress: float) -> void:
    var wave := sin(progress*PI)
    match action_kind:
        "chop", "mine":
            right_arm.rotation.x = -0.25-1.65*wave
            right_elbow.rotation.x = -0.25-0.5*sin(progress*TAU)
            left_arm.rotation.x = -0.25-wave*0.4
            torso.rotation.x = 0.12*wave
            torso.rotation.z = sin(progress*TAU)*0.07
        "spear":
            # Forward hunting thrust with the crafted stone-tipped spear.
            right_arm.rotation.x = -0.4 - 1.3 * wave
            right_elbow.rotation.x = -0.5 - 0.4 * wave
            left_arm.rotation.x = -0.6 - 0.3 * wave
            torso.rotation.x = 0.15 * wave
        "gather", "search", "drink", "cut":
            torso.rotation.x = 0.46*wave
            right_arm.rotation.x = -0.95*wave
            left_arm.rotation.x = -0.65*wave
            left_knee.rotation.x = wave*0.28
            right_knee.rotation.x = wave*0.28
            body_pivot.position.y = -wave*0.18
            if action_kind == "drink":
                right_arm.rotation.x -= smoothstep(0.3,0.65,progress)*1.1*(1-progress)
            elif action_kind == "cut":
                right_arm.rotation.z = sin(progress*TAU)*0.45
        "fish":
            right_arm.rotation.x = -0.75-sin(minf(progress*3.0,1)*PI)*0.7
            right_elbow.rotation.x = -0.3
            left_arm.rotation.x = -0.65
            left_elbow.rotation.x = -0.45
            torso.rotation.x = 0.05+sin(progress*TAU)*0.03
            head_pivot.rotation.x = 0.13
        "build", "craft", "handcraft":
            var tap := absf(sin(progress*PI*3))
            right_arm.rotation.x = -0.65-tap*0.72
            right_elbow.rotation.x = -0.2-tap*0.25
            left_arm.rotation.x = -0.75
            torso.rotation.x = 0.14
            body_pivot.position.y = -0.08
        "cook":
            right_arm.rotation.x = -0.9
            right_elbow.rotation.x = -0.2+sin(progress*TAU)*0.06
            torso.rotation.x = 0.12
        "eat":
            right_arm.rotation.x = -1.8*wave
            right_elbow.rotation.x = -0.8*wave
            right_arm.rotation.z = -0.5*wave
            head_pivot.rotation.x = 0.1*wave
        "rest":
            body_pivot.position.y = -0.38*wave
            torso.rotation.x = 0.08
            left_leg.rotation.x = -1.1*wave
            right_leg.rotation.x = -1.1*wave
            left_knee.rotation.x = 1.2*wave
            right_knee.rotation.x = 1.2*wave
            left_arm.rotation.x = -0.45*wave
            right_arm.rotation.x = -0.45*wave

func _joint(parent: Node3D,pos: Vector3) -> Node3D:
    var joint := Node3D.new()
    joint.position = pos
    parent.add_child(joint)
    return joint

func _limb(parent: Node3D,length: float,radius: float,color: Color) -> void:
    SurvivorModels.beam(parent,Vector3.ZERO,Vector3(0,-length,0),radius,color)

func _build_character() -> void:
    var skin := Color(0.66,0.44,0.30)
    var shirt := Color(0.16,0.36,0.42)
    var pants := Color(0.24,0.26,0.27)
    body_pivot = _joint(self,Vector3.ZERO)
    body_pivot.name = "AnimatedBody"
    torso = _joint(body_pivot,Vector3(0,1.45,0))
    SurvivorModels.sphere(torso,0.48,shirt,Vector3.ZERO,Vector3(1.05,1.28,0.73))
    SurvivorModels.box(torso,Vector3(0.88,0.09,0.60),Color(0.24,0.18,0.11),Vector3(0,-0.40,0))
    SurvivorModels.box(torso,Vector3(0.15,0.12,0.045),Color(0.65,0.61,0.44),Vector3(0,-0.40,0.32))
    for x in [-0.27,0.27]:
        SurvivorModels.box(torso,Vector3(0.21,0.23,0.04),shirt.lightened(0.07),Vector3(x,0.07,0.35))
        SurvivorModels.beam(torso,Vector3(x,-0.15,-0.32),Vector3(x,0.42,0.23),0.045,Color(0.42,0.32,0.17))
    SurvivorModels.box(torso,Vector3(0.66,0.86,0.38),Color(0.39,0.30,0.17),Vector3(0,-0.03,-0.49))
    SurvivorModels.box(torso,Vector3(0.52,0.18,0.09),Color(0.45,0.35,0.19),Vector3(0,-0.14,-0.72))
    SurvivorModels.merge_static(torso,"hero_torso")
    head_pivot = _joint(torso,Vector3(0,0.67,0))
    SurvivorModels.beam(head_pivot,Vector3(0,-0.12,0),Vector3(0,0.07,0),0.16,skin)
    SurvivorModels.sphere(head_pivot,0.33,skin,Vector3(0,0.22,0),Vector3(0.95,1.06,0.90))
    SurvivorModels.sphere(head_pivot,0.34,Color(0.17,0.15,0.12),Vector3(0,0.48,-0.045),Vector3(1,0.43,1))
    SurvivorModels.sphere(head_pivot,0.08,skin,Vector3(0,0.23,0.31),Vector3(0.65,0.65,0.9))
    for side in [-1,1]:
        SurvivorModels.sphere(head_pivot,0.078,skin,Vector3(side*0.31,0.21,0))
        SurvivorModels.sphere(head_pivot,0.04,Color(0.90,0.88,0.77),Vector3(side*0.12,0.28,0.274))
        SurvivorModels.sphere(head_pivot,0.022,Color(0.09,0.12,0.13),Vector3(side*0.12,0.28,0.308))
        SurvivorModels.beam(head_pivot,Vector3(side*0.08,0.35,0.29),Vector3(side*0.17,0.35,0.26),0.018,Color(0.19,0.15,0.10))
    SurvivorModels.beam(head_pivot,Vector3(-0.10,0.08,0.27),Vector3(0.10,0.08,0.27),0.025,Color(0.31,0.20,0.14))
    SurvivorModels.merge_static(head_pivot,"hero_head")
    left_leg = _joint(body_pivot,Vector3(-0.25,1.0,0))
    right_leg = _joint(body_pivot,Vector3(0.25,1.0,0))
    left_knee = _joint(left_leg,Vector3(0,-0.44,0))
    right_knee = _joint(right_leg,Vector3(0,-0.44,0))
    for leg in [left_leg,right_leg]:
        _limb(leg,0.44,0.19,pants)
        SurvivorModels.merge_static(leg,"hero_thigh")
    for knee in [left_knee,right_knee]:
        _limb(knee,0.39,0.15,pants)
        SurvivorModels.box(knee,Vector3(0.33,0.22,0.48),Color(0.19,0.15,0.1),Vector3(0,-0.40,0.10))
        SurvivorModels.merge_static(knee,"hero_shin")
    left_arm = _joint(torso,Vector3(-0.53,0.35,0))
    right_arm = _joint(torso,Vector3(0.53,0.35,0))
    left_elbow = _joint(left_arm,Vector3(0,-0.38,0))
    right_elbow = _joint(right_arm,Vector3(0,-0.38,0))
    for arm in [left_arm,right_arm]:
        _limb(arm,0.18,0.18,shirt)
        SurvivorModels.beam(arm,Vector3(0,-0.16,0),Vector3(0,-0.38,0),0.13,skin)
        SurvivorModels.merge_static(arm,"hero_upper_arm")
    for elbow in [left_elbow,right_elbow]:
        _limb(elbow,0.31,0.12,skin)
        SurvivorModels.sphere(elbow,0.12,skin,Vector3(0,-0.34,0),Vector3(0.72,1.05,0.55))
        for finger in range(3):
            SurvivorModels.beam(elbow,Vector3((finger-1)*0.045,-0.37,0.03),Vector3((finger-1)*0.04,-0.46,0.04),0.025,skin)
        SurvivorModels.merge_static(elbow,"hero_forearm_hand")
    right_hand = _joint(right_elbow,Vector3(0,-0.35,0))
    _build_tools()
    fishing_mesh = ImmediateMesh.new()
    fishing_line = MeshInstance3D.new()
    fishing_line.mesh = fishing_mesh
    var line_material := StandardMaterial3D.new()
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    line_material.albedo_color = Color(0.86,0.84,0.66)
    fishing_line.material_override = line_material
    fishing_line.visible = false
    add_child(fishing_line)
    bobber = SurvivorModels.sphere(self,0.08,Color(0.91,0.24,0.10),Vector3.ZERO)
    bobber.visible = false

func _build_tools() -> void:
    var timber := Color(0.43,0.29,0.14)
    var metal := Color(0.43,0.48,0.49)
    for kind in ["axe","pick","knife","spear","hammer","rod","food","skewer"]:
        var root := _joint(right_hand,Vector3.ZERO)
        root.name = kind
        root.visible = false
        tools[kind] = root
        match kind:
            "knife":
                SurvivorModels.beam(root,Vector3(0,0.1,0),Vector3(0,-0.2,0),0.045,timber)
                SurvivorModels.triangles(root,PackedVector3Array([Vector3(-0.08,-0.18,-0.04),Vector3(0.08,-0.18,-0.04),Vector3(0,-0.58,0),Vector3(0.08,-0.18,0.04),Vector3(-0.08,-0.18,0.04),Vector3(0,-0.58,0)]),Color(0.49,0.51,0.43))
            "axe":
                SurvivorModels.beam(root,Vector3(0,0.15,0),Vector3(0,-0.66,0),0.055,timber)
                SurvivorModels.triangles(root,PackedVector3Array([Vector3(-0.03,-0.5,-0.08),Vector3(-0.35,-0.53,-0.08),Vector3(-0.24,-0.77,-0.08),Vector3(-0.03,-0.5,0.08),Vector3(-0.24,-0.77,0.08),Vector3(-0.35,-0.53,0.08)]),metal)
                SurvivorModels.box(root,Vector3(0.12,0.20,0.16),metal,Vector3(0,-0.57,0))
            "pick":
                SurvivorModels.beam(root,Vector3(0,0.15,0),Vector3(0,-0.64,0),0.055,timber)
                SurvivorModels.beam(root,Vector3(-0.34,-0.58,0),Vector3(0.34,-0.66,0),0.07,metal)
            "spear":
                SurvivorModels.beam(root,Vector3(0,0.18,0),Vector3(0,-2.42,0),0.055,timber)
                SurvivorModels.triangles(root,PackedVector3Array([
                    Vector3(-0.18,-2.32,-0.07),Vector3(0.18,-2.32,-0.07),Vector3(0,-2.86,0),
                    Vector3(0.18,-2.32,0.07),Vector3(-0.18,-2.32,0.07),Vector3(0,-2.86,0)
                ]),Color(0.57,0.62,0.59))
                for y in [-2.34,-2.20]:
                    SurvivorModels.beam(root,Vector3(-0.1,y,0.035),Vector3(0.1,y+0.03,0.035),0.025,Color(0.68,0.52,0.33))
            "hammer":
                SurvivorModels.beam(root,Vector3(0,0.12,0),Vector3(0,-0.48,0),0.045,timber)
                SurvivorModels.box(root,Vector3(0.29,0.16,0.14),metal,Vector3(0,-0.46,0))
            "rod":
                root.rotation.x = -0.95
                SurvivorModels.beam(root,Vector3(0,0.12,0),Vector3(0,-2.75,0),0.04,Color(0.62,0.43,0.19))
                SurvivorModels.sphere(root,0.09,metal,Vector3(0,-0.15,0.05))
                SurvivorModels.beam(root,Vector3(0,-2.75,0),Vector3(0,-2.95,1.35),0.008,Color(0.82,0.83,0.71))
            "food":
                SurvivorModels.sphere(root,0.16,Color(0.48,0.34,0.18),Vector3(0,-0.10,0))
            "skewer":
                SurvivorModels.beam(root,Vector3(0,0.1,0),Vector3(0,-1.2,0),0.018,timber)
                SurvivorModels.sphere(root,0.14,Color(0.61,0.42,0.18),Vector3(0,-0.8,0),Vector3(0.8,1.9,0.6))
        SurvivorModels.merge_static(root,"hero_tool_"+kind)

func _update_fishing_line() -> void:
    var tip: Vector3 = tools.rod.global_transform*Vector3(0,-2.75,0)
    var end := action_point+Vector3(0,sin(animation_clock)*0.025,0)
    fishing_mesh.clear_surfaces()
    fishing_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    fishing_mesh.surface_add_vertex(to_local(tip))
    fishing_mesh.surface_add_vertex(to_local(end))
    fishing_mesh.surface_end()
    bobber.global_position = end
