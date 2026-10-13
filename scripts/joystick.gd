extends Control
class_name SurvivorJoystick

var value := Vector2.ZERO
var finger := -1
var active := false
const RADIUS := 88.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(220, 220)

func reset() -> void:
    finger = -1
    value = Vector2.ZERO
    queue_redraw()

func _input(event: InputEvent) -> void:
    if not active or not is_visible_in_tree():
        reset()
        return
    if event is InputEventScreenTouch:
        if event.pressed and finger < 0 and get_global_rect().has_point(event.position):
            finger = event.index
            _update_value(event.position)
            get_viewport().set_input_as_handled()
        elif not event.pressed and event.index == finger:
            reset()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == finger:
        _update_value(event.position)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and get_global_rect().has_point(event.position):
            finger = -2
            _update_value(event.position)
        elif not event.pressed and finger == -2:
            reset()
    elif event is InputEventMouseMotion and finger == -2:
        _update_value(event.position)

func _update_value(pos: Vector2) -> void:
    var center := global_position + size * 0.5
    value = ((pos - center) / RADIUS).limit_length(1.0)
    if value.length() < 0.12:
        value = Vector2.ZERO
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, RADIUS, Color(0.03, 0.1, 0.13, 0.38))
    draw_arc(center, RADIUS, 0, TAU, 64, Color(0.76, 0.87, 0.8, 0.58), 2, true)
    draw_circle(center + value * RADIUS * 0.63, 32, Color(0.73, 0.82, 0.65, 0.72))
