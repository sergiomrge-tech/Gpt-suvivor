class_name DFActor
extends Node2D

var game
var kind: String = "varek"
var is_player: bool = false
var boss: bool = false
var hp: float = 100
var max_hp: float = 100
var attack_power: float = 10
var defense: float = 0
var state: String = "idle"
var timer: float = 0
var duration: float = 0
var phase: float = 0
var facing: int = 1
var cooldown: float = 0
var invuln: float = 0
var dodge_cd: float = 0
var skill_cd: Array = [0.0,0.0]
var supreme: float = 0
var mana: float = 100
var slowed: float = 0
var anim_clock: float = 0
var swing_done: bool = false
var attack_kind: String = "basic"
var combo: int = 0
var direction: Vector2 = Vector2.RIGHT
var aim: Vector2 = Vector2.ZERO
var id: int = 0
var pending_attack: bool = false
var atlas: Texture2D
var size_scale: float = 1.65
var shield: float = 0
var shield_time: float = 0
var buff_attack: float = 0
var recent_dodge: float = 0
var weakened: float = 0
var mark_time: float = 0
var mark_power: float = 0
var hunted: float = 0
var passive: bool = false
var pattern: String = ""
var attack_sequence: int = 0
var queued_skill: int = -1
var gait_clock: float = 0

func setup(owner_game, actor_kind: String, player: bool, life: float, damage: float, boss_actor: bool = false) -> void:
	game = owner_game; kind = actor_kind; is_player = player; boss = boss_actor
	hp = life; max_hp = life; attack_power = damage
	atlas = load("res://assets/%s.png" % kind)
	size_scale = 2.25 if boss else (1.65 if is_player else 1.5)
	cooldown = .6+float(id%4)*.35

func start_action(name: String, action_type: String, seconds: float) -> void:
	state = name; attack_kind = action_type; duration = seconds; timer = seconds; swing_done = false

func request_attack() -> void:
	if hp<=0: return
	if state in ["idle","run"]:
		combo = (combo+1)%3
		var seconds=.40 if combo<2 else .54
		var family=game.db.item(game.progress.d.equipped.weapon).get("family","")
		if family=="hammer":seconds*=1.4
		elif family=="daggers":seconds*=.8
		start_action("attack","basic",seconds)
		game.play_sfx("swing")
	elif state=="attack" and timer < .2:
		pending_attack = true

func request_dodge() -> void:
	if hp<=0 or dodge_cd>0 or not state in ["idle","run","attack"]: return
	start_action("dodge","dodge",.28)
	invuln = .20; dodge_cd = .85
	dodge_cd*=1-game.progress.talent_bonuses().dodge
	direction = game.move_axis if game.move_axis.length()>.1 else Vector2(facing,0)
	direction = direction.normalized()
	pending_attack = false;queued_skill=-1

func request_skill(slot: int) -> void:
	if hp<=0 or slot<0 or slot>1 or skill_cd[slot]>0:return
	if not state in ["idle","run"]:
		if state=="attack" and timer<.18:queued_skill=slot
		return
	var def=game.progress.active_skill(slot)
	if def.is_empty():game.toast("Escolha uma habilidade liberada no hub.");return
	if def.mode=="riposte" and recent_dodge<=0:game.toast("Esquive de um golpe para liberar o contra-ataque.");return
	if kind=="maela" and mana<float(def.mana):
		game.toast("Mana insuficiente; ela recupera com o tempo.")
		return
	if kind=="maela": mana-=float(def.mana)
	skill_cd[slot] = float(def.cooldown)*(1-game.progress.talent_bonuses().cooldown)
	pending_attack=false;queued_skill=-1
	start_action("cast",def.id,.62)
	game.play_sfx("magic")

func request_supreme() -> void:
	if supreme<100 or hp<=0 or not state in ["idle","run"]: return
	supreme = 0
	start_action("cast","supreme",.85)
	invuln = .65
	game.play_sfx("magic")

func tick(delta: float) -> void:
	anim_clock += delta
	cooldown = maxf(0,cooldown-delta)
	invuln = maxf(0,invuln-delta)
	dodge_cd = maxf(0,dodge_cd-delta)
	slowed = maxf(0,slowed-delta)
	shield_time=maxf(0,shield_time-delta)
	if shield_time<=0:shield=0
	buff_attack=maxf(0,buff_attack-delta);recent_dodge=maxf(0,recent_dodge-delta)
	weakened=maxf(0,weakened-delta);mark_time=maxf(0,mark_time-delta);hunted=maxf(0,hunted-delta)
	for i in range(2): skill_cd[i] = maxf(0,skill_cd[i]-delta)
	mana = minf(100,mana+delta*9*(1+game.progress.talent_bonuses().mana if is_player else 1))
	if state=="death":
		timer = maxf(0,timer-delta); queue_redraw(); return
	if state in ["attack","cast","dodge","hurt","windup"]:
		timer -= delta
		if state=="dodge": position += direction*530*delta
		if boss and state=="attack" and pattern in ["charge","rush"] and timer>duration*.4:
			position.x+=facing*380*delta
		if state=="windup" and timer<=0:
			start_action("attack","enemy",.55 if not boss else .85)
		elif state in ["attack","cast"] and not swing_done and timer<duration*.55:
			swing_done = true
			if is_player: game.player_strike(self,attack_kind)
			else: game.enemy_strike(self)
		if timer<=0:
			state = "idle"
			if is_player and queued_skill>=0:
				var slot=queued_skill;queued_skill=-1;request_skill(slot)
			elif is_player and pending_attack:
				pending_attack = false; request_attack()
	else:
		if is_player: tick_player(delta)
		else: tick_enemy(delta)
	position.x = clampf(position.x,70,1210)
	position.y = clampf(position.y,410,557)
	z_index = int(position.y)
	queue_redraw()

func tick_player(delta: float) -> void:
	var axis: Vector2 = game.move_axis
	state = "run" if axis.length()>.1 else "idle"
	if axis.length()>.1:
		if absf(axis.x)>.1: facing = 1 if axis.x>0 else -1
		var speed=250*(1+game.progress.talent_bonuses().movement)*(.55 if slowed>0 else 1.0)
		gait_clock+=delta*axis.length()*speed/250
		position += Vector2(axis.x,axis.y*.70)*speed*delta
		if int(anim_clock*7)%4==0 and game.step_timer<=0:
			game.step_timer=.23; game.play_sfx("step")
	if game.attack_held: request_attack()

func tick_enemy(delta: float) -> void:
	if passive:return
	if game.player==null or game.player.hp<=0: return
	var target_pos: Vector2=game.player.position
	if not boss and not game.skills.decoy.is_empty():target_pos=Vector2(game.skills.decoy.x,game.skills.decoy.y)
	var diff: Vector2 = target_pos-position
	facing = 1 if diff.x>=0 else -1
	var ranged = kind in ["archer","sereia","severan"]
	var reach = 115.0 if boss else 77.0
	if ranged: reach = 370
	if absf(diff.x)<reach and absf(diff.y)<45 and cooldown<=0 and game.windup_count()<3:
		aim = target_pos
		start_action("windup","enemy",.70 if not boss else 1.0)
		if boss:game.encounter.warn_boss(self)
		cooldown = (1.5 if not boss else 1.7)+float(id%3)*.15
	else:
		var target = diff
		if ranged and absf(diff.x)<180: target.x = -diff.x
		if absf(diff.x)<reach and absf(diff.y)<28: target = Vector2.ZERO
		state = "run" if target.length()>5 else "idle"
		if target.length()>5:
			var speed = (65.0 if boss else 94.0) * (.55 if slowed>0 else 1.0)
			position += Vector2(target.normalized().x,target.normalized().y*.8)*speed*delta

func hurt(amount: float, push: Vector2 = Vector2.ZERO) -> bool:
	if hp<=0:return false
	if invuln>0:
		if is_player and game.relic_effect()=="guard":game.guard_charge=3.0
		if is_player and state=="dodge":recent_dodge=2.0
		return false
	if not is_player:
		if mark_time>0:amount+=mark_power;mark_time=0;mark_power=0
		if hunted>0:amount*=1.2
	var received = maxf(1,amount*100/(100+defense))
	if is_player and game.relic_effect()=="resist":received*=.9
	if is_player and game.progress.d.settings.story_mode: received *= .6
	if is_player and shield>0:
		var absorbed=minf(shield,received);shield-=absorbed;received-=absorbed
	if passive:
		game.training_damage+=received
		hp=max_hp
		game.damage_text(position-Vector2(0,100),int(received),false)
		return true
	hp = maxf(0,hp-received)
	game.damage_text(position-Vector2(0,100),int(received),is_player)
	game.play_sfx("impact")
	position += push
	if hp<=0:
		start_action("death","death",.7)
		if not is_player: game.on_enemy_dead(self)
		else: game.on_player_dead()
	else:
		if not boss:
			start_action("hurt","hurt",.19); invuln=.12
		else:
			phase += received*(1+game.progress.talent_bonuses().rupture)
			if phase>max_hp*.20:
				phase=0; start_action("hurt","hurt",.65)
		if is_player: invuln=.4; game.shake_timer=.13
	return true

func snapshot() -> Dictionary:
	var out={"id":id,"kind":kind,"boss":boss,"hp":hp,"max_hp":max_hp,"attack":attack_power,"x":position.x,"y":position.y,"facing":facing,"aimx":aim.x,"aimy":aim.y,"dx":direction.x,"dy":direction.y}
	for key in ["state","timer","duration","swing_done","attack_kind","combo","cooldown","invuln","dodge_cd","supreme","mana","slowed","shield","shield_time","buff_attack","recent_dodge","weakened","mark_time","mark_power","hunted","pattern","attack_sequence","phase","anim_clock","gait_clock"]:out[key]=get(key)
	out.skill_cd=skill_cd.duplicate()
	return out

func restore(value: Dictionary) -> void:
	for key in ["state","timer","duration","swing_done","attack_kind","combo","cooldown","invuln","dodge_cd","supreme","mana","slowed","shield","shield_time","buff_attack","recent_dodge","weakened","mark_time","mark_power","hunted","pattern","attack_sequence","phase","anim_clock","gait_clock"]:
		if value.has(key):set(key,value[key])
	if value.has("skill_cd"):skill_cd=value.skill_cd.duplicate()
	aim=Vector2(value.get("aimx",position.x),value.get("aimy",position.y));direction=Vector2(value.get("dx",facing),value.get("dy",0))
	queued_skill=-1;pending_attack=false

func _draw() -> void:
	if atlas==null: return
	var fade = clampf(timer/.7,0,1) if state=="death" else 1.0
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.30))
	draw_circle(Vector2.ZERO,23*size_scale,Color(0,0,0,.30*fade))
	draw_set_transform(Vector2.ZERO)
	if state=="windup":
		var warn = Color(1,.36,.17,.45+sin(anim_clock*14)*.15)
		draw_arc(Vector2.ZERO,60 if boss else 43,0,TAU,32,warn,4)
		draw_line(Vector2.ZERO,(aim-position).normalized()*95,warn,4)
	var row = {"idle":0,"run":1,"attack":2,"dodge":3,"hurt":4,"death":5,"cast":6,"windup":2}.get(state,0)
	var frame = int(anim_clock*(13 if state=="run" else 8))%8
	if state=="run" and is_player:frame=int(gait_clock*26)%8
	if state in ["attack","cast","dodge","hurt","death"]: frame = clampi(int((1-timer/maxf(duration,.01))*8),0,7)
	if state=="windup": frame=0
	var tint = Color.WHITE
	if invuln>0 and state=="hurt": tint=Color(1,.6,.55)
	draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	draw_texture_rect_region(atlas,Rect2(-48*size_scale,-84*size_scale,96*size_scale,96*size_scale),Rect2(frame*96,row*96,96,96),tint)
	draw_set_transform(Vector2.ZERO)
	if shield>0:draw_arc(Vector2(0,-55),52,0,TAU,30,Color(.5,.85,1,.5),3)
	if mark_time>0 or hunted>0:draw_circle(Vector2(0,-100),6,Color("cda7e8"))
	if not is_player and hp>0:
		var w = 85 if boss else 54
		draw_rect(Rect2(-w/2.0,-94*size_scale,w,6),Color(.12,.10,.15,.9))
		draw_rect(Rect2(-w/2.0,-94*size_scale,w*hp/max_hp,6),Color(.86,.27,.22))
