extends SceneTree

var checks: int = 0
var failures: Array = []

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:failures.append(message);push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var db=DFContent.new()
	check(db.dungeons.size()==15,"15 dungeons")
	check(db.items.size()==120,"120 items")
	var p=DFProgress.new(db,"user://unit_save.json")
	check(p.valid(p.d),"fresh save valid")
	check(p.save(),"atomic initial save")
	var q=DFProgress.new(db,"user://unit_save.json")
	check(q.load_save() and q.d.gold==160,"roundtrip")
	check(not p.equip("W_bow_0"),"cross hero weapon rejected")
	var gold=p.d.gold
	check(p.upgrade("W_sword_0"),"upgrade succeeds")
	check(p.d.gold==gold-40 and p.d.upgrades.W_sword_0==1,"upgrade exact cost")
	check(not p.upgrade_hub("forge"),"hub gate enforced")
	p.d.gold=20000;p.d.ore=20000
	check(p.buy_item("W_hammer_0"),"craft compatible")
	var after=p.d.gold
	check(not p.buy_item("W_hammer_0") and p.d.gold==after,"duplicate purchase rejected")
	for i in range(3):
		var result=p.complete(i,{"gold":0,"ore":0,"xp":50})
		check(result.first,"first clear granted")
	check(p.unlocked()==3,"graph advances sequentially")
	check(p.d.cores.CORE_0==1,"guardian material granted")
	check(p.upgrade_hub("forge"),"hub upgrade after guardian")
	check(p.buy_item("R_0"),"boss relic recipe")
	check(p.d.cores.CORE_0==0,"unique material consumed")
	var ash=p.d.ash
	check(not p.complete(2,{}).first and p.d.ash==ash,"first reward idempotent")
	check(p.switch_hero("maela"),"hero unlock")
	check(p.d.equipped.weapon=="W_staff_0","hero weapon consistency")
	check(not p.switch_hero("neris"),"later hero locked")
	var corrupt=p.d.duplicate(true);corrupt.gold=-1
	check(not p.valid(corrupt),"negative balance rejected")
	corrupt=p.d.duplicate(true);corrupt.inventory.append("DOES_NOT_EXIST")
	check(not p.valid(corrupt),"broken item rejected")
	p.save();p.save()
	var f=FileAccess.open(p.path,FileAccess.WRITE);f.store_string("broken");f.close()
	var recovery=DFProgress.new(db,p.path)
	check(recovery.load_save(),"backup recovered")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.progress=DFProgress.new(db,"user://integration_save.json")
	scene.progress.d.settings.sound=false
	check(scene.screen=="menu","menu starts")
	scene.show_hub();check(scene.screen=="hub" and scene.player!=null,"hub enters")
	scene.show_map(0);check(scene.screen=="map","map opens")
	scene.show_preparation(0);check(scene.screen=="prepare","loadout opens")
	scene.start_dungeon(0)
	check(scene.enemies.size()==3 and scene.controls.active,"first encounter loads")
	var enemy=scene.enemies[0]
	scene.player.position=enemy.position-Vector2(48,0);scene.player.facing=1
	var life=enemy.hp
	scene.player.request_attack()
	for tick in range(32):scene._physics_process(1.0/60)
	check(enemy.hp<life,"animated basic attack deals damage")
	scene.player.request_dodge();check(scene.player.invuln>0,"dodge grants window")
	var h=scene.player.hp
	check(not scene.player.hurt(20) and scene.player.hp==h,"invulnerability blocks hit")
	scene.player.state="idle";scene.player.skill_cd=[0.0,0.0];scene.player.request_skill(0)
	check(scene.player.state=="cast" and scene.player.skill_cd[0]>0,"skill state and cooldown")
	scene.player.hp=scene.player.max_hp*.5
	var charges=scene.potions;scene.use_potion()
	check(scene.potions==charges-1 and scene.player.hp>scene.player.max_hp*.5,"limited healing")
	scene.save_run()
	var saved_hp=scene.player.hp
	scene.show_pause();check(scene.screen=="pause" and not scene.controls.active,"pause suppresses input")
	scene.resume_run();check(absf(scene.player.hp-saved_hp)<.01,"resume preserves hp")
	scene.show_pause();scene.back();check(scene.screen=="combat","pause closes")
	scene.controls.press(0,Vector2(180,601));scene.controls.press(1,Vector2(1130,611))
	check(scene.controls.stick_id==0 and scene.attack_held,"multitouch movement and attack")
	scene.controls.release(1);check(not scene.attack_held,"attack release")
	scene.controls.clear();check(scene.controls.axis==Vector2.ZERO,"controls reset")
	# Resolve each complete expedition through the actual death/reward/room loop.
	for index in range(15):
		scene.start_dungeon(index)
		for stage in range(5):
			for a in scene.enemies.duplicate():
				a.invuln=0;a.hurt(1000000)
			scene._physics_process(.017)
			if stage<4:
				check(scene.cleared_room,"room clears %d/%d"%[index,stage])
				scene.next_room()
		check(scene.screen=="result" and scene.progress.d.cleared.has(index),"victory %d"%index)
		check(scene.progress.d.run.is_empty(),"reward commits and clears snapshot %d"%index)
		await process_frame
	check(scene.progress.d.cleared.size()==15,"complete campaign graph")
	check(scene.progress.switch_hero("maela"),"mage playable")
	scene.start_dungeon(0);scene.player.state="idle";scene.player_strike(scene.player,"basic")
	check(scene.world.projectiles.size()>0,"mage projectile")
	scene.progress.d.run={};check(scene.progress.switch_hero("neris"),"ranger playable")
	scene.start_dungeon(0);scene.player_strike(scene.player,"basic")
	check(scene.world.projectiles.size()>0,"bow projectile")
	scene.player.invuln=0;scene.player.hurt(1000000)
	check(scene.hero_dead and scene.progress.d.run.is_empty(),"death invalidates snapshot")
	scene._physics_process(1)
	check(scene.screen=="failed","defeat flow")
	var report={"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"campaign":15,"rooms":75}
	var output=FileAccess.open("user://test_report.json",FileAccess.WRITE);output.store_string(JSON.stringify(report));output.close()
	print(JSON.stringify(report))
	scene.queue_free();await process_frame
	call_deferred("quit",0 if failures.is_empty() else 1)
