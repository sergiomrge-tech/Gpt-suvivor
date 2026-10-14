class_name DFWorld
extends Node2D

var game
var background: Texture2D
var theme_index: int = 5
var clock: float = 0
var numbers: Array = []
var effects: Array = []
var projectiles: Array = []
var font: Font
var overlay: Node2D

func _ready() -> void:
	font=load("res://assets/DejaVuSans.ttf")
	overlay=Node2D.new();overlay.z_index=1000;add_child(overlay)
	overlay.draw.connect(draw_effects)

func change_theme(index: int) -> void:
	theme_index=index
	background=load("res://assets/world_%d.png" % index)
	queue_redraw()
	if overlay!=null:overlay.queue_redraw()

func tick(delta: float) -> void:
	clock+=delta
	for n in numbers: n.time-=delta; n.pos.y-=delta*35
	numbers=numbers.filter(func(n):return n.time>0)
	for e in effects:e.time-=delta
	effects=effects.filter(func(e):return e.time>0)
	for p in projectiles:
		p.time-=delta; p.pos+=p.velocity*delta
		if p.player:
			for target in game.enemies:
				if target.hp>0 and absf(target.position.y-p.pos.y)<24 and absf(target.position.x-p.pos.x)<30 and not p.hit.has(target.id):
					p.hit.append(target.id)
					if target.hurt(p.damage,Vector2(signf(p.velocity.x)*8,0)):
						game.player.supreme=minf(100,game.player.supreme+4)
					if not p.piercing:p.time=0;break
		else:
			if game.player!=null and game.player.hp>0 and game.player.position.distance_to(p.pos)<30:
				game.player.hurt(p.damage);p.time=0
	projectiles=projectiles.filter(func(p):return p.time>0 and p.pos.x>-100 and p.pos.x<1380)
	queue_redraw()
	overlay.queue_redraw()

func missile(pos: Vector2, velocity: Vector2, damage: float, player: bool, color: Color, piercing: bool = false) -> void:
	projectiles.append({"pos":pos,"velocity":velocity,"damage":damage,"player":player,"time":3.0,"color":color,"hit":[],"piercing":piercing})

func fx(pos: Vector2, radius: float, color: Color, seconds: float = .4) -> void:
	effects.append({"pos":pos,"radius":radius,"color":color,"time":seconds,"duration":seconds})

func _draw() -> void:
	if background!=null: draw_texture_rect(background,Rect2(0,0,1280,720),false)
	# Animated fire embers and localized torch halos.
	for i in range(17):
		var x = fmod(i*91.7+clock*(7+i%4),1280)
		var y = 400-fmod(clock*18+i*29,230)
		draw_circle(Vector2(x,y),1.5,Color(.98,.61,.28,.4))
	if theme_index==5:
		var level = int(game.progress.d.hub.forge)
		for i in range(level*3):
			draw_line(Vector2(260+i*12,370),Vector2(260+i*12,420),Color(.71,.53,.34,.7),3)
		for i in range(int(game.progress.d.hub.archive)):
			draw_rect(Rect2(890+i*15,355,10,45),Color(.49,.35,.26))
func draw_effects() -> void:
	for e in effects:
		var alpha = e.time/e.duration
		var color: Color = e.color; color.a*=alpha
		overlay.draw_arc(e.pos,e.radius*(1-alpha*.25),0,TAU,40,color,6)
		for i in range(9):
			var a = i*TAU/9+clock*3
			overlay.draw_circle(e.pos+Vector2(cos(a),sin(a)*.55)*e.radius*(1-alpha*.4),3,color)
	for p in projectiles:
		var facing = signf(p.velocity.x)
		var visual_pos: Vector2=p.pos-Vector2(0,65)
		overlay.draw_line(visual_pos-Vector2(facing*20,0),visual_pos+Vector2(facing*12,0),p.color,4)
		overlay.draw_circle(visual_pos,5,p.color)
	for n in numbers:
		var color = Color(1,.41,.32,n.time) if n.player else Color(1,.88,.58,n.time)
		overlay.draw_string(font,n.pos,str(n.value),HORIZONTAL_ALIGNMENT_LEFT,-1,23,color)
