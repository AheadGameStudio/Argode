# AudioDefinitionManager.gd
# v2新機能: `audio` ステートメント解析・管理 + 自動ファイルスキャン
extends Node
class_name AudioDefinitionManager

# === シグナル ===
signal audio_defined(alias: String, path: String)
signal definition_error(message: String)
signal definitions_loaded()
signal definition_added(audio_name: String, audio_type: String)

# === 定義ストレージ ===
var audio_definitions: Dictionary = {}  # alias -> path
var bgm_definitions: Dictionary = {}    # auto-scanned BGM files
var se_definitions: Dictionary = {}     # auto-scanned SE files

# === 設定 ===
var auto_scan_enabled: bool = true
var default_bgm_path: String = "res://assets/audios/bgm/"
var default_se_path: String = "res://assets/audios/se/"

# === 正規表現パターン ===
var regex_audio_define: RegEx

func _ready():
	_compile_regex()
	print("🎵 AudioDefinitionManager initialized (v2)")
	if auto_scan_enabled:
		await scan_audio_files()

func _compile_regex():
	"""audio ステートメント解析用の正規表現をコンパイル"""
	# audio alias "path" 形式をパース
	regex_audio_define = RegEx.new()
	regex_audio_define.compile("^audio\\s+(?<alias>\\w+)\\s+\"(?<path>[^\"]+)\"")

func scan_audio_files():
	"""オーディオファイルをスキャンして自動定義作成"""
	print("🔍 Scanning audio files...")
	
	# BGMファイルをスキャン
	_scan_directory(default_bgm_path, "bgm")
	
	# SEファイルをスキャン
	_scan_directory(default_se_path, "se")
	
	print("✅ Audio file scan completed")
	print("📊 BGM definitions:", bgm_definitions.size())
	print("📊 SE definitions:", se_definitions.size())
	
	definitions_loaded.emit()

func _scan_directory(directory_path: String, audio_type: String):
	"""指定ディレクトリのオーディオファイルをスキャン"""
	print("📁 Scanning directory:", directory_path)
	
	var dir = DirAccess.open(directory_path)
	if not dir:
		print("⚠️ Cannot access directory:", directory_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var file_extension = file_name.get_extension().to_lower()
			if file_extension in ["ogg", "wav", "mp3"]:
				var audio_name = file_name.get_basename()
				var full_path = directory_path + file_name
				
				add_auto_definition(audio_name, full_path, audio_type)
				print("  ✅ Added:", audio_name, "->", full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func add_auto_definition(audio_name: String, file_path: String, audio_type: String):
	"""自動スキャンによるオーディオ定義を追加"""
	var definition = {
		"name": audio_name,
		"path": file_path,
		"type": audio_type
	}
	
	match audio_type:
		"bgm":
			bgm_definitions[audio_name] = definition
		"se":
			se_definitions[audio_name] = definition
		_:
			push_warning("⚠️ Unknown audio type: " + audio_type)
			return
	
	definition_added.emit(audio_name, audio_type)

func parse_audio_statement(line: String) -> bool:
	"""
	audio ステートメントを解析して定義を登録
	@param line: 解析する行
	@return: 解析成功時 true
	"""
	var match = regex_audio_define.search(line.strip_edges())
	if not match:
		return false
	
	var alias = match.get_string("alias")
	var path = match.get_string("path")
	
	audio_definitions[alias] = path
	audio_defined.emit(alias, path)
	
	print("🎵 Audio defined: ", alias, " -> ", path)
	return true

func _handle_audio_statement(line: String, file_path: String = "", line_number: int = 0):
	"""
	DefinitionLoaderから呼び出されるオーディオ定義処理メソッド
	@param line: 処理する行
	@param file_path: ファイルパス（デバッグ用）
	@param line_number: 行番号（デバッグ用）
	"""
	var success = parse_audio_statement(line)
	if success:
		print("✅ Audio definition processed: ", line.strip_edges())
	else:
		print("⚠️ Failed to parse audio statement: ", line.strip_edges())

func get_audio_path(alias: String) -> String:
	"""オーディオエイリアス・名前からパスを取得（統合検索）"""
	# まずマニュアル定義から検索
	if alias in audio_definitions:
		return audio_definitions[alias]
	
	# 自動スキャンされたBGMから検索
	if alias in bgm_definitions:
		return bgm_definitions[alias]["path"]
	
	# 自動スキャンされたSEから検索
	if alias in se_definitions:
		return se_definitions[alias]["path"]
	
	return ""

func has_audio(alias: String) -> bool:
	"""オーディオが定義済みかチェック（統合検索）"""
	return alias in audio_definitions or alias in bgm_definitions or alias in se_definitions

func get_audio_type(audio_name: String) -> String:
	"""オーディオの種類を取得"""
	if audio_name in bgm_definitions:
		return "bgm"
	elif audio_name in se_definitions:
		return "se"
	else:
		return "unknown"

func list_bgm_definitions() -> Array[String]:
	"""BGM定義のリストを取得"""
	return bgm_definitions.keys()

func list_se_definitions() -> Array[String]:
	"""SE定義のリストを取得"""
	return se_definitions.keys()

func get_all_audio_aliases() -> Array[String]:
	"""定義済みオーディオエイリアスのリストを取得（統合）"""
	var aliases: Array[String] = []
	
	# マニュアル定義
	for alias in audio_definitions.keys():
		aliases.append(alias)
	
	# 自動スキャン定義
	for alias in bgm_definitions.keys():
		aliases.append(alias)
	for alias in se_definitions.keys():
		aliases.append(alias)
	
	return aliases

func get_all_definitions() -> Dictionary:
	"""全定義を取得"""
	return {
		"manual": audio_definitions,
		"bgm": bgm_definitions,
		"se": se_definitions
	}

func build_definitions():
	"""v2設計: 定義をビルド"""
	var total_count = audio_definitions.size() + bgm_definitions.size() + se_definitions.size()
	print("🎵 Audio definitions built: ", total_count, " audio files")
	print("  - Manual definitions: ", audio_definitions.size())
	print("  - Auto BGM: ", bgm_definitions.size())  
	print("  - Auto SE: ", se_definitions.size())

func clear_definitions():
	"""全定義をクリア"""
	audio_definitions.clear()
	bgm_definitions.clear()
	se_definitions.clear()
	print("🎵 Audio definitions cleared")

# === デバッグ・ログ出力 ===
func print_all_definitions():
	"""全定義をログ出力"""
	print("🎵 === Audio Definitions ===")
	
	print("Manual Definitions (", audio_definitions.size(), "):")
	for alias in audio_definitions.keys():
		print("  ", alias, " -> ", audio_definitions[alias])
	
	print("BGM Definitions (", bgm_definitions.size(), "):")
	for bgm_name in bgm_definitions.keys():
		var def = bgm_definitions[bgm_name]
		print("  ", bgm_name, " -> ", def["path"])
	
	print("SE Definitions (", se_definitions.size(), "):")
	for se_name in se_definitions.keys():
		var def = se_definitions[se_name]
		print("  ", se_name, " -> ", def["path"])