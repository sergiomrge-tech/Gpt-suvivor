extends CanvasLayer
class_name SurvivorHUD

signal action_requested(action: String)
signal recipe_selected(recipe: String)
signal move_changed(direction: Vector2)

const COLOR_BG = Color(0.055, 0.12, 0.13, 0.87)
const COLOR_BORDER = Color(0.75, 0.69, 0.48, 0.80)
const COLOR_TEXT = Color(0.97, 0.95, 0.85)
const RECIPE_NAMES = {
    "knife": "Faca de pedra", "axe": "Machado de pedra",
    "pickaxe": "Picareta de pedra", "fishing_rod": "Vara de pescar", "spear": "Lança", "campfire": "Fogueira", "shelter": "Abrigo",
    "collector": "Coletor de água", "workbench": "Bancada", "raft": "Jangada de fuga"
}

var root: Control
var playing_view: Control
var menu_view: ColorRect
var menu_content: VBoxContainer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var active_state: SurvivorState
var active_tab := "items"
var inventory_signature := ""
var vitals: Dictionary = {}
var inventory_label: Label
var nearby_label: Label
var toast_label: Label
var day_label: Label
var help_label: Label
var toast_until := 0.0
var joystick: SurvivorJoystick
var game_active := false

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    _build_playing_view()
    _build_menu_view()
    show_main_menu()

func _panel() -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = COLOR_BG
    style.border_color = COLOR_BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(12)
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _label(text: String, font_size: int = 18) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_color_override("font_color", COLOR_TEXT)
    label.add_theme_font_size_override("font_size", font_size)
    return label

func _button(title: String, action: String) -> Button:
    var button := Button.new()
    button.text = title
    button.custom_minimum_size = Vector2(122.0, 50.0)
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(func() -> void: action_requested.emit(action))
    return button

func _build_playing_view() -> void:
    playing_view = Control.new()
    playing_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    playing_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(playing_view)

    var top := _panel()
    top.anchor_left = 0.0
    top.anchor_top = 0.0
    top.anchor_right = 0.0
    top.anchor_bottom = 0.0
    top.offset_left = 16.0
    top.offset_top = 14.0
    top.offset_right = 365.0
    top.offset_bottom = 214.0
    playing_view.add_child(top)
    var top_column := VBoxContainer.new()
    top_column.add_theme_constant_override("separation", 5)
    top.add_child(top_column)
    top_column.add_child(_label("GPT SURVIVOR  •  ILHA PERDIDA", 20))
    day_label = _label("DIA 1", 16)
    top_column.add_child(day_label)
    for stat in ["health", "hunger", "thirst"]:
        var row := HBoxContainer.new()
        top_column.add_child(row)
        var label_text: String = {"health": "Vida", "hunger": "Fome", "thirst": "Sede"}[stat]
        var title := _label(label_text, 17)
        title.custom_minimum_size.x = 66.0
        row.add_child(title)
        var bar := ProgressBar.new()
        bar.min_value = 0
        bar.max_value = 100
        bar.show_percentage = true
        bar.custom_minimum_size = Vector2(213, 22)
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.value = 100
        var fill := StyleBoxFlat.new()
        fill.bg_color = {"health": Color(0.62, 0.21, 0.17), "hunger": Color(0.75, 0.54, 0.18), "thirst": Color(0.15, 0.53, 0.76)}[stat]
        fill.set_corner_radius_all(6)
        bar.add_theme_stylebox_override("fill", fill)
        row.add_child(bar)
        vitals[stat] = bar

    var info_panel := _panel()
    info_panel.anchor_left = 0.5
    info_panel.anchor_right = 0.5
    info_panel.offset_left = -220.0
    info_panel.offset_right = 220.0
    info_panel.offset_top = 15.0
    info_panel.offset_bottom = 87.0
    playing_view.add_child(info_panel)
    var info_col := VBoxContainer.new()
    info_panel.add_child(info_col)
    nearby_label = _label("Procure recursos naturais", 18)
    nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_col.add_child(nearby_label)
    toast_label = _label("", 15)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_col.add_child(toast_label)

    var right := VBoxContainer.new()
    right.anchor_left = 1.0
    right.anchor_right = 1.0
    right.anchor_top = 0.19
    right.anchor_bottom = 0.19
    right.offset_left = -163.0
    right.offset_right = -13.0
    right.add_theme_constant_override("separation", 3)
    playing_view.add_child(right)
    for action in ["collect", "fish", "eat", "drink", "inventory", "craft_menu", "zoom_in", "zoom_out", "menu"]:
        var title: String = {"collect": "COLETAR [E]", "fish": "PESCAR [F]", "eat": "COMER [H]", "drink": "BEBER [T]", "inventory": "MOCHILA [I]", "craft_menu": "CRIAR [B]", "zoom_in": "ZOOM +", "zoom_out": "ZOOM -", "menu": "MENU"}[action]
        right.add_child(_button(title, action))

    var bottom := _panel()
    bottom.anchor_top = 1.0
    bottom.anchor_bottom = 1.0
    bottom.anchor_left = 0.28
    bottom.anchor_right = 0.87
    bottom.offset_top = -65.0
    bottom.offset_bottom = -12.0
    playing_view.add_child(bottom)
    inventory_label = _label("Inventário", 16)
    inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inventory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(inventory_label)

    joystick = SurvivorJoystick.new()
    joystick.anchor_top = 1.0
    joystick.anchor_bottom = 1.0
    joystick.offset_left = 52.0
    joystick.offset_top = -276.0
    joystick.offset_right = 292.0
    joystick.offset_bottom = -36.0
    joystick.direction_changed.connect(func(vec: Vector2) -> void: move_changed.emit(vec))
    playing_view.add_child(joystick)

    inventory_panel = _panel()
    inventory_panel.anchor_left = 0.5
    inventory_panel.anchor_right = 0.5
    inventory_panel.anchor_top = 0.5
    inventory_panel.anchor_bottom = 0.5
    inventory_panel.offset_left = -310.0
    inventory_panel.offset_right = 310.0
    inventory_panel.offset_top = -255.0
    inventory_panel.offset_bottom = 255.0
    inventory_panel.visible = false
    playing_view.add_child(inventory_panel)
    var inventory_column := VBoxContainer.new()
    inventory_column.add_theme_constant_override("separation", 10)
    inventory_panel.add_child(inventory_column)
    inventory_column.add_child(_label("MOCHILA DO SOBREVIVENTE", 25))
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 6)
    inventory_column.add_child(tabs)
    for tab_name in ["items", "equipment", "craft"]:
        var tab_button := Button.new()
        tab_button.custom_minimum_size = Vector2(170, 46)
        tab_button.text = {"items": "ITENS", "equipment": "EQUIPAR", "craft": "FABRICAR"}[tab_name]
        tab_button.pressed.connect(_select_tab.bind(tab_name))
        tabs.add_child(tab_button)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(552.0, 328.0)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inventory_column.add_child(scroll)
    inventory_list = VBoxContainer.new()
    inventory_list.custom_minimum_size.x = 548.0
    inventory_list.add_theme_constant_override("separation", 8)
    scroll.add_child(inventory_list)
    inventory_column.add_child(_button("FECHAR MOCHILA", "close_inventory"))

func _build_menu_view() -> void:
    menu_view = ColorRect.new()
    menu_view.color = Color(0.015, 0.055, 0.06, 0.91)
    menu_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_view.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(menu_view)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_view.add_child(center)
    var panel := _panel()
    panel.custom_minimum_size = Vector2(565, 390)
    center.add_child(panel)
    menu_content = VBoxContainer.new()
    menu_content.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_content.add_theme_constant_override("separation", 18)
    panel.add_child(menu_content)

func _clear_menu() -> void:
    for child in menu_content.get_children():
        child.queue_free()

func show_main_menu() -> void:
    game_active = false
    playing_view.visible = false
    menu_view.visible = true
    _clear_menu()
    var title := _label("GPT SURVIVOR", 45)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_content.add_child(title)
    var subtitle := _label("ILHA PERDIDA • SOBREVIVA, CONSTRUA, ESCAPE", 17)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_content.add_child(subtitle)
    menu_content.add_child(_button("NOVA SOBREVIVÊNCIA", "start"))
    if SurvivorState.save_exists():
        menu_content.add_child(_button("CONTINUAR JOGO SALVO", "load"))
    var help := _label("WASD / SETAS para mover • E coletar • B criar\nNo celular use o joystick e os botões na tela", 16)
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_content.add_child(help)

func show_game() -> void:
    game_active = true
    menu_view.visible = false
    playing_view.visible = true
    inventory_panel.visible = false

func show_ending(won: bool) -> void:
    game_active = false
    playing_view.visible = false
    menu_view.visible = true
    _clear_menu()
    var title := _label("VOCÊ ESCAPOU!" if won else "FIM DA SOBREVIVÊNCIA", 35)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_content.add_child(title)
    var note := _label("Uma nova vida espera além do oceano." if won else "A ilha exige preparo. Tente novamente.", 20)
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_content.add_child(note)
    menu_content.add_child(_button("NOVA PARTIDA", "start"))
    menu_content.add_child(_button("MENU PRINCIPAL", "menu"))

func inventory_is_open() -> bool:
    return inventory_panel.visible

func _select_tab(tab_name: String) -> void:
    active_tab = tab_name
    inventory_signature = ""
    _refresh_inventory()

func toggle_inventory() -> void:
    if not game_active:
        return
    if inventory_panel.visible:
        close_inventory()
    else:
        open_inventory("items")

func open_inventory(tab_name: String = "items") -> void:
    if not game_active:
        return
    inventory_panel.visible = true
    _select_tab(tab_name)

func close_inventory() -> void:
    inventory_panel.visible = false

func _inventory_button(label_text: String, action: String, enabled: bool = true) -> void:
    var button := _button(label_text, action)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.disabled = not enabled
    inventory_list.add_child(button)

func _refresh_inventory() -> void:
    if active_state == null or not inventory_panel.visible:
        return
    for child in inventory_list.get_children():
        child.free()
    var state: SurvivorState = active_state
    if active_tab == "items":
        inventory_list.add_child(_label("RECURSOS / CONSUMÍVEIS", 22))
        for item in ["wood", "stone", "fiber", "palm_leaf", "fruit", "fish", "water"]:
            var count: int = state.item_count(item)
            if count > 0:
                inventory_list.add_child(_label("%s   x%d" % [SurvivorState.ITEM_NAMES[item], count], 19))
        inventory_list.add_child(_label("FERRAMENTAS NA MOCHILA", 22))
        var found := false
        for item in SurvivorState.TOOL_SLOTS:
            var count: int = state.item_count(item)
            if count > 0:
                found = true
                var equipped: String = " • EQUIPADO" if state.is_equipped(item) else ""
                inventory_list.add_child(_label("%s   x%d%s" % [SurvivorState.ITEM_NAMES[item], count, equipped], 19))
        if not found:
            inventory_list.add_child(_label("Sem ferramentas. Abra FABRICAR para criar.", 17))
    elif active_tab == "equipment":
        inventory_list.add_child(_label("ESPAÇOS PARA EQUIPAR", 22))
        for slot in ["main_hand", "utility"]:
            var slot_title: String = "MÃO PRINCIPAL" if slot == "main_hand" else "FERRAMENTA"
            var equipped: String = str(state.equipment.get(slot, ""))
            var item_title: String = SurvivorState.ITEM_NAMES.get(equipped, "Vazio")
            inventory_list.add_child(_label("%s: %s" % [slot_title, item_title], 19))
            if equipped != "":
                _inventory_button("DESEQUIPAR " + item_title, "unequip:" + slot)
        inventory_list.add_child(_label("EQUIPAMENTOS DISPONÍVEIS", 22))
        var owned := false
        for item in SurvivorState.TOOL_SLOTS:
            if state.item_count(item) > 0:
                owned = true
                var in_use: bool = state.is_equipped(item)
                _inventory_button(("EQUIPADO: " if in_use else "EQUIPAR: ") + SurvivorState.ITEM_NAMES[item], "equip:" + item, not in_use)
        if not owned:
            inventory_list.add_child(_label("Fabrique uma faca, machado, picareta ou vara.", 17))
    elif active_tab == "craft":
        inventory_list.add_child(_label("FERRAMENTAS BÁSICAS", 21))
        for recipe in SurvivorState.RECIPES:
            if SurvivorState.BUILDING_RECIPES.has(recipe):
                continue
            _add_recipe(state, str(recipe))
        inventory_list.add_child(_label("CONSTRUÇÕES", 21))
        for recipe in SurvivorState.BUILDING_RECIPES:
            _add_recipe(state, str(recipe))
    inventory_signature = str(state.inventory) + str(state.equipment) + str(state.crafted)

func _add_recipe(state: SurvivorState, recipe: String) -> void:
    var costs: Array[String] = []
    var materials: Dictionary = SurvivorState.RECIPES[recipe]
    for item in materials:
        costs.append("%s %d/%d" % [SurvivorState.ITEM_NAMES[item], state.item_count(item), int(materials[item])])
    var title_text: String = RECIPE_NAMES[recipe] + "  |  " + ", ".join(costs)
    _inventory_button(title_text, "recipe:" + recipe, state.can_craft(recipe))

func notify(message: String) -> void:
    toast_label.text = message
    toast_until = Time.get_ticks_msec() / 1000.0 + 5.0

func update_display(state: SurvivorState, near: String) -> void:
    if not game_active:
        return
    (vitals["health"] as ProgressBar).value = state.health
    (vitals["hunger"] as ProgressBar).value = state.hunger
    (vitals["thirst"] as ProgressBar).value = state.thirst
    day_label.text = "DIA %d  •  %02d:%02d" % [state.days, int(state.clock * 24.0), int(fmod(state.clock * 1440.0, 60.0))]
    nearby_label.text = near if near != "" else "Explore a ilha e procure recursos"
    var items: Array[String] = []
    for item in ["wood", "stone", "fiber", "palm_leaf", "fruit", "fish", "water", "spear"]:
        var count: int = state.item_count(item)
        if count > 0:
            items.append("%s: %d" % [SurvivorState.ITEM_NAMES[item], count])
    inventory_label.text = "  •  ".join(items)
    if Time.get_ticks_msec() / 1000.0 > toast_until:
        toast_label.text = ""
