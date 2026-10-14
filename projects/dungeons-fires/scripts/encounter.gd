class_name DFEncounter
extends RefCounted

var game
var elapsed: float = 0
var hazard_cycle: int = -1
var treasure_claimed: bool = false

func _init(owner_game) -> void:game=owner_game

func reset() -> void:
	elapsed=0;hazard_cycle=-1;treasure_claimed=false

func room_data() -> Dictionary:
	if game.room>=4:return {}
	return game.db.encounters[game.dungeon].rooms[game.room]

func tick(delta: float) -> void:
	elapsed+=delta
	var profile=room_data()
	if profile.is_empty() or not profile.hazard or game.cleared_room:return
	var cycle=int(elapsed/7)
	if cycle==hazard_cycle:return
	hazard_cycle=cycle
	var region=int(game.db.dungeons[game.dungeon].region)
	var x=430+((game.dungeon*117+game.room*89+cycle*151)%620)
	var y=447+cycle%2*62
	var type=["debris","tide","frost","molten","white"][region]
	var radius=[62,100,85,70,105][region]
	game.skills.zone(Vector2(x,y),radius,12+region*3,1.0,type,true,1.2)

func warn_boss(a: DFActor) -> void:
	a.attack_sequence+=1
	if a.pattern in ["roots","frost","molten","crystal"]:
		var type="frost" if a.pattern in ["frost","crystal"] else "molten"
		game.skills.zone(a.aim,75,a.attack_power*.85,.75,type,true,1.0)
		if a.hp<a.max_hp*.5:game.skills.zone(a.aim+Vector2(125*a.facing,0),65,a.attack_power*.65,.65,type,true,1.0)

func cast_boss(a: DFActor) -> bool:
	if not a.boss:return false
	if a.pattern in ["charge","rush"]:
		game.world.fx(a.position-Vector2(0,35),90,Color("eda457"),.4)
		if game.player.position.distance_to(a.position)<160:game.player.hurt(a.attack_power*(.75 if a.weakened>0 else 1))
		return true
	if a.pattern in ["echo","white","hook"]:
		var vel=(a.aim-a.position).normalized()*330
		var spread=[-.16,0,.16] if a.hp<a.max_hp*.5 or a.pattern=="white" else [0]
		for angle in spread:game.world.missile(a.position,vel.rotated(angle),a.attack_power,false,Color("c9ddeb") if a.pattern=="white" else Color("ef8268"))
		return true
	if a.pattern=="mirrors" and a.attack_sequence%3==0:
		var helpers=game.enemies.filter(func(e):return e.hp>0 and not e.boss)
		if helpers.size()<2:
			game.spawn_actor("archer",Vector2(clampf(a.position.x-150,160,1130),465),false,55+game.dungeon*5,a.attack_power*.5)
	if a.pattern in ["sweep","chain","shield"]:
		var radius=135 if a.hp<a.max_hp*.5 else 105
		game.world.fx(a.position,radius,Color("e8a557"),.45)
		if game.player.position.distance_to(a.position)<radius:game.player.hurt(a.attack_power*(.75 if a.weakened>0 else 1))
		return true
	return false

func treasure() -> bool:
	if treasure_claimed or not game.cleared_room or game.room!=2:return false
	treasure_claimed=true
	game.loot.gold+=25+game.dungeon*4;game.loot.ore+=3
	var id="A_head_%d"%mini(game.dungeon,11)
	game.loot.items.append(id)
	game.save_run()
	game.toast("Baú aberto: equipamento e materiais no saque pendente.",4)
	return true

func snapshot() -> Dictionary:
	return {"elapsed":elapsed,"hazard_cycle":hazard_cycle,"treasure_claimed":treasure_claimed}

func restore(value: Dictionary) -> void:
	elapsed=float(value.get("elapsed",0));hazard_cycle=int(value.get("hazard_cycle",-1));treasure_claimed=value.get("treasure_claimed",false)
