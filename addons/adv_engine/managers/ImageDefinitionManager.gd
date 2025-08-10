# ImageDefinitionManager.gd
# v2新機能: `image` ステートメント解析・管理
extends Node
class_name ImageDefinitionManager

# === シグナル ===
signal image_defined(tags: Array[String], definition: Dictionary)
signal definition_error(message: String)

# === 定義ストレージ ===
var image_definitions: Dictionary = {}  # "tag1 tag2" -> definition

# === 正規表現パターン ===
var regex_image_simple: RegEx  # image yuko happy = "path"
var regex_image_animation: RegEx  # image yuko idle:

func _ready():
	_compile_regex()
	print("🖼️ ImageDefinitionManager initialized (v2)")

func _compile_regex():
	"""image ステートメント解析用の正規表現をコンパイル"""
	# 静止画: image yuko happy = "res://images/yuko_happy.png"
	regex_image_simple = RegEx.new()
	regex_image_simple.compile("^image\\s+(?<tags>[^=]+)\\s*=\\s*\"(?<path>[^\"]+)\"")
	
	# アニメーション: image yuko idle:
	regex_image_animation = RegEx.new()
	regex_image_animation.compile("^image\\s+(?<tags>[^:]+):")

func parse_image_statement(line: String) -> bool:
	"""
	image ステートメントを解析して定義を登録
	@param line: 解析する行
	@return: 解析成功時 true
	"""
	line = line.strip_edges()
	
	# 静止画の場合
	var simple_match = regex_image_simple.search(line)
	if simple_match:
		return _parse_simple_image(simple_match)
	
	# アニメーション開始の場合
	var anim_match = regex_image_animation.search(line)
	if anim_match:
		return _parse_animation_start(anim_match)
	
	return false

func _parse_simple_image(match: RegExMatch) -> bool:
	"""静止画定義を解析"""
	var tags_str = match.get_string("tags").strip_edges()
	var path = match.get_string("path")
	
	var tags = _parse_tags(tags_str)
	var definition = {
		"type": "static",
		"path": path
	}
	
	var tag_key = " ".join(tags)
	image_definitions[tag_key] = definition
	image_defined.emit(tags, definition)
	
	print("🖼️ Static image defined: ", tag_key, " -> ", path)
	return true

func _parse_animation_start(match: RegExMatch) -> bool:
	"""アニメーション開始を解析（実際のフレーム情報は後続行で解析）"""
	var tags_str = match.get_string("tags").strip_edges()
	var tags = _parse_tags(tags_str)
	
	var definition = {
		"type": "animation",
		"frames": [],
		"loop": false
	}
	
	var tag_key = " ".join(tags)
	image_definitions[tag_key] = definition
	
	print("🖼️ Animation started: ", tag_key)
	return true

func parse_animation_frame(line: String, current_animation_tags: Array[String]) -> bool:
	"""
	アニメーションフレーム行を解析
	例: "res://images/yuko_idle_1.png"
	例: 0.5
	例: loop
	"""
	line = line.strip_edges()
	
	if line.is_empty():
		return false
	
	var tag_key = " ".join(current_animation_tags)
	if not tag_key in image_definitions:
		return false
	
	var definition = image_definitions[tag_key]
	
	# ループ指定
	if line.to_lower() == "loop":
		definition["loop"] = true
		print("🖼️ Animation loop enabled: ", tag_key)
		return true
	
	# 画像パス
	if line.begins_with("\"") and line.ends_with("\""):
		var path = line.substr(1, line.length() - 2)  # クォートを除去
		definition["frames"].append({"path": path, "duration": 1.0})  # デフォルト1秒
		print("🖼️ Animation frame added: ", tag_key, " -> ", path)
		return true
	
	# 時間指定
	if line.is_valid_float():
		var duration = line.to_float()
		var frames = definition["frames"]
		if frames.size() > 0:
			frames[frames.size() - 1]["duration"] = duration
			print("🖼️ Animation frame duration set: ", tag_key, " -> ", duration)
			return true
	
	return false

func _parse_tags(tags_str: String) -> Array[String]:
	"""タグ文字列をArray[String]に分割"""
	var tags: Array[String] = []
	for tag in tags_str.split(" "):
		tag = tag.strip_edges()
		if not tag.is_empty():
			tags.append(tag)
	return tags

func get_image_definition(tags: Array[String]) -> Dictionary:
	"""画像定義を取得"""
	var tag_key = " ".join(tags)
	return image_definitions.get(tag_key, {})

func get_image_path(tag_string: String) -> String:
	"""文字列キーから画像パスを取得"""
	if tag_string in image_definitions:
		var definition = image_definitions[tag_string]
		if "path" in definition:
			return definition["path"]
	return ""

func has_image(tags: Array[String]) -> bool:
	"""画像が定義済みかチェック"""
	var tag_key = " ".join(tags)
	return tag_key in image_definitions

func find_best_match(tags: Array[String]) -> Dictionary:
	"""
	タグの最適マッチを検索（部分マッチも考慮）
	例: ["yuko", "happy"] で "yuko happy" や "yuko" にマッチ
	"""
	var tag_key = " ".join(tags)
	
	# 完全マッチ
	if tag_key in image_definitions:
		return image_definitions[tag_key]
	
	# 部分マッチを検索（より多くのタグがマッチするものを優先）
	var best_match = {}
	var best_score = 0
	
	for defined_key in image_definitions.keys():
		var defined_tags = defined_key.split(" ")
		var score = 0
		
		for tag in tags:
			if tag in defined_tags:
				score += 1
		
		if score > best_score and score > 0:
			best_score = score
			best_match = image_definitions[defined_key]
	
	return best_match

func build_definitions():
	"""v2設計: 定義をビルド（現在は何もしない）"""
	print("🖼️ Image definitions built: ", image_definitions.size(), " images")

func clear_definitions():
	"""全定義をクリア"""
	image_definitions.clear()
	print("🖼️ Image definitions cleared")