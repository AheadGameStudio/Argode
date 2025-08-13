# SaveLoadManager.gd
# Ren'Py風セーブ・ロードシステム - ゲーム状態の保存と復元
extends Node
class_name SaveLoadManager

# === シグナル ===
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)
signal settings_saved()
signal settings_loaded()
signal settings_save_failed(error: String)
signal settings_load_failed(error: String)

# === セーブデータ構造 ===
const SAVE_VERSION = "2.0"
const SAVE_EXTENSION = ".save"
const SAVE_FOLDER = "user://saves/"
const AUTO_SAVE_SLOT = 0  # スロット0をオートセーブ専用に
var max_save_slots = 10   # デフォルト10スロット（設定可能）

# === 設定ファイル ===
const SETTINGS_FILE = "user://argode_settings.cfg"
const SETTINGS_VERSION = "1.0"

# === デフォルト設定値 ===
var default_settings = {
	"audio": {
		"master_volume": 1.0,
		"bgm_volume": 0.8,
		"se_volume": 0.9,
		"voice_volume": 1.0,
		"mute_audio": false
	},
	"display": {
		"fullscreen": false,
		"window_size": Vector2i(1280, 720),
		"vsync": true,
		"show_fps": false
	},
	"text": {
		"text_speed": 1.0,
		"auto_play_speed": 2.0,
		"skip_read_text": true,
		"skip_unread_text": false,
		"text_size_scale": 1.0
	},
	"ui": {
		"show_text_window": true,
		"ui_scale": 1.0,
		"message_alpha": 0.8,
		"quick_menu_enabled": true
	},
	"accessibility": {
		"high_contrast": false,
		"color_blind_mode": "none",  # "none", "protanopia", "deuteranopia", "tritanopia"
		"screen_reader": false,
		"subtitle_enabled": true
	},
	"system": {
		"language": "ja",  # "ja", "en"
		"auto_save_interval": 300.0,  # 5分間隔でオートセーブ
		"confirm_quit": true,
		"confirm_overwrite": true
	}
}

# === 現在の設定 ===
var current_settings: Dictionary = {}

# === 暗号化設定 ===
const ENABLE_ENCRYPTION = true
const ENCRYPTION_KEY = "argode_save_key_2024"  # 本番では環境変数や設定ファイルから取得推奨

# === スクリーンショット設定 ===
const ENABLE_SCREENSHOTS = true
const SCREENSHOT_WIDTH = 200
const SCREENSHOT_HEIGHT = 150
const SCREENSHOT_QUALITY = 0.7  # JPEG品質 (0.0-1.0)

# === マネージャー参照 ===
var argode_system: Node = null

# === セーブデータ情報キャッシュ ===
var save_info_cache: Dictionary = {}

# === 一時スクリーンショット機能 ===
var temp_screenshot_data: String = ""  # Base64エンコードされた一時スクリーンショット
var temp_screenshot_timestamp: float = 0.0  # 撮影タイムスタンプ
const TEMP_SCREENSHOT_LIFETIME = 300.0  # 一時スクショの有効期限（5分）

func _ready():
	print("💾 SaveLoadManager: Initializing save/load system...")
	print("🔐 Encryption: " + ("Enabled" if ENABLE_ENCRYPTION else "Disabled"))
	_ensure_save_directory()
	_load_save_info_cache()
	_initialize_settings()
	print("⚙️ SaveLoadManager: Settings system initialized")

func initialize(adv_system: Node):
	"""ArgodeSystemからの参照を設定"""
	argode_system = adv_system
	print("💾 SaveLoadManager: Connected to ArgodeSystem")

func _ensure_save_directory():
	"""セーブディレクトリの存在確認・作成"""
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		var dir = DirAccess.open("user://")
		if dir:
			dir.make_dir("saves")
			print("📁 SaveLoadManager: Created saves directory")

# === セーブ機能 ===

func save_game(slot: int, save_name: String = "") -> bool:
	"""ゲーム状態をセーブ"""
	if slot < 0 or slot >= max_save_slots:
		push_error("❌ SaveLoadManager: Invalid save slot: " + str(slot))
		save_failed.emit(slot, "Invalid slot number")
		return false
	
	print("💾 SaveLoadManager: Saving game to slot " + str(slot) + "...")
	
	# セーブデータを収集
	var save_data = _collect_game_state()
	
	# セーブ名の設定（オートセーブかユーザーセーブかで分ける）
	if slot == AUTO_SAVE_SLOT:
		save_data["save_name"] = "Auto Save"
	else:
		save_data["save_name"] = save_name if save_name != "" else ("Save " + str(slot))
	
	save_data["save_time"] = Time.get_unix_time_from_system()
	save_data["save_date_string"] = Time.get_datetime_string_from_system()
	save_data["version"] = SAVE_VERSION
	save_data["slot"] = slot
	
	# スクリーンショットを撮影
	if ENABLE_SCREENSHOTS:
		var screenshot_b64 = _get_screenshot_for_save()
		if screenshot_b64 != "":
			save_data["screenshot"] = screenshot_b64
			print("📷 SaveLoadManager: Screenshot added to save data")
	
	# 一時スクリーンショットをクリア（セーブ後は不要）
	_clear_temp_screenshot()
	
	# ファイルに書き込み
	var file_path = SAVE_FOLDER + "slot_" + str(slot) + SAVE_EXTENSION
	var file = null
	
	if ENABLE_ENCRYPTION:
		# 暗号化して保存
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, ENCRYPTION_KEY)
	else:
		# 平文で保存
		file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("❌ SaveLoadManager: Failed to open save file: " + file_path)
		save_failed.emit(slot, "Failed to create save file")
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	# キャッシュ更新
	save_info_cache[slot] = {
		"save_name": save_data["save_name"],
		"save_date": save_data["save_date_string"],
		"save_time": save_data["save_time"],
		"script_file": save_data.get("current_script_path", ""),
		"line_number": save_data.get("current_line_index", 0),
		"has_screenshot": save_data.has("screenshot")
	}
	
	var save_type = "Auto-save" if slot == AUTO_SAVE_SLOT else "Manual save"
	print("✅ SaveLoadManager: " + save_type + " completed successfully to slot " + str(slot))
	game_saved.emit(slot)
	return true

func _collect_game_state() -> Dictionary:
	"""現在のゲーム状態を収集"""
	var state = {}
	
	# スクリプト実行状態
	if argode_system and argode_system.Player:
		var player = argode_system.Player
		state["current_script_path"] = player.current_script_path
		state["current_line_index"] = player.current_line_index
		state["call_stack"] = player.call_stack.duplicate()
		
		# スクリプト内容も保存（ファイルが変更されていた場合の対策）
		if player.script_lines:
			state["script_lines"] = player.script_lines.duplicate()
			state["label_map"] = player.label_map.duplicate()
	
	# 変数状態
	if argode_system and argode_system.VariableManager:
		var all_vars = argode_system.VariableManager.get_all_variables()
		state["variables"] = all_vars
		print("💾 Saving variables: ", all_vars.size(), " variables")
		for var_name in all_vars:
			print("  - ", var_name, " = ", all_vars[var_name])
	
	# キャラクター表示状態
	if argode_system and argode_system.CharacterManager:
		state["characters"] = _collect_character_state()
	
	# 背景状態
	if argode_system and argode_system.LayerManager:
		state["background"] = _collect_background_state()
	
	# オーディオ状態
	if argode_system and argode_system.AudioManager:
		state["audio"] = _collect_audio_state()
	
	print("📊 SaveLoadManager: Collected game state with " + str(state.size()) + " categories")
	return state

func _collect_character_state() -> Dictionary:
	"""キャラクター表示状態を収集"""
	var char_state = {}
	
	var layer_manager = argode_system.LayerManager
	if layer_manager and layer_manager.character_nodes:
		for char_name in layer_manager.character_nodes:
			var char_node = layer_manager.character_nodes[char_name]
			if char_node:
				char_state[char_name] = {
					"visible": char_node.visible,
					"position": char_node.position,
					"modulate": char_node.modulate,
					"texture_path": char_node.texture.resource_path if char_node.texture else ""
				}
	
	return char_state

func _collect_background_state() -> Dictionary:
	"""背景状態を収集"""
	var bg_state = {}
	
	var layer_manager = argode_system.LayerManager
	if layer_manager and layer_manager.current_background:
		var bg = layer_manager.current_background
		bg_state["type"] = bg.get_class()
		
		if bg is TextureRect:
			bg_state["texture_path"] = bg.texture.resource_path if bg.texture else ""
		elif bg is ColorRect:
			bg_state["color"] = bg.color
		
		bg_state["modulate"] = bg.modulate
		bg_state["visible"] = bg.visible
	
	return bg_state

func _collect_audio_state() -> Dictionary:
	"""オーディオ状態を収集"""
	var audio_state = {}
	
	var audio_manager = argode_system.AudioManager
	if audio_manager:
		# BGM状態
		if audio_manager.bgm_player and audio_manager.bgm_player.playing:
			audio_state["bgm"] = {
				"stream_path": audio_manager.bgm_player.stream.resource_path if audio_manager.bgm_player.stream else "",
				"position": audio_manager.bgm_player.get_playback_position(),
				"volume": audio_manager.bgm_player.volume_db
			}
		
		# SE状態（通常はセーブしないが、長時間SEがある場合用）
		audio_state["volume_settings"] = {
			"master_volume": argode_system.VariableManager.get_variable("master_volume"),
			"bgm_volume": argode_system.VariableManager.get_variable("bgm_volume"),
			"se_volume": argode_system.VariableManager.get_variable("se_volume")
		}
	
	return audio_state

# === ロード機能 ===

func load_game(slot: int) -> bool:
	"""ゲーム状態をロード"""
	if slot < 0 or slot >= max_save_slots:
		push_error("❌ SaveLoadManager: Invalid load slot: " + str(slot))
		load_failed.emit(slot, "Invalid slot number")
		return false
	
	var file_path = SAVE_FOLDER + "slot_" + str(slot) + SAVE_EXTENSION
	if not FileAccess.file_exists(file_path):
		push_error("❌ SaveLoadManager: Save file not found: " + file_path)
		load_failed.emit(slot, "Save file not found")
		return false
	
	print("📂 SaveLoadManager: Loading game from slot " + str(slot) + "...")
	
	var file = null
	
	if ENABLE_ENCRYPTION:
		# 暗号化されたファイルを復号化して読み込み
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, ENCRYPTION_KEY)
	else:
		# 平文ファイルを読み込み
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("❌ SaveLoadManager: Failed to open save file: " + file_path)
		load_failed.emit(slot, "Failed to open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("❌ SaveLoadManager: Invalid save file format: " + file_path)
		load_failed.emit(slot, "Invalid save file format")
		return false
	
	var save_data = json.data
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("❌ SaveLoadManager: Invalid save data structure")
		load_failed.emit(slot, "Invalid save data structure")
		return false
	
	# バージョンチェック
	if save_data.get("version", "1.0") != SAVE_VERSION:
		push_warning("⚠️ SaveLoadManager: Save file version mismatch. Attempting to load anyway.")
	
	# ゲーム状態を復元
	_restore_game_state(save_data)
	
	print("✅ SaveLoadManager: Game loaded successfully from slot " + str(slot))
	game_loaded.emit(slot)
	return true

func _restore_game_state(save_data: Dictionary):
	"""セーブデータからゲーム状態を復元"""
	print("🔄 SaveLoadManager: Restoring game state...")
	
	# 変数状態を復元
	if "variables" in save_data and argode_system.VariableManager:
		for var_name in save_data["variables"]:
			var value = save_data["variables"][var_name]
			argode_system.VariableManager.set_variable_direct(var_name, value)
			print("🔄 Restoring variable: ", var_name, " = ", value)
		print("📊 SaveLoadManager: Restored " + str(save_data["variables"].size()) + " variables")
	
	# キャラクター状態を復元
	if "characters" in save_data:
		_restore_character_state(save_data["characters"])
	
	# 背景状態を復元
	if "background" in save_data:
		_restore_background_state(save_data["background"])
	
	# オーディオ状態を復元
	if "audio" in save_data:
		_restore_audio_state(save_data["audio"])
	
	# スクリプト状態を復元（最後に実行）
	if "current_script_path" in save_data:
		_restore_script_state(save_data)
	
	# ロード後も一時スクリーンショットをクリア
	_clear_temp_screenshot()

func _restore_character_state(char_data: Dictionary):
	"""キャラクター状態を復元"""
	if not argode_system.CharacterManager or not argode_system.LayerManager:
		return
	
	# 現在のキャラクターをすべて非表示
	var layer_manager = argode_system.LayerManager
	for char_name in layer_manager.character_nodes.keys():
		layer_manager.hide_character(char_name)
	
	# セーブされたキャラクター状態を復元
	for char_name in char_data:
		var char_state = char_data[char_name]
		if char_state.get("visible", false) and char_state.get("texture_path", "") != "":
			# キャラクターを表示（簡略版、詳細位置は後で設定）
			var char_manager = argode_system.CharacterManager
			char_manager.show_character(char_name, "normal", "center")  # デフォルト表情・位置
			
			# 詳細状態を設定
			await get_tree().process_frame  # キャラクター作成を待つ
			if char_name in layer_manager.character_nodes:
				var char_node = layer_manager.character_nodes[char_name]
				char_node.position = char_state.get("position", Vector2.ZERO)
				char_node.modulate = char_state.get("modulate", Color.WHITE)
	
	print("👤 SaveLoadManager: Restored character states")

func _restore_background_state(bg_data: Dictionary):
	"""背景状態を復元"""
	if not argode_system.LayerManager:
		return
	
	var layer_manager = argode_system.LayerManager
	var bg_type = bg_data.get("type", "")
	
	if bg_type == "ColorRect":
		# ColorRect背景（scene black用）
		var color_bg = ColorRect.new()
		color_bg.color = bg_data.get("color", Color.BLACK)
		color_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer_manager._set_background_immediately(color_bg)
	elif bg_type == "TextureRect" and bg_data.get("texture_path", "") != "":
		# TextureRect背景
		var texture_bg = TextureRect.new()
		texture_bg.texture = load(bg_data["texture_path"])
		texture_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer_manager._set_background_immediately(texture_bg)
	
	print("🖼️ SaveLoadManager: Restored background state")

func _restore_audio_state(audio_data: Dictionary):
	"""オーディオ状態を復元"""
	if not argode_system.AudioManager:
		return
	
	# BGMを復元
	if "bgm" in audio_data and audio_data["bgm"].get("stream_path", "") != "":
		var bgm_info = audio_data["bgm"]
		var audio_manager = argode_system.AudioManager
		
		# BGMを読み込んで再生
		var audio_stream = load(bgm_info["stream_path"])
		if audio_stream:
			audio_manager.play_bgm("", audio_stream)
			
			# 位置と音量を復元
			await get_tree().process_frame  # 再生開始を待つ
			if audio_manager.bgm_player:
				audio_manager.bgm_player.seek(bgm_info.get("position", 0.0))
				audio_manager.bgm_player.volume_db = bgm_info.get("volume", 0.0)
	
	# 音量設定を復元
	if "volume_settings" in audio_data:
		var vol_settings = audio_data["volume_settings"]
		for setting in vol_settings:
			if argode_system.VariableManager:
				argode_system.VariableManager.set_variable_direct(setting, vol_settings[setting])
	
	print("🎵 SaveLoadManager: Restored audio state")

func _restore_script_state(save_data: Dictionary):
	"""スクリプト実行状態を復元"""
	if not argode_system.Player:
		return
	
	var player = argode_system.Player
	var script_path = save_data.get("current_script_path", "")
	var line_index = save_data.get("current_line_index", 0)
	
	if script_path != "":
		# スクリプトファイルを読み込んで実行位置に移動
		if save_data.has("script_lines") and save_data.has("label_map"):
			# セーブ時のスクリプト内容を使用（ファイル変更対策）
			player.script_lines = save_data["script_lines"]
			player.label_map = save_data["label_map"]
			player.current_script_path = script_path
		else:
			# ファイルから読み直し
			player.load_script(script_path)
		
		player.current_line_index = line_index
		player.call_stack = save_data.get("call_stack", [])
		
		print("📜 SaveLoadManager: Restored script state - " + script_path + ":" + str(line_index))

# === セーブ情報取得 ===

func get_save_info(slot: int) -> Dictionary:
	"""セーブスロットの情報を取得"""
	if slot in save_info_cache:
		return save_info_cache[slot].duplicate()
	
	var file_path = SAVE_FOLDER + "slot_" + str(slot) + SAVE_EXTENSION
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = null
	
	if ENABLE_ENCRYPTION:
		# 暗号化されたファイルから情報を読み込み
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, ENCRYPTION_KEY)
	else:
		# 平文ファイルから情報を読み込み
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var save_data = json.data
	if typeof(save_data) != TYPE_DICTIONARY:
		return {}
	
	var info = {
		"save_name": save_data.get("save_name", "Save " + str(slot)),
		"save_date": save_data.get("save_date_string", "Unknown"),
		"save_time": save_data.get("save_time", 0),
		"script_file": save_data.get("current_script_path", ""),
		"line_number": save_data.get("current_line_index", 0),
		"has_screenshot": save_data.has("screenshot")
	}
	
	# スクリーンショットのBase64データも含める（UIで使用可能）
	if save_data.has("screenshot"):
		info["screenshot"] = save_data["screenshot"]
	
	save_info_cache[slot] = info
	return info

func get_all_save_info() -> Dictionary:
	"""すべてのセーブスロット情報を取得"""
	var all_info = {}
	for slot in range(max_save_slots):
		var info = get_save_info(slot)
		if not info.is_empty():
			all_info[slot] = info
	return all_info

func delete_save(slot: int) -> bool:
	"""セーブデータを削除"""
	var file_path = SAVE_FOLDER + "slot_" + str(slot) + SAVE_EXTENSION
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(SAVE_FOLDER)
		if dir and dir.remove("slot_" + str(slot) + SAVE_EXTENSION) == OK:
			save_info_cache.erase(slot)
			print("🗑️ SaveLoadManager: Deleted save slot " + str(slot))
			return true
	
	return false

func _load_save_info_cache():
	"""起動時にセーブ情報キャッシュを読み込み"""
	save_info_cache.clear()
	for slot in range(max_save_slots):
		get_save_info(slot)  # 副作用でキャッシュに格納される
	
	print("💾 SaveLoadManager: Loaded save info cache for " + str(save_info_cache.size()) + " slots")

# === オートセーブ機能 ===

func auto_save() -> bool:
	"""オートセーブを実行（スロット0使用）"""
	return save_game(AUTO_SAVE_SLOT, "Auto Save")

func load_auto_save() -> bool:
	"""オートセーブをロード"""
	return load_game(AUTO_SAVE_SLOT)

# === スロット設定 ===

func set_max_save_slots(new_max: int):
	"""最大セーブスロット数を設定（1以上、オートセーブ除く）"""
	if new_max >= 1:
		max_save_slots = new_max + 1  # オートセーブ分を追加
		print("💾 SaveLoadManager: Max save slots set to " + str(new_max) + " (+ 1 auto-save)")

func get_user_save_slots() -> int:
	"""ユーザーが使用できるセーブスロット数を取得（オートセーブ除く）"""
	return max(max_save_slots - 1, 0)

func is_auto_save_slot(slot: int) -> bool:
	"""指定されたスロットがオートセーブ専用かどうか"""
	return slot == AUTO_SAVE_SLOT

# === スクリーンショット機能 ===

func capture_temp_screenshot() -> bool:
	"""一時的なスクリーンショットを撮影（メニューを開く前などに呼び出し）"""
	if not ENABLE_SCREENSHOTS:
		print("📷 SaveLoadManager: Screenshot feature is disabled")
		return false
	
	var screenshot_data = _capture_screenshot()
	if screenshot_data != "":
		temp_screenshot_data = screenshot_data
		temp_screenshot_timestamp = Time.get_unix_time_from_system()
		print("📷 SaveLoadManager: Temporary screenshot captured (valid for " + str(TEMP_SCREENSHOT_LIFETIME) + " seconds)")
		return true
	else:
		print("⚠️ SaveLoadManager: Failed to capture temporary screenshot")
		return false

func _clear_temp_screenshot():
	"""一時スクリーンショットをクリア"""
	if temp_screenshot_data != "":
		print("🗑️ SaveLoadManager: Cleared temporary screenshot")
		temp_screenshot_data = ""
		temp_screenshot_timestamp = 0.0

func _is_temp_screenshot_valid() -> bool:
	"""一時スクリーンショットが有効かどうかチェック"""
	if temp_screenshot_data == "":
		return false
	
	var current_time = Time.get_unix_time_from_system()
	var age = current_time - temp_screenshot_timestamp
	
	if age > TEMP_SCREENSHOT_LIFETIME:
		print("⏰ SaveLoadManager: Temporary screenshot expired (age: " + str(age) + "s)")
		_clear_temp_screenshot()
		return false
	
	return true

func _get_screenshot_for_save() -> String:
	"""セーブ用のスクリーンショットを取得（一時スクショ優先、なければリアルタイム撮影）"""
	if not ENABLE_SCREENSHOTS:
		return ""
	
	# 一時スクリーンショットが有効ならそれを使用
	if _is_temp_screenshot_valid():
		print("📷 SaveLoadManager: Using temporary screenshot for save")
		return temp_screenshot_data
	
	# 一時スクリーンショットがない場合はリアルタイム撮影
	print("📷 SaveLoadManager: Capturing real-time screenshot for save")
	return _capture_screenshot()

func has_temp_screenshot() -> bool:
	"""有効な一時スクリーンショットが存在するかチェック"""
	return _is_temp_screenshot_valid()

func get_temp_screenshot_age() -> float:
	"""一時スクリーンショットの経過時間を取得（デバッグ用）"""
	if temp_screenshot_data == "":
		return -1.0
	
	var current_time = Time.get_unix_time_from_system()
	return current_time - temp_screenshot_timestamp

func auto_capture_before_ui(ui_name: String = "menu") -> bool:
	"""UI表示前に自動的に一時スクリーンショットを撮影"""
	print("📷 SaveLoadManager: Auto-capturing screenshot before showing " + ui_name)
	return capture_temp_screenshot()

func _capture_screenshot() -> String:
	"""現在の画面をスクリーンショット撮影してBase64で返す"""
	if not ENABLE_SCREENSHOTS:
		return ""
	
	# メインビューポートから画像を取得
	var viewport = get_viewport()
	if not viewport:
		push_warning("⚠️ SaveLoadManager: Cannot access viewport for screenshot")
		return ""
	
	var img = viewport.get_texture().get_image()
	if not img:
		push_warning("⚠️ SaveLoadManager: Failed to capture screenshot")
		return ""
	
	# リサイズして圧縮
	img.resize(SCREENSHOT_WIDTH, SCREENSHOT_HEIGHT, Image.INTERPOLATE_LANCZOS)
	
	# JPEGとしてエンコード
	var jpg_buffer = img.save_jpg_to_buffer(SCREENSHOT_QUALITY)
	if jpg_buffer.size() == 0:
		push_warning("⚠️ SaveLoadManager: Failed to encode screenshot")
		return ""
	
	# Base64エンコード
	var base64_data = Marshalls.raw_to_base64(jpg_buffer)
	print("📷 SaveLoadManager: Screenshot captured (" + str(jpg_buffer.size()) + " bytes → " + str(base64_data.length()) + " chars)")
	
	return base64_data

# === 暗号化ユーティリティ ===

func is_encryption_enabled() -> bool:
	"""暗号化が有効かどうかを返す"""
	return ENABLE_ENCRYPTION

func get_save_file_path(slot: int) -> String:
	"""セーブファイルの完全パスを取得"""
	return SAVE_FOLDER + "slot_" + str(slot) + SAVE_EXTENSION

func get_save_directory() -> String:
	"""セーブディレクトリのパスを取得"""
	return SAVE_FOLDER

# === スクリーンショット・ユーティリティ ===

func create_image_texture_from_screenshot(base64_data: String) -> ImageTexture:
	"""Base64スクリーンショットからImageTextureを作成"""
	if base64_data == "":
		return null
	
	var jpg_buffer = Marshalls.base64_to_raw(base64_data)
	if jpg_buffer.size() == 0:
		push_error("❌ SaveLoadManager: Failed to decode screenshot data")
		return null
	
	var img = Image.new()
	var error = img.load_jpg_from_buffer(jpg_buffer)
	if error != OK:
		push_error("❌ SaveLoadManager: Failed to load screenshot image")
		return null
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func is_screenshot_enabled() -> bool:
	"""スクリーンショット機能が有効かどうか"""
	return ENABLE_SCREENSHOTS

# === スロット・バリデーション ===

func is_valid_save_slot(slot: int) -> bool:
	"""有効なセーブスロットかどうかチェック"""
	return slot >= 0 and slot < max_save_slots

func is_user_save_slot(slot: int) -> bool:
	"""ユーザーが使用可能なセーブスロットかどうか（オートセーブ以外）"""
	return slot > AUTO_SAVE_SLOT and slot < max_save_slots

func get_available_user_slots() -> Array:
	"""利用可能なユーザーセーブスロット番号の配列を取得"""
	var slots = []
	for slot in range(1, max_save_slots):  # スロット1から開始（0はオートセーブ）
		slots.append(slot)
	return slots

# ===============================
# === 設定システム (Settings) ===
# ===============================

func _initialize_settings():
	"""設定システムの初期化"""
	current_settings = default_settings.duplicate(true)
	load_settings()  # 保存された設定があれば読み込み

# === 設定の保存・読み込み ===

func save_settings() -> bool:
	"""現在の設定をファイルに保存"""
	print("⚙️ SaveLoadManager: Saving settings to file...")
	
	var config = ConfigFile.new()
	
	# バージョン情報を保存
	config.set_value("meta", "version", SETTINGS_VERSION)
	config.set_value("meta", "save_time", Time.get_unix_time_from_system())
	config.set_value("meta", "save_date", Time.get_datetime_string_from_system())
	
	# 各設定カテゴリを保存
	for category in current_settings:
		for key in current_settings[category]:
			config.set_value(category, key, current_settings[category][key])
	
	# ファイルに保存
	var error = config.save(SETTINGS_FILE)
	if error != OK:
		push_error("❌ SaveLoadManager: Failed to save settings: " + error_string(error))
		settings_save_failed.emit("Failed to save settings file")
		return false
	
	print("✅ SaveLoadManager: Settings saved successfully")
	settings_saved.emit()
	return true

func load_settings() -> bool:
	"""設定ファイルから設定を読み込み"""
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("⚙️ SaveLoadManager: Settings file not found, using defaults")
		return true  # デフォルト設定を使用するので成功扱い
	
	print("⚙️ SaveLoadManager: Loading settings from file...")
	
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	if error != OK:
		push_error("❌ SaveLoadManager: Failed to load settings: " + error_string(error))
		settings_load_failed.emit("Failed to load settings file")
		return false
	
	# バージョンチェック
	var file_version = config.get_value("meta", "version", "")
	if file_version != SETTINGS_VERSION:
		print("⚠️ SaveLoadManager: Settings version mismatch (file: " + str(file_version) + ", expected: " + SETTINGS_VERSION + ")")
		# バージョン違いの場合はデフォルトに戻すか、マイグレーション処理を行う
	
	# 設定値を読み込み（デフォルト値をフォールバックとして使用）
	for category in default_settings:
		for key in default_settings[category]:
			var value = config.get_value(category, key, default_settings[category][key])
			current_settings[category][key] = value
	
	print("✅ SaveLoadManager: Settings loaded successfully")
	settings_loaded.emit()
	return true

func reset_settings_to_default():
	"""設定をデフォルト値にリセット"""
	print("⚙️ SaveLoadManager: Resetting settings to default...")
	current_settings = default_settings.duplicate(true)
	save_settings()

# === 設定値のアクセサ ===

func get_setting(category: String, key: String, default_value = null):
	"""設定値を取得"""
	if not current_settings.has(category):
		return default_value
	if not current_settings[category].has(key):
		return default_value
	return current_settings[category][key]

func set_setting(category: String, key: String, value) -> bool:
	"""設定値を変更"""
	if not current_settings.has(category):
		current_settings[category] = {}
	
	current_settings[category][key] = value
	return true

func apply_setting(category: String, key: String, value) -> bool:
	"""設定値を変更して即座に保存"""
	if set_setting(category, key, value):
		return save_settings()
	return false

# === 音声設定の便利メソッド ===

func get_master_volume() -> float:
	return get_setting("audio", "master_volume", 1.0)

func set_master_volume(volume: float) -> bool:
	volume = clampf(volume, 0.0, 1.0)
	return apply_setting("audio", "master_volume", volume)

func get_bgm_volume() -> float:
	return get_setting("audio", "bgm_volume", 0.8)

func set_bgm_volume(volume: float) -> bool:
	volume = clampf(volume, 0.0, 1.0)
	return apply_setting("audio", "bgm_volume", volume)

func get_se_volume() -> float:
	return get_setting("audio", "se_volume", 0.9)

func set_se_volume(volume: float) -> bool:
	volume = clampf(volume, 0.0, 1.0)
	return apply_setting("audio", "se_volume", volume)

# === テキスト設定の便利メソッド ===

func get_text_speed() -> float:
	return get_setting("text", "text_speed", 1.0)

func set_text_speed(speed: float) -> bool:
	speed = clampf(speed, 0.1, 5.0)
	return apply_setting("text", "text_speed", speed)

func get_auto_play_speed() -> float:
	return get_setting("text", "auto_play_speed", 2.0)

func set_auto_play_speed(speed: float) -> bool:
	speed = clampf(speed, 0.5, 10.0)
	return apply_setting("text", "auto_play_speed", speed)

# === 表示設定の便利メソッド ===

func is_fullscreen() -> bool:
	return get_setting("display", "fullscreen", false)

func set_fullscreen(enabled: bool) -> bool:
	if apply_setting("display", "fullscreen", enabled):
		# 即座にフルスクリーン設定を適用
		if enabled:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return true
	return false

func get_window_size() -> Vector2i:
	return get_setting("display", "window_size", Vector2i(1280, 720))

func set_window_size(size: Vector2i) -> bool:
	if apply_setting("display", "window_size", size):
		# 即座にウィンドウサイズを適用（フルスクリーンでない場合のみ）
		if not is_fullscreen():
			DisplayServer.window_set_size(size)
		return true
	return false

# === 設定のエクスポート・インポート ===

func export_settings() -> Dictionary:
	"""設定を辞書形式でエクスポート（バックアップ用）"""
	return current_settings.duplicate(true)

func import_settings(settings_data: Dictionary) -> bool:
	"""設定を辞書から読み込み（復元用）"""
	if not settings_data or settings_data.is_empty():
		return false
	
	# 基本的なバリデーション
	for category in settings_data:
		if category in default_settings:
			for key in settings_data[category]:
				if key in default_settings[category]:
					current_settings[category][key] = settings_data[category][key]
	
	return save_settings()

# === デバッグ・ユーティリティ ===

func print_current_settings():
	"""現在の設定をコンソールに出力（デバッグ用）"""
	print("=== Current Settings ===")
	for category in current_settings:
		print("📁 " + category + ":")
		for key in current_settings[category]:
			print("  • " + key + ": " + str(current_settings[category][key]))

func get_settings_file_path() -> String:
	"""設定ファイルのパスを取得"""
	return SETTINGS_FILE
