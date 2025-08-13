# Plugin for Argode - Advanced visual novel engine for Godot
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
	
	# Argode設定をプロジェクト設定に追加
	_setup_project_settings()
	
	# ArgodeSystemをautoloadに追加（まだ追加されていない場合）
	if not ProjectSettings.has_setting("autoload/ArgodeSystem"):
		add_autoload_singleton("ArgodeSystem", "res://addons/argode/core/ArgodeSystem.gd")
		print("🚀 Argode Plugin: Added ArgodeSystem to autoloads")
	
	print("✅ Argode Plugin: Initialization complete")

func _setup_project_settings():
	"""Argode関連の設定をプロジェクト設定に追加"""
	
	# セーブ＆ロード設定
	_add_project_setting("argode/save/save_folder", "user://saves/", TYPE_STRING, "セーブファイルの保存フォルダ")
	_add_project_setting("argode/save/max_save_slots", 10, TYPE_INT, "最大セーブスロット数")
	_add_project_setting("argode/save/auto_save_interval", 300.0, TYPE_FLOAT, "オートセーブの間隔（秒）")
	
	# 暗号化設定
	_add_project_setting("argode/encryption/enable_encryption", true, TYPE_BOOL, "セーブファイル暗号化を有効化")
	_add_project_setting("argode/encryption/encryption_key", "argode_default_key_2024", TYPE_STRING, "暗号化キー")
	
	# スクリーンショット設定
	_add_project_setting("argode/screenshot/enable_screenshots", true, TYPE_BOOL, "セーブ時のスクリーンショット保存を有効化")
	_add_project_setting("argode/screenshot/screenshot_width", 200, TYPE_INT, "スクリーンショットの幅")
	_add_project_setting("argode/screenshot/screenshot_height", 150, TYPE_INT, "スクリーンショットの高さ")
	_add_project_setting("argode/screenshot/screenshot_quality", 0.8, TYPE_FLOAT, "スクリーンショットの品質（0.0-1.0）")
	
	# UI設定
	_add_project_setting("argode/ui/default_text_speed", 0.05, TYPE_FLOAT, "デフォルトテキスト表示速度（秒/文字）")
	_add_project_setting("argode/ui/auto_advance_time", 3.0, TYPE_FLOAT, "オートモードの進行時間（秒）")
	_add_project_setting("argode/ui/skip_unread", false, TYPE_BOOL, "未読テキストもスキップ可能にする")
	
	# オーディオ設定
	_add_project_setting("argode/audio/master_volume", 1.0, TYPE_FLOAT, "マスターボリューム")
	_add_project_setting("argode/audio/bgm_volume", 0.8, TYPE_FLOAT, "BGMボリューム")
	_add_project_setting("argode/audio/se_volume", 0.9, TYPE_FLOAT, "SEボリューム")
	_add_project_setting("argode/audio/voice_volume", 1.0, TYPE_FLOAT, "ボイスボリューム")
	
	# デバッグ設定
	_add_project_setting("argode/debug/enable_debug_mode", false, TYPE_BOOL, "デバッグモードを有効化")
	_add_project_setting("argode/debug/log_level", 1, TYPE_INT, "ログレベル (0=エラー, 1=警告, 2=情報, 3=詳細)")
	
	print("⚙️ Argode project settings configured")

func _add_project_setting(path: String, default_value: Variant, type: Variant.Type, hint_string: String = ""):
	"""プロジェクト設定を追加（既存の場合は更新しない）"""
	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, default_value)
		
		# 設定のメタデータを追加（エディタでの表示用）
		var property_info = {
			"name": path,
			"type": type,
			"hint_string": hint_string
		}
		
		# 設定を保存
		ProjectSettings.save()
		print("⚙️ Added project setting: %s = %s" % [path, str(default_value)])

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