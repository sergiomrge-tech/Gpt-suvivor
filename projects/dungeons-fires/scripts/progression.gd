class_name DFProgress
extends RefCounted

const VERSION = 1
var path: String = "user://dungeons_fires_save.json"
var db: DFContent
var d: Dictionary = {}
var last_error: String = ""

func _init(content: DFContent, save_path: String = "user://dungeons_fires_save.json") -> void:
	db = content
	path = save_path
	d = fresh()

func fresh() -> Dictionary:
	return {"version":VERSION,"gold":160,"ore":12,"cloth":4,"ash":0,"cores":{},"hero":"varek","cleared":[],"inventory":["W_sword_0","W_staff_0","W_bow_0","A_body_0","A_boots_0","T_0"],"upgrades":{},"equipped":{"weapon":"W_sword_0","head":"","body":"A_body_0","boots":"A_boots_0","talisman":"T_0","relic":""},"heroes":{"varek":{"level":1,"xp":0,"talents":0},"maela":{"level":1,"xp":0,"talents":0},"neris":{"level":1,"xp":0,"talents":0}},"hub":{"forge":1,"sanctuary":1,"botica":1,"archive":1,"barracks":1},"settings":{"sound":true,"shake":true,"story_mode":false,"zoom":1.0},"run":{},"tutorial":false}

func valid(value) -> bool:
	if not value is Dictionary or int(value.get("version",0)) != VERSION:
		return false
	for k in ["gold","ore","cloth","ash"]:
		if not value.has(k) or not (value[k] is float or value[k] is int) or value[k] < 0:
			return false
	for k in ["cores","upgrades","equipped","heroes","hub","settings","run"]:
		if not value.get(k) is Dictionary:
			return false
	if not value.get("inventory") is Array or not value.get("cleared") is Array or not value.hero in ["varek","maela","neris"]:
		return false
	for id in value.inventory:
		if not db.items.has(id): return false
	for slot in ["weapon","head","body","boots","talisman","relic"]:
		if not value.equipped.has(slot): return false
		var id = value.equipped[slot]
		if id != "" and (not value.inventory.has(id) or db.item(id).slot != slot): return false
	for hero in ["varek","maela","neris"]:
		if not value.heroes.get(hero) is Dictionary: return false
		var h = value.heroes[hero]
		if not h.has_all(["level","xp","talents"]) or h.level < 1 or h.level > 30 or h.xp < 0 or h.talents < 0: return false
	for key in ["forge","sanctuary","botica","archive","barracks"]:
		if not value.hub.has(key) or value.hub[key] < 1 or value.hub[key] > 3: return false
	return true

func load_save() -> bool:
	for candidate in [path,path+".bak"]:
		if FileAccess.file_exists(candidate):
			var parser = JSON.new()
			if parser.parse(FileAccess.get_file_as_string(candidate)) != OK: continue
			var value = parser.data
			if valid(value):
				d = value
				return true
	return false

func save() -> bool:
	last_error = ""
	if not valid(d):
		last_error = "Invalid save state"
		return false
	var f = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f == null:
		last_error = "Cannot open save"
		return false
	f.store_string(JSON.stringify(d))
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path,path+".bak") != OK: return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		last_error = "Cannot commit save"
		return false
	return true

func unlocked() -> int:
	var n = 0
	while d.cleared.has(n): n += 1
	return mini(n,14)

func stage() -> int:
	return mini(unlocked()/3,4)

func hero_stats() -> Dictionary:
	var hero = d.heroes[d.hero]
	var atk = 14.0 + (int(hero.level)-1)*3.0
	var defense = 0.0
	var bonus_hp = 0
	for id in d.equipped.values():
		if id == "": continue
		var def = db.item(id)
		var upgrade = int(d.upgrades.get(id,0))
		atk += float(def.attack)*(1+upgrade*.08)
		defense += float(def.defense)*(1+upgrade*.08)
		if def.get("effect","")=="vitality":bonus_hp+=12
	atk *= 1+float(hero.talents)*.035
	return {"attack":atk,"defense":defense,"hp":180+(int(hero.level)-1)*12+int(hero.talents)*8+bonus_hp,"level":int(hero.level)}

func give_xp(amount: int) -> void:
	var h = d.heroes[d.hero]
	h.xp += amount
	while int(h.level)<30:
		var l = int(h.level)-1
		var cost = 100+25*l+5*l*l
		if h.xp < cost: break
		h.xp -= cost
		h.level += 1

func buy_item(id: String) -> bool:
	var def = db.item(id)
	if def.is_empty() or d.inventory.has(id) or int(def.tier)>stage()+1: return false
	if def.hero != "all" and def.hero != d.hero: return false
	if d.inventory.size() >= 60: return false
	if d.gold < def.cost or d.ore < def.ore: return false
	var core = def.get("core","")
	if core != "" and int(d.cores.get(core,0))<1: return false
	if def.slot == "relic" and d.hub.forge<2: return false
	var old = d.duplicate(true)
	d.gold -= def.cost
	d.ore -= def.ore
	if core != "": d.cores[core] -= 1
	d.inventory.append(id)
	if not save(): d = old; return false
	return true

func equip(id: String) -> bool:
	if not d.inventory.has(id): return false
	var def = db.item(id)
	if def.hero != "all" and def.hero != d.hero: return false
	var old = d.duplicate(true)
	d.equipped[def.slot] = id
	if not save(): d = old; return false
	return true

func upgrade(id: String) -> bool:
	if not d.inventory.has(id): return false
	var n = int(d.upgrades.get(id,0))
	var cap = [3,7,10][int(d.hub.forge)-1]
	var cost = 40+n*25
	var ore = 4+n*2
	if n>=cap or d.gold<cost or d.ore<ore: return false
	var old = d.duplicate(true)
	d.gold -= cost
	d.ore -= ore
	d.upgrades[id] = n+1
	if not save(): d = old; return false
	return true

func upgrade_hub(key: String) -> bool:
	if not d.hub.has(key): return false
	var tier = int(d.hub[key])
	var required = 3 if tier==1 else 9
	var gold = 250 if tier==1 else 700
	var ore = 20 if tier==1 else 50
	if tier>=3 or unlocked()<required or d.gold<gold or d.ore<ore or d.ash<1: return false
	var old = d.duplicate(true)
	d.gold -= gold; d.ore -= ore; d.ash -= 1
	d.hub[key] += 1
	if not save(): d = old; return false
	return true

func complete(index: int, loot: Dictionary) -> Dictionary:
	var def = db.dungeons[index]
	var old = d.duplicate(true)
	var first = not d.cleared.has(index)
	var gold = int(loot.get("gold",0))+int(def.reward_gold)
	var ore = int(loot.get("ore",0))+int(def.reward_ore)
	d.gold += gold; d.ore += ore
	d.cloth += int(loot.get("cloth",0))
	var acquired: Array = []
	for id in loot.get("items",[]):
		if grant_item(str(id)):acquired.append(db.item(str(id)).name)
	if first:
		var family={"varek":"sword","maela":"staff","neris":"bow"}[d.hero]
		var gift="W_%s_%d"%[family,mini(index/2+1,7)]
		if grant_item(gift):acquired.append(db.item(gift).name)
	give_xp(int(loot.get("xp",0))+int(def.xp))
	if first:
		d.cleared.append(index)
		# Six ash per chapter pays for the five first building upgrades.
		d.ash += 6 if def.guardian else 1
	if def.guardian:
		d.cores[def.material] = int(d.cores.get(def.material,0))+1
	d.run = {}
	if not save(): d = old; return {"error":"Não foi possível salvar. Tente novamente."}
	return {"gold":gold,"ore":ore,"first":first,"items":acquired,"level":int(d.heroes[d.hero].level)}

func grant_item(id: String) -> bool:
	if not db.items.has(id):return false
	if d.inventory.has(id) or d.inventory.size()>=60:
		d.ore+=3
		return false
	d.inventory.append(id)
	return true

func switch_hero(id: String) -> bool:
	var requirement = {"varek":0,"maela":3,"neris":6}
	if not requirement.has(id) or unlocked()<requirement[id]: return false
	var old = d.duplicate(true)
	d.hero = id
	var weapon = {"varek":"W_sword_0","maela":"W_staff_0","neris":"W_bow_0"}[id]
	d.equipped.weapon = weapon
	d.heroes[id].level = maxi(int(d.heroes[id].level),mini(unlocked()*2+1,30))
	if not save(): d = old; return false
	return true
