extends Control
class_name SurvivorJoystick

signal direction_changed(direction: Vector2)

var direction := Vector2.ZERO
var active_pointer := -999
const RADIUS = 84.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    custom_minimum_size = Vector2(236, 236)

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, RADIUS + 9.0, Color(0.05, 0.09, 0.10, 0.37))
    draw_arc(center, RADIUS, 0.0, TAU, 56, Color(0.94, 0.89, 0.68, 0.55), 3.0, true)
    draw_circle(center + direction * RADIUS, 37.0, Color(0.95, 0.90, 0.69, 0.72))

func _update_direction(pos: Vector2) -> void:
    direction = ((pos - size * 0.5) / RADIUS).limit_length(1.0)
    direction_changed.emit(direction)
    queue_redraw()

func _release() -> void:
    direction = Vector2.ZERO
    active_pointer = -999
    direction_changed.emit(direction)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and active_pointer == -999:
            active_pointer = touch.index
            _update_direction(touch.position)
            accept_event()
        elif not touch.pressed and touch.index == active_pointer:
            _release()
            accept_event()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == active_pointer:
            _update_direction(drag.position)
            accept_event()
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                active_pointer = -1
                _update_direction(mouse.position)
            elif active_pointer == -1:
                _release()
            accept_event()
    elif event is InputEventMouseMotion and active_pointer == -1:
        var motion := event as InputEventMouseMotion
        _update_direction(motion.position)
        accept_event()
