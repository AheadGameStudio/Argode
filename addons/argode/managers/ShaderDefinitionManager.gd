# ShaderDefinitionManager.gd
# v2新機能: `shader` ステートメント解析・管理
extends Node
class_name ShaderDefinitionManager

# === シグナル ===
signal shader_defined(alias: String, path: String)
signal definition_error(message: String)

# === 定義ストレージ ===
var shader_definitions: Dictionary = {}  # alias -> path
var loaded_shaders: Dictionary = {}  # alias -> Shader resource

# === 正規表現パターン ===
var regex_shader_define: RegEx

func _ready():
	_compile_regex()
	print("🎨 ShaderDefinitionManager initialized (v2)")

func _compile_regex():
	"""shader ステートメント解析用の正規表現をコンパイル"""
	# shader sepia_effect = "res://shaders/sepia.gdshader"
	regex_shader_define = RegEx.new()
	regex_shader_define.compile("^shader\\s+(?<alias>\\w+)\\s*=\\s*\"(?<path>[^\"]+)\"")

func parse_shader_statement(line: String) -> bool:
	"""
	shader ステートメントを解析して定義を登録
	@param line: 解析する行
	@return: 解析成功時 true
	"""
	var match = regex_shader_define.search(line.strip_edges())
	if not match:
		return false
	
	var alias = match.get_string("alias")
	var path = match.get_string("path")
	
	shader_definitions[alias] = path
	shader_defined.emit(alias, path)
	
	print("🎨 Shader defined: ", alias, " -> ", path)
	return true

func get_shader_path(alias: String) -> String:
	"""シェーダーエイリアスからパスを取得"""
	return shader_definitions.get(alias, "")

func load_shader(alias: String) -> Shader:
	"""
	シェーダーをロードして取得（キャッシュ機能付き）
	@param alias: シェーダーエイリアス
	@return: ロードされたShaderリソース、失敗時はnull
	"""
	if alias in loaded_shaders:
		return loaded_shaders[alias]
	
	var path = get_shader_path(alias)
	if path.is_empty():
		push_warning("⚠️ Shader alias not found: " + alias)
		return null
	
	var shader = load(path) as Shader
	if shader:
		loaded_shaders[alias] = shader
		print("🎨 Shader loaded: ", alias, " -> ", path)
	else:
		push_error("🚫 Failed to load shader: " + path)
	
	return shader

func has_shader(alias: String) -> bool:
	"""シェーダーが定義済みかチェック"""
	return alias in shader_definitions

func get_all_shader_aliases() -> Array[String]:
	"""定義済みシェーダーエイリアスのリストを取得"""
	var aliases: Array[String] = []
	for alias in shader_definitions.keys():
		aliases.append(alias)
	return aliases

func preload_shader(alias: String):
	"""シェーダーを事前ロード"""
	load_shader(alias)

func preload_all_shaders():
	"""全シェーダーを事前ロード"""
	for alias in shader_definitions.keys():
		preload_shader(alias)

func build_definitions():
	"""v2設計: 定義をビルド（現在は何もしない）"""
	print("🎨 Shader definitions built: ", shader_definitions.size(), " shaders")

func clear_definitions():
	"""全定義をクリア"""
	shader_definitions.clear()
	loaded_shaders.clear()
	print("🎨 Shader definitions cleared")