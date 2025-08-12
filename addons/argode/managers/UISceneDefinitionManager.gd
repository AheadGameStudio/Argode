# UISceneDefinitionManager.gd
# v2新機能: UIシーン定義管理システム
class_name UISceneDefinitionManager
extends Node

# UI シーン定義辞書 (名前 -> パス)
var ui_scene_definitions: Dictionary = {}

# 定義統計
var total_ui_scenes: int = 0

func _ready():
	print("🎬 UISceneDefinitionManager initialized")

func build_definitions():
	"""定義統計を更新（デバッグ用）"""
	total_ui_scenes = ui_scene_definitions.size()
	print("🎬 UI Scene definitions built: ", total_ui_scenes, " scenes")

func parse_ui_scene_statement(line: String) -> bool:
	"""
	ui_scene ステートメントを解析して登録
	形式: ui_scene scene_name "path/to/scene.tscn"
	"""
	line = line.strip_edges()
	
	if not line.begins_with("ui_scene "):
		return false
	
	# "ui_scene " を削除
	var content = line.substr(9).strip_edges()
	
	# 最初の空白までが名前、残りがパス（クォートで囲まれている）
	var parts = content.split(" ", false, 1)
	if parts.size() < 2:
		push_warning("⚠️ Invalid ui_scene statement: " + line)
		return false
	
	var scene_name = parts[0]
	var scene_path = parts[1]
	
	# パスのクォートを削除
	if scene_path.begins_with("\"") and scene_path.ends_with("\""):
		scene_path = scene_path.substr(1, scene_path.length() - 2)
	
	# UI シーン定義を登録
	ui_scene_definitions[scene_name] = scene_path
	print("🎬 UI Scene registered: ", scene_name, " -> ", scene_path)
	
	return true

func get_ui_scene_path(scene_name: String) -> String:
	"""
	UIシーン名からパスを取得
	@param scene_name: UIシーン名
	@return: TSCNファイルパス、見つからない場合は空文字
	"""
	if scene_name in ui_scene_definitions:
		return ui_scene_definitions[scene_name]
	else:
		push_warning("⚠️ UI scene not found: " + scene_name)
		return ""

func has_ui_scene(scene_name: String) -> bool:
	"""
	指定されたUIシーン名が定義されているかチェック
	"""
	return scene_name in ui_scene_definitions

func list_ui_scenes() -> Array[String]:
	"""
	登録されている全てのUIシーン名を取得
	"""
	var scenes: Array[String] = []
	for scene_name in ui_scene_definitions.keys():
		scenes.append(scene_name)
	return scenes

func get_definition_info() -> Dictionary:
	"""
	定義情報を辞書として取得（デバッグ用）
	"""
	return {
		"total_ui_scenes": total_ui_scenes,
		"ui_scenes": ui_scene_definitions.duplicate()
	}

# デバッグ用: 全定義を表示
func debug_print_all_definitions():
	print("🎬 UISceneDefinitionManager Debug Info:")
	print("   Total UI Scenes: ", total_ui_scenes)
	print("   Definitions:")
	for scene_name in ui_scene_definitions.keys():
		print("     - ", scene_name, " -> ", ui_scene_definitions[scene_name])
