extends Node3D
class_name SurvivorSkinnedActor

# Original integration code. Model is a separately licensed, pinned MakeHuman
# output with 53 actual bones, skinned mesh, 4 native clips and diffuse maps.
# The old procedural body stays available as an error-safe fallback.
const SOURCE := "res://assets/characters/makehuman_survivor.glb"
var character: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var clips: Dictionary = {}
var grip: BoneAttachment3D
var owner_player: SurvivorPlayer
var normalized_height := 0.0
var equipment_basis := Basis.IDENTITY

func initialize(player: SurvivorPlayer, tool_hand: Node3D) -> bool:
    owner_player = player
    if not ResourceLoader.exists(SOURCE):
        push_warning("CC0 MakeHuman source missing: original procedural hero retained")
        return false
    var resource: PackedScene = load(SOURCE) as PackedScene
    if resource == null:
        return false
    character = resource.instantiate() as Node3D
    if character == null:
        return false
    add_child(character)
    for node in character.find_children("*", "Skeleton3D", true, false):
        skeleton = node as Skeleton3D
        break
    for node in character.find_children("*", "AnimationPlayer", true, false):
        animator = node as AnimationPlayer
        break
    if skeleton == null or animator == null:
        push_warning("Skinned MakeHuman import lacks Skeleton3D or AnimationPlayer")
        character.queue_free()
        return false
    var hand_bone := _find_bone(["hand_r", "RightHand", "mixamorig:RightHand"])
    if hand_bone < 0:
        push_warning("Skinned MakeHuman rig lacks right hand bone")
        character.queue_free()
        return false
    for name in animator.get_animation_list():
        var simple := String(name).get_slice("/", String(name).get_slice_count("/") - 1).to_lower()
        clips[simple] = String(name)
    if not clips.has("idle") or not clips.has("walk") or not clips.has("run"):
        push_warning("Skinned MakeHuman rig lacks native idle/walk/run")
        character.queue_free()
        return false
    # Replace incompatible source locomotion with rig-space, looping clips.
    # Duplicate only the mapping: the imported GLB and its native wave stay intact.
    clips.merge(SurvivorHeroLocomotion.install(skeleton,animator),true)
    # Measure the actual imported skinned vertices in world space so the scale
    # stays consistent even if the GLB exporter uses centimetre units.
    var minimum := Vector3(INF,INF,INF)
    var maximum := Vector3(-INF,-INF,-INF)
    var found_mesh := false
    for child in character.find_children("*", "MeshInstance3D", true, false):
        var mesh_node := child as MeshInstance3D
        if mesh_node.mesh == null:
            continue
        found_mesh = true
        var aabb := mesh_node.mesh.get_aabb()
        for corner in range(8):
            var p := to_local(mesh_node.global_transform * aabb.get_endpoint(corner))
            minimum = minimum.min(p)
            maximum = maximum.max(p)
    if not found_mesh or maximum.y-minimum.y < 0.01:
        character.queue_free()
        return false
    normalized_height = 2.07
    var scale_factor := clampf(normalized_height/(maximum.y-minimum.y),0.01,100.0)
    character.scale = Vector3.ONE*scale_factor
    character.position.y = -minimum.y*scale_factor
    # Attach all existing equipment to a real animated right-hand bone,
    # leaving tools[] and their interaction/state contracts untouched.
    grip = BoneAttachment3D.new()
    grip.name = "SurvivalEquipmentGrip"
    skeleton.add_child(grip)
    grip.bone_name = skeleton.get_bone_name(hand_bone)
    tool_hand.reparent(grip,false)
    tool_hand.position = Vector3(0,-0.025,0)
    tool_hand.rotation = Vector3.ZERO
    animator.play(clips["idle"],0.0)
    animator.advance(0.0)
    skeleton.force_update_all_bone_transforms()
    equipment_basis = skeleton.get_bone_global_pose(hand_bone).basis.orthonormalized().inverse()
    tool_hand.basis = equipment_basis
    print("REAL_HERO_ACTIVE bones=%d height=%.2f grip=%s clips=%s" % [
        skeleton.get_bone_count(),normalized_height,grip.bone_name,str(clips.keys())])
    return true

func _find_bone(candidates: Array[String]) -> int:
    for name in candidates:
        var i := skeleton.find_bone(name)
        if i >= 0:
            return i
    for i in range(skeleton.get_bone_count()):
        var label := skeleton.get_bone_name(i).to_lower()
        if "hand" in label and ("right" in label or label.ends_with("_r")):
            return i
    return -1

func _process(_delta: float) -> void:
    if owner_player == null or animator == null:
        return
    var target := "idle"
    if owner_player.is_busy():
        target = owner_player.action_kind if clips.has(owner_player.action_kind) else "gather"
        if animator.current_animation!=clips[target]:
            animator.play(clips[target],0.0)
        animator.speed_scale = 0.0
        var progress := clampf(1.0-owner_player.action_remaining/owner_player.action_duration,0.0,1.0)
        animator.seek(progress*animator.current_animation_length,true)
    else:
        if owner_player.walking:
            target = "run" if owner_player.locomotion_blend>0.52 else "walk"
        if animator.current_animation!=clips[target]:
            animator.play(clips[target],0.16)
        # Calibrated support phase stride in world units; cadence responds to
        # actual displacement, including slow analog input and collision sliding.
        if target in ["walk","run"]:
            var reference := (4.0*0.38/0.72 if target=="run" else 4.0*0.33)*character.scale.y
            animator.speed_scale = clampf(owner_player.measured_speed/reference,0.20,1.65)
        else:
            animator.speed_scale = 1.0
    # Equipment dimensions are authored in metres, independent of the imported
    # character scale. Orient the grip in actor space instead of inheriting the
    # exporter's wrist axis; the attachment still follows the real wrist position.
    if grip != null and owner_player.right_hand != null:
        skeleton.force_update_all_bone_transforms()
        var wrist := skeleton.get_bone_global_pose(skeleton.find_bone(grip.bone_name)).basis.orthonormalized()
        var pitch := -0.45
        if owner_player.action_kind == "fish":
            pitch = -1.88
            owner_player.tools.rod.rotation.x = 0.0
        elif owner_player.action_kind == "spear":
            pitch = -PI*0.5
        elif owner_player.action_kind in ["chop","mine","build","craft","cut"]:
            var phase := clampf(1.0-owner_player.action_remaining/owner_player.action_duration,0.0,1.0)
            if phase<0.25:
                pitch = lerpf(-0.45,-2.3,phase/0.25)
            elif phase<0.47:
                pitch = lerpf(-2.3,-0.65,(phase-0.25)/0.22)
            else:
                pitch = lerpf(-0.65,-0.45,(phase-0.47)/0.53)
        elif owner_player.action_kind in ["eat","cook"]:
            pitch = 0.0
        owner_player.right_hand.basis = (wrist.inverse()*Basis(Vector3.RIGHT,pitch)).scaled(Vector3.ONE/character.scale.y)
