class_name DFSkills
extends RefCounted

var game
var zones: Array = []
var decoy: Dictionary = {}

func _init(owner_game) -> void:game=owner_game

func reset() -> void:
	zones.clear();decoy={}

func nearest(a: DFActor, reach: float = 520) -> DFActor:
	var target: DFActor=null
	var distance=reach
	for e in game.enemies:
		if e.hp>0 and e.position.distance_to(a.position)<distance:
			target=e;distance=e.position.distance_to(a.position)
	return target

func power(a: DFActor, factor: float) -> float:
	var bonuses=game.progress.talent_bonuses()
	var amount=a.attack_power*factor*(1+bonuses.skill)
	if game.rng.randf()<bonuses.crit:amount*=1.5
	return amount

func hit_area(a: DFActor, point: Vector2, damage: float, reach: float, depth: float = 85, front: bool = false) -> void:
	for e in game.enemies.duplicate():
		var diff: Vector2=e.position-point
		if e.hp>0 and absf(diff.x)<reach and absf(diff.y)<depth and (not front or diff.x*a.facing>=-20):
			if e.hurt(damage,Vector2(a.facing*10,0)):
				a.supreme=minf(100,a.supreme+6*(1+game.progress.talent_bonuses().supreme))

func zone(point: Vector2, radius: float, damage: float, duration: float, type: String, hostile: bool = false, warning: float = 0) -> void:
	if zones.size()>=24:return
	zones.append({"x":point.x,"y":point.y,"radius":radius,"damage":damage,"time":duration+warning,"pulse":.0,"type":type,"hostile":hostile,"warning":warning,"triggered":false})

func execute(a: DFActor, id: String) -> void:
	var def=game.db.skill(id)
	if def.is_empty():return
	var target=nearest(a)
	var point=a.position+Vector2(a.facing*135,0) if target==null else target.position
	var damage=power(a,float(def.power))
	var bonuses=game.progress.talent_bonuses()
	match def.mode:
		"dash":
			var origin=a.position
			a.position.x=clampf(a.position.x+a.facing*110,70,1210)
			hit_area(a,(origin+a.position)*.5,damage,160,65,true)
			game.world.fx(a.position-Vector2(0,35),80,Color("ffd17e"))
		"guard","shield":
			a.shield=maxf(a.shield,a.max_hp*(.22 if def.mode=="guard" else .35)*(1+bonuses.barrier));a.shield_time=6
			if def.mode=="guard":a.buff_attack=4.0
			game.world.fx(a.position-Vector2(0,45),66,Color("91d5df"),.7)
		"line","pierce","bolt":
			var vel=Vector2(a.facing,0)*620
			if target!=null:vel=(target.position-a.position).normalized()*620
			game.world.missile(a.position,vel,damage,true,Color("edc279") if a.kind!="maela" else Color("ff8b51"),def.mode!="bolt")
		"weaken":
			for e in game.enemies:
				if e.hp>0 and e.position.distance_to(a.position)<250:e.weakened=5
			hit_area(a,a.position,damage,250,140)
			game.world.fx(a.position,160,Color("be8dd9"),.6)
		"riposte":
			a.invuln=maxf(a.invuln,.3);a.recent_dodge=0
			hit_area(a,a.position,damage,225,100)
			game.world.fx(a.position-Vector2(0,50),130,Color("fff0bd"),.5)
		"ward":
			a.shield=maxf(a.shield,a.max_hp*.25*(1+bonuses.barrier));a.shield_time=6
			zone(a.position,150,damage*.35,4,"ward")
		"burn","channel","rain":
			zone(point,130 if def.mode!="channel" else 170,damage,4 if def.mode!="channel" else 3,"fire" if a.kind=="maela" else "rain",false,.35)
		"mark":
			if target!=null:
				if target.mark_time>0:target.hurt(0)
				else:target.mark_power=damage;target.mark_time=6;game.world.fx(target.position-Vector2(0,35),40,Color("e78aef"),.6)
		"chain":
			var targets=game.enemies.filter(func(e):return e.hp>0 and e.position.distance_to(a.position)<520)
			targets.sort_custom(func(x,y):return x.position.distance_to(a.position)<y.position.distance_to(a.position))
			for i in range(mini(3,targets.size())):
				targets[i].hurt(damage*pow(.75,i));game.world.fx(targets[i].position-Vector2(0,40),55,Color("dfbdff"))
		"hunt":
			if target!=null:target.hunted=5;target.hurt(damage);game.world.fx(target.position-Vector2(0,45),45,Color("e4c783"))
		"trap":zone(a.position+Vector2(a.facing*90,0),100,damage,8,"trap",false,.6)
		"decoy":
			decoy={"x":a.position.x,"y":a.position.y,"time":2.5}
			a.position.x=clampf(a.position.x-a.facing*145,70,1210);a.invuln=.28
			game.world.fx(a.position-Vector2(0,45),55,Color("9ccaab"))

func supreme(a: DFActor) -> void:
	if a.kind=="maela":
		zone(a.position+Vector2(a.facing*110,0),240,power(a,1.2),3.5,"fire")
		hit_area(a,a.position,power(a,2),300,180)
	elif a.kind=="neris":
		for angle in [-.16,-.08,0,.08,.16]:
			game.world.missile(a.position,Vector2(a.facing,0).rotated(angle)*650,power(a,2),true,Color("fcdfa2"),true)
	else:
		hit_area(a,a.position,power(a,4),390,180)
		game.world.fx(a.position,220,Color("fff0be"),.7)

func tick(delta: float) -> void:
	if not decoy.is_empty():
		decoy.time-=delta
		if decoy.time<=0:decoy={}
	for z in zones:
		z.time-=delta
		if z.warning>0:z.warning-=delta;continue
		z.pulse-=delta
		if z.pulse>0:continue
		z.pulse=.6
		var point=Vector2(z.x,z.y)
		if z.hostile:
			if not z.triggered and game.player.position.distance_to(point)<z.radius:
				game.player.hurt(z.damage);z.triggered=true
				if z.type=="frost":game.player.slowed=1.4
		else:
			for e in game.enemies.duplicate():
				if e.hp<=0 or e.position.distance_to(point)>z.radius:continue
				if z.type=="trap" and z.triggered:break
				e.hurt(z.damage)
				if z.type in ["trap","ward"]:e.slowed=2
				if z.type=="trap":z.triggered=true;z.time=.25
	zones=zones.filter(func(z):return z.time>0)

func draw(target: Node2D) -> void:
	for z in zones:
		var color=Color("ed684b") if z.hostile else Color("e7a548")
		if z.type in ["ward","frost"]:color=Color("8ecbda")
		if z.warning>0:color.a=.6
		else:color.a=.8
		var center=Vector2(z.x,z.y)
		target.draw_arc(center,z.radius,0,TAU,40,color,3)
		color.a=.10 if z.warning>0 else .20
		target.draw_circle(center,z.radius,color)
	if not decoy.is_empty():target.draw_circle(Vector2(decoy.x,decoy.y)-Vector2(0,55),32,Color(.7,.9,.8,.4))

func snapshot() -> Dictionary:
	return {"zones":zones.duplicate(true),"decoy":decoy.duplicate(true)}

func restore(value: Dictionary) -> void:
	zones=value.get("zones",[]).duplicate(true);decoy=value.get("decoy",{}).duplicate(true)
