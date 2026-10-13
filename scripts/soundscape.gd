extends Node3D
class_name SurvivorSoundscape

const EFFECTS := ["step_sand","step_grass","step_wood","chop","hammer","mine","rustle","splash","consume","ui"]
const STREAM_PATHS := {
    "step_sand":"res://assets/audio/step_sand.wav",
    "step_grass":"res://assets/audio/step_grass.wav",
    "step_wood":"res://assets/audio/step_wood.wav",
    "chop":"res://assets/audio/chop.wav",
    "hammer":"res://assets/audio/hammer.wav",
    "mine":"res://assets/audio/mine.wav",
    "rustle":"res://assets/audio/rustle.wav",
    "splash":"res://assets/audio/splash.wav",
    "consume":"res://assets/audio/consume.wav",
    "ui":"res://assets/audio/ui.wav",
    "sea":"res://assets/audio/sea.wav",
    "wind":"res://assets/audio/wind.wav",
    "fire":"res://assets/audio/fire.wav",
}
var streams: Dictionary = {}
var sea: AudioStreamPlayer
var wind: AudioStreamPlayer
var fire: AudioStreamPlayer3D
var voices: Array[AudioStreamPlayer3D] = []
var voice_cursor := 0
var muted := false
var frozen := false
var active := false
var output_available := false
var last_effect := ""

func _ready() -> void:
    # Headless test sessions have no output mixer; do not allocate looping
    # playbacks there. Assets and routing remain available for validation.
    output_available = DisplayServer.get_name() != "headless"
    for bus in ["Ambiente","Efeitos"]:
        if AudioServer.get_bus_index(bus) < 0:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
    for kind in EFFECTS+["sea","wind","fire"]:
        var stream := load(STREAM_PATHS[kind]) as AudioStreamWAV
        if kind in ["sea","wind","fire"]:
            stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
            stream.loop_begin = 0
            stream.loop_end = stream.data.size()/2
        streams[kind] = stream
    sea = _ambient("sea",-21)
    wind = _ambient("wind",-24)
    fire = AudioStreamPlayer3D.new()
    fire.bus = "Ambiente"
    fire.stream = streams.fire
    fire.unit_size = 5
    fire.max_distance = 25
    fire.volume_db = -12
    add_child(fire)
    for i in range(7):
        var voice := AudioStreamPlayer3D.new()
        voice.bus = "Efeitos"
        voice.unit_size = 6
        voice.max_distance = 28
        voice.volume_db = -9
        add_child(voice)
        voices.append(voice)

func _ambient(kind: String,volume: float) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = streams[kind]
    player.bus = "Ambiente"
    player.volume_db = volume
    add_child(player)
    return player

func set_active(value: bool) -> void:
    active = value
    if active and not muted and output_available:
        if not sea.playing: sea.play()
        if not wind.playing: wind.play()
    else:
        sea.stop()
        wind.stop()
        fire.stop()
        for voice in voices: voice.stop()

func set_muted(value: bool) -> void:
    muted = value
    set_active(active)

func set_frozen(value: bool) -> void:
    frozen = value
    for player in [sea,wind,fire]+voices:
        player.stream_paused = value

func play_effect(kind: String,point: Vector3,pitch: float = 1.0) -> void:
    if muted or frozen or not active or not streams.has(kind):
        return
    last_effect = kind
    if not output_available: return
    var voice := voices[voice_cursor]
    voice_cursor = (voice_cursor+1)%voices.size()
    voice.stop()
    voice.position = point
    voice.stream = streams[kind]
    voice.pitch_scale = clampf(pitch,0.85,1.15)
    voice.play()

func update_environment(point: Vector3,terrain: SurvivorTerrain,world: SurvivorWorld,delta: float) -> void:
    var coastal_radius := terrain.radius_at_angle(atan2(point.z,point.x))*0.9757
    var distance := absf(Vector2(point.x,point.z).length()-coastal_radius)
    var desired := lerpf(-16,-34,clampf(distance/90.0,0,1))
    sea.volume_db = lerpf(sea.volume_db,desired,minf(1,delta*2))
    var camp := world.near_structure(point,"campfire",25)
    if not muted and active and output_available and not camp.is_empty():
        fire.position = camp.position+Vector3(0,0.8,0)
        if not fire.playing: fire.play()
    elif fire.playing:
        fire.stop()

func shutdown() -> void:
    active = false
    frozen = false
    for player in [sea,wind,fire]+voices:
        if is_instance_valid(player):
            player.stream_paused = false
            player.stop()
            player.stream = null
    streams.clear()

func _exit_tree() -> void:
    shutdown()
