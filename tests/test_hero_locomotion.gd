extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("HERO_GAIT_FAIL: "+message)

func point(skeleton: Skeleton3D, bone: String) -> Vector3:
    return skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin

func run() -> void:
    var player := SurvivorPlayer.new()
    root.add_child(player)
    player.set_physics_process(false)
    check(player.using_skinned_hero,"real dressed MakeHuman loads")
    var rig := player.rigged_hero
    rig.set_process(false)
    var skeleton := rig.skeleton
    var animator := rig.animator
    for name in ["idle","walk","run"]:
        var clip := animator.get_animation(rig.clips[name])
        check(clip.loop_mode == Animation.LOOP_LINEAR,name+" loops without freezing")
        animator.play(rig.clips[name],0.0)
        animator.pause()
        for sample in range(121):
            animator.seek(clip.length*float(sample)/120.0,true)
            skeleton.force_update_all_bone_transforms()
            var left := point(skeleton,"foot_l")
            var right := point(skeleton,"foot_r")
            var pelvis := point(skeleton,"pelvis")
            var head := point(skeleton,"head")
            check(left.x > 0.15 and right.x < -0.15,"feet never swap sides: "+name)
            check(point(skeleton,"calf_l").x > 0.09 and point(skeleton,"calf_r").x < -0.09,"knees never cross: "+name)
            check(point(skeleton,"hand_l").x > 0.19 and point(skeleton,"hand_r").x < -0.19,"hands stay on correct sides: "+name)
            check(absf(head.x-pelvis.x)<0.015 and absf(head.z-pelvis.z)<0.08,"upright torso: "+name)
            var floor_y := skeleton.get_bone_global_rest(skeleton.find_bone("foot_l")).origin.y
            check(absf(minf(left.y,right.y)-floor_y)<0.015,"support foot stays grounded: "+name)
        # End/start are the same transform, with no one-frame seam at repeat.
        for track in range(clip.get_track_count()):
            var first: Variant = clip.track_get_key_value(track,0)
            var last: Variant = clip.track_get_key_value(track,clip.track_get_key_count(track)-1)
            if first is Quaternion:
                check(absf(first.dot(last))>0.9999,"rotation seam "+name)
            else:
                check(first.distance_to(last)<0.0001,"position seam "+name)
    player.walking = true
    for blend in [0.0,1.0]:
        player.locomotion_blend = blend
        for yaw in [0.0,PI/2.0,PI,-PI/2.0]:
            player.body_pivot.rotation.y = yaw
            player.animation_clock = 1.25
            player._base_pose()
            check(is_zero_approx(player.body_pivot.rotation.x) and is_zero_approx(player.body_pivot.rotation.z),"no legacy lean in any heading")
            check(is_zero_approx(player.body_pivot.position.y),"no double body bounce")
    for mode in ["idle","walk","run","walk","idle"]:
        player.walking = mode != "idle"
        player.locomotion_blend = 1.0 if mode == "run" else 0.0
        rig._process(1.0/60.0)
        check(animator.current_animation == rig.clips[mode],"controller transition "+mode)
        animator.advance(0.3)
        skeleton.force_update_all_bone_transforms()
        check(point(skeleton,"foot_l").x>0.1 and point(skeleton,"foot_r").x < -0.1,"transition has no crossed legs")
    check(player.right_hand.get_parent()==rig.grip,"equipment remains attached to real hand")
    print("HERO_LOCOMOTION: %d checks, %d failures" % [checks,failures])
    player.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
