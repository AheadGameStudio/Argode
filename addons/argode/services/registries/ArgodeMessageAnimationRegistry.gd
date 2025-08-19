extends RefCounted
class_name ArgodeMessageAnimationRegistry

## メッセージアニメーション効果のレジストリ
## builtin/message_animations/ と custom_message_animations/ から効果クラスを自動登録

signal progress_updated(task_name: String, progress: float, total: int, current: int)
signal registry_completed(registry_name: String)

var search_directories: Array[String] = []
var total_files: int = 0
var processed_files: int = 0
var animation_dictionary: Dictionary = {}

func _init():
	_load_search_directories()

## 検索ディレクトリを設定
func _load_search_directories():
	search_directories = [
		"res://addons/argode/builtin/message_animations/"
	]
	
	# プロジェクト設定からカスタムアニメーションディレクトリを取得
	var custom_dir = ProjectSettings.get_setting("argode/general/custom_animation_directory", "res://custom_message_animations/")
	if custom_dir != "":
		search_directories.append(custom_dir)

## レジストリ処理を開始
func start_registry():
	total_files = 0
	processed_files = 0
	animation_dictionary.clear()
	
	# ファイル総数をカウント
	_count_gd_files()
	
	ArgodeSystem.log("🔄 ArgodeMessageAnimationRegistry started. Total files: %d" % total_files)
	
	# アニメーションファイルを処理
	await _process_animation_files()
	
	ArgodeSystem.log("✅ ArgodeMessageAnimationRegistry completed. Registered %d animations." % animation_dictionary.size())
	registry_completed.emit("ArgodeMessageAnimationRegistry")

## GDScriptファイル数をカウント
func _count_gd_files():
	for directory_path in search_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			total_files += _count_gd_files_recursive(directory_path)

func _count_gd_files_recursive(path: String) -> int:
	var count = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				count += _count_gd_files_recursive(path.path_join(file_name))
			elif file_name.ends_with(".gd"):
				count += 1
			file_name = dir.get_next()
	return count

## アニメーションファイルを非同期で処理
func _process_animation_files():
	for directory_path in search_directories:
		if DirAccess.dir_exists_absolute(directory_path):
			await _process_directory_recursive(directory_path)

func _process_directory_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				await _process_directory_recursive(path.path_join(file_name))
			elif file_name.ends_with(".gd"):
				await _process_animation_file(path.path_join(file_name))
			file_name = dir.get_next()

## 個別のアニメーションファイルを処理
func _process_animation_file(file_path: String):
	processed_files += 1
	var progress = float(processed_files) / float(total_files)
	progress_updated.emit("アニメーション登録", progress, total_files, processed_files)
	
	var animation_data = _parse_animation_class(file_path)
	if animation_data.has("effect_name") and animation_data.has("class_name"):
		animation_dictionary[animation_data.effect_name] = {
			"class_name": animation_data.class_name,
			"file_path": file_path,
			"script_resource": animation_data.script_resource,
			"description": animation_data.description
		}
		ArgodeSystem.log("🎨 Animation registered: %s -> %s" % [animation_data.effect_name, animation_data.class_name])

## アニメーションクラス情報を抽出
func _parse_animation_class(file_path: String) -> Dictionary:
	var script = load(file_path)
	if not script:
		return {}
	
	# CharacterAnimationEffectを継承しているかチェック
	var instance = script.new()
	if not (instance is CharacterAnimationEffect):
		return {}
	
	# _ready()を呼び出して初期化
	if instance.has_method("_ready"):
		instance._ready()
	
	var script_class = script.get_global_name()
	if script_class.is_empty():
		script_class = file_path.get_file().get_basename()
	
	var effect_name = instance.get("effect_name")
	var description = instance.get("effect_description")
	
	if not effect_name:
		# effect_nameが設定されていない場合、クラス名から推定
		effect_name = _derive_effect_name(script_class)
	
	return {
		"class_name": script_class,
		"effect_name": effect_name,
		"script_resource": script,
		"description": description if description else "アニメーション効果"
	}

## クラス名から効果名を推定
func _derive_effect_name(script_class_name: String) -> String:
	if script_class_name.ends_with("Effect"):
		var base_name = script_class_name.substr(0, script_class_name.length() - 6)  # "Effect" = 6文字
		return base_name.to_lower()
	else:
		return script_class_name.to_lower()

## 指定された効果のインスタンスを作成
func create_effect(effect_name: String, parameters: Dictionary = {}) -> CharacterAnimationEffect:
	if not animation_dictionary.has(effect_name):
		ArgodeSystem.log("⚠️ Unknown animation effect: %s" % effect_name, 1)
		return null
	
	var animation_data = animation_dictionary[effect_name]
	var script = animation_data.script_resource
	var instance = script.new()
	
	# パラメータを適用（duration等）
	if parameters.has("duration"):
		instance.duration = parameters.duration
	if parameters.has("delay"):
		instance.delay = parameters.delay
	
	return instance

## 特定の効果が存在するかチェック
func has_effect(effect_name: String) -> bool:
	return animation_dictionary.has(effect_name)

## 全効果名のリストを取得
func get_effect_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for effect_name in animation_dictionary.keys():
		names.append(effect_name)
	return names

## 効果の詳細情報を取得
func get_effect_info(effect_name: String) -> Dictionary:
	if animation_dictionary.has(effect_name):
		return animation_dictionary[effect_name]
	return {}

## 全効果の情報を取得
func get_all_effects() -> Dictionary:
	return animation_dictionary.duplicate()
