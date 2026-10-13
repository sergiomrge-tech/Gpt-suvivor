extends Button
class_name SurvivorTouchButton

# Controls need explicit touch ownership so a second finger can press an action
# while the first finger remains on the movement joystick.
var touch_allowed: Callable
var touch_finger := -1
var touch_origin := Vector2.ZERO
var touch_cancelled := false

func can_touch() -> bool:
    return is_visible_in_tree() and not disabled and (not touch_allowed.is_valid() or touch_allowed.call())

func _input(event: InputEvent) -> void:
    if not can_touch():
        if touch_finger >= 0:
            touch_finger = -1
            set_pressed_no_signal(false)
        return
    if event is InputEventScreenTouch:
        if event.pressed and touch_finger < 0 and get_global_rect().has_point(event.position):
            touch_finger = event.index
            touch_origin = event.position
            touch_cancelled = false
            set_pressed_no_signal(true)
            get_viewport().set_input_as_handled()
        elif not event.pressed and event.index == touch_finger:
            var trigger := not touch_cancelled and get_global_rect().has_point(event.position)
            touch_finger = -1
            set_pressed_no_signal(false)
            get_viewport().set_input_as_handled()
            if trigger:
                pressed.emit()
    elif event is InputEventScreenDrag and event.index == touch_finger:
        if event.position.distance_to(touch_origin) > 18:
            touch_cancelled = true
            set_pressed_no_signal(false)
