extends SceneTree

# Authentic Godot 4.6.1 GLB renders for explicit model choice.
# Source files are the real glTF MakeHuman outputs, not AI mockups.
const ASSETS := [
    ["man.glb","A — Homem (corpo-base)"],
    ["suited.glb","B — Homem vestido"],
    ["human.glb","C — Humano alternativo"]
]
const DEST := "/tmp/hero-options-real-godot"
var studio: Node3D
var cam: Camera3D
var subjects: Array[Node3D] = []

func _initialize() -> void:
    call_deferred("_execute")

func _capture(name: String) -> void:
    await create_timer(0.3).timeout
    await RenderingServer.frame_post_draw
    var result := get_root().get_texture().get_image().save_png(DEST.path_join(name+".png"))
    assert(result == OK)
    print("REAL_MAKEHUMAN_OPTION ",name)

func _execute() -> void:
    DirAccess.make_dir_recursive_absolute(DEST)
    root.size = Vector2i(1400,800)
    studio = Node3D.new()
    root.add_child(studio)
    var lighting := DirectionalLight3D.new()
    lighting.rotation_degrees = Vector3(-54,-27,0)
    lighting.light_energy = 1.25
    lighting.shadow_enabled = true
    studio.add_child(lighting)
    var soft := DirectionalLight3D.new()
    soft.rotation_degrees = Vector3(-36,120,0)
    soft.light_energy = 0.30
    studio.add_child(soft)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.19,0.22,0.25)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72,0.78,0.85)
    env.ambient_light_energy = 0.63
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    studio.add_child(world)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(17.0,10.0)
    ground.mesh = plane
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.34,0.37,0.40)
    floor_mat.roughness = 0.90
    ground.material_override = floor_mat
    studio.add_child(ground)
    cam = Camera3D.new()
    cam.fov = 43.0
    studio.add_child(cam)
    cam.make_current()
    for i in range(ASSETS.size()):
        var filename: String = ASSETS[i][0]
        var path := "res://assets/characters/candidates/"+filename
        assert(ResourceLoader.exists(path),"Model unavailable: "+path)
        var source: PackedScene = load(path) as PackedScene
        assert(source != null)
        var scene := source.instantiate() as Node3D
        studio.add_child(scene)
        var skel: Skeleton3D
        var animator: AnimationPlayer
        for n in scene.find_children("*","Skeleton3D",true,false):
            skel = n as Skeleton3D
            break
        for n in scene.find_children("*","AnimationPlayer",true,false):
            animator = n as AnimationPlayer
            break
        assert(skel!=null and skel.get_bone_count()>=40,filename)
        assert(animator!=null,filename)
        var minimum := Vector3(INF,INF,INF)
        var maximum := Vector3(-INF,-INF,-INF)
        var found := 0
        for n in scene.find_children("*","MeshInstance3D",true,false):
            var mesh := n as MeshInstance3D
            if mesh.mesh == null:continue
            found+=1
            var bounds := mesh.mesh.get_aabb()
            for c in range(8):
                var v := scene.to_local(mesh.global_transform*bounds.get_endpoint(c))
                minimum = minimum.min(v)
                maximum = maximum.max(v)
        assert(found>0 and maximum.y-minimum.y>0.1)
        var factor := 2.15/(maximum.y-minimum.y)
        scene.scale=Vector3.ONE*factor
        scene.position=Vector3((float(i)-1.0)*2.5,-minimum.y*factor,0)
        subjects.append(scene)
        for name in animator.get_animation_list():
            if String(name).to_lower().ends_with("idle"):
                animator.play(name)
                break
        print("OPTION_MODEL ",filename," bones=",skel.get_bone_count()," meshes=",found," normalized_height=2.15 materials=",scene.find_children("*","MeshInstance3D",true,false).size())
    # Show physically separate 3d assets together, no image generation.
    cam.global_position = Vector3(0,2.9,12.4)
    cam.look_at(Vector3(0,1.18,0),Vector3.UP)
    await create_timer(1.3).timeout
    await _capture("01_three_makehuman_models_original")
    for i in range(subjects.size()):
        for j in range(subjects.size()):
            subjects[j].visible = j==i
        cam.global_position=Vector3((float(i)-1.0)*2.5,2.22,5.2)
        cam.look_at(Vector3((float(i)-1.0)*2.5,1.10,0),Vector3.UP)
        await _capture("0%d_%s_full_body" % [i+2,ASSETS[i][0].get_basename()])
        cam.global_position=Vector3((float(i)-1.0)*2.5,2.25,2.15)
        cam.look_at(Vector3((float(i)-1.0)*2.5,1.70,0),Vector3.UP)
        await _capture("0%d_%s_face_details" % [i+5,ASSETS[i][0].get_basename()])
    print("MAKEHUMAN_COMPARISON_COMPLETE")
    studio.queue_free()
    await create_timer(0.25).timeout
    quit()
