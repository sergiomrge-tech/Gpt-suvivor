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
var birds: AudioStreamPlayer
var insects: AudioStreamPlayer
var rain: AudioStreamPlayer
var cave: AudioStreamPlayer
var mixer_levels: Dictionary = {"Ambiente":1.0,"Efeitos":1.0,"Passos":1.0}
var voices: Array[AudioStreamPlayer3D] = []
var voice_cursor := 0
var muted := false
var frozen := false
var active := false
var output_available := false
var last_effect := ""
const FOOTSTEP_VOLUME_DB := -23.0
const FOOTSTEP_FILTER_ALPHA := 0.17

func _ready() -> void:
    # Headless test sessions have no output mixer; do not allocate looping
    # playbacks there. Assets and routing remain available for validation.
    output_available = DisplayServer.get_name() != "headless"
    for bus in ["Ambiente","Efeitos","Passos"]:
        if AudioServer.get_bus_index(bus) < 0:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
    for kind in EFFECTS+["sea","wind","fire"]:
        var stream := load(STREAM_PATHS[kind]) as AudioStreamWAV
        if kind.begins_with("step_"):
            # Filter a private copy; the imported WAV is never modified globally.
            stream = stream.duplicate() as AudioStreamWAV
            stream.data = _soften_footstep(stream.data, stream.mix_rate)
        if kind in ["sea","wind","fire"]:
            stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
            stream.loop_begin = 0
            stream.loop_end = stream.data.size()/2
        streams[kind] = stream
    for kind in ["birds","insects","rain","cave"]:
        streams[kind] = SurvivorAmbientSynth.make(kind)
    sea = _ambient("sea",-21)
    wind = _ambient("wind",-24)
    birds = _ambient("birds",-55)
    insects = _ambient("insects",-58)
    rain = _ambient("rain",-60)
    cave = _ambient("cave",-60)
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

func _soften_footstep(pcm: PackedByteArray, sample_rate: int) -> PackedByteArray:
    # 16-bit mono PCM. Low-pass removes sharp heel clicks; fade avoids edge pops.
    var out := pcm.duplicate()
    var samples := out.size() / 2
    if samples < 2:
        return out
    var smooth := 0.0
    var fade_in := maxi(1,int(sample_rate * 0.010))
    var fade_out := maxi(1,int(sample_rate * 0.055))
    for i in range(samples):
        smooth = lerpf(smooth,float(pcm.decode_s16(i*2)),FOOTSTEP_FILTER_ALPHA)
        var start_fade := minf(1.0,float(i)/float(fade_in))
        var end_fade := minf(1.0,float(samples-1-i)/float(fade_out))
        var sample := clampi(roundi(smooth * 0.79 * minf(start_fade,end_fade)),-32768,32767)
        out.encode_s16(i*2,sample)
    return out

func set_mixer_level(bus_name: String, level: float) -> void:
    if not mixer_levels.has(bus_name):
        return
    var value := clampf(level,0.0,1.0)
    mixer_levels[bus_name] = value
    var index := AudioServer.get_bus_index(bus_name)
    if index >= 0:
        AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)))

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
        for loop in [sea,wind,birds,insects,rain,cave]:
            if not loop.playing: loop.play()
    else:
        for loop in [sea,wind,birds,insects,rain,cave]: loop.stop()
        fire.stop()
        for voice in voices: voice.stop()

func set_muted(value: bool) -> void:
    muted = value
    set_active(active)

func set_frozen(value: bool) -> void:
    frozen = value
    for player in [sea,wind,birds,insects,rain,cave,fire]+voices:
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
    if kind.begins_with("step_"):
        # Gentle, close-to-the-player foley without intrusive thumps or spikes.
        voice.bus = "Passos"
        voice.volume_db = FOOTSTEP_VOLUME_DB
        voice.pitch_scale = randf_range(0.965,1.035)
    else:
        voice.bus = "Efeitos"
        voice.volume_db = -9.0
        voice.pitch_scale = clampf(pitch,0.85,1.15)
    voice.play()

func update_environment(point: Vector3,terrain: SurvivorTerrain,world: SurvivorWorld,delta: float) -> void:
    var coastal_radius := terrain.radius_at_angle(atan2(point.z,point.x))*0.9757
    var distance := absf(Vector2(point.x,point.z).length()-coastal_radius)
    var desired := lerpf(-16,-34,clampf(distance/90.0,0,1))
    sea.volume_db = lerpf(sea.volume_db,desired,minf(1,delta*2))
    var in_cave := world.caves != null and world.caves.is_inside(point)
    var rainfall := SurvivorClimate.rainfall_at(world.state.elapsed)
    var sheltered := not world.near_structure(point,"house",9).is_empty()
    birds.volume_db = lerpf(birds.volume_db,-33.0 if not in_cave and terrain.daylight_amount > 0.35 and rainfall < 0.2 else -66.0,minf(1.0,delta*2.0))
    insects.volume_db = lerpf(insects.volume_db,-38.0 if not in_cave and terrain.daylight_amount < 0.25 and rainfall < 0.2 else -66.0,minf(1.0,delta*2.0))
    rain.volume_db = lerpf(rain.volume_db,(-34.0 if sheltered else -28.0) if not in_cave and rainfall > 0.15 else -66.0,minf(1.0,delta*2.0))
    cave.volume_db = lerpf(cave.volume_db,-33.0 if in_cave else -66.0,minf(1.0,delta*2.0))
    if in_cave: sea.volume_db = lerpf(sea.volume_db,-66.0,minf(1.0,delta*3.0))
    var camp := world.near_structure(point,"campfire",25)
    if not muted and active and output_available and not camp.is_empty():
        fire.position = camp.position+Vector3(0,0.8,0)
        if not fire.playing: fire.play()
    elif fire.playing:
        fire.stop()

func shutdown() -> void:
    active = false
    frozen = false
    for player in [sea,wind,birds,insects,rain,cave,fire]+voices:
        if is_instance_valid(player):
            player.stream_paused = false
            player.stop()
            player.stream = null
    streams.clear()

func _exit_tree() -> void:
    shutdown()
