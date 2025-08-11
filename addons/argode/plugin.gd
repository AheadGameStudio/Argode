# plugin.gd
# Argode - Advanced visual novel engine for Godot
@tool
extends EditorPlugin

var rgd_loader: RgdFormatLoader

func _enter_tree():
	print("🔌 Argode Plugin: Entering tree")
	
	# RGDファイルローダーを登録
	rgd_loader = RgdFormatLoader.new()
	ResourceLoader.add_resource_format_loader(rgd_loader)
	print("📄 Argode Plugin: RGD file format loader registered")
	
	# ArgodeSystemをautoloadに追加（まだ追加されていない場合）
	if not ProjectSettings.has_setting("autoload/ArgodeSystem"):
		add_autoload_singleton("ArgodeSystem", "res://addons/argode/core/ArgodeSystem.gd")
		print("🚀 Argode Plugin: Added ArgodeSystem to autoloads")
	
	print("✅ Argode Plugin: Initialization complete")

func _exit_tree():
	print("🔌 Argode Plugin: Exiting tree")
	
	# RGDファイルローダーを削除
	if rgd_loader:
		ResourceLoader.remove_resource_format_loader(rgd_loader)
		rgd_loader = null
		print("📄 Argode Plugin: RGD file format loader removed")
	
	# autoloadを削除
	if ProjectSettings.has_setting("autoload/ArgodeSystem"):
		remove_autoload_singleton("ArgodeSystem")
		print("🚀 Argode Plugin: Removed ArgodeSystem from autoloads")
	
	print("✅ Argode Plugin: Cleanup complete")

func get_plugin_name():
	return "Argode"