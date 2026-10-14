extends RefCounted
class_name SurvivorPerformanceMonitor
const WINDOW := 600
var frames: Array[float] = []
var elapsed := 0.0
var peak_memory := 0.0
var latest: Dictionary = {}

func sample(delta: float) -> void:
    if delta<=0.0:
        return
    frames.append(delta*1000.0)
    if frames.size()>WINDOW:
        frames.pop_front()
    elapsed += delta
    peak_memory = maxf(peak_memory,Performance.get_monitor(Performance.MEMORY_STATIC))

func snapshot() -> Dictionary:
    var ordered := frames.duplicate()
    ordered.sort()
    var total := 0.0
    for value in frames:
        total += value
    var average := total/maxi(1,frames.size())
    var p95 := float(ordered[mini(ordered.size()-1,int(ordered.size()*0.95))]) if not ordered.is_empty() else 0.0
    latest = {"device":OS.get_model_name(),"godot":Engine.get_version_info().string,"samples":frames.size(),"mean_fps":1000.0/maxf(average,0.001) if not frames.is_empty() else 0.0,"p95_frame_ms":p95,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"peak_static_memory_mib":peak_memory/1048576.0,"render_memory_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"uptime_seconds":elapsed}
    return latest.duplicate(true)

func report() -> String:
    var stats := snapshot()
    return "Aparelho: %s\nFPS médio: %.1f\nTempo de quadro P95: %.1f ms\nChamadas de desenho: %d\nMemória estática: %.1f MB (pico %.1f MB)\nMemória de renderização: %.1f MB\nAmostras: %d\n\nDados da sessão deste aparelho. A memória de renderização pode não estar disponível no driver. Temperatura e bateria não são medidas pelo jogo." % [stats.device,stats.mean_fps,stats.p95_frame_ms,int(stats.draw_calls),stats.static_memory_mib,stats.peak_static_memory_mib,stats.render_memory_mib,stats.samples]

func save_report() -> Error:
    var file := FileAccess.open("user://performance_last.json",FileAccess.WRITE)
    if file==null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(snapshot(),"\t"))
    file.close()
    return OK
