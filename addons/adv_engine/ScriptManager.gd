extends Node
class_name ScriptManager

# 複数.rgdファイルの統合管理システム

signal script_switched(from_file: String, to_file: String)

var current_file: String = ""
var loaded_scripts: Dictionary = {}  # filename -> script_content
var global_label_map: Dictionary = {}  # label -> {"file": filename, "line": line_number}
var script_player: Node

func _ready():
	var adv_system = get_node("/root/AdvSystem")
	if not adv_system or not adv_system.Player:
		push_error("❌ ScriptManager: AdvSystem.Player not available")
		return
		
	script_player = adv_system.Player
	print("📚 ScriptManager: Connected to AdvSystem.Player")

## 1. 事前読み込み方式
func preload_scripts(script_paths: Array):
	"""複数のスクリプトを事前に読み込み、統合する"""
	print("📚 Preloading scripts: ", script_paths)
	
	for path in script_paths:
		var filename = path.get_file()
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			loaded_scripts[filename] = file.get_as_text().split("\n")
			file.close()
			_parse_labels_from_file(filename)
			print("✅ Loaded: ", filename)
		else:
			print("❌ Failed to load: ", path)
	
	print("🗺️ Global label map: ", global_label_map.keys())

func _parse_labels_from_file(filename: String):
	"""ファイル内のラベルをグローバルマップに追加"""
	var lines = loaded_scripts[filename]
	var label_regex = RegEx.new()
	label_regex.compile("^label\\s+(?<name>\\w+):")
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		var match_result = label_regex.search(line)
		if match_result:
			var label_name = match_result.get_string("name")
			global_label_map[label_name] = {"file": filename, "line": i}
			print("🏷️ Found label: ", label_name, " in ", filename, " at line ", i)

## 2. 動的ファイル切り替え方式
func jump_to_file_label(filename: String, label_name: String):
	"""指定ファイル内のラベルにジャンプ"""
	print("🚀 Jumping to ", label_name, " in ", filename)
	
	if not loaded_scripts.has(filename):
		print("❌ File not loaded: ", filename)
		return false
	
	# ファイルを切り替え
	var old_file = current_file
	current_file = filename
	
	# AdvScriptPlayerに統合スクリプトを設定
	var file_content = "\\n".join(loaded_scripts[filename])
	script_player.script_lines = loaded_scripts[filename]
	script_player._preparse_labels()
	script_player.play_from_label(label_name)
	
	script_switched.emit(old_file, filename)
	return true

func smart_jump(label_name: String) -> bool:
	"""ラベルを自動検索してジャンプ"""
	if global_label_map.has(label_name):
		var label_info = global_label_map[label_name]
		return jump_to_file_label(label_info["file"], label_name)
	else:
		print("❌ Label not found in any loaded file: ", label_name)
		return false

## 3. インクルード方式
func create_combined_script(main_file: String, include_files: Array) -> String:
	"""複数ファイルを統合した単一スクリプトを生成"""
	var combined = ""
	
	# メインファイル処理
	if loaded_scripts.has(main_file):
		combined += "# === " + main_file + " ===\\n"
		combined += "\\n".join(loaded_scripts[main_file]) + "\\n\\n"
	
	# インクルードファイル処理
	for include_file in include_files:
		if loaded_scripts.has(include_file):
			combined += "# === " + include_file + " ===\\n"
			var lines = loaded_scripts[include_file]
			# ラベル名にプレフィックス追加
			var prefix = include_file.get_basename() + "_"
			for line in lines:
				if line.strip_edges().begins_with("label "):
					line = line.replace("label ", "label " + prefix)
				elif line.strip_edges().begins_with("jump "):
					# jumpコマンドも適切に処理
					pass
				combined += line + "\\n"
			combined += "\\n"
	
	return combined

## 使用例を提供する関数
func setup_example_scenario():
	"""サンプル設定"""
	var script_files = [
		"res://scenarios/main.rgd",
		"res://scenarios/chapter1.rgd", 
		"res://scenarios/chapter2.rgd"
	]
	preload_scripts(script_files)
	
	# メインスクリプトから開始
	jump_to_file_label("main.rgd", "start")