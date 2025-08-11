# DefinitionLoader.gd
# 定義ファイル自動発見・読み込みシステム
class_name DefinitionLoader
extends RefCounted

const DEFINITIONS_DIR = "res://definitions/"
const DEFINITION_EXTENSIONS = [".rgd"]

static func load_all_definitions(argode_system: Node) -> Dictionary:
	"""全定義ファイルを自動発見して読み込み"""
	print("🔍 DefinitionLoader: Scanning definitions directory...")
	
	var results = {
		"characters": 0,
		"images": 0,
		"audio": 0,
		"shaders": 0,
		"variables": 0,
		"total_files": 0
	}
	
	var dir = DirAccess.open(DEFINITIONS_DIR)
	if not dir:
		print("❌ Cannot open definitions directory: ", DEFINITIONS_DIR)
		return results
	
	# ファイルリストを取得
	var definition_files = _scan_definition_files(dir)
	results.total_files = definition_files.size()
	
	# 各ファイルを処理
	for file_path in definition_files:
		var file_results = _load_definition_file(file_path, argode_system)
		results.characters += file_results.characters
		results.images += file_results.images
		results.audio += file_results.audio
		results.shaders += file_results.shaders
		results.variables += file_results.variables
	
	_print_summary(results)
	return results

static func _scan_definition_files(dir: DirAccess) -> Array[String]:
	"""定義ファイルをスキャンしてリストを取得"""
	var files: Array[String] = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var extension = "." + file_name.get_extension()
			if extension in DEFINITION_EXTENSIONS:
				var full_path = DEFINITIONS_DIR + file_name
				files.append(full_path)
				print("   📋 Found definition file: ", file_name)
		file_name = dir.get_next()
	
	# ファイルを優先順序でソート
	files.sort_custom(_compare_definition_priority)
	return files

static func _compare_definition_priority(a: String, b: String) -> bool:
	"""定義ファイルの優先順序を決定（variables → characters → assets）"""
	var priority_order = ["variables", "characters", "assets"]
	
	var a_name = a.get_file().get_basename()
	var b_name = b.get_file().get_basename()
	
	var a_priority = priority_order.find(a_name)
	var b_priority = priority_order.find(b_name)
	
	if a_priority == -1: a_priority = 999
	if b_priority == -1: b_priority = 999
	
	return a_priority < b_priority

static func _load_definition_file(file_path: String, argode_system: Node) -> Dictionary:
	"""単一の定義ファイルを読み込み"""
	print("📖 Loading definition file: ", file_path.get_file())
	
	var results = {
		"characters": 0,
		"images": 0,
		"audio": 0,
		"shaders": 0,
		"variables": 0
	}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Cannot open file: ", file_path)
		return results
	
	var line_number = 0
	while not file.eof_reached():
		line_number += 1
		var line = file.get_line().strip_edges()
		
		# 空行・コメント行をスキップ
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# 定義文を解析・実行
		var definition_type = _process_definition_line(line, argode_system, file_path, line_number)
		if definition_type != "":
			results[definition_type] += 1
	
	file.close()
	return results

static func _process_definition_line(line: String, argode_system: Node, file_path: String, line_number: int) -> String:
	"""定義行を解析して適切なマネージャーに処理を委譲"""
	
	# character定義
	var character_regex = RegEx.new()
	character_regex.compile("^character\\s+")
	if character_regex.search(line):
		if argode_system.CharDefs and argode_system.CharDefs.has_method("_handle_character_statement"):
			argode_system.CharDefs._handle_character_statement(line, file_path, line_number)
		else:
			print("⚠️ CharDefs not available for: ", line)
		return "characters"
	
	# image定義
	var image_regex = RegEx.new()
	image_regex.compile("^image\\s+")
	if image_regex.search(line):
		if argode_system.ImageDefs and argode_system.ImageDefs.has_method("_handle_image_statement"):
			argode_system.ImageDefs._handle_image_statement(line, file_path, line_number)
		else:
			print("⚠️ ImageDefs not available for: ", line)
		return "images"
	
	# audio定義
	var audio_regex = RegEx.new()
	audio_regex.compile("^audio\\s+")
	if audio_regex.search(line):
		if argode_system.AudioDefs and argode_system.AudioDefs.has_method("_handle_audio_statement"):
			argode_system.AudioDefs._handle_audio_statement(line, file_path, line_number)
		else:
			print("⚠️ AudioDefs not available for: ", line)
		return "audio"
	
	# shader定義
	var shader_regex = RegEx.new()
	shader_regex.compile("^shader\\s+")
	if shader_regex.search(line):
		if argode_system.ShaderDefs and argode_system.ShaderDefs.has_method("_handle_shader_statement"):
			argode_system.ShaderDefs._handle_shader_statement(line, file_path, line_number)
		else:
			print("⚠️ ShaderDefs not available for: ", line)
		return "shaders"
	
	# set変数定義
	var set_regex = RegEx.new()
	set_regex.compile("^set\\s+")
	if set_regex.search(line):
		if argode_system.VariableManager and argode_system.VariableManager.has_method("handle_set_from_definition"):
			argode_system.VariableManager.handle_set_from_definition(line, file_path, line_number)
		elif argode_system.Player and argode_system.Player.has_method("_handle_set_statement"):
			# フォールバック: ArgodeScriptPlayerのsetハンドラーを使用
			argode_system.Player._handle_set_statement(line)
		else:
			print("⚠️ Variable handling not available for: ", line)
		return "variables"
	
	print("⚠️ Unknown definition line at ", file_path, ":", line_number, " -> ", line)
	return ""

static func _print_summary(results: Dictionary):
	"""読み込み結果のサマリーを表示"""
	print("✅ Definition loading completed:")
	print("   📋 Files processed: ", results.total_files)
	print("   👤 Characters: ", results.characters)
	print("   🖼️ Images: ", results.images)
	print("   🔊 Audio: ", results.audio)
	print("   🎨 Shaders: ", results.shaders)
	print("   📊 Variables: ", results.variables)
	print("   📈 Total definitions: ", results.characters + results.images + results.audio + results.shaders + results.variables)
