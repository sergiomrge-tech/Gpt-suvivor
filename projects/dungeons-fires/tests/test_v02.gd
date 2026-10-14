extends SceneTree

var checks: int = 0
var failures: Array = []

func check(ok: bool, note: String) -> void:
	checks+=1
	if not ok:failures.append(note);push_error(note)

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var db=DFContent.new()
	check(db.skills.size()==18,"18 active skills")
	check(db.talents.size()==54,"54 talent nodes")
	var p=DFProgress.new(db,"user://v02_unit.json")
	var legacy=p.fresh();legacy.version=1;legacy.erase("claimed_quests");legacy.gold=713;legacy.cleared=[0,1,2]
	for hero in legacy.heroes:
		legacy.heroes[hero].erase("nodes");legacy.heroes[hero].erase("skills")
	legacy.heroes.varek.level=8;legacy.heroes.varek.talents=7
	var migrated=p.migrate(legacy)
	check(p.valid(migrated),"legacy migration valid")
	p.d=migrated
	check(p.d.gold==713 and p.d.cleared==[0,1,2],"legacy money and progress preserved")
	check(p.available_points()==7 and p.d.heroes.varek.nodes.is_empty(),"legacy talents refunded")
	check(p.active_skill(1).id=="S_varek_1","appropriate starting skills migrated")
	p.d.heroes.varek.level=30;p.d.hub.sanctuary=1
	check(not p.invest_talent("N_varek_0_1"),"branch prerequisite enforced")
	for i in range(3):check(p.invest_talent("N_varek_0_0"),"initial node rank %d"%i)
	check(not p.invest_talent("N_varek_0_0"),"rank cap enforced")
	for node in [1,2]:
		for i in range(3):check(p.invest_talent("N_varek_0_%d"%node),"branch rank")
	check(not p.invest_talent("N_varek_0_3"),"sanctuary gate enforced")
	p.d.hub.sanctuary=3
	for node in [3,4]:
		for i in range(3):check(p.invest_talent("N_varek_0_%d"%node),"advanced rank")
	check(p.invest_talent("N_varek_0_5"),"capstone works")
	check(p.d.heroes.varek.talents==16 and p.available_points()==13,"branch spends exact 16 points")
	check(p.talent_bonuses().hp==36 and p.talent_bonuses().defense>0,"bonuses affect distinct attributes")
	check(p.respec() and p.available_points()==29,"respec returns all points")
	check(p.equip_skill(0,"S_varek_3"),"high level skill equips")
	check(p.equip_skill(1,"S_varek_3") and p.active_skill(0).id!="S_varek_3","duplicate slot selection swaps")
	p.d.run={"pending":true}
	check(not p.equip_skill(0,"S_varek_0") and not p.respec(),"pending run locks build editing")
	p.d.run={}
	var gold=p.d.gold
	check(p.claim_quest("Q_0"),"completed quest claims")
	check(not p.claim_quest("Q_0") and p.d.gold==gold+80,"quest claim is idempotent")
	check(not p.claim_quest("Q_5"),"incomplete quest denied")
	var corrupt=p.d.duplicate(true);corrupt.heroes.varek.nodes.NOT_A_NODE=1
	check(not p.valid(corrupt),"unknown node invalid")
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	for hero in ["varek","maela","neris"]:
		for index in range(6):
			game.progress=DFProgress.new(db,"user://v02_skill_test.json")
			game.progress.d.hero=hero;game.progress.d.heroes[hero].level=30;game.progress.d.heroes[hero].skills=["S_%s_%d"%[hero,index],""]
			game.progress.d.equipped.weapon={"varek":"W_sword_0","maela":"W_staff_0","neris":"W_bow_0"}[hero]
			game.progress.d.settings.sound=false
			game.start_dungeon(0)
			game.player.position=Vector2(400,470);game.player.facing=1;game.player.recent_dodge=2
			for n in range(game.enemies.size()):
				game.enemies[n].position=Vector2(460+n*95,470);game.enemies[n].hp=10000;game.enemies[n].max_hp=10000;game.enemies[n].passive=false;game.enemies[n].cooldown=20
			game.player.request_skill(0)
			check(game.player.state=="cast" and game.player.skill_cd[0]>0,"cast accepted %s/%d"%[hero,index])
			for tick in range(42):game._physics_process(1.0/60)
			var mode=db.skill("S_%s_%d"%[hero,index]).mode
			match mode:
				"guard","shield":check(game.player.shield>0,"shield created")
				"weaken":check(game.enemies[0].weakened>0,"weakness applied")
				"mark":check(game.enemies[0].mark_time>0,"mark applied")
				"hunt":check(game.enemies[0].hunted>0,"hunt applied")
				"ward","burn","channel","rain","trap":check(not game.skills.zones.is_empty(),"persistent zone created")
				"decoy":check(not game.skills.decoy.is_empty(),"decoy created")
				_:check(game.enemies.any(func(e):return e.hp<10000),"skill hits a target %s/%d"%[hero,index])
			await process_frame
	# Mark is consumed once by the following real hit.
	var target=game.enemies[0];target.mark_time=4;target.mark_power=30;target.invuln=0;target.defense=0
	var old_hp=target.hp;target.hurt(10)
	check(target.hp==old_hp-40 and target.mark_time==0,"mark detonates once")
	game.skills.zone(Vector2(450,475),90,25,3,"fire",false,.8)
	game.player.shield=47;game.player.shield_time=5;game.player.skill_cd=[3.2,7.1]
	game.world.missile(Vector2(450,475),Vector2(620,0),18,true,Color.WHITE)
	game.save_run();var cds=game.player.skill_cd.duplicate();var projectile_count=game.world.projectiles.size()
	game.show_pause();game.resume_run()
	check(game.player.skill_cd==cds and game.player.shield==47,"cooldowns and shield survive resume")
	check(game.world.projectiles.size()==projectile_count and not game.skills.zones.is_empty(),"projectiles and zones survive resume")
	game.start_dungeon(1);game.room=1;game.spawn_room();game.combat_ui();game.encounter.tick(.1)
	check(game.skills.zones.any(func(z):return z.hostile and z.warning>0),"environment hazard has warning")
	game.room=2;game.cleared_room=true;game.encounter.reset()
	check(game.encounter.treasure(),"treasure opens after clearing")
	var ore=game.loot.ore
	check(not game.encounter.treasure() and game.loot.ore==ore,"treasure does not duplicate")
	game.progress.d.run={};game.show_hub();game.start_training()
	var before=game.progress.d.gold
	game.player.position=game.enemies[0].position-Vector2(65,0);game.player.facing=1
	game.player_strike(game.player,"basic")
	for tick in range(16):game._physics_process(1.0/60)
	check(game.training_damage>0 and game.enemies[0].hp==game.enemies[0].max_hp,"training target records damage")
	game.save_run();check(game.progress.d.run.is_empty() and game.progress.d.gold==before,"training does not grant or save loot")
	for page in ["show_talents","show_skills","show_quarter"]:
		game.call(page);await process_frame;check(game.ui.get_child_count()>0,"new UI opens "+page)
	var result={"checks":checks,"failures":failures,"skills":18,"talents":54,"save_version":2}
	print(JSON.stringify(result))
	game.queue_free();await process_frame
	call_deferred("quit",0 if failures.is_empty() else 1)
