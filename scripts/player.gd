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
var left_foot: Node3D
var right_foot: Node3D
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
var rigged_hero: SurvivorSkinnedActor
var using_skinned_hero := false

func _ready() -> void:
    _build_character()
    _activate_skinned_hero()
    var listener := AudioListener3D.new()
    listener.position.y = 1.6
    add_child(listener)
    listener.make_current()

func is_busy() -> bool:
    return action_remaining > 0.0

# The original movement, crafting and equipment code remains authoritative.
# Only the rendered character and its equipment hand follow the imported rig.
func _activate_skinned_hero() -> void:
    rigged_hero = SurvivorSkinnedActor.new()
    rigged_hero.name = "RealMakeHumanSurvivor"
    body_pivot.add_child(rigged_hero)
    if not rigged_hero.initialize(self,right_hand):
        rigged_hero.queue_free()
        rigged_hero = null
        return
    using_skinned_hero = true
    torso.visible = false
    left_leg.visible = false
    right_leg.visible = false

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
    position.y = world.surface_height(position)
    var moved := Vector2(position.x-previous.x,position.z-previous.z).length()
    walking = walking and moved > 0.001
    if walking:
        # Collision may block just one axis. Face the real displacement so
        # sliding along a rock does not leave the gait pointing diagonally.
        var heading := atan2(position.x-previous.x,position.z-previous.z)
        body_pivot.rotation.y = lerp_angle(body_pivot.rotation.y,heading,minf(1.0,delta*12))
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
    # Feet counter-rotate against the shin and roll gently heel-to-toe;
    # ankle pivots are visual only and preserve the original collision body.
    left_foot.rotation.x = -left_knee.rotation.x * 0.56 + swing * (0.18 if walking else 0.0)
    right_foot.rotation.x = -right_knee.rotation.x * 0.56 - swing * (0.18 if walking else 0.0)
    # Heel clearance follows the swing-leg phase, whereas the planted leg
    # remains near the terrain. No physics or resource locations are changed.
    var lift_left := maxf(0.0,-sin(animation_clock))*0.045 if walking else 0.0
    var lift_right := maxf(0.0,sin(animation_clock))*0.045 if walking else 0.0
    left_foot.position.y = -0.52 + lift_left
    right_foot.position.y = -0.52 + lift_right
    left_arm.rotation = Vector3(-swing*lerpf(0.65,0.78,locomotion_blend)-locomotion_blend*0.22,0,0.04)
    right_arm.rotation = Vector3(swing*lerpf(0.65,0.78,locomotion_blend)-locomotion_blend*0.22,0,-0.04)
    left_elbow.rotation.x = -0.15
    right_elbow.rotation.x = -0.15
    # Counter-rotation keeps the gaze stable while hips and shoulders move.
    var breathing := sin(animation_clock * 0.58) * 0.012
    var shoulder_turn := sin(animation_clock) * (0.055 if walking else 0.006)
    var lateral_sway := sin(animation_clock) * (0.035 if walking else 0.005)
    torso.rotation = Vector3(((0.035 + locomotion_blend * 0.16) if walking else breathing), shoulder_turn, -lateral_sway)
    # Different shoulder and hip phases keep strides from appearing rigid.
    left_leg.rotation.z = 0.025*sin(animation_clock+0.55) if walking else 0.0
    right_leg.rotation.z = 0.025*sin(animation_clock-0.55) if walking else 0.0
    left_elbow.rotation.y = -0.045*sin(animation_clock) if walking else 0.0
    right_elbow.rotation.y = 0.045*sin(animation_clock) if walking else 0.0
    head_pivot.rotation = Vector3(-torso.rotation.x * 0.32, -shoulder_turn * 0.56, lateral_sway * 0.44)
    if using_skinned_hero:
        # Native skin already animates weight transfer. Legacy pivot sway was
        # being added on top, leaning the entire body and both planted soles.
        body_pivot.rotation.x = 0.0
        body_pivot.rotation.z = 0.0
        body_pivot.position.y = 0.0
        return
    body_pivot.rotation.x = 0.028 * locomotion_blend
    body_pivot.rotation.z = sin(animation_clock) * (0.021 if walking else 0.003)
    body_pivot.position.y = absf(sin(animation_clock)) * lerpf(0.042, 0.073, locomotion_blend) if walking else breathing * 0.30

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
    if kind == "chop" and world != null and world.state.is_equipped("reinforced_axe"):
        tool = "reinforced_axe"
    elif kind == "mine" and world != null and world.state.is_equipped("reinforced_pickaxe"):
        tool = "reinforced_pickaxe"
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
    SurvivorHeroGeometry.shaped_limb(parent, length, radius, radius * 0.85, color)

func _build_character() -> void:
    # v1.7: restrained anatomical detailing, shaped footwear and articulated
    # ankle pivots. Keep all original action joints, grip and tool transforms.
    var skin := Color(0.65, 0.44, 0.31)
    var skin_shadow := Color(0.58, 0.38, 0.27)
    var shirt := Color(0.19, 0.34, 0.36)
    var shirt_shadow := Color(0.14, 0.27, 0.29)
    var pants := Color(0.30, 0.31, 0.29)
    var leather := Color(0.35, 0.26, 0.18)
    var stitches := Color(0.42, 0.45, 0.39)
    body_pivot = _joint(self, Vector3.ZERO)
    body_pivot.name = "AnimatedBody"
    torso = _joint(body_pivot, Vector3(0, 1.45, 0))
    SurvivorHeroGeometry.loft(torso, PackedVector4Array([
        Vector4(0.52, 0.135, 0.125, 0),
        Vector4(0.45, 0.255, 0.183, -0.015),
        Vector4(0.32, 0.365, 0.224, -0.005),
        Vector4(0.17, 0.385, 0.248, 0.005),
        Vector4(0.03, 0.369, 0.261, 0.008),
        Vector4(-0.13, 0.317, 0.255, 0.014),
        Vector4(-0.27, 0.302, 0.247, 0.015),
        Vector4(-0.42, 0.295, 0.23, 0.0),
        Vector4(-0.48, 0.283, 0.213, 0)
    ]), shirt, 24)
    # Shirt hem, folded sleeves, reinforced shoulder seams and a flatter pack.
    SurvivorModels.beam(torso, Vector3(-0.30, -0.405, 0.21), Vector3(0.30, -0.405, 0.21), 0.024, shirt_shadow)
    for side in [-1.0, 1.0]:
        SurvivorModels.beam(torso, Vector3(side * 0.13, 0.46, 0.10), Vector3(side * 0.35, 0.29, 0.04), 0.014, shirt_shadow)
        SurvivorModels.beam(torso, Vector3(side * 0.28, -0.27, 0.25), Vector3(side * 0.29, -0.43, 0.23), 0.015, stitches)
        SurvivorModels.beam(torso, Vector3(side * 0.29, -0.34, -0.20), Vector3(side * 0.28, 0.40, -0.13), 0.052, leather)
    SurvivorHeroGeometry.loft(torso, PackedVector4Array([
        Vector4(0.36, 0.23, 0.095, -0.35),
        Vector4(0.27, 0.32, 0.15, -0.38),
        Vector4(-0.29, 0.32, 0.15, -0.38),
        Vector4(-0.40, 0.23, 0.095, -0.36)
    ]), leather, 18)
    SurvivorModels.box(torso, Vector3(0.61, 0.11, 0.08), Color(0.26, 0.21, 0.15), Vector3(0, -0.40, 0.23))
    SurvivorModels.box(torso, Vector3(0.12, 0.075, 0.035), Color(0.66, 0.62, 0.50), Vector3(0, -0.40, 0.28))
    # Open shirt neckline, displaced stitched collar and irregular creases
    # break the otherwise seamless tubular silhouette of the torso.
    for side in [-1.0, 1.0]:
        SurvivorModels.beam(torso,Vector3(side*0.12,0.51,0.166),Vector3(side*0.19,0.38,0.208),0.016,shirt_shadow)
        SurvivorModels.beam(torso,Vector3(side*0.17,-0.11,0.281),Vector3(side*0.32,-0.22,0.235),0.011,shirt.lightened(0.10))
        SurvivorModels.beam(torso,Vector3(side*0.21,0.12,0.242),Vector3(side*0.32,0.07,0.206),0.009,shirt_shadow)
    SurvivorModels.beam(torso,Vector3(0,0.40,0.295),Vector3(0,0.17,0.304),0.009,shirt_shadow)
    # Two cinch straps anchor the fabric to the already existing backpack.
    SurvivorModels.beam(torso,Vector3(-0.29,0.33,-0.10),Vector3(-0.24,-0.37,-0.23),0.031,leather)
    SurvivorModels.beam(torso,Vector3(0.29,0.33,-0.10),Vector3(0.24,-0.37,-0.23),0.031,leather)
    SurvivorModels.merge_static(torso, "hero_torso_v18")

    head_pivot = _joint(torso, Vector3(0, 0.67, 0))
    # Anatomical audit: the former oversized cranium read as a toy head.
    # Scale only its visual joint so gear/action roots stay unchanged.
    head_pivot.scale = Vector3(0.80,0.73,0.80)
    SurvivorHeroGeometry.shaped_limb(head_pivot, 0.22, 0.15, 0.16, skin_shadow, 1.0)
    # Face is a single continuous jaw/cheek/cranium surface (not a ball).
    SurvivorHeroGeometry.loft(head_pivot, PackedVector4Array([
        Vector4(0.62, 0.012, 0.012, -0.01),
        Vector4(0.58, 0.165, 0.178, -0.02),
        Vector4(0.50, 0.257, 0.225, -0.015),
        Vector4(0.42, 0.278, 0.244, -0.005),
        Vector4(0.33, 0.29, 0.252, 0.00),
        Vector4(0.23, 0.278, 0.242, 0.015),
        Vector4(0.13, 0.255, 0.224, 0.015),
        Vector4(0.04, 0.19, 0.178, 0.02),
        Vector4(-0.04, 0.125, 0.125, 0.01),
        Vector4(-0.085, 0.035, 0.045, 0.005)
    ]), skin, 24)
    # Irregular close-cropped hair follows the scalp, with a natural hairline.
    SurvivorHeroGeometry.loft(head_pivot, PackedVector4Array([
        Vector4(0.648, 0.012, 0.012, -0.018),
        Vector4(0.60, 0.195, 0.206, -0.023),
        Vector4(0.515, 0.286, 0.259, -0.035),
        Vector4(0.435, 0.308, 0.267, -0.055)
    ]), Color(0.19, 0.17, 0.14), 24)
    # The previous dark eye-socket spheres and protruding circular nose made
    # the face read like a toy. A contoured bridge and subdued recessed eyelids
    # keep the same expression without oversize cartoon features.
    SurvivorHeroGeometry.loft(head_pivot, PackedVector4Array([
        Vector4(0.355,0.026,0.028,0.236),
        Vector4(0.314,0.032,0.045,0.257),
        Vector4(0.263,0.042,0.052,0.275),
        Vector4(0.217,0.054,0.059,0.287),
        Vector4(0.183,0.052,0.052,0.292),
        Vector4(0.158,0.025,0.022,0.274)
    ]), skin, 16)
    for side in [-1.0, 1.0]:
        SurvivorModels.sphere(head_pivot, 0.071, skin, Vector3(side * 0.29, 0.252, -0.013), Vector3(0.43, 1.0, 0.64))
        # Recessed eyes. White sclera is a small shallow surface, not a
        # bright sphere floating in front of the cheeks.
        SurvivorModels.sphere(head_pivot, 0.043, skin_shadow, Vector3(side * 0.130,0.308,0.240), Vector3(1.2,0.55,0.28))
        SurvivorModels.sphere(head_pivot, 0.027, Color(0.67,0.62,0.53), Vector3(side * 0.130,0.305,0.249), Vector3(1.15,0.41,0.28))
        SurvivorModels.sphere(head_pivot, 0.015, Color(0.18,0.16,0.15), Vector3(side * 0.130,0.305,0.260), Vector3(0.8,0.88,0.4))
        SurvivorModels.beam(head_pivot,Vector3(side*0.077,0.323,0.249),Vector3(side*0.179,0.323,0.227),0.010,skin_shadow)
        SurvivorModels.beam(head_pivot, Vector3(side * 0.077, 0.370, 0.250), Vector3(side * 0.200, 0.364, 0.222), 0.014, Color(0.22, 0.18, 0.15))
    SurvivorModels.beam(head_pivot, Vector3(-0.077, 0.091, 0.228), Vector3(0.077, 0.091, 0.228), 0.016, skin_shadow)
    # Subtle cheek/jaw plane transitions, scalp hair wisps and a believable
    # narrow mouth avoid the previous painted-on spherical facial appearance.
    for side in [-1.0, 1.0]:
        SurvivorModels.beam(head_pivot,Vector3(side*0.215,0.214,0.174),Vector3(side*0.105,0.115,0.232),0.010,skin_shadow.lightened(0.06))
        SurvivorModels.beam(head_pivot,Vector3(side*0.24,0.477,0.159),Vector3(side*0.12,0.43,0.236),0.012,Color(0.18,0.15,0.13))
        SurvivorModels.sphere(head_pivot,0.018,skin_shadow,Vector3(side*0.031,0.184,0.321),Vector3(0.9,0.50,0.26))
    SurvivorModels.merge_static(head_pivot, "hero_head_v18_face")

    # Raised pelvis + longer upper/lower legs, keeping ankle soles at the
    # original surface height. Anatomical shape changes never affect speed,
    # collisions or the world save position.
    left_leg = _joint(body_pivot, Vector3(-0.22, 1.24, 0))
    right_leg = _joint(body_pivot, Vector3(0.22, 1.24, 0))
    left_knee = _joint(left_leg, Vector3(0, -0.55, 0))
    right_knee = _joint(right_leg, Vector3(0, -0.55, 0))
    for leg in [left_leg, right_leg]:
        SurvivorHeroGeometry.shaped_limb(leg, 0.55, 0.174, 0.144, pants, 1.04)
        SurvivorModels.beam(leg, Vector3(0.10, -0.12, 0.13), Vector3(0.08, -0.46, 0.13), 0.012, pants.darkened(0.13))
        SurvivorModels.merge_static(leg, "hero_thigh_v17")
    for knee in [left_knee, right_knee]:
        SurvivorHeroGeometry.shaped_limb(knee, 0.51, 0.151, 0.108, pants, 0.97)
        SurvivorModels.beam(knee, Vector3(-0.085, -0.37, 0.095), Vector3(0.085, -0.37, 0.095), 0.013, pants.darkened(0.19))
        SurvivorModels.merge_static(knee, "hero_shin_v17")
    left_foot = _joint(left_knee, Vector3(0, -0.52, 0))
    right_foot = _joint(right_knee, Vector3(0, -0.52, 0))
    left_foot.name = "LeftAnkle"
    right_foot.name = "RightAnkle"
    for foot in [left_foot, right_foot]:
        SurvivorHeroGeometry.boot(foot,leather,Color(0.18,0.16,0.14))
        SurvivorModels.merge_static(foot, "hero_boot_v17")

    left_arm = _joint(torso, Vector3(-0.395, 0.30, 0))
    right_arm = _joint(torso, Vector3(0.395, 0.30, 0))
    left_elbow = _joint(left_arm, Vector3(0, -0.38, 0))
    right_elbow = _joint(right_arm, Vector3(0, -0.38, 0))
    for arm in [left_arm, right_arm]:
        SurvivorHeroGeometry.shaped_limb(arm, 0.245, 0.126, 0.108, shirt, 1.0)
        SurvivorHeroGeometry.shaped_limb(arm, 0.385, 0.113, 0.098, skin, 0.96)
        SurvivorModels.beam(arm, Vector3(-0.16, -0.20, 0), Vector3(0.16, -0.20, 0), 0.020, shirt_shadow)
        SurvivorModels.merge_static(arm, "hero_upper_arm_v17")
    for elbow in [left_elbow, right_elbow]:
        SurvivorHeroGeometry.shaped_limb(elbow, 0.32, 0.104, 0.086, skin, 0.92)
        SurvivorHeroGeometry.loft(elbow,PackedVector4Array([
            Vector4(-0.315,0.089,0.078,0.012),
            Vector4(-0.360,0.103,0.078,0.018),
            Vector4(-0.423,0.091,0.066,0.028),
            Vector4(-0.453,0.067,0.052,0.035)
        ]),skin,16)
        SurvivorModels.beam(elbow,Vector3(0.11,-0.352,0.042),Vector3(0.152,-0.429,0.103),0.028,skin)
        for finger in range(4):
            var fx := (float(finger) - 1.5) * 0.046
            SurvivorModels.beam(elbow, Vector3(fx, -0.37, 0.026), Vector3(fx * 0.97, -0.455 + absf(fx) * 0.18, 0.054), 0.018, skin)
        SurvivorModels.merge_static(elbow, "hero_forearm_hand_v17")
    right_hand = _joint(right_elbow, Vector3(0, -0.35, 0))
    _build_tools()
    fishing_mesh = ImmediateMesh.new()
    fishing_line = MeshInstance3D.new()
    fishing_line.mesh = fishing_mesh
    var line_material := StandardMaterial3D.new()
    line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    line_material.albedo_color = Color(0.86, 0.84, 0.66)
    fishing_line.material_override = line_material
    fishing_line.visible = false
    add_child(fishing_line)
    bobber = SurvivorModels.sphere(self, 0.08, Color(0.91, 0.24, 0.10), Vector3.ZERO)
    bobber.visible = false

func _build_tools() -> void:
    var timber := Color(0.43,0.29,0.14)
    var metal := Color(0.43,0.48,0.49)
    for kind in ["axe","pick","reinforced_axe","reinforced_pickaxe","knife","spear","hammer","rod","food","skewer"]:
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
            "reinforced_axe":
                SurvivorModels.beam(root,Vector3(0,0.14,0),Vector3(0,-0.85,0),0.065,timber)
                SurvivorModels.box(root,Vector3(0.65,0.30,0.22),Color(0.73,0.79,0.77),Vector3(-0.23,-0.69,0))
                SurvivorModels.triangles(root,PackedVector3Array([
                    Vector3(-0.5,-0.55,-0.12),Vector3(-0.67,-0.85,-0.12),Vector3(-0.48,-0.83,-0.12),
                    Vector3(-0.5,-0.55,0.12),Vector3(-0.48,-0.83,0.12),Vector3(-0.67,-0.85,0.12)
                ]),Color(0.86,0.88,0.85))
            "reinforced_pickaxe":
                SurvivorModels.beam(root,Vector3(0,0.15,0),Vector3(0,-0.87,0),0.066,timber)
                SurvivorModels.beam(root,Vector3(-0.58,-0.66,0),Vector3(0.58,-0.66,0),0.105,Color(0.70,0.76,0.76))
                SurvivorModels.triangles(root,PackedVector3Array([
                    Vector3(0.48,-0.64,-0.08),Vector3(0.72,-0.88,0),Vector3(0.48,-0.68,0.08),
                    Vector3(-0.48,-0.64,-0.08),Vector3(-0.72,-0.88,0),Vector3(-0.48,-0.68,0.08)
                ]),Color(0.86,0.88,0.85))
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
