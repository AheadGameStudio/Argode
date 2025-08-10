# AudioDefinitionManager.gd
# v2新機能: `audio` ステートメント解析・管理
extends Node
class_name AudioDefinitionManager

# === シグナル ===
signal audio_defined(alias: String, path: String)
signal definition_error(message: String)

# === 定義ストレージ ===
var audio_definitions: Dictionary = {}  # alias -> path

# === 正規表現パターン ===
var regex_audio_define: RegEx

func _ready():
	_compile_regex()
	print("🎵 AudioDefinitionManager initialized (v2)")

func _compile_regex():
	"""audio ステートメント解析用の正規表現をコンパイル"""
	# audio town_bgm = "res://bgm/town.ogg"
	regex_audio_define = RegEx.new()
	regex_audio_define.compile("^audio\\s+(?<alias>\\w+)\\s*=\\s*\"(?<path>[^\"]+)\"")

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

func get_audio_path(alias: String) -> String:
	"""オーディオエイリアスからパスを取得"""
	return audio_definitions.get(alias, "")

func has_audio(alias: String) -> bool:
	"""オーディオが定義済みかチェック"""
	return alias in audio_definitions

func get_all_audio_aliases() -> Array[String]:
	"""定義済みオーディオエイリアスのリストを取得"""
	var aliases: Array[String] = []
	for alias in audio_definitions.keys():
		aliases.append(alias)
	return aliases

func build_definitions():
	"""v2設計: 定義をビルド（現在は何もしない）"""
	print("🎵 Audio definitions built: ", audio_definitions.size(), " audio files")

func clear_definitions():
	"""全定義をクリア"""
	audio_definitions.clear()
	print("🎵 Audio definitions cleared")