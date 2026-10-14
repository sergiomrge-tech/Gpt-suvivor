class_name DFTouch
extends Control

signal action(name: String, held: bool)
var axis: Vector2 = Vector2.ZERO
var active: bool = false
var stick_id: int = -1
var stick_center: Vector2 = Vector2(180,601)
var thumb: Vector2 = Vector2.ZERO
var touches: Dictionary = {}
var mouse_down: bool = false
var font: Font
var buttons: Dictionary = {"attack":Vector2(1130,611),"dodge":Vector2(987,625),"skill0":Vector2(1050,504),"skill1":Vector2(1180,493),"supreme":Vector2(893,513),"potion":Vector2(398,628)}
var cooldowns: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = load("res://assets/DejaVuSans.ttf")

func clear() -> void:
	stick_id=-1; axis=Vector2.ZERO; thumb=Vector2.ZERO; touches.clear(); mouse_down=false
	action.emit("attack",false)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventScreenTouch:
		if event.pressed: press(event.index,event.position)
		else: release(event.index)
	elif event is InputEventScreenDrag:
		if event.index==stick_id: move_stick(event.position)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_down=event.pressed
		if mouse_down: press(-2,event.position)
		else: release(-2)
	elif event is InputEventMouseMotion and mouse_down:
		if stick_id==-2: move_stick(event.position)
	queue_redraw()

func press(id: int, pos: Vector2) -> void:
	if pos.distance_to(stick_center)<115 and stick_id==-1:
		stick_id=id; move_stick(pos); return
	for name in buttons:
		var radius = 65 if name=="attack" else 49
		if pos.distance_to(buttons[name])<radius:
			touches[id]=name; action.emit(name,true); return

func release(id: int) -> void:
	if id==stick_id: stick_id=-1; axis=Vector2.ZERO; thumb=Vector2.ZERO
	if touches.has(id):
		var name = touches[id]; touches.erase(id)
		if not touches.values().has(name): action.emit(name,false)

func move_stick(pos: Vector2) -> void:
	thumb = (pos-stick_center).limit_length(70)
	axis = thumb/70
	if axis.length()<.16: axis=Vector2.ZERO

func _draw() -> void:
	if not active or font==null: return
	draw_circle(stick_center,85,Color(.08,.09,.13,.60))
	draw_arc(stick_center,85,0,TAU,50,Color(.74,.57,.32,.6),3)
	draw_circle(stick_center+thumb,34,Color(.50,.53,.58,.75))
	draw_arc(stick_center+thumb,34,0,TAU,32,Color(.85,.77,.55,.9),2)
	var labels = {"attack":"GOLPE","dodge":"ESQUIVA","skill0":"TÉCNICA","skill1":"PODER","supreme":"BRASA","potion":"CURAR"}
	for name in buttons:
		var center: Vector2 = buttons[name]
		var r = 61 if name=="attack" else 45
		var held = touches.values().has(name)
		draw_circle(center,r,Color(.15,.14,.18,.83) if not held else Color(.39,.25,.17,.9))
		draw_arc(center,r,0,TAU,40,Color(.79,.61,.34,.95),3)
		var label: String = labels[name]
		var cd = float(cooldowns.get(name,0))
		if cd>0: label="%.1f" % cd
		var fs = 16 if name!="attack" else 20
		var tw = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		draw_string(font,center-Vector2(tw/2,-5),label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(.96,.87,.68))
		if name=="supreme":draw_arc(center,r-6,-PI/2,-PI/2+TAU*float(cooldowns.get("charge",0))/100,35,Color(.96,.46,.19),3)
