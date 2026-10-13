extends CanvasLayer
class_name SurvivorHUD

signal action_requested
signal build_requested(kind: String)
signal confirm_build_requested
signal cancel_build_requested
signal equipment_requested(kind: String)
signal unequip_requested(slot: String)
signal fishing_requested
signal consume_requested
signal save_requested
signal menu_requested
signal start_requested(load_save: bool)
signal sound_requested
signal journal_requested
signal quality_requested
signal zoom_requested(amount: float)
signal resume_requested

var root: Control
var game_controls: Control
var joystick: SurvivorJoystick
var minimap: SurvivorMinimap
var stats: Label
var zoom_in_button: Button
var zoom_out_button: Button
var item_detail: Label
var inventory_tab := "items"
var item_buttons: Dictionary = {}
var objective_label: Label
var time_label: Label
var action_button: Button
var fishing_button: Button
var toast_label: Label
var placement_label: Label
var panel: PanelContainer
var panel_content: VBoxContainer
var modal_top: VBoxContainer
var modal_mode := ""
var toast_time := 0.0
var ui_refresh := 0.0
var state: SurvivalState
var target: Dictionary = {}
var is_playing := false
var placement_kind := ""
var light_visuals := false
var quality_button: Button
var sound_button: Button
var muted := false
var activity_label: Label
var activity_progress: ProgressBar
var can_fish := false
var activity_name := ""
var activity_fraction := 0.0
var build_buttons: Dictionary = {}
const INK := Color(0.045, 0.1, 0.13, 0.94)
const GOLD := Color(0.88, 0.75, 0.47)

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    game_controls = Control.new()
    game_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(game_controls)
    var top := PanelContainer.new()
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    top.offset_left = 16
    top.offset_right = 424
    top.offset_top = 12
    top.offset_bottom = 56
    var compact_style := _style(INK)
    compact_style.content_margin_top = 8
    compact_style.content_margin_bottom = 8
    top.add_theme_stylebox_override("panel",compact_style)
    game_controls.add_child(top)
    stats = _label("",18)
    top.add_child(stats)
    var bag := _button("Mochila",func(): toggle_inventory())
    bag.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    bag.offset_left = 434
    bag.offset_right = 548
    bag.offset_top = 12
    bag.offset_bottom = 56
    bag.custom_minimum_size = Vector2(114,44)
    bag.add_theme_font_size_override("font_size",18)
    game_controls.add_child(bag)
    objective_label = _label("",17)
    objective_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    objective_label.offset_left = 24
    objective_label.offset_right = -210
    objective_label.offset_top = 68
    objective_label.offset_bottom = 109
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    game_controls.add_child(objective_label)
    var map_box := VBoxContainer.new()
    map_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    map_box.offset_left = -140
    map_box.offset_right = -18
    map_box.offset_top = 12
    game_controls.add_child(map_box)
    minimap = SurvivorMinimap.new()
    minimap.custom_minimum_size = Vector2(122,122)
    map_box.add_child(minimap)
    time_label = _label("",14)
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    map_box.add_child(time_label)
    var menu := _button("Pausar", func(): menu_requested.emit())
    menu.custom_minimum_size = Vector2(122,44)
    map_box.add_child(menu)
    var zoom_row := HBoxContainer.new()
    zoom_row.add_theme_constant_override("separation",6)
    map_box.add_child(zoom_row)
    zoom_out_button = _button("−",func(): zoom_requested.emit(3.0))
    zoom_in_button = _button("+",func(): zoom_requested.emit(-3.0))
    for zoom_button in [zoom_out_button,zoom_in_button]:
        zoom_button.custom_minimum_size = Vector2(58,48)
        zoom_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        zoom_row.add_child(zoom_button)
    zoom_out_button.tooltip_text = "Afastar câmera"
    zoom_in_button.tooltip_text = "Aproximar câmera"
    joystick = SurvivorJoystick.new()
    joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.offset_left = 100
    joystick.offset_right = 320
    joystick.offset_top = -274
    joystick.offset_bottom = -54
    game_controls.add_child(joystick)
    var actions := VBoxContainer.new()
    actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    actions.offset_left = -210
    actions.offset_right = -20
    actions.offset_top = -232
    actions.offset_bottom = -24
    actions.alignment = BoxContainer.ALIGNMENT_END
    actions.add_theme_constant_override("separation",7)
    game_controls.add_child(actions)
    action_button = _button("Explorar", func(): action_requested.emit())
    actions.add_child(action_button)
    fishing_button = _button("Pescar", func(): fishing_requested.emit())
    actions.add_child(fishing_button)
    var secondary := HBoxContainer.new()
    secondary.add_theme_constant_override("separation",6)
    actions.add_child(secondary)
    var build := _button("Construir",func(): show_crafting())
    build.custom_minimum_size = Vector2(90,50)
    build.add_theme_font_size_override("font_size",17)
    secondary.add_child(build)
    var food := _button("Alimento",func(): consume_requested.emit())
    food.custom_minimum_size = Vector2(90,50)
    food.add_theme_font_size_override("font_size",17)
    secondary.add_child(food)
    for button in [build,food]:
        for theme_name in ["normal","pressed","hover","disabled"]:
            var compact: StyleBoxFlat = button.get_theme_stylebox(theme_name).duplicate()
            compact.content_margin_left = 6
            compact.content_margin_right = 6
            button.add_theme_stylebox_override(theme_name,compact)
    var activity := VBoxContainer.new()
    activity.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    activity.offset_left = -140
    activity.offset_right = 140
    activity.offset_top = -102
    activity.offset_bottom = -53
    activity.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_controls.add_child(activity)
    activity_label = _label("",17)
    activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    activity.add_child(activity_label)
    activity_progress = ProgressBar.new()
    activity_progress.custom_minimum_size = Vector2(260,10)
    activity_progress.max_value = 1.0
    activity_progress.show_percentage = false
    activity_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var track := StyleBoxFlat.new()
    track.bg_color = Color(0.04,0.13,0.14,0.8)
    track.set_corner_radius_all(4)
    var fill := StyleBoxFlat.new()
    fill.bg_color = GOLD
    fill.set_corner_radius_all(4)
    activity_progress.add_theme_stylebox_override("background",track)
    activity_progress.add_theme_stylebox_override("fill",fill)
    activity.add_child(activity_progress)
    var hint := _label("WASD / setas • E ação • B construir • F pescar • H comer • P salvar", 14)
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    hint.offset_left = 200
    hint.offset_right = -254
    hint.offset_top = -32
    hint.offset_bottom = -12
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.visible = not OS.has_feature("android")
    game_controls.add_child(hint)
    toast_label = _label("", 21)
    toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    toast_label.offset_left = -320
    toast_label.offset_right = 320
    toast_label.offset_top = -170
    toast_label.offset_bottom = -107
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(toast_label)
    placement_label = _label("", 21)
    placement_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    placement_label.offset_left = -340
    placement_label.offset_right = 340
    placement_label.offset_top = 132
    placement_label.offset_bottom = 194
    placement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    placement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    game_controls.add_child(placement_label)
    root.resized.connect(_resize_modal)
    set_playing(false)

func _style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color(0.59, 0.67, 0.51, 0.6)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style

func _label(text: String, font_size: int = 20) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.87))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    return label

func _button(text: String, callback: Callable) -> Button:
    var button := SurvivorTouchButton.new()
    button.touch_allowed = func() -> bool:
        return modal_mode == "" or is_instance_valid(panel) and panel.is_ancestor_of(button)
    button.text = text
    button.custom_minimum_size = Vector2(0, 57)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_stylebox_override("normal", _style(Color(0.08, 0.19, 0.2, 0.94)))
    button.add_theme_stylebox_override("pressed", _style(Color(0.27, 0.39, 0.26)))
    button.add_theme_stylebox_override("hover", _style(Color(0.14, 0.28, 0.27)))
    button.add_theme_stylebox_override("disabled", _style(Color(0.11, 0.15, 0.16, 0.8)))
    button.pressed.connect(callback)
    return button

func set_playing(value: bool) -> void:
    is_playing = value
    game_controls.visible = value
    joystick.active = value and modal_mode == ""
    if not joystick.active:
        joystick.reset()

func _new_modal(mode: String, title: String, description: String) -> void:
    close_modal()
    modal_mode = mode
    joystick.active = false
    joystick.reset()
    var blocker := ColorRect.new()
    blocker.name = "ModalBlocker"
    blocker.color = Color(0.01, 0.035, 0.05, 0.67)
    blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(blocker)
    panel = PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _style(INK))
    root.add_child(panel)
    var scroll := SurvivorTouchScroll.new()
    scroll.touch_allowed = func() -> bool: return is_instance_valid(panel) and panel.is_ancestor_of(scroll)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    var shell := VBoxContainer.new()
    shell.add_theme_constant_override("separation",12)
    panel.add_child(shell)
    modal_top = VBoxContainer.new()
    modal_top.add_theme_constant_override("separation",10)
    shell.add_child(modal_top)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    shell.add_child(scroll)
    panel_content = VBoxContainer.new()
    panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel_content.add_theme_constant_override("separation", 14)
    scroll.add_child(panel_content)
    var heading := _label(title, 32)
    heading.add_theme_color_override("font_color", GOLD)
    if mode in ["craft", "inventory", "pause"]:
        var header := HBoxContainer.new()
        heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(heading)
        var close := _button("×", func(): close_modal(); resume_requested.emit())
        close.custom_minimum_size = Vector2(56, 56)
        header.add_child(close)
        modal_top.add_child(header)
    else:
        modal_top.add_child(heading)
    var desc := _label(description, 19)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    modal_top.add_child(desc)
    _resize_modal()

func _resize_modal() -> void:
    if is_instance_valid(panel):
        var width := minf(1080.0 if modal_mode in ["inventory","craft"] else 650.0, root.size.x - 32.0)
        var height := minf(610.0, root.size.y - 36.0)
        panel.position = (root.size - Vector2(width, height)) * 0.5
        panel.size = Vector2(width, height)

func close_modal() -> void:
    if is_instance_valid(panel):
        root.remove_child(panel)
        panel.queue_free()
        panel = null
    var blocker := root.get_node_or_null("ModalBlocker")
    if blocker != null:
        root.remove_child(blocker)
        blocker.queue_free()
    modal_mode = ""
    build_buttons.clear()
    joystick.active = is_playing

func show_menu(saved: bool, paused: bool = false) -> void:
    _new_modal("pause" if paused else "menu", "ILHA • ÚLTIMO VOO", "Um sobrevivente. Uma ilha desconhecida. Construa seu caminho de volta.\nProtótipo Godot 3D • v0.4.2")
    if paused:
        panel_content.add_child(_button("Voltar ao jogo", func(): close_modal(); resume_requested.emit()))
        panel_content.add_child(_button("Salvar progresso", func(): save_requested.emit()))
    elif saved:
        panel_content.add_child(_button("Continuar sobrevivência", func(): close_modal(); start_requested.emit(true)))
    panel_content.add_child(_button("Nova sobrevivência", func(): _confirm_new_game(saved or paused)))
    sound_button = _button("Som: desligado" if muted else "Som: ligado",func(): sound_requested.emit())
    panel_content.add_child(sound_button)
    quality_button = _button("Visual: Leve" if light_visuals else "Visual: Completo", func(): quality_requested.emit())
    panel_content.add_child(quality_button)
    var help := _label("Explore os destroços, coqueiros, rochas e cavernas. A nascente aparece em azul no mapa. As barras diminuem após os três primeiros minutos.\n\nCelular: joystick à esquerda e ações à direita. PC: WASD / setas. O jogo salva automaticamente a cada minuto e ao sair.", 18)
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_content.add_child(help)

func _confirm_new_game(overwrite: bool) -> void:
    if overwrite:
        _new_modal("confirm_new", "Começar novamente?", "Seu progresso atual será substituído após o início da nova partida.")
        panel_content.add_child(_button("Começar nova partida", func(): _intro()))
        panel_content.add_child(_button("Voltar", func(): show_menu(true, is_playing)))
    else:
        _intro()

func _intro() -> void:
    _new_modal("intro", "O último voo", "A tempestade derrubou seu avião perto de uma ilha tropical. Você acorda na areia, cercado por destroços.\n\nMonte um acampamento, encontre água e alimento, explore as cavernas e recupere metal. Construa uma casa e um barco para deixar a ilha.\n\nPrimeiro passo: pegue troncos e pedras soltas no chão, e fibras nas plantas. Abra Mochila → Construções para fabricar machado e picareta de pedra. Depois corte árvores e extraia pedra para sua fogueira.")
    panel_content.add_child(_button("Acordar na praia", func(): close_modal(); start_requested.emit(false)))

func show_crafting() -> void:
    show_inventory("craft")

func show_inventory(tab: String = "items") -> void:
    if not is_playing or state == null: return
    inventory_tab = tab
    item_buttons.clear()
    _new_modal("craft" if tab == "craft" else "inventory", "MOCHILA", "Organize itens e equipe as ferramentas antes de usá-las na ilha.")
    var tabs := HBoxContainer.new()
    modal_top.add_child(tabs)
    for entry in [["Itens", "items"], ["Equipar", "equipment"], ["Construções", "craft"]]:
        var tab_button := _button(entry[0],_inventory_tab_callback(entry[1]))
        tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if tab == entry[1]:
            tab_button.add_theme_stylebox_override("normal",_style(Color(0.28,0.36,0.23)))
        tabs.add_child(tab_button)
    var summary := _label("Madeira %d  •  Pedra %d  •  Fibra %d  •  Metal %d" % [state.inventory.wood,state.inventory.stone,state.inventory.fiber,state.inventory.metal],19)
    modal_top.add_child(summary)
    if tab == "equipment":
        _equipment_panel()
    elif tab == "craft":
        _recipe_grid("Ferramentas básicas • feitas à mão",["stone_knife","stone_axe","stone_pickaxe"])
        _recipe_grid("Acampamento e bancada",["campfire","workbench","fishing_rod","house","dock","boat","meal"])
    else:
        _inventory_grid()
    panel_content.add_child(_button("Voltar ao jogo",func(): close_modal(); resume_requested.emit()))

func _inventory_tab_callback(tab: String) -> Callable:
    return func(): show_inventory(tab)

func _icon(kind: String) -> Texture2D:
    var path := "res://" + "assets/icons/items/" + kind + ".svg"
    return load(path) if ResourceLoader.exists(path) else null

func _inventory_grid() -> void:
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation",20)
    panel_content.add_child(columns)
    var bag_column := VBoxContainer.new()
    bag_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(bag_column)
    bag_column.add_child(_label("RECURSOS E FERRAMENTAS",19))
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation",8)
    grid.add_theme_constant_override("v_separation",8)
    bag_column.add_child(grid)
    for kind in ["wood","stone","fiber","metal","coconut","raw_fish","meal","stone_knife","stone_axe","stone_pickaxe","fishing_rod"]:
        var title: String = SurvivalState.ITEMS.get(kind,SurvivalState.RECIPES.get(kind,{}).get("title",kind))
        var amount: int = state.inventory.get(kind,0)
        var slot := _button("%s\n×%d" % [title,amount],_item_callback(kind))
        slot.custom_minimum_size = Vector2(126,112)
        slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slot.add_theme_font_size_override("font_size",15)
        slot.text = ""
        var caption := _label("%s\n×%d" % [title,amount],15)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
        caption.add_theme_color_override("font_color",Color(0.95,0.93,0.8) if amount > 0 else Color(0.58,0.65,0.60))
        slot.add_child(caption)
        caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
        caption.offset_top = -46
        caption.offset_bottom = -6
        var icon := TextureRect.new()
        icon.texture = _icon(kind)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot.add_child(icon)
        icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
        icon.offset_left = -26
        icon.offset_right = 26
        icon.offset_top = 7
        icon.offset_bottom = 59
        slot.add_theme_color_override("font_color",Color(0.95,0.93,0.8) if amount > 0 else Color(0.58,0.65,0.60))
        grid.add_child(slot)
        item_buttons[kind] = slot
    item_detail = _label("Toque em um item para ver sua função.",18)
    item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bag_column.add_child(item_detail)
    bag_column.add_child(_button("Comer / beber",func(): close_modal(); consume_requested.emit()))
    var character_column := VBoxContainer.new()
    character_column.custom_minimum_size.x = 280
    columns.add_child(character_column)
    character_column.add_child(_label("SOBREVIVENTE",19))
    var viewport_container := SubViewportContainer.new()
    viewport_container.custom_minimum_size = Vector2(280,260)
    viewport_container.stretch = true
    viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    character_column.add_child(viewport_container)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(280,260)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_container.add_child(viewport)
    var scene := Node3D.new()
    viewport.add_child(scene)
    var hero := SurvivorPlayer.new()
    scene.add_child(hero)
    hero.body_pivot.rotation.y = -0.16
    var preview_camera := Camera3D.new()
    scene.add_child(preview_camera)
    preview_camera.position = Vector3(0,1.4,6.2)
    preview_camera.look_at(Vector3(0,1.4,0))
    preview_camera.fov = 32
    preview_camera.current = true
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.08,0.15,0.16)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.85,0.9,1)
    environment.environment.ambient_light_energy = 0.85
    scene.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-35,-25,0)
    sun.light_energy = 1.2
    scene.add_child(sun)
    var equipment := _label("EQUIPADOS\n",18)
    for slot in ["main_hand","utility"]:
        var item: String = str(state.equipment.get(slot,""))
        var caption: String = "Mão principal" if slot == "main_hand" else "Ferramenta"
        equipment.text += "%s: %s\n" % [caption, "Vazio" if item == "" else SurvivalState.RECIPES[item].title]
    character_column.add_child(equipment)
    character_column.add_child(_button("Gerenciar equipamentos",func(): show_inventory("equipment")))
    character_column.add_child(_button("Diário da ilha",func(): show_journal()))

func _equipment_panel() -> void:
    panel_content.add_child(_label("EQUIPAMENTOS DO PERSONAGEM",23))
    panel_content.add_child(_label("É preciso equipar a ferramenta correta. A vara fica na mão principal; machado, picareta e faca usam o espaço de ferramenta.",18))
    var slots := HBoxContainer.new()
    slots.add_theme_constant_override("separation",14)
    panel_content.add_child(slots)
    for entry in [["main_hand","MÃO PRINCIPAL"],["utility","FERRAMENTA"]]:
        var slot: String = entry[0]
        var container := PanelContainer.new()
        container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.add_theme_stylebox_override("panel",_style(Color(0.13,0.25,0.23)))
        slots.add_child(container)
        var body := VBoxContainer.new()
        body.add_theme_constant_override("separation",10)
        container.add_child(body)
        body.add_child(_label(entry[1],20))
        var held: String = str(state.equipment.get(slot,""))
        var title: String = "VAZIO" if held == "" else str(SurvivalState.RECIPES[held].title)
        body.add_child(_label(title,21))
        if held != "":
            var icon := TextureRect.new()
            icon.texture = _icon(held)
            icon.custom_minimum_size = Vector2(0,54)
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            body.add_child(icon)
            body.add_child(_button("Desequipar",_unequip_callback(slot)))
    panel_content.add_child(_label("ESCOLHER FERRAMENTA",22))
    var choices := GridContainer.new()
    choices.columns = 2
    choices.add_theme_constant_override("h_separation",12)
    choices.add_theme_constant_override("v_separation",10)
    panel_content.add_child(choices)
    for kind in SurvivalState.TOOLS:
        var available: bool = state.owns(kind)
        var equipped: bool = state.is_equipped(kind)
        var status: String = "EQUIPADO" if equipped else ("EQUIPAR" if available else "FABRICAR PRIMEIRO")
        var button := _button("%s • %s" % [SurvivalState.RECIPES[kind].title,status],_equip_callback(kind))
        button.custom_minimum_size = Vector2(0,65)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.disabled = not available or equipped
        choices.add_child(button)
    panel_content.add_child(_label("Pesca: equipe a VARA DE PESCAR na mão principal; vá à praia ou ao cais e toque PESCAR.",18))

func _equip_callback(kind: String) -> Callable:
    return func(): equipment_requested.emit(kind)

func _unequip_callback(slot: String) -> Callable:
    return func(): unequip_requested.emit(slot)

func _item_callback(kind: String) -> Callable:
    return func():
        if not is_instance_valid(item_detail): return
        var title: String = SurvivalState.ITEMS.get(kind,SurvivalState.RECIPES.get(kind,{}).get("title",kind))
        var descriptions := {"wood":"Troncos soltos podem ser recolhidos à mão. Para cortar árvores, fabrique um machado.","stone":"Pedras soltas podem ser recolhidas à mão. Para minerar rochas, fabrique uma picareta.","fiber":"Recolha à mão nas plantas. A faca aumenta a quantidade coletada.","metal":"Recupere ferragens nos destroços e nas cavernas para construir o barco.","coconut":"Recupera água e fome. Use Comer / beber.","raw_fish":"Asse na fogueira antes de comer.","meal":"Peixe assado: recupera fome e saúde."}
        var detail: String = descriptions.get(kind,SurvivalState.RECIPES.get(kind,{}).get("description",""))
        item_detail.text = "%s • %d no inventário\n%s" % [title,state.inventory.get(kind,0),detail]

func _recipe_grid(title: String,kinds: Array) -> void:
    panel_content.add_child(_label(title,22))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",10)
    panel_content.add_child(grid)
    for kind in kinds:
        var recipe: Dictionary = SurvivalState.RECIPES[kind]
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel",_style(Color(0.10,0.21,0.21)))
        grid.add_child(card)
        var body := VBoxContainer.new()
        body.add_theme_constant_override("separation",8)
        card.add_child(body)
        var heading := _label(recipe.title,21)
        body.add_child(heading)
        var icon := TextureRect.new()
        icon.texture = _icon(kind)
        icon.custom_minimum_size = Vector2(0,52)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        body.add_child(icon)
        var costs := PackedStringArray()
        for item in recipe.cost:
            costs.append("%s: %d / %d" % [SurvivalState.ITEMS.get(item,item),state.inventory.get(item,0),recipe.cost[item]])
        body.add_child(_label("\n".join(costs),18))
        var detail := _label(recipe.description,17)
        detail.custom_minimum_size.x = 230
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.add_child(detail)
        var error := state.recipe_error(kind)
        var button := _button("Pronto" if state.owns(kind) else ("Fabricar" if kind in SurvivalState.TOOLS or kind == "meal" else "Construir"),_recipe_callback(kind))
        button.disabled = error != ""
        body.add_child(button)
        build_buttons[kind] = button
        var status := _label(error,15)
        status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.add_child(status)

func update_zoom(distance: float) -> void:
    if is_instance_valid(zoom_in_button): zoom_in_button.disabled = distance <= 12.0
    if is_instance_valid(zoom_out_button): zoom_out_button.disabled = distance >= 48.0

func _recipe_callback(kind: String) -> Callable:
    return func():
        close_modal()
        build_requested.emit(kind)

func show_end(victory: bool, elapsed: float) -> void:
    set_playing(false)
    _new_modal("end", "Você voltou para casa" if victory else "A ilha venceu esta vez", "Você construiu seu barco e deixou a ilha após %d minutos de sobrevivência." % int(elapsed / 60.0) if victory else "Sua saúde chegou a zero. Água, cocos e peixe assado ajudam a sobreviver. Descanse na casa para recuperar saúde.")
    panel_content.add_child(_button("Menu", func(): show_menu(SurvivorSave.recover() != null)))

func toast(message: String, seconds: float = 3.2) -> void:
    toast_label.text = message
    toast_time = seconds
    toast_label.visible = true

func update_placement(kind: String, error: String) -> void:
    placement_kind = kind
    if kind == "":
        placement_label.text = ""
        return
    placement_label.text = "%s\n%s" % [SurvivalState.RECIPES[kind].title, error if error != "" else "Local livre. Toque em Confirmar."]
    placement_label.add_theme_color_override("font_color", Color(1, 0.64, 0.47) if error != "" else Color(0.76, 0.95, 0.65))

func _process(delta: float) -> void:
    # Wrapped labels recalculate their minimum after the first container layout.
    # Reapply the viewport bounds so an initial narrow layout cannot leave a tall panel.
    if is_instance_valid(panel): _resize_modal()
    toast_time = maxf(0, toast_time - delta)
    toast_label.visible = toast_time > 0
    if not is_playing or state == null:
        return
    ui_refresh += delta
    if ui_refresh < 0.12:
        return
    ui_refresh = 0
    stats.text = "Saúde %d • Fome %d • Água %d" % [state.health, state.hunger, state.thirst]
    activity_label.text = activity_name
    activity_progress.visible = activity_name != ""
    activity_progress.value = activity_fraction
    fishing_button.visible = true
    fishing_button.disabled = false
    action_button.disabled = target.is_empty() and placement_kind == ""
    objective_label.text = state.objective()
    var hour := fmod(8.0 + state.elapsed / SurvivalState.DAY_SECONDS * 24.0, 24.0)
    time_label.text = "Dia %d • %02d:%02d" % [1 + int(state.elapsed / SurvivalState.DAY_SECONDS), int(hour), int(fmod(hour, 1) * 60)]
    if placement_kind != "":
        action_button.text = "Confirmar"
        fishing_button.text = "Cancelar"
    else:
        fishing_button.text = "Pescar"
        action_button.text = "Explorar"
        if not target.is_empty():
            action_button.text = {"palm": "Coletar madeira", "tree":"Cortar árvore", "discovery":"Investigar", "rock": "Extrair pedra", "fiber": "Coletar fibra", "metal": "Recuperar metal", "loose_log":"Pegar tronco", "loose_stone":"Pegar pedras", "spring": "Beber água", "campfire": "Assar peixe", "house": "Descansar", "boat": "Embarcar"}.get(str(target.kind), "Explorar")
    if not target.is_empty() and placement_kind == "" and activity_name == "":
        var error := state.harvest_error(str(target.kind))
        if error != "": action_button.text = "Precisa de machado" if target.kind in ["tree","palm"] else "Precisa de picareta"
    if activity_name!="" and placement_kind=="":
        action_button.text="Cancelar ação"
        action_button.disabled=false

func toggle_inventory() -> void:
    if modal_mode == "":
        show_inventory()
    elif modal_mode in ["inventory","craft"]:
        close_modal()

func show_discovery(info: Dictionary) -> void:
    _new_modal("discovery",info.title,info.text)
    var rewards := PackedStringArray()
    for item in info.reward:
        rewards.append("%s +%d"%[SurvivalState.ITEMS.get(item,item),info.reward[item]])
    panel_content.add_child(_label("Recuperado: "+" • ".join(rewards),18))
    panel_content.add_child(_button("Continuar exploração",func(): close_modal()))

func show_journal() -> void:
    _new_modal("journal","Diário da ilha","Registros encontrados durante a exploração.")
    var count := 0
    for id in SurvivorWorld.DISCOVERIES:
        if state.discoveries.get(id,false):
            var info: Dictionary = SurvivorWorld.DISCOVERIES[id]
            panel_content.add_child(_label(info.title,22))
            var text := _label(info.text,18)
            text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            panel_content.add_child(text)
            count += 1
    if count == 0:
        panel_content.add_child(_label("Procure objetos junto aos destroços e às cavernas.",18))
    panel_content.add_child(_button("Voltar ao jogo",func(): close_modal()))
