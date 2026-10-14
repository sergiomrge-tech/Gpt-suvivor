extends Node3D
class_name SurvivorHarvestEffects
var active := 0
const MAX_ACTIVE := 8

func collect(entry: Dictionary, terrain: SurvivorTerrain) -> void:
    if active>=MAX_ACTIVE or entry.kind not in ["tree","palm","rock","loose_log","loose_stone","fiber"]:
        return
    active += 1
    var effect := Node3D.new()
    effect.name = "HarvestFeedback"
    effect.position = entry.position
    effect.rotation.y = entry.node.rotation.y
    add_child(effect)
    if entry.kind in ["tree","palm"]:
        var source := str(entry.get("source_asset",""))
        var height := float(entry.get("height",8.25))
        if source=="":
            for child in entry.node.get_children():
                if child is Node3D and child.has_meta("source_asset"):
                    source = str(child.get_meta("source_asset"))
                    height = float(child.get_meta("target_height",8.25))
                    break
        if source=="":
            source = "palm_light" if entry.kind=="palm" else "pachira"
        SurvivorRealWorldAssets.attach(effect,source,height,65.0)
        var fall := create_tween()
        fall.tween_property(effect,"rotation:z",PI*0.48,0.80).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        fall.tween_interval(0.25)
        fall.tween_property(effect,"scale",Vector3.ONE*0.02,0.35)
        fall.tween_callback(func(): effect.queue_free(); active-=1)
    else:
        var count := 6 if entry.kind=="rock" else 3
        for i in range(count):
            var fragment := Node3D.new()
            effect.add_child(fragment)
            SurvivorRealWorldAssets.attach(fragment,"rock_07" if entry.kind in ["rock","loose_stone"] else "dead_tree_trunk_02",0.12,38.0)
            var angle := TAU*float(i)/float(count)
            var spread := Vector3(cos(angle),0,sin(angle))*0.60
            var bounce := create_tween()
            bounce.tween_property(fragment,"position",spread+Vector3.UP*0.45,0.18)
            bounce.tween_property(fragment,"position",spread,0.30).set_trans(Tween.TRANS_QUAD)
            bounce.tween_property(fragment,"scale",Vector3.ZERO,0.18)
        var cleanup := create_tween()
        cleanup.tween_interval(0.75)
        cleanup.tween_callback(func(): effect.queue_free(); active-=1)
