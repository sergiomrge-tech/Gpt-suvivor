extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://combat_bot_save.json")
	game.progress.d.settings.sound=false
	game.start_dungeon(0)
	var ticks=0;var dodges=0;var skills=0
	while game.screen=="combat" and ticks<18000:
		ticks+=1
		if game.cleared_room:
			game.next_room()
		var nearest: DFActor=null
		var distance=INF
		for a in game.enemies:
			if a.hp>0 and a.position.distance_to(game.player.position)<distance:
				nearest=a;distance=a.position.distance_to(game.player.position)
		if nearest!=null:
			var diff=nearest.position-game.player.position
			game.controls.axis=Vector2(signf(diff.x) if absf(diff.x)>63 else 0,signf(diff.y) if absf(diff.y)>18 else 0)
			game.player.facing=1 if diff.x>=0 else -1
			game.attack_held=absf(diff.x)<117 and absf(diff.y)<52
			if nearest.state=="windup" and nearest.timer<.25 and game.player.dodge_cd<=0:
				game.move_axis=Vector2(0,-1 if game.player.position.y>485 else 1);game.player.request_dodge();dodges+=1
			if distance<200 and game.player.skill_cd[0]<=0:game.player.request_skill(0);skills+=1
			if game.player.hp<game.player.max_hp*.6:game.use_potion()
		game._physics_process(1.0/60)
		if ticks%60==0:await process_frame
	var result={"won":game.screen=="result","seconds_simulated":ticks/60.0,"dodges":dodges,"skills":skills,"health":game.player.hp,"gold":game.progress.d.gold,"level":game.progress.hero_stats().level}
	print(JSON.stringify(result))
	game.queue_free();await process_frame
	call_deferred("quit",0 if result.won else 1)
