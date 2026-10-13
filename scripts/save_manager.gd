extends RefCounted
class_name SurvivorSave

const PATH := "user://survivor_save.json"

static func save_state(state: SurvivalState, path: String = PATH) -> Error:
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(state.to_data(), "\t"))
    file.flush()
    file.close()
    if load_state(temporary) == null:
        return ERR_FILE_CORRUPT
    # Keep the last valid save available if writing or replacing fails.
    if FileAccess.file_exists(path) and load_state(path) != null:
        var copy_error := DirAccess.copy_absolute(path, path + ".bak")
        if copy_error != OK:
            return copy_error
    return DirAccess.rename_absolute(temporary, path)

static func load_state(path: String = PATH) -> SurvivalState:
    if not FileAccess.file_exists(path):
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null or file.get_length() > 1048576:
        return null
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
        return null
    return SurvivalState.from_data(parser.data)

static func recover() -> SurvivalState:
    var state := load_state()
    if state == null:
        state = load_state(PATH + ".bak")
    return state
