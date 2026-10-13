extends RefCounted
class_name SurvivorAmbientSynth

# Lightweight original, deterministic 16 kHz PCM beds: no licensed samples.
static func make(kind: String) -> AudioStreamWAV:
    const RATE := 16000
    const FRAMES := 32000
    var rng := RandomNumberGenerator.new()
    rng.seed = 23079 + absi(kind.hash())
    var data := PackedByteArray()
    data.resize(FRAMES * 2)
    var lowpass := 0.0
    for i in range(FRAMES):
        var t := float(i) / RATE
        var sample := 0.0
        match kind:
            "birds":
                var phrase := fposmod(t, 0.62)
                var envelope := sin(PI * clampf(phrase / 0.26, 0.0, 1.0)) * maxf(0.0, 1.0 - phrase / 0.43)
                sample = sin(TAU * (1370.0 * t + 220.0 * t * t)) * maxf(0.0, envelope) * 0.17
            "insects":
                var pulse := 0.5 + 0.5 * sin(TAU * 4.8 * t)
                sample = sin(TAU * 3450.0 * t) * pow(pulse, 5.0) * 0.13
            "rain":
                lowpass = lerpf(lowpass, rng.randf_range(-1.0, 1.0), 0.25)
                sample = lowpass * 0.18
            "cave":
                var drop := fposmod(t, 0.63)
                sample = sin(TAU * (690.0 * drop - 110.0 * drop * drop)) * exp(-drop * 26.0) * 0.21
        data.encode_s16(i * 2, clampi(roundi(sample * 32000.0), -32768, 32767))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = data
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = FRAMES
    return stream
