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
	
	# RGDファイルをスクリプトエディタで開けるように自動設定
	_setup_rgd_file_association()
	
	# ArgodeSystemをautoloadに追加（まだ追加されていない場合）
	if not ProjectSettings.has_setting("autoload/ArgodeSystem"):
		add_autoload_singleton("ArgodeSystem", "res://addons/argode/core/ArgodeSystem.gd")
		print("🚀 Argode Plugin: Added ArgodeSystem to autoloads")
	
	print("✅ Argode Plugin: Initialization complete")

func _setup_rgd_file_association():
	"""RGDファイルをスクリプトエディタで開けるように自動設定"""
	
	# 1. 検索対象拡張子に .rgd を追加
	var search_extensions = ProjectSettings.get_setting("editor/script/search_in_file_extensions", PackedStringArray())
	if not search_extensions.has("rgd"):
		search_extensions.append("rgd")
		ProjectSettings.set_setting("editor/script/search_in_file_extensions", search_extensions)
		print("📄 Added 'rgd' to script search extensions")
	
	# 2. テキストファイルとして認識される拡張子に .rgd を追加
	var text_extensions = ProjectSettings.get_setting("editor/script/templates_search_path", "res://")
	# この設定は直接的な拡張子設定ではないので、代替手段を使用
	
	# 3. Godotのファイルタイプ設定に追加（可能であれば）
	if ProjectSettings.has_setting("editor/script/script_types"):
		var script_types = ProjectSettings.get_setting("editor/script/script_types", {})
		if not script_types.has("rgd"):
			script_types["rgd"] = "PlainText"
			ProjectSettings.set_setting("editor/script/script_types", script_types)
			print("📄 Added 'rgd' to script types")
	
	# 4. プロジェクトファイルフィルターに追加
	var file_dialog_access = ProjectSettings.get_setting("editor/script/file_dialog_access", [])
	if not file_dialog_access.has("*.rgd"):
		file_dialog_access.append("*.rgd")
		ProjectSettings.set_setting("editor/script/file_dialog_access", file_dialog_access)
		print("📄 Added '*.rgd' to file dialog access")
	
	# 設定を保存
	var error = ProjectSettings.save()
	if error == OK:
		print("✅ RGD file association settings saved automatically")
	else:
		print("⚠️ Failed to save RGD file association settings: ", error)

func _exit_tree():
	print("🔌 Argode Plugin: Exiting tree")
	
	# 設定をクリーンアップ（オプション - 通常は残しておく）
	_cleanup_rgd_file_association()
	
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

func _cleanup_rgd_file_association():
	"""プラグイン無効化時にRGD関連設定をクリーンアップ（オプション）"""
	
	# 検索対象拡張子から .rgd を削除
	var search_extensions = ProjectSettings.get_setting("editor/script/search_in_file_extensions", PackedStringArray())
	if search_extensions.has("rgd"):
		var new_extensions = PackedStringArray()
		for ext in search_extensions:
			if ext != "rgd":
				new_extensions.append(ext)
		ProjectSettings.set_setting("editor/script/search_in_file_extensions", new_extensions)
		print("📄 Removed 'rgd' from script search extensions")
	
	# その他の設定もクリーンアップ
	if ProjectSettings.has_setting("editor/script/script_types"):
		var script_types = ProjectSettings.get_setting("editor/script/script_types", {})
		if script_types.has("rgd"):
			script_types.erase("rgd")
			ProjectSettings.set_setting("editor/script/script_types", script_types)
			print("📄 Removed 'rgd' from script types")
	
	# 設定を保存
	var error = ProjectSettings.save()
	if error == OK:
		print("✅ RGD file association cleanup completed")
	else:
		print("⚠️ Failed to save cleanup settings: ", error)

func get_plugin_name():
	return "Argode"