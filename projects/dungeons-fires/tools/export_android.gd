extends SceneTree

# Run after editor import. Uses the native Godot Android exporter directly.
# The packaging step applies filtering, licensing, alignment and signing.
func _initialize() -> void:
	call_deferred("run_export")

func run_export() -> void:
	await create_timer(.5).timeout
	var args=OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Supply an absolute output APK path after --")
		quit(1)
		return
	var platform=EditorExportPlatformAndroid.new()
	var preset=platform.create_preset()
	var config=ConfigFile.new()
	if config.load("res://export_presets.cfg")!=OK:
		quit(1)
		return
	for key in config.get_section_keys("preset.0.options"):
		preset.set(key,config.get_value("preset.0.options",key))
	var result=platform.export_project(preset,true,args[0],0)
	for i in range(platform.get_message_count()):print(platform.get_message_text(i))
	print("ANDROID_EXPORT_RESULT=",result)
	call_deferred("quit",0 if result==OK else 1)
