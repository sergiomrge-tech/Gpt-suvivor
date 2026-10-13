extends CanvasLayer
class_name SurvivorHUD

signal action_requested
signal build_requested(kind: String)
signal confirm_build_requested
signal cancel_build_requested
signal fishing_requested
signal consume_requested
signal save_requested
signal menu_requested
signal start_requested(load_save: bool)
signal sound_requested
signal journal_requested
signal quality_requested
signal resume_requested

var root: Control
var game_controls: Control
var joystick: SurvivorJoystick
var minimap: SurvivorMinimap
var stats: Label
var inventory_label: Label
var objective_label: Label
var time_label: Label
var action_button: Button
var fishing_button: Button
var toast_label: Label
var placement_label: Label
var panel: PanelContainer
var panel_content: VBoxContainer
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
var inventory_panel: PanelContainer
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
    inventory_panel = PanelContainer.new()
    inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    inventory_panel.offset_left = 16
    inventory_panel.offset_right = 446
    inventory_panel.offset_top = 112
    inventory_panel.offset_bottom = 300
    inventory_panel.add_theme_stylebox_override("panel",_style(INK))
    inventory_panel.visible = false
    game_controls.add_child(inventory_panel)
    var contents := VBoxContainer.new()
    contents.add_theme_constant_override("separation",8)
    inventory_panel.add_child(contents)
    inventory_label = _label("",18)
    contents.add_child(inventory_label)
    var journal := _button("Diário da ilha",func(): inventory_panel.visible=false; journal_requested.emit())
    journal.custom_minimum_size.y = 46
    journal.add_theme_font_size_override("font_size",18)
    contents.add_child(journal)
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
    joystick = SurvivorJoystick.new()
    joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.offset_left = 20
    joystick.offset_right = 190
    joystick.offset_top = -196
    joystick.offset_bottom = -26
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
    if not value: inventory_panel.visible = false
    if not joystick.active:
        joystick.reset()

func _new_modal(mode: String, title: String, description: String) -> void:
    close_modal()
    modal_mode = mode
    inventory_panel.visible = false
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
    panel.add_child(scroll)
    panel_content = VBoxContainer.new()
    panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel_content.add_theme_constant_override("separation", 14)
    scroll.add_child(panel_content)
    var heading := _label(title, 32)
    heading.add_theme_color_override("font_color", GOLD)
    if mode in ["craft", "pause"]:
        var header := HBoxContainer.new()
        heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(heading)
        var close := _button("×", func(): close_modal(); resume_requested.emit())
        close.custom_minimum_size = Vector2(56, 56)
        header.add_child(close)
        panel_content.add_child(header)
    else:
        panel_content.add_child(heading)
    var desc := _label(description, 19)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_content.add_child(desc)
    _resize_modal()

func _resize_modal() -> void:
    if is_instance_valid(panel):
        var width := minf(650.0, root.size.x - 32.0)
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
    _new_modal("pause" if paused else "menu", "ILHA • ÚLTIMO VOO", "Um sobrevivente. Uma ilha desconhecida. Construa seu caminho de volta.\nProtótipo Godot 3D • v0.4.0")
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
    _new_modal("intro", "O último voo", "A tempestade derrubou seu avião perto de uma ilha tropical. Você acorda na areia, cercado por destroços.\n\nMonte um acampamento, encontre água e alimento, explore as cavernas e recupere metal. Construa uma casa e um barco para deixar a ilha.\n\nPrimeiro passo: colete madeira nos coqueiros e pedras nas rochas. Abra Construir para fazer sua fogueira.")
    panel_content.add_child(_button("Acordar na praia", func(): close_modal(); start_requested.emit(false)))

func show_crafting() -> void:
    if not is_playing or state == null:
        return
    _new_modal("craft", "Acampamento e fabricação", "Selecione uma receita. Construções mostram uma prévia no chão; mova o personagem para escolher o local.")
    for kind in SurvivalState.RECIPES:
        var recipe: Dictionary = SurvivalState.RECIPES[kind]
        var costs := PackedStringArray()
        for item in recipe.cost:
            costs.append("%d/%d %s" % [state.inventory.get(item, 0), recipe.cost[item], SurvivalState.ITEMS.get(item, item)])
        var button := _button("%s\n%s" % [recipe.title, "  •  ".join(costs)], _recipe_callback(kind))
        button.custom_minimum_size.y = 74
        var error := state.recipe_error(kind)
        button.disabled = error != ""
        button.tooltip_text = recipe.description + ("\n" + error if error != "" else "")
        panel_content.add_child(button)
        build_buttons[kind] = button
        var detail := _label(error if error != "" else recipe.description, 15)
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        panel_content.add_child(detail)
    panel_content.add_child(_button("Fechar", func(): close_modal()))

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
    toast_time = maxf(0, toast_time - delta)
    toast_label.visible = toast_time > 0
    if not is_playing or state == null:
        return
    ui_refresh += delta
    if ui_refresh < 0.12:
        return
    ui_refresh = 0
    stats.text = "Saúde %d • Fome %d • Água %d" % [state.health, state.hunger, state.thirst]
    inventory_label.text = "Madeira: %d     Pedra: %d\nFibra: %d     Metal: %d\nCocos: %d     Peixes crus: %d\nRefeições: %d     Vara: %s" % [state.inventory.wood,state.inventory.stone,state.inventory.fiber,state.inventory.metal,state.inventory.coconut,state.inventory.raw_fish,state.inventory.meal,"sim" if state.owns("fishing_rod") else "não"]
    activity_label.text = activity_name
    activity_progress.visible = activity_name != ""
    activity_progress.value = activity_fraction
    fishing_button.visible = placement_kind != "" or state.owns("fishing_rod")
    fishing_button.disabled = placement_kind == "" and not can_fish
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
            action_button.text = {"palm": "Coletar madeira", "tree":"Cortar árvore", "discovery":"Investigar", "rock": "Coletar pedra", "fiber": "Coletar fibra", "metal": "Recuperar metal", "spring": "Beber água", "campfire": "Assar peixe", "house": "Descansar", "boat": "Embarcar"}.get(str(target.kind), "Explorar")
    if activity_name!="" and placement_kind=="":
        action_button.text="Cancelar ação"
        action_button.disabled=false

func toggle_inventory() -> void:
    if modal_mode == "":
        inventory_panel.visible = not inventory_panel.visible

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
