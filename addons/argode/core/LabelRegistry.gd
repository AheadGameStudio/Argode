extends Node

# Ren'Pyライクな軽量ラベルポインタ管理システム
# メモリ効率を重視し、必要な時のみファイル内容を読み込む

# ラベル情報の軽量構造体
class LabelInfo:
	var file_path: String      # ファイルパス
	var line_number: int       # ラベルの行番号
	var file_size: int         # ファイルサイズ（変更検知用）
	var last_modified: int     # 最終変更時刻（変更検知用）
	
	func _init(path: String, line: int, size: int, modified: int):
		file_path = path
		line_number = line
		file_size = size
		last_modified = modified

# キャッシュされたスクリプトファイル情報
class ScriptCache:
	var lines: PackedStringArray  # スクリプト内容（使用時のみ読み込み）
	var is_loaded: bool = false   # メモリに読み込み済みか
	var last_accessed: int = 0    # 最終アクセス時刻（LRU用）
	
	func _init():
		lines = PackedStringArray()

var label_registry: Dictionary = {}     # label_name -> LabelInfo
var script_cache: Dictionary = {}       # file_path -> ScriptCache
var scan_directories: Array[String] = ["res://scenarios/"]
var max_cache_size: int = 5             # 同時にメモリ保持するファイル数制限
var duplicate_labels: Array[Dictionary] = []  # 重複ラベル情報

signal label_registry_updated(total_labels: int)
signal duplicate_label_error(label_name: String, duplicates: Array)

func _ready():
	print("🏷️ LabelRegistry initialized")
	# 起動時にラベル情報をスキャン
	scan_all_labels()

## ===== ラベルスキャニング（軽量・高速） =====

func scan_all_labels():
	"""全.rgdファイルをスキャンしてラベル情報のみを収集"""
	print("🔍 Scanning all .rgd files for labels...")
	var start_time = Time.get_unix_time_from_system()
	
	label_registry.clear()
	duplicate_labels.clear()
	var total_labels = 0
	
	for dir_path in scan_directories:
		total_labels += _scan_directory(dir_path)
	
	var end_time = Time.get_unix_time_from_system()
	print("✅ Label scan completed: ", total_labels, " labels in ", (end_time - start_time), "s")
	
	# 重複ラベルがある場合はエラー表示
	if not duplicate_labels.is_empty():
		_show_duplicate_label_errors()
	
	label_registry_updated.emit(total_labels)

func _scan_directory(dir_path: String) -> int:
	"""指定ディレクトリ内の.rgdファイルをスキャン"""
	var dir = DirAccess.open(dir_path)
	var label_count = 0
	
	if not dir:
		print("❌ Cannot access directory: ", dir_path)
		return 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".rgd"):
			var file_path = dir_path + "/" + file_name
			label_count += _scan_file_headers(file_path)
		file_name = dir.get_next()
	
	return label_count

func _scan_file_headers(file_path: String) -> int:
	"""ファイルのヘッダー部分のみをスキャンしてラベルを抽出"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Cannot open file: ", file_path)
		return 0
	
	var file_size = file.get_length()
	var last_modified = FileAccess.get_modified_time(file_path)
	var label_regex = RegEx.new()
	label_regex.compile("^label\\s+(?<name>\\w+):")
	
	var line_number = 0
	var label_count = 0
	var max_scan_lines = 1000  # 大きなファイルでは先頭1000行のみスキャン
	
	while not file.eof_reached() and line_number < max_scan_lines:
		var line = file.get_line().strip_edges()
		var match_result = label_regex.search(line)
		
		if match_result:
			var label_name = match_result.get_string("name")
			
			# 重複ラベルの場合は記録し、最初に見つかったものを優先
			if label_registry.has(label_name):
				var existing = label_registry[label_name]
				
				# 重複情報を記録
				var duplicate_info = {
					"label_name": label_name,
					"first_file": existing.file_path,
					"first_line": existing.line_number,
					"duplicate_file": file_path,
					"duplicate_line": line_number
				}
				duplicate_labels.append(duplicate_info)
				
				print("❌ DUPLICATE LABEL ERROR: '", label_name, "'")
				print("   First occurrence: ", existing.file_path, ":", existing.line_number)
				print("   Duplicate found: ", file_path, ":", line_number)
			else:
				# 初回のみ登録
				label_registry[label_name] = LabelInfo.new(file_path, line_number, file_size, last_modified)
				print("🏷️ Found label: ", label_name, " at ", file_path, ":", line_number)
				label_count += 1
		
		line_number += 1
	
	file.close()
	return label_count

## ===== 効率的なファイル読み込み（オンデマンド） =====

func get_script_lines(file_path: String) -> PackedStringArray:
	"""指定ファイルの内容を取得（キャッシュ付き）"""
	
	# キャッシュヒット確認
	if script_cache.has(file_path):
		var cache = script_cache[file_path]
		if cache.is_loaded:
			cache.last_accessed = Time.get_unix_time_from_system()
			print("💾 Cache hit: ", file_path)
			return cache.lines
	
	# ファイル読み込み
	print("📁 Loading file: ", file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open file: " + file_path)
		return PackedStringArray()
	
	var lines = file.get_as_text().split("\n")
	file.close()
	
	# キャッシュに保存
	_cache_script_content(file_path, lines)
	
	return lines

func _cache_script_content(file_path: String, lines: PackedStringArray):
	"""スクリプト内容をキャッシュに保存（LRU管理）"""
	
	# キャッシュサイズ制限チェック
	if script_cache.size() >= max_cache_size:
		_evict_oldest_cache()
	
	# 新しいキャッシュエントリ作成
	var cache = ScriptCache.new()
	cache.lines = lines
	cache.is_loaded = true
	cache.last_accessed = Time.get_unix_time_from_system()
	
	script_cache[file_path] = cache
	print("💾 Cached script: ", file_path, " (", lines.size(), " lines)")

func _evict_oldest_cache():
	"""最も古いキャッシュエントリを削除（LRU）"""
	var oldest_path = ""
	var oldest_time = Time.get_unix_time_from_system()
	
	for path in script_cache.keys():
		var cache = script_cache[path]
		if cache.last_accessed < oldest_time:
			oldest_time = cache.last_accessed
			oldest_path = path
	
	if oldest_path != "":
		script_cache.erase(oldest_path)
		print("🗑️ Evicted cache: ", oldest_path)

## ===== Ren'Pyライクなラベルジャンプ =====

func jump_to_label(label_name: String, script_player: Node) -> bool:
	"""指定ラベルにジャンプ（ファイルを跨いでも動作）"""
	
	print("🔍 LabelRegistry: Looking for label '", label_name, "'")
	
	if not label_registry.has(label_name):
		print("❌ Label not found in registry: ", label_name)
		return false
	
	var label_info = label_registry[label_name]
	print("🚀 Jumping to label: ", label_name, " in ", label_info.file_path, " at line ", label_info.line_number)
	
	# ファイル内容を取得
	var lines = get_script_lines(label_info.file_path)
	if lines.is_empty():
		print("❌ Failed to load file: ", label_info.file_path)
		return false
	
	print("✅ File loaded successfully: ", lines.size(), " lines")
	
	# スクリプトプレイヤーにスクリプトを設定
	script_player.script_lines = lines
	script_player.current_script_path = label_info.file_path  # パスも更新
	script_player._preparse_labels()
	
	# ⚠️ 重要: play_from_label()を呼ばずに、直接ラベルに移動
	if script_player.label_map.has(label_name):
		script_player.current_line_index = script_player.label_map[label_name]
		script_player.is_playing = true
		script_player.is_waiting_for_choice = false
		print("✅ Successfully positioned at label: ", label_name, " line: ", script_player.current_line_index)
		
		# _tick()を呼んで実行開始
		script_player.call_deferred("_tick")
		return true
	else:
		print("❌ Label '", label_name, "' not found after loading file: ", label_info.file_path)
		return false

## ===== メモリ管理・デバッグ機能 =====

func get_registry_stats() -> Dictionary:
	"""レジストリの統計情報を取得"""
	var stats = {
		"total_labels": label_registry.size(),
		"cached_files": script_cache.size(),
		"memory_usage_kb": _calculate_memory_usage()
	}
	return stats

func _calculate_memory_usage() -> int:
	"""概算メモリ使用量を計算（KB）"""
	var total_chars = 0
	for cache in script_cache.values():
		if cache.is_loaded:
			for line in cache.lines:
				total_chars += line.length()
	return total_chars / 1024  # KB単位

func print_debug_info():
	"""デバッグ情報を出力"""
	var stats = get_registry_stats()
	print("=== LabelRegistry Debug Info ===")
	print("Total labels: ", stats.total_labels)
	print("Cached files: ", stats.cached_files)
	print("Memory usage: ", stats.memory_usage_kb, " KB")
	print("Labels by file:")
	
	var file_counts = {}
	for label_name in label_registry.keys():
		var label_info = label_registry[label_name]
		var file_name = label_info.file_path.get_file()
		file_counts[file_name] = file_counts.get(file_name, 0) + 1
	
	for file_name in file_counts.keys():
		print("  ", file_name, ": ", file_counts[file_name], " labels")

## ===== ホットリロード対応 =====

func check_file_changes():
	"""ファイル変更を検知してレジストリを更新"""
	var changed_files = []
	
	for label_name in label_registry.keys():
		var label_info = label_registry[label_name]
		var current_modified = FileAccess.get_modified_time(label_info.file_path)
		
		if current_modified != label_info.last_modified:
			changed_files.append(label_info.file_path)
	
	if not changed_files.is_empty():
		print("🔄 Detected file changes: ", changed_files)
		# 変更されたファイルのキャッシュを無効化
		for file_path in changed_files:
			if script_cache.has(file_path):
				script_cache.erase(file_path)
		
		# レジストリを再スキャン
		scan_all_labels()

func _show_duplicate_label_errors():
	"""重複ラベルエラーを画面に表示"""
	print("\n" + "=".repeat(60))
	print("🚨 DUPLICATE LABEL ERRORS DETECTED 🚨")
	print("=".repeat(60))
	print("シナリオ作成者へ: 以下の重複ラベルを修正してください:")
	print("")
	
	for dup in duplicate_labels:
		print("❌ ラベル名: '", dup.label_name, "'")
		print("   最初の定義: ", dup.first_file.get_file(), " (行 ", dup.first_line + 1, ")")
		print("   重複定義:   ", dup.duplicate_file.get_file(), " (行 ", dup.duplicate_line + 1, ")")
		print("   → ", dup.duplicate_file.get_file(), "の'", dup.label_name, "'を別名に変更してください")
		print("")
	
	print("⚠️ 重複ラベルがあると、予期しない動作が発生する可能性があります。")
	print("⚠️ 各ファイルで固有のラベル名を使用してください。")
	print("=".repeat(60))
	
	# UIManagerに通知（エラーダイアログ表示用）
	# v2: ArgodeSystem経由でUIManagerにアクセス
	var adv_system = get_node("/root/ArgodeSystem")
	var ui_manager = adv_system.UIManager if adv_system else null
	if ui_manager and ui_manager.has_method("show_error_message"):
		var error_message = _create_duplicate_label_error_message()
		ui_manager.show_error_message("重複ラベルエラー", error_message)

func _create_duplicate_label_error_message() -> String:
	"""エラーメッセージ文字列を生成"""
	var message = "以下のラベルが重複しています:\n\n"
	
	for i in range(min(duplicate_labels.size(), 5)):  # 最初の5個のみ表示
		var dup = duplicate_labels[i]
		message += "• '" + dup.label_name + "' ラベル\n"
		message += "  " + dup.first_file.get_file() + " (行" + str(dup.first_line + 1) + ")\n"
		message += "  " + dup.duplicate_file.get_file() + " (行" + str(dup.duplicate_line + 1) + ")\n\n"
	
	if duplicate_labels.size() > 5:
		message += "...他 " + str(duplicate_labels.size() - 5) + " 件\n\n"
	
	message += "各ファイルで固有のラベル名を使用してください。"
	return message