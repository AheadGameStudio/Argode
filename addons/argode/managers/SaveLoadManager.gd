# SaveLoadManager.gd
# Ren'Py風セーブ・ロードシステム - ゲーム状態の保存と復元
extends Node
class_name SaveLoadManager

# === シグナル ===
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)

# === セーブデータ構造 ===
const SAVE_VERSION = "2.0"
const SAVE_EXTENSION = ".save"
const SAVE_FOLDER = "user://saves/"
const MAX_SAVE_SLOTS = 10

# === 暗号化設定 ===
const ENABLE_ENCRYPTION = true
const ENCRYPTION_KEY = "argode_save_key_2024"  # 本番では環境変数や設定ファイルから取得推奨

# === マネージャー参照 ===
var argode_system: Node = null

# === セーブデータ情報キャッシュ ===
var save_info_cache: Dictionary = {}

func _ready():
	print("💾 SaveLoadManager: Initializing save/load system...")
	print("🔐 Encryption: " + ("Enabled" if ENABLE_ENCRYPTION else "Disabled"))
	_ensure_save_directory()
	_load_save_info_cache()

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
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("❌ SaveLoadManager: Invalid save slot: " + str(slot))
		save_failed.emit(slot, "Invalid slot number")
		return false
	
	print("💾 SaveLoadManager: Saving game to slot " + str(slot) + "...")
	
	# セーブデータを収集
	var save_data = _collect_game_state()
	save_data["save_name"] = save_name if save_name != "" else ("Save " + str(slot + 1))
	save_data["save_time"] = Time.get_unix_time_from_system()
	save_data["save_date_string"] = Time.get_datetime_string_from_system()
	save_data["version"] = SAVE_VERSION
	save_data["slot"] = slot
	
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
		"line_number": save_data.get("current_line_index", 0)
	}
	
	print("✅ SaveLoadManager: Game saved successfully to slot " + str(slot))
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
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
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
		"save_name": save_data.get("save_name", "Save " + str(slot + 1)),
		"save_date": save_data.get("save_date_string", "Unknown"),
		"save_time": save_data.get("save_time", 0),
		"script_file": save_data.get("current_script_path", ""),
		"line_number": save_data.get("current_line_index", 0)
	}
	
	save_info_cache[slot] = info
	return info

func get_all_save_info() -> Dictionary:
	"""すべてのセーブスロット情報を取得"""
	var all_info = {}
	for slot in range(MAX_SAVE_SLOTS):
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
	for slot in range(MAX_SAVE_SLOTS):
		get_save_info(slot)  # 副作用でキャッシュに格納される
	
	print("💾 SaveLoadManager: Loaded save info cache for " + str(save_info_cache.size()) + " slots")

# === オートセーブ機能 ===

func auto_save() -> bool:
	"""オートセーブを実行（専用スロット使用）"""
	return save_game(MAX_SAVE_SLOTS - 1, "Auto Save")

func load_auto_save() -> bool:
	"""オートセーブをロード"""
	return load_game(MAX_SAVE_SLOTS - 1)

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
