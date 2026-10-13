extends CanvasLayer
class_name SurvivorHUD

signal action_requested
signal build_requested(kind: String)
signal rotate_requested
signal relocate_requested(kind: String)
signal storage_requested(kind: String, to_chest: bool)
signal confirm_build_requested
signal cancel_build_requested
signal equipment_requested(kind: String)
signal shortcut_requested(kind: String)
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
signal sprint_requested
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
var run_button: Button
var action_button: Button
var fishing_button: Button
var rotate_button: Button
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
var selected_item := ""
var inventory_tabs: Dictionary = {}
var inventory_title_font: SystemFont
var shortcut_bar: HBoxContainer
var shortcut_buttons: Array[Button] = []
var shortcut_visual_keys: Array[String] = []
const QUICK_BASE := ["stone_axe","stone_pickaxe","stone_knife","stone_spear","fishing_rod"]
const BAG_BG := Color(0.075,0.069,0.057,0.985)
const BAG_PANEL := Color(0.13,0.119,0.094,0.97)
const BAG_SLOT := Color(0.17,0.153,0.121,0.99)
const BAG_GOLD := Color(0.83,0.67,0.39)
const BAG_TEXT := Color(0.94,0.87,0.74)
const BAG_MUTED := Color(0.65,0.63,0.55)
const BAG_GREEN := Color(0.60,0.81,0.55)
const BAG_RED := Color(0.91,0.49,0.44)
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
    bag.add_theme_stylebox_override("normal",_bag_style(BAG_PANEL,true))
    bag.add_theme_font_override("font",_bag_font())
    bag.add_theme_color_override("font_color",BAG_TEXT)
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
    # Reachable sprint toggle outside the joystick's touch ownership area.
    run_button = _button("Correr",func(): sprint_requested.emit())
    run_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    run_button.offset_left = 338
    run_button.offset_right = 458
    run_button.offset_top = -125
    run_button.offset_bottom = -63
    run_button.add_theme_font_size_override("font_size",17)
    game_controls.add_child(run_button)
    var actions := VBoxContainer.new()
    actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    actions.offset_left = -210
    actions.offset_right = -20
    actions.offset_top = -298
    actions.offset_bottom = -24
    actions.alignment = BoxContainer.ALIGNMENT_END
    actions.add_theme_constant_override("separation",7)
    game_controls.add_child(actions)
    action_button = _button("Explorar", func(): action_requested.emit())
    actions.add_child(action_button)
    fishing_button = _button("Pescar", func(): fishing_requested.emit())
    actions.add_child(fishing_button)
    rotate_button = _button("Girar 90°",func(): rotate_requested.emit())
    rotate_button.visible = false
    actions.add_child(rotate_button)
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
    _create_shortcuts()
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

func _bag_style(color: Color, selected: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = BAG_GOLD if selected else Color(0.49,0.39,0.26,0.89)
    style.set_border_width_all(2 if selected else 1)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    style.shadow_color = Color(0.01,0.01,0.005,0.48)
    style.shadow_size = 3
    return style

func _bag_font() -> Font:
    if inventory_title_font == null:
        inventory_title_font = SystemFont.new()
        inventory_title_font.font_names = PackedStringArray(["Noto Serif","Georgia","serif"])
    return inventory_title_font

func _bag_heading(value: String, size: int = 23) -> Label:
    var label := _label(value,size)
    label.add_theme_font_override("font",_bag_font())
    label.add_theme_color_override("font_color",BAG_GOLD)
    label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.92))
    return label

func _bag_button(value: String, action: Callable, selected: bool = false) -> Button:
    var button := _button(value,action)
    button.add_theme_stylebox_override("normal",_bag_style(BAG_PANEL if selected else BAG_SLOT,selected))
    button.add_theme_stylebox_override("hover",_bag_style(Color(0.24,0.20,0.14),true))
    button.add_theme_stylebox_override("pressed",_bag_style(Color(0.26,0.21,0.14),true))
    button.add_theme_stylebox_override("disabled",_bag_style(Color(0.12,0.115,0.095)))
    button.add_theme_color_override("font_color",BAG_TEXT if selected else BAG_MUTED)
    button.add_theme_color_override("font_hover_color",BAG_GOLD)
    button.add_theme_font_size_override("font_size",17)
    button.add_theme_font_override("font",_bag_font())
    button.custom_minimum_size.y = 50
    return button

func _create_shortcuts() -> void:
    shortcut_bar = HBoxContainer.new()
    shortcut_bar.name = "ToolShortcuts"
    shortcut_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    shortcut_bar.offset_left = -179
    shortcut_bar.offset_right = 179
    shortcut_bar.offset_top = -77
    shortcut_bar.offset_bottom = -13
    shortcut_bar.alignment = BoxContainer.ALIGNMENT_CENTER
    shortcut_bar.add_theme_constant_override("separation",6)
    game_controls.add_child(shortcut_bar)
    for i in range(QUICK_BASE.size()):
        var index := i
        var button := _bag_button("",func(): _activate_shortcut(index))
        button.name = "Shortcut%d" % (i+1)
        button.custom_minimum_size = Vector2(64,62)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        shortcut_bar.add_child(button)
        var icon := TextureRect.new()
        icon.name = "ToolIcon"
        icon.texture = _icon(QUICK_BASE[i])
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(icon)
        icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        icon.offset_left = 13
        icon.offset_top = 5
        icon.offset_right = -10
        icon.offset_bottom = -9
        var number := _label(str(i+1),12)
        number.mouse_filter = Control.MOUSE_FILTER_IGNORE
        number.add_theme_color_override("font_color",BAG_GOLD)
        number.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        number.offset_left = 5
        number.offset_right = 20
        number.offset_top = 0
        number.offset_bottom = 18
        button.add_child(number)
        shortcut_buttons.append(button)
        shortcut_visual_keys.append("")

func _active_shortcut_kind(index: int) -> String:
    if index < 0 or index >= QUICK_BASE.size():
        return ""
    var base: String = QUICK_BASE[index]
    if base == "stone_axe" and state.owns("reinforced_axe"):
        return "reinforced_axe"
    if base == "stone_pickaxe" and state.owns("reinforced_pickaxe"):
        return "reinforced_pickaxe"
    return base

func _activate_shortcut(index: int) -> void:
    if not is_playing or modal_mode != "" or state == null:
        return
    var kind := _active_shortcut_kind(index)
    if kind != "" and state.owns(kind):
        shortcut_requested.emit(kind)

func update_shortcuts() -> void:
    if not is_playing or state == null:
        return
    for i in range(shortcut_buttons.size()):
        var button := shortcut_buttons[i]
        var kind := _active_shortcut_kind(i)
        var available := state.owns(kind)
        var selected := state.is_equipped(kind)
        var visual_key := "%s/%s/%s" % [kind,str(available),str(selected)]
        if visual_key == shortcut_visual_keys[i]:
            continue
        shortcut_visual_keys[i] = visual_key
        button.disabled = not available
        button.tooltip_text = str(SurvivalState.RECIPES[kind].title)+" • tecla "+str(i+1)
        button.add_theme_stylebox_override("normal",_bag_style(Color(0.29,0.24,0.14,0.98) if selected else BAG_SLOT,selected))
        var picture: TextureRect = button.get_node("ToolIcon")
        picture.texture = _icon(kind)
        picture.modulate = Color.WHITE if available else Color(0.42,0.40,0.35,0.7)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var digit := int(event.keycode)-int(KEY_1)
        if digit >= 0 and digit < QUICK_BASE.size() and is_playing and modal_mode == "":
            _activate_shortcut(digit)
            get_viewport().set_input_as_handled()

func set_playing(value: bool) -> void:
    is_playing = value
    game_controls.visible = value
    if value:
        update_shortcuts()
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
    blocker.color = Color(0.015,0.011,0.008,0.83) if mode in ["inventory","craft"] else Color(0.01, 0.035, 0.05, 0.67)
    blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(blocker)
    panel = PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _bag_style(BAG_BG,true) if mode in ["inventory","craft"] else _style(INK))
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
    heading.add_theme_color_override("font_color", BAG_GOLD if mode in ["inventory","craft"] else GOLD)
    if mode in ["inventory","craft"]:
        heading.add_theme_font_override("font",_bag_font())
    if mode in ["craft", "inventory", "pause", "storage"]:
        var header := HBoxContainer.new()
        heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(heading)
        var close := _bag_button("×",func(): close_modal(); resume_requested.emit()) if mode in ["inventory","craft"] else _button("×",func(): close_modal(); resume_requested.emit())
        close.custom_minimum_size = Vector2(56, 56)
        header.add_child(close)
        modal_top.add_child(header)
    else:
        modal_top.add_child(heading)
    var desc := _label(description, 19)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    modal_top.add_child(desc)
    if mode in ["inventory","craft"]:
        desc.visible = description != ""
        desc.add_theme_color_override("font_color",BAG_MUTED)
    _resize_modal()

func _resize_modal() -> void:
    if is_instance_valid(panel):
        var width := minf(1170.0 if modal_mode in ["inventory","craft"] else 650.0, root.size.x - 30.0)
        var height := minf(664.0 if modal_mode in ["inventory","craft"] else 610.0, root.size.y - 28.0)
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
    inventory_tabs.clear()
    joystick.active = is_playing

func show_menu(saved: bool, paused: bool = false) -> void:
    _new_modal("pause" if paused else "menu", "ILHA • ÚLTIMO VOO", "Um sobrevivente. Uma ilha desconhecida. Construa seu caminho de volta.\nGodot 3D • v1.1 (interface aprimorada)")
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
    if not is_playing or state == null:
        return
    inventory_tab = tab
    item_buttons.clear()
    var active_tab := "craft" if tab == "camp" else tab
    var labels := {"items":"MOCHILA","equipment":"EQUIPAMENTOS","craft":"CONSTRUÇÕES","recipes":"RECEITAS"}
    var subtitle := {
        "items":"Recursos e itens coletados na ilha",
        "equipment":"Gerencie os espaços do personagem e compare ferramentas",
        "craft":"Estruturas por nível e evolução do acampamento",
        "recipes":"Materiais, ferramentas, comida e pesquisas desbloqueadas",
        "camp":"Edificações instaladas e progresso da embarcação"
    }
    _new_modal("craft" if active_tab == "craft" else "inventory",
        str(labels.get(active_tab,"MOCHILA")),str(subtitle.get(tab,"")))
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation",8)
    modal_top.add_child(tabs)
    for entry in [["MOCHILA","items"],["EQUIPAMENTOS","equipment"],["CONSTRUÇÕES","craft"],["RECEITAS","recipes"]]:
        var tab_button := _bag_button(entry[0],_inventory_tab_callback(entry[1]),active_tab == entry[1])
        tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tabs.add_child(tab_button)
        inventory_tabs[entry[1]] = tab_button
    var summary := HBoxContainer.new()
    summary.add_theme_constant_override("separation",12)
    modal_top.add_child(summary)
    for kind in ["wood","stone","fiber","metal","rope","plank"]:
        var count := int(state.inventory.get(kind,0))
        var pill := _label("%s  %d" % [str(SurvivalState.ITEMS.get(kind,kind)),count],15)
        pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        pill.add_theme_color_override("font_color",BAG_TEXT if count > 0 else BAG_MUTED)
        summary.add_child(pill)
    var accent := HSeparator.new()
    accent.add_theme_constant_override("separation",4)
    modal_top.add_child(accent)
    if tab == "equipment":
        _equipment_panel()
    elif tab == "craft":
        _recipe_grid("ACAMPAMENTO • NÍVEL 1",["campfire","workbench","house","chest","bed","rain_collector","dock","boat"])
        _recipe_grid("CASA MODULAR",["floor_panel","wall_panel","door_panel","window_panel","roof_panel"])
        _recipe_grid("CONSTRUÇÕES REFORÇADAS • NÍVEL 2",["tool_rack","reinforced_wall","reinforced_roof"])
        panel_content.add_child(_bag_button("GERENCIAR ACAMPAMENTO",func(): show_inventory("camp")))
    elif tab == "recipes":
        _recipe_grid("FERRAMENTAS INICIAIS",["stone_knife","stone_axe","stone_pickaxe","stone_spear","fishing_rod"])
        _recipe_grid("APRIMORAMENTOS • NÍVEL 2",["reinforced_axe","reinforced_pickaxe"])
        _recipe_grid("MATERIAIS E INSUMOS",["rope","plank"])
        _recipe_grid("COZINHA",SurvivalState.FOOD_RECIPES)
    elif tab == "camp":
        _camp_panel()
    else:
        _inventory_grid()
    panel_content.add_child(_bag_button("VOLTAR À ILHA",func(): close_modal(); resume_requested.emit()))

func _inventory_tab_callback(tab: String) -> Callable:
    return func(): show_inventory(tab)

func _icon(kind: String) -> Texture2D:
    var path := "res://" + "assets/icons/items/" + kind + ".svg"
    return load(path) if ResourceLoader.exists(path) else null

func _inventory_grid() -> void:
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation",22)
    panel_content.add_child(columns)
    var bag_column := VBoxContainer.new()
    bag_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(bag_column)
    bag_column.add_child(_bag_heading("ITENS COLETADOS",21))
    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation",7)
    grid.add_theme_constant_override("v_separation",7)
    bag_column.add_child(grid)
    for kind in ["wood","stone","fiber","metal","rope","plank","coconut","raw_fish","meal","raw_crab","raw_meat","grilled_crab","cooked_meat","cave_crystal","stone_knife","stone_axe","stone_pickaxe","reinforced_axe","reinforced_pickaxe","stone_spear","fishing_rod"]:
        var title: String = SurvivalState.ITEMS.get(kind,SurvivalState.RECIPES.get(kind,{}).get("title",kind))
        var amount: int = state.inventory.get(kind,0)
        var slot := _button("%s\n×%d" % [title,amount],_item_callback(kind))
        slot.custom_minimum_size = Vector2(106,105)
        slot.add_theme_stylebox_override("normal",_bag_style(BAG_SLOT,selected_item == kind))
        slot.add_theme_stylebox_override("hover",_bag_style(Color(0.26,0.22,0.15),true))
        slot.add_theme_stylebox_override("pressed",_bag_style(Color(0.29,0.24,0.16),true))
        slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slot.add_theme_font_size_override("font_size",15)
        slot.text = ""
        var caption := _label("%s\n×%d" % [title,amount],13)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
        caption.add_theme_color_override("font_color",BAG_TEXT if amount > 0 else BAG_MUTED)
        slot.add_child(caption)
        caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
        caption.offset_top = -43
        caption.offset_bottom = -4
        var icon := TextureRect.new()
        icon.texture = _icon(kind)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot.add_child(icon)
        icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
        icon.offset_left = -25
        icon.offset_right = 25
        icon.offset_top = 5
        icon.offset_bottom = 55
        slot.add_theme_color_override("font_color",BAG_TEXT if amount > 0 else BAG_MUTED)
        grid.add_child(slot)
        item_buttons[kind] = slot
    var detail_box := PanelContainer.new()
    detail_box.add_theme_stylebox_override("panel",_bag_style(BAG_PANEL))
    bag_column.add_child(detail_box)
    item_detail = _label("Toque em um item para visualizar seus detalhes e comparar equipamentos.",16)
    item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item_detail.custom_minimum_size.y = 62
    detail_box.add_child(item_detail)
    bag_column.add_child(_bag_button("CONSUMIR ALIMENTO",func(): close_modal(); consume_requested.emit()))
    if selected_item != "" and item_buttons.has(selected_item):
        _item_callback(selected_item).call()
    var character_column := VBoxContainer.new()
    character_column.custom_minimum_size.x = 280
    columns.add_child(character_column)
    character_column.add_child(_bag_heading("SOBREVIVENTE",21))
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
    environment.environment.background_color = BAG_BG
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
    equipment.add_theme_color_override("font_color",BAG_TEXT)
    character_column.add_child(equipment)
    character_column.add_child(_bag_button("GERENCIAR EQUIPAMENTOS",func(): show_inventory("equipment")))
    character_column.add_child(_bag_button("DIÁRIO DE EXPLORAÇÃO",func(): show_journal()))

func _camp_panel() -> void:
    panel_content.add_child(_label("CONSTRUÇÕES DO ACAMPAMENTO",23))
    panel_content.add_child(_label("Para reposicionar, escolha Mover, caminhe até o novo local e confirme. Nenhum recurso será cobrado.",18))
    if state.buildings.is_empty():
        panel_content.add_child(_label("Construa primeiro a fogueira e a bancada.",18))
    for building in state.buildings:
        var kind: String = str(building.get("kind",""))
        var title: String = str(SurvivalState.RECIPES.get(kind,{}).get("title",kind))
        if kind == "boat":
            title += " • Etapa %d/5 (%s)" % [state.boat_stage(),SurvivalState.BOAT_STAGE_NAMES[state.boat_stage()]]
        var line := HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        panel_content.add_child(line)
        var label_node := _label(title,20)
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(label_node)
        if kind not in ["boat","dock"] and kind not in SurvivalState.MODULES:
            line.add_child(_button("Mover",_relocate_callback(kind)))
    if state.boat_stage() > 0 and not state.boat_ready():
        var next_stage := state.boat_stage()+1
        var supplies := PackedStringArray()
        for item in SurvivalState.BOAT_STAGE_COSTS[next_stage]:
            supplies.append("%s %d/%d" % [SurvivalState.ITEMS.get(item,item),state.inventory.get(item,0),SurvivalState.BOAT_STAGE_COSTS[next_stage][item]])
        panel_content.add_child(_label("Próxima etapa do barco: %s • %s" % [SurvivalState.BOAT_STAGE_NAMES[next_stage],", ".join(supplies)],18))
    if state.has_structure("chest"):
        panel_content.add_child(_button("Abrir baú de recursos",func(): show_storage()))
    if state.has_structure("rain_collector"):
        panel_content.add_child(_label("Coletor de chuva: %.1f / 12 medidas. Aproxime-se para beber." % state.rain_water,18))

func _relocate_callback(kind: String) -> Callable:
    return func():
        close_modal()
        resume_requested.emit()
        relocate_requested.emit(kind)

func show_storage() -> void:
    if not is_playing or state == null or not state.has_structure("chest"):
        return
    _new_modal("storage","BAÚ DO ACAMPAMENTO","Capacidade: 100 itens. Para guardar ou retirar, fique próximo ao baú.")
    var total := 0
    for kind in SurvivalState.STORABLE:
        total += int(state.storage.get(kind,0))
    panel_content.add_child(_label("Armazenamento %d / 100" % total,21))
    for kind in SurvivalState.STORABLE:
        var line := HBoxContainer.new()
        panel_content.add_child(line)
        var label_node := _label("%s: mochila %d • baú %d" % [SurvivalState.ITEMS.get(kind,kind),int(state.inventory.get(kind,0)),int(state.storage.get(kind,0))],18)
        label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(label_node)
        var deposit_kind: String = kind
        line.add_child(_button("Guardar 1",func(): storage_requested.emit(deposit_kind,true)))
        line.add_child(_button("Retirar 1",func(): storage_requested.emit(deposit_kind,false)))
    panel_content.add_child(_button("Fechar baú",func(): close_modal(); resume_requested.emit()))

func set_rotation_visible(value: bool) -> void:
    if is_instance_valid(rotate_button):
        rotate_button.visible = value

func _equipment_panel() -> void:
    panel_content.add_child(_bag_heading("ESPAÇOS EQUIPADOS",21))
    var slots := HBoxContainer.new()
    slots.add_theme_constant_override("separation",12)
    panel_content.add_child(slots)
    for entry in [["main_hand","MÃO PRINCIPAL"],["utility","FERRAMENTA"]]:
        var slot: String = entry[0]
        var container := PanelContainer.new()
        container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        container.add_theme_stylebox_override("panel",_bag_style(BAG_PANEL))
        slots.add_child(container)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation",12)
        container.add_child(row)
        var held: String = str(state.equipment.get(slot,""))
        var icon := TextureRect.new()
        icon.texture = _icon(held) if held != "" else null
        icon.custom_minimum_size = Vector2(70,68)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(icon)
        var body := VBoxContainer.new()
        body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(body)
        body.add_child(_bag_heading(str(entry[1]),16))
        var equipped_title := _label("VAZIO" if held == "" else str(SurvivalState.RECIPES[held].title),17)
        equipped_title.add_theme_color_override("font_color",BAG_TEXT if held != "" else BAG_MUTED)
        body.add_child(equipped_title)
        if held != "":
            var clear := _bag_button("DESEQUIPAR",_unequip_callback(slot))
            clear.custom_minimum_size.y = 42
            body.add_child(clear)
    panel_content.add_child(_bag_heading("FERRAMENTAS DISPONÍVEIS",21))
    var choices := GridContainer.new()
    choices.columns = 3
    choices.add_theme_constant_override("h_separation",10)
    choices.add_theme_constant_override("v_separation",10)
    panel_content.add_child(choices)
    for kind in SurvivalState.TOOLS:
        var available: bool = state.owns(kind)
        var equipped: bool = state.is_equipped(kind)
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel",_bag_style(BAG_PANEL if available else Color(0.105,0.103,0.094,0.98),equipped))
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choices.add_child(card)
        var contents := VBoxContainer.new()
        contents.add_theme_constant_override("separation",4)
        card.add_child(contents)
        var top := HBoxContainer.new()
        top.add_theme_constant_override("separation",8)
        contents.add_child(top)
        var tool_icon := TextureRect.new()
        tool_icon.texture = _icon(kind)
        tool_icon.custom_minimum_size = Vector2(55,55)
        tool_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tool_icon.modulate = Color.WHITE if available else Color(0.47,0.46,0.42,1)
        top.add_child(tool_icon)
        var label := _label(str(SurvivalState.RECIPES[kind].title),17)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        top.add_child(label)
        var status := _label("EQUIPADO" if equipped else ("DISPONÍVEL" if available else "NÃO CRIADO"),13)
        status.add_theme_color_override("font_color",BAG_GREEN if equipped else (BAG_TEXT if available else BAG_MUTED))
        contents.add_child(status)
        var actions := HBoxContainer.new()
        actions.add_theme_constant_override("separation",6)
        contents.add_child(actions)
        var compare := _bag_button("COMPARAR",_item_callback(kind))
        compare.custom_minimum_size.y = 42
        compare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        actions.add_child(compare)
        var equip := _bag_button("EQUIPAR",_equip_callback(kind),available and not equipped)
        equip.custom_minimum_size.y = 42
        equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        equip.disabled = not available or equipped
        actions.add_child(equip)
    var comparison := PanelContainer.new()
    comparison.add_theme_stylebox_override("panel",_bag_style(BAG_PANEL))
    panel_content.add_child(comparison)
    item_detail = _label("Selecione COMPARAR para ver a ferramenta e o rendimento real em relação ao equipamento atual.",16)
    item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item_detail.custom_minimum_size.y = 70
    comparison.add_child(item_detail)
    var help := _label("Machados, picaretas, faca e lança compartilham o espaço Ferramenta. A vara de pesca utiliza Mão principal.",15)
    help.add_theme_color_override("font_color",BAG_MUTED)
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_content.add_child(help)

func _equip_callback(kind: String) -> Callable:
    return func(): equipment_requested.emit(kind)

func _unequip_callback(slot: String) -> Callable:
    return func(): unequip_requested.emit(slot)

func _tool_yield(kind: String) -> int:
    match kind:
        "stone_axe": return 8
        "reinforced_axe": return 12
        "stone_pickaxe": return 6
        "reinforced_pickaxe": return 9
        "stone_knife": return 8
    return 0

func _tool_family(kind: String) -> String:
    if kind in ["stone_axe","reinforced_axe"]:
        return "madeira"
    if kind in ["stone_pickaxe","reinforced_pickaxe"]:
        return "pedra"
    if kind == "stone_knife":
        return "fibra"
    return "uso"

func _comparison_text(kind: String) -> String:
    if kind not in SurvivalState.TOOLS:
        return ""
    var slot := str(SurvivalState.TOOL_SLOTS[kind])
    var equipped := str(state.equipment.get(slot,""))
    var label := "MÃO PRINCIPAL" if slot == "main_hand" else "FERRAMENTA"
    if equipped == "":
        return "\n%s: vazio → %s" % [label,SurvivalState.RECIPES[kind].title]
    if equipped == kind:
        return "\n%s: equipado agora" % label
    var desc := "\n%s: %s → %s" % [label,SurvivalState.RECIPES[equipped].title,SurvivalState.RECIPES[kind].title]
    if _tool_family(equipped) == _tool_family(kind) and _tool_yield(equipped) > 0 and _tool_yield(kind) > 0:
        var before := _tool_yield(equipped)
        var after := _tool_yield(kind)
        var difference := after-before
        desc += "\nRendimento de %s: %d → %d (%+d por coleta)" % [_tool_family(kind),before,after,difference]
    else:
        desc += "\nFunções diferentes; equipar substitui o item do mesmo espaço."
    return desc

func _item_callback(kind: String) -> Callable:
    return func():
        if not is_instance_valid(item_detail): return
        var title: String = SurvivalState.ITEMS.get(kind,SurvivalState.RECIPES.get(kind,{}).get("title",kind))
        var descriptions := {"wood":"Troncos soltos podem ser recolhidos à mão. Para cortar árvores, fabrique um machado.","stone":"Pedras soltas podem ser recolhidas à mão. Para minerar rochas, fabrique uma picareta.","fiber":"Recolha à mão nas plantas. A faca aumenta a quantidade coletada.","metal":"Recupere ferragens nos destroços e nas cavernas para construir o barco.","coconut":"Recupera água e fome. Use Comer / beber.","raw_fish":"Asse na fogueira antes de comer.","meal":"Peixe assado: recupera fome e saúde.","raw_crab":"Recolha caranguejos na praia e prepare na fogueira.","raw_meat":"Cace javalis com a lança de pedra equipada e asse na fogueira.","grilled_crab":"Caranguejo assado: recupera 26 pontos de fome.","cooked_meat":"Carne assada: recupera fome e saúde.","rope":"Material intermediário feito com fibras. Use nos móveis e no barco.","plank":"Peça preparada na bancada. Necessária para o barco.","cave_crystal":"Cristal raro obtido após ativar dois selos de uma caverna. Pesquise a estação de aprimoramento."}
        var detail: String = descriptions.get(kind,SurvivalState.RECIPES.get(kind,{}).get("description",""))
        selected_item = kind
        item_detail.text = "%s • %d na mochila\n%s%s" % [title,state.inventory.get(kind,0),detail,_comparison_text(kind)]
        for id in item_buttons:
            var item_button: Button = item_buttons[id]
            item_button.add_theme_stylebox_override("normal",_bag_style(BAG_SLOT,id == kind))

func _recipe_unlocked(kind: String) -> bool:
    if kind == "tool_rack" and not bool(state.discoveries.get("east_vault",false)):
        return false
    if kind == "boat" and not bool(state.discoveries.get("sail_diagram",false)):
        return false
    if kind == "reinforced_roof" and not state.has_structure("reinforced_wall"):
        return false
    var recipe: Dictionary = SurvivalState.RECIPES[kind]
    for requirement in recipe.requires:
        if not state.owns(requirement):
            return false
    return true

func _recipe_grid(title: String,kinds: Array) -> void:
    panel_content.add_child(_bag_heading(title,21))
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",10)
    panel_content.add_child(grid)
    for kind in kinds:
        var recipe: Dictionary = SurvivalState.RECIPES[kind]
        var unlocked := _recipe_unlocked(kind)
        var error := state.recipe_error(kind)
        var owned: bool = state.owns(kind) and kind not in SurvivalState.MODULES and kind not in SurvivalState.FOOD_RECIPES and kind not in SurvivalState.MATERIAL_RECIPES
        var can_craft := error == ""
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel",_bag_style(BAG_PANEL if unlocked else Color(0.105,0.103,0.094,0.98)))
        grid.add_child(card)
        var body := VBoxContainer.new()
        body.add_theme_constant_override("separation",5)
        card.add_child(body)
        var header := HBoxContainer.new()
        header.add_theme_constant_override("separation",8)
        body.add_child(header)
        var heading := _bag_heading(str(recipe.title),18)
        heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(heading)
        var state_label := _label("PRONTO" if owned else ("DESBLOQUEADA" if unlocked else "BLOQUEADA"),12)
        state_label.add_theme_color_override("font_color",BAG_GREEN if owned or unlocked else BAG_MUTED)
        header.add_child(state_label)
        var icon := TextureRect.new()
        icon.texture = _icon(kind)
        icon.custom_minimum_size = Vector2(0,56)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.modulate = Color.WHITE if unlocked else Color(0.46,0.46,0.43,1)
        body.add_child(icon)
        var costs := VBoxContainer.new()
        costs.add_theme_constant_override("separation",2)
        body.add_child(costs)
        var satisfied := 0
        var total := 0
        for material in recipe.cost:
            var have := int(state.inventory.get(material,0))
            var needed := int(recipe.cost[material])
            var cost_label := _label("%s  %d / %d" % [str(SurvivalState.ITEMS.get(material,material)),have,needed],14)
            cost_label.add_theme_color_override("font_color",BAG_GREEN if have >= needed else BAG_RED)
            costs.add_child(cost_label)
            total += 1
            if have >= needed:
                satisfied += 1
        var progress := ProgressBar.new()
        progress.custom_minimum_size.y = 7
        progress.max_value = maxi(1,total)
        progress.value = satisfied
        progress.show_percentage = false
        progress.add_theme_stylebox_override("background",_bag_style(Color(0.12,0.11,0.09)))
        var fill := StyleBoxFlat.new()
        fill.bg_color = BAG_GREEN if satisfied == total else BAG_GOLD
        fill.set_corner_radius_all(3)
        progress.add_theme_stylebox_override("fill",fill)
        body.add_child(progress)
        var detail := _label(str(recipe.description),14)
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        detail.custom_minimum_size.x = 215
        detail.add_theme_color_override("font_color",BAG_MUTED)
        body.add_child(detail)
        var action := "FABRICAR" if kind in SurvivalState.TOOLS or kind in SurvivalState.MATERIAL_RECIPES or kind in SurvivalState.FOOD_RECIPES else "CONSTRUIR"
        var button := _bag_button("CONCLUÍDO" if owned else action,_recipe_callback(kind),can_craft)
        button.disabled = not can_craft
        body.add_child(button)
        build_buttons[kind] = button
        if error != "" and not owned:
            var status := _label(error,13)
            status.add_theme_color_override("font_color",BAG_MUTED if not unlocked else BAG_RED)
            status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            body.add_child(status)

func update_sprint(value: bool) -> void:
    if is_instance_valid(run_button):
        run_button.text = "Andar" if value else "Correr"

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
    update_shortcuts()
    activity_label.text = activity_name
    activity_progress.visible = activity_name != ""
    activity_progress.value = activity_fraction
    fishing_button.visible = true
    fishing_button.disabled = false
    action_button.disabled = target.is_empty() and placement_kind == ""
    objective_label.text = state.objective()
    var hour := fmod(8.0 + state.elapsed / SurvivalState.DAY_SECONDS * 24.0, 24.0)
    time_label.text = "Dia %d • %02d:%02d\n%s" % [1 + int(state.elapsed / SurvivalState.DAY_SECONDS), int(hour), int(fmod(hour, 1) * 60), SurvivorClimate.label_at(state.elapsed)]
    if placement_kind != "":
        action_button.text = "Confirmar"
        fishing_button.text = "Cancelar"
    else:
        fishing_button.text = "Pescar"
        action_button.text = "Explorar"
        if not target.is_empty():
            action_button.text = {"palm": "Coletar madeira", "tree":"Cortar árvore", "discovery":"Investigar", "rock": "Extrair pedra", "fiber": "Coletar fibra", "metal": "Recuperar metal", "loose_log":"Pegar tronco", "loose_stone":"Pegar pedras", "crab":"Pegar caranguejo", "boar":"Caçar javali", "cave":"Entrar na caverna", "cave_exit":"Sair da caverna", "cave_cache":"Investigar caixa", "cave_seal":"Ativar selo", "cave_vault":"Abrir relicário", "spring": "Beber água", "campfire": "Assar peixe", "house": "Descansar", "bed":"Descansar", "chest":"Abrir baú", "rain_collector":"Beber chuva", "door_panel":"Abrir porta" if not bool(target.get("door_open", false)) else "Fechar porta", "boat": "Embarcar"}.get(str(target.kind), "Explorar")
            if target.kind == "boat" and state.boat_stage() < 5:
                action_button.text = "Montar %s (%d/5)" % [SurvivalState.BOAT_STAGE_NAMES[state.boat_stage()+1],state.boat_stage()+1]
    if not target.is_empty() and placement_kind == "" and activity_name == "":
        var error := state.harvest_error(str(target.kind))
        if error != "":
            action_button.text = "Precisa de machado" if target.kind in ["tree","palm"] else ("Precisa de lança" if target.kind == "boar" else "Precisa de picareta")
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
    panel_content.add_child(_label("EXPLORAÇÃO E PESQUISA",22))
    for cave_id in ["east","roots"]:
        var area_name := "Caverna do Leste" if cave_id == "east" else "Gruta das raízes"
        var seals := int(bool(state.discoveries.get(cave_id+"_amber",false))) + int(bool(state.discoveries.get(cave_id+"_blue",false)))
        var opened := bool(state.discoveries.get(cave_id+"_vault",false))
        var status := "Relicário aberto" if opened else ("Selos %d/2 • procure os dois mecanismos" % seals)
        panel_content.add_child(_label("%s • %s" % [area_name,status],18))
    if state.has_structure("tool_rack"):
        panel_content.add_child(_label("Oficina nível 2: construída. Melhore o machado e a picareta perto dela.",18))
    elif bool(state.discoveries.get("east_vault",false)):
        panel_content.add_child(_label("Pesquisa concluída: cristais das cavernas permitem criar a Estação de aprimoramento na aba Construções.",18))
    else:
        panel_content.add_child(_label("Pesquisa bloqueada: encontre os selos do Leste e abra o relicário para desbloquear a oficina nível 2.",18))
    if count == 0:
        panel_content.add_child(_label("Procure objetos junto aos destroços e às cavernas.",18))
    panel_content.add_child(_button("Voltar ao jogo",func(): close_modal()))
