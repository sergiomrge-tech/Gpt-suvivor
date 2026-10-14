class_name DFContent
extends RefCounted

var dungeons: Array = []
var items: Dictionary = {}
var regions: Array = []

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	if not parsed is Dictionary:
		push_error("Invalid catalog")
		return
	dungeons = parsed.dungeons
	regions = parsed.regions
	for item in parsed.items:
		items[item.id] = item

func item(id: String) -> Dictionary:
	return items.get(id, {})

func unlocked_items(stage: int, hero: String) -> Array:
	var result: Array = []
	for def in items.values():
		if int(def.tier) <= stage and (def.hero == hero or def.hero == "all"):
			result.append(def)
	return result
