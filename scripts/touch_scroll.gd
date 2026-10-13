extends ScrollContainer
class_name SurvivorTouchScroll

var touch_allowed: Callable

func _input(event: InputEvent) -> void:
    if not is_visible_in_tree() or touch_allowed.is_valid() and not touch_allowed.call():
        return
    if event is InputEventScreenDrag and get_global_rect().has_point(event.position):
        scroll_vertical -= roundi(event.relative.y)
        # Let child buttons see the same drag and cancel their pending tap.
