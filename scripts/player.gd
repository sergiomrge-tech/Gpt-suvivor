extends Node3D
class_name SurvivorPlayer

var terrain: SurvivorTerrain
var move_vector := Vector2.ZERO
var speed := 8.5
var walking := false
var body_pivot: Node3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var stride_phase := 0.0

func _ready() -> void:
    _build_character()

func _physics_process(delta: float) -> void:
    if terrain == null:
        return
    var vec: Vector2 = move_vector.limit_length(1.0)
    walking = vec.length_squared() > 0.012
    if walking:
        var next_pos: Vector3 = position + Vector3(vec.x, 0.0, vec.y) * speed * delta
        if terrain.is_land(next_pos.x, next_pos.z):
            position.x = next_pos.x
            position.z = next_pos.z
        body_pivot.rotation.y = lerp_angle(body_pivot.rotation.y, atan2(vec.x, vec.y), delta * 11.0)
    position.y = terrain.height_at(position.x, position.z)
    if body_pivot != null:
        if walking:
            stride_phase += delta * 12.0
        var stride: float = sin(stride_phase) * 0.45 if walking else 0.0
        left_leg.rotation.x = lerpf(left_leg.rotation.x, stride, delta * 12.0)
        right_leg.rotation.x = lerpf(right_leg.rotation.x, -stride, delta * 12.0)
        left_arm.rotation.x = lerpf(left_arm.rotation.x, -stride * 0.65, delta * 12.0)
        right_arm.rotation.x = lerpf(right_arm.rotation.x, stride * 0.65, delta * 12.0)
        body_pivot.position.y = absf(sin(stride_phase)) * 0.08 if walking else 0.0

func _piece(parent: Node3D, shape: Mesh, color: Color, pos: Vector3, scale3: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = shape
    node.position = pos
    node.scale = scale3
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.8
    node.material_override = mat
    parent.add_child(node)
    return node

func _build_character() -> void:
    body_pivot = Node3D.new()
    body_pivot.name = "AnimatedBody"
    add_child(body_pivot)
    var torso := CapsuleMesh.new()
    torso.radius = 0.55
    torso.height = 1.7
    _piece(body_pivot, torso, Color(0.18, 0.37, 0.43), Vector3(0.0, 1.38, 0.0), Vector3(1.0, 0.9, 0.85))
    var head := SphereMesh.new()
    head.radius = 0.48
    head.height = 0.96
    _piece(body_pivot, head, Color(0.62, 0.39, 0.26), Vector3(0.0, 2.49, 0.0))
    _piece(body_pivot, head, Color(0.16, 0.16, 0.14), Vector3(0.0, 2.80, -0.03), Vector3(1.02, 0.35, 1.04))
    var leg := CapsuleMesh.new()
    leg.radius = 0.23
    leg.height = 1.0
    left_leg = _piece(body_pivot, leg, Color(0.21, 0.22, 0.25), Vector3(-0.29, 0.51, 0.0))
    right_leg = _piece(body_pivot, leg, Color(0.21, 0.22, 0.25), Vector3(0.29, 0.51, 0.0))
    var arm := CapsuleMesh.new()
    arm.radius = 0.19
    arm.height = 1.15
    left_arm = _piece(body_pivot, arm, Color(0.66, 0.43, 0.29), Vector3(-0.69, 1.47, 0.0))
    right_arm = _piece(body_pivot, arm, Color(0.66, 0.43, 0.29), Vector3(0.69, 1.47, 0.0))
    var pack := BoxMesh.new()
    pack.size = Vector3(1.0, 1.2, 0.55)
    _piece(body_pivot, pack, Color(0.37, 0.29, 0.16), Vector3(0.0, 1.48, -0.52))
