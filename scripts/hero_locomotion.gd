extends RefCounted
class_name SurvivorHeroLocomotion

# Local, in-place clips built on the imported bind skeleton. The supplied walk
# crosses left/right legs and arms; its Euler axes are not this rig's hinges.
# Solve limb endpoints in model space, then convert back to each bone's parent.
# The CC0 mesh, skin weights, materials, proportions and original GLB stay intact.
const LIBRARY := "survivor_locomotion"

static func install(skeleton: Skeleton3D, animator: AnimationPlayer) -> Dictionary:
    var library := AnimationLibrary.new()
    var path := animator.get_node(animator.root_node).get_path_to(skeleton)
    for clip in ["idle", "walk", "run"]:
        library.add_animation(clip, _make_clip(skeleton, path, clip))
    animator.add_animation_library(LIBRARY, library)
    return {"idle": LIBRARY+"/idle", "walk": LIBRARY+"/walk", "run": LIBRARY+"/run"}

static func _make_clip(skeleton: Skeleton3D, path: NodePath, kind: String) -> Animation:
    var clip := Animation.new()
    clip.length = 2.0 if kind == "idle" else (0.72 if kind == "run" else 1.0)
    clip.loop_mode = Animation.LOOP_LINEAR
    var count := skeleton.get_bone_count()
    var rest: Array[Transform3D] = []
    var parents: Array[int] = []
    for bone in range(count):
        rest.append(skeleton.get_bone_global_rest(bone))
        parents.append(skeleton.get_bone_parent(bone))
        var bone_path := NodePath(String(path)+":"+skeleton.get_bone_name(bone))
        var position_track := clip.add_track(Animation.TYPE_POSITION_3D)
        clip.track_set_path(position_track, bone_path)
        var rotation_track := clip.add_track(Animation.TYPE_ROTATION_3D)
        clip.track_set_path(rotation_track, bone_path)
    var frames := int(ceil(clip.length * 30.0))
    var pelvis := skeleton.find_bone("pelvis")
    var moving := kind != "idle"
    var running := kind == "run"
    for frame in range(frames+1):
        var phase := float(frame)/float(frames)
        var pose: Array[Transform3D] = rest.duplicate()
        # Small vertical weight transfer; never roll the entire body sideways.
        var drop := (-0.07 if running else -0.03) - (0.028 if running else 0.022)*cos(phase*TAU*2.0) if moving else -0.002+0.001*sin(phase*TAU)
        _move_subtree(pelvis, Vector3(0,drop,0), pose, parents)
        for side in ["l", "r"]:
            var p := fposmod(phase + (0.5 if side == "r" else 0.0),1.0)
            var thigh := skeleton.find_bone("thigh_"+side)
            var calf := skeleton.find_bone("calf_"+side)
            var foot := skeleton.find_bone("foot_"+side)
            var target := rest[foot].origin
            # Support phase travels front-to-back at constant speed. Swing
            # returns smoothly, with heel clearance and a forward knee pole.
            var half_stride := 0.38 if running else 0.25
            if moving:
                if p < 0.5:
                    target.z += lerpf(half_stride,-half_stride,p*2.0)
                else:
                    var swing := (p-0.5)*2.0
                    target.z += lerpf(-half_stride,half_stride,smoothstep(0.0,1.0,swing))
                    target.y += (0.19 if running else 0.11)*sin(swing*PI)
            _solve_leg(thigh,calf,foot,target,pose,rest,parents)
            # Upper arms hang alongside the torso, not across it. Arm and leg
            # on the same side counter-swing, with modest elbow flexion.
            var upper := skeleton.find_bone("upperarm_"+side)
            var lower := skeleton.find_bone("lowerarm_"+side)
            var hand := skeleton.find_bone("hand_"+side)
            var sign_x := 1.0 if side == "l" else -1.0
            var swing_angle := (0.48 if running else 0.30)*cos(p*TAU) if moving else 0.0
            var direction := Vector3(sign_x*0.10,-cos(swing_angle),-sin(swing_angle)).normalized()
            _aim(upper,lower,direction,pose,rest,parents)
            var forearm := Vector3(sign_x*0.04,-cos(swing_angle-0.28),-sin(swing_angle-0.28)).normalized()
            _aim(lower,hand,forearm,pose,rest,parents)
        for bone in range(count):
            var local := pose[bone]
            if parents[bone] >= 0:
                local = pose[parents[bone]].affine_inverse()*local
            var time := phase*clip.length
            clip.position_track_insert_key(bone*2,time,local.origin)
            clip.rotation_track_insert_key(bone*2+1,time,local.basis.orthonormalized().get_rotation_quaternion())
    return clip

static func _descends_from(bone: int, ancestor: int, parents: Array[int]) -> bool:
    var current := bone
    while current >= 0:
        if current == ancestor:
            return true
        current = parents[current]
    return false

static func _move_subtree(bone: int, delta: Vector3, pose: Array[Transform3D], parents: Array[int]) -> void:
    for child in range(pose.size()):
        if _descends_from(child,bone,parents):
            pose[child].origin += delta

static func _set_basis(bone: int, desired: Basis, pose: Array[Transform3D], parents: Array[int]) -> void:
    var before := pose[bone]
    var after := Transform3D(desired,before.origin)
    var change := after*before.affine_inverse()
    for child in range(pose.size()):
        if _descends_from(child,bone,parents):
            pose[child] = change*pose[child]

static func _aim(bone: int, child: int, direction: Vector3, pose: Array[Transform3D], rest: Array[Transform3D], parents: Array[int]) -> void:
    var initial := (rest[child].origin-rest[bone].origin).normalized()
    var rotation := Quaternion(initial,direction.normalized())
    _set_basis(bone,Basis(rotation)*rest[bone].basis,pose,parents)

static func _solve_leg(thigh: int, calf: int, foot: int, target: Vector3, pose: Array[Transform3D], rest: Array[Transform3D], parents: Array[int]) -> void:
    var hip := pose[thigh].origin
    var upper_length := rest[thigh].origin.distance_to(rest[calf].origin)
    var lower_length := rest[calf].origin.distance_to(rest[foot].origin)
    var axis := (target-hip).normalized()
    var distance := clampf(hip.distance_to(target),0.01,upper_length+lower_length-0.001)
    var along := (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2.0*distance)
    var height := sqrt(maxf(0.0,upper_length*upper_length-along*along))
    var pole := (Vector3.BACK-axis*Vector3.BACK.dot(axis)).normalized()
    var knee := hip+axis*along+pole*height
    _aim(thigh,calf,knee-hip,pose,rest,parents)
    _aim(calf,foot,target-pose[calf].origin,pose,rest,parents)
    # Keep the sole's authored bind orientation throughout support/swing.
    _set_basis(foot,rest[foot].basis,pose,parents)
