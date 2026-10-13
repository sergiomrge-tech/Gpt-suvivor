extends SceneTree

func _initialize() -> void:
    var state := SurvivorState.new()
    assert(state.item_count("wood") == 2)
    assert(not state.can_craft("raft"))
    state.add_item("wood", 10)
    state.add_item("stone", 10)
    state.add_item("fiber", 10)
    assert(state.can_craft("spear"))
    assert(state.craft("spear"))
    assert(state.item_count("spear") == 1)
    state.add_item("fruit", 2)
    var hunger_before: float = state.hunger
    state.eat()
    assert(state.hunger >= hunger_before)
    var encoded: Dictionary = state.to_dict()
    var copy := SurvivorState.new()
    assert(copy.from_dict(encoded))
    assert(copy.item_count("spear") == 1)
    assert(not copy.from_dict({"version": 99}))
    print("SURVIVAL TESTS: OK")
    quit(0)
