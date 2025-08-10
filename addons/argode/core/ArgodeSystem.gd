# ArgodeSystem.gd
# Argode v2: Advanced visual novel engine core system
class_name ArgodeSystemCore
extends Node

# === シグナル ===
signal system_initialized
signal system_error(message: String)

# === 各Managerへのパブリックな参照 ===
var Player  # ArgodeScriptPlayer
var AssetManager  # 未実装 (v2新機能)
var SaveLoadManager  # 未実装 (Ren'Py機能)
var LabelRegistry  # LabelRegistry
var ImageDefs  # ImageDefinitionManager
var CharDefs  # CharacterDefinitionManager  
var AudioDefs  # AudioDefinitionManager
var ShaderDefs  # ShaderDefinitionManager
var UIManager  # UIManager
var CharacterManager  # CharacterManager
var VariableManager  # VariableManager
var TransitionPlayer  # TransitionPlayer
var LayerManager  # LayerManager (v2新機能)
var CustomCommandHandler  # CustomCommandHandler (v2新機能)

# === レイヤーマッピング (v2新機能) ===
var layers: Dictionary = {}

# === システム状態 ===
var is_initialized: bool = false
var initialization_errors: Array[String] = []

func _ready():
	print("🎮 ArgodeSystem: Initializing v2 architecture...")
	# グループに追加（他のノードから参照しやすくする）
	add_to_group("argode_system")
	_create_managers()

func _create_managers():
	"""既存のManagerインスタンスを子ノードとして作成・統合"""
	print("📦 Creating and integrating managers...")
	
	# 既存のv1 Managerを子ノードとして作成
	var script_player_script = preload("res://addons/argode/script/ArgodeScriptPlayer.gd")
	Player = script_player_script.new()
	Player.name = "AdvScriptPlayer"
	add_child(Player)
	
	var label_registry_script = preload("res://addons/argode/core/LabelRegistry.gd")
	LabelRegistry = label_registry_script.new()
	LabelRegistry.name = "LabelRegistry"
	add_child(LabelRegistry)
	
	var ui_manager_script = preload("res://addons/argode/managers/UIManager.gd")
	UIManager = ui_manager_script.new()
	UIManager.name = "UIManager"
	add_child(UIManager)
	
	var character_manager_script = preload("res://addons/argode/managers/CharacterManager.gd")
	CharacterManager = character_manager_script.new()
	CharacterManager.name = "CharacterManager"
	add_child(CharacterManager)
	
	var variable_manager_script = preload("res://addons/argode/managers/VariableManager.gd")
	VariableManager = variable_manager_script.new()
	VariableManager.name = "VariableManager"
	add_child(VariableManager)
	
	var transition_player_script = preload("res://addons/argode/managers/TransitionPlayer.gd")
	TransitionPlayer = transition_player_script.new()
	TransitionPlayer.name = "TransitionPlayer"
	add_child(TransitionPlayer)
	
	# v2新機能: DefinitionManagers
	var image_def_script = preload("res://addons/argode/managers/ImageDefinitionManager.gd")
	ImageDefs = image_def_script.new()
	ImageDefs.name = "ImageDefinitionManager"
	add_child(ImageDefs)
	
	var char_def_script = preload("res://addons/argode/managers/CharacterDefinitionManager.gd")
	CharDefs = char_def_script.new()
	CharDefs.name = "CharacterDefinitionManager"
	add_child(CharDefs)
	
	var audio_def_script = preload("res://addons/argode/managers/AudioDefinitionManager.gd")
	AudioDefs = audio_def_script.new()
	AudioDefs.name = "AudioDefinitionManager"
	add_child(AudioDefs)
	
	var shader_def_script = preload("res://addons/argode/managers/ShaderDefinitionManager.gd")
	ShaderDefs = shader_def_script.new()
	ShaderDefs.name = "ShaderDefinitionManager"
	add_child(ShaderDefs)
	
	# v2新機能: LayerManager
	var layer_manager_script = preload("res://addons/argode/managers/LayerManager.gd")
	LayerManager = layer_manager_script.new()
	LayerManager.name = "LayerManager"
	add_child(LayerManager)
	
	# v2新機能: CustomCommandHandler
	var custom_command_script = preload("res://addons/argode/commands/CustomCommandHandler.gd")
	CustomCommandHandler = custom_command_script.new()
	CustomCommandHandler.name = "CustomCommandHandler"
	add_child(CustomCommandHandler)
	
	# 組み込みコマンドの自動登録
	_register_builtin_commands()
	
	print("✅ All managers created successfully")

func _register_builtin_commands():
	"""カスタムコマンドを自動発見・登録"""
	print("📝 Auto-discovering custom commands...")
	
	var registered_count = _auto_discover_and_register_commands()
	
	print("📝 Auto-registration completed: ", registered_count, " commands registered")

func _auto_discover_and_register_commands() -> int:
	"""カスタムコマンドを自動発見・登録する"""
	var registered_count = 0
	var search_directories = [
		"res://custom/commands/",
		"res://addons/*/commands/",  # 他のアドオンからのコマンド
		"res://project_commands/",   # プロジェクト専用コマンドディレクトリ
	]
	
	for directory in search_directories:
		var found_commands = _scan_directory_for_commands(directory)
		
		for command_path in found_commands:
			if _try_load_and_register_command(command_path):
				registered_count += 1
	
	return registered_count

func _scan_directory_for_commands(directory_path: String) -> Array[String]:
	"""指定ディレクトリ内のコマンドファイルをスキャン"""
	var command_files: Array[String] = []
	
	# ワイルドカード対応
	if directory_path.contains("*"):
		return _scan_wildcard_directories(directory_path)
	
	var dir = DirAccess.open(directory_path)
	if not dir:
		# ディレクトリが存在しない場合は警告しない（オプションディレクトリ）
		return command_files
	
	print("🔍 Scanning for commands in: ", directory_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".gd") and not file_name.begins_with("."):
			var full_path = directory_path + file_name
			
			# BaseCustomCommandを継承しているかチェック
			if _is_custom_command_file(full_path):
				command_files.append(full_path)
				print("   🎯 Found custom command: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return command_files

func _scan_wildcard_directories(wildcard_path: String) -> Array[String]:
	"""ワイルドカード付きディレクトリをスキャン（例：res://addons/*/commands/）"""
	var command_files: Array[String] = []
	var parts = wildcard_path.split("/")
	var wildcard_index = -1
	
	# ワイルドカードの位置を特定
	for i in range(parts.size()):
		if parts[i].contains("*"):
			wildcard_index = i
			break
	
	if wildcard_index == -1:
		return command_files
	
	# ワイルドカード前までのパスを構築
	var base_path = ""
	for i in range(wildcard_index):
		base_path += parts[i] + "/"
	
	# ワイルドカード後のパスを構築
	var suffix_path = ""
	for i in range(wildcard_index + 1, parts.size()):
		suffix_path += "/" + parts[i]
	
	var dir = DirAccess.open(base_path)
	if not dir:
		return command_files
	
	dir.list_dir_begin()
	var dir_name = dir.get_next()
	
	while dir_name != "":
		if dir.current_is_dir() and not dir_name.begins_with("."):
			var candidate_path = base_path + dir_name + suffix_path
			var found_in_subdir = _scan_directory_for_commands(candidate_path)
			command_files.append_array(found_in_subdir)
		
		dir_name = dir.get_next()
	
	dir.list_dir_end()
	return command_files

func _is_custom_command_file(script_path: String) -> bool:
	"""ファイルがBaseCustomCommandを継承しているかチェック"""
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# BaseCustomCommandを継承しているかチェック
	var inherits_base_command = (
		content.contains("extends BaseCustomCommand") or
		content.contains("extends \"res://addons/argode/commands/BaseCustomCommand.gd\"")
	)
	
	# class_nameが定義されているかもチェック（推奨パターン）
	var has_class_name = content.contains("class_name") and content.contains("Command")
	
	return inherits_base_command

func _try_load_and_register_command(script_path: String) -> bool:
	"""指定されたスクリプトパスからカスタムコマンドをロード・登録"""
	if not ResourceLoader.exists(script_path):
		print("⚠️ Command script not found: ", script_path)
		return false
	
	var script = load(script_path)
	if not script:
		print("❌ Failed to load command script: ", script_path)
		return false
	
	var command_instance = script.new() as BaseCustomCommand
	if not command_instance:
		print("❌ Failed to create command instance: ", script_path)
		return false
	
	return CustomCommandHandler.add_custom_command(command_instance)

func initialize_game(layer_map: Dictionary) -> bool:
	"""
	v2設計: ゲームのメインシーンから呼び出される統一初期化関数
	@param layer_map: レイヤーロール名 -> CanvasLayer のマッピング
	@return: 初期化成功時 true
	"""
	print("🚀 ArgodeSystem: Starting game initialization...")
	initialization_errors.clear()
	
	# 1. レイヤーをマッピング
	self.layers = layer_map
	print("🗺️ Layer mapping configured: ", layer_map.keys())
	
	# 2. 各定義をビルド (v2新機能)
	_build_definitions()
	
	# 3. LayerManagerを初期化 (v2新機能)
	_initialize_layer_manager(layer_map)
	
	# 4. ラベルレジストリは既に_ready()で初期化済み
	print("🏷️ Label registry already initialized during _ready()")
	
	# 5. フローグラフをビルド (v2新機能 - 未実装)
	# AssetManager.build_graph_and_associate_assets()
	
	# 6. CustomCommandHandlerを初期化 (v2新機能)
	_initialize_custom_command_handler()
	
	# 7. マネージャー間の参照を設定
	_setup_manager_references()
	
	is_initialized = true
	system_initialized.emit()
	print("✅ ArgodeSystem: Game initialization completed successfully!")
	return true

func _initialize_layer_manager(layer_map: Dictionary):
	"""LayerManagerを初期化"""
	if not LayerManager:
		push_error("❌ LayerManager not created")
		return
	
	var bg_layer = layer_map.get("background", null)
	var char_layer = layer_map.get("character", null)
	var ui_layer = layer_map.get("ui", null)
	
	LayerManager.initialize_layers(bg_layer, char_layer, ui_layer)
	print("🗺️ LayerManager initialized with layers")

func _initialize_custom_command_handler():
	"""CustomCommandHandlerを初期化"""
	if not CustomCommandHandler:
		push_error("❌ CustomCommandHandler not created")
		return
	
	CustomCommandHandler.initialize(self)
	print("🎯 CustomCommandHandler initialized and connected")

func _setup_manager_references():
	"""マネージャー間の相互参照を設定"""
	# AdvScriptPlayerに他のマネージャーへの参照を設定
	Player.character_manager = CharacterManager
	Player.ui_manager = UIManager
	Player.variable_manager = VariableManager
	Player.transition_player = TransitionPlayer
	Player.label_registry = LabelRegistry
	Player.layer_manager = LayerManager  # v2新機能
	
	# CharacterManagerに他のマネージャーへの参照を設定
	CharacterManager.transition_player = TransitionPlayer
	CharacterManager.variable_manager = VariableManager
	CharacterManager.character_defs = CharDefs  # v2新機能
	CharacterManager.layer_manager = LayerManager  # v2新機能
	
	# UIManagerに他のマネージャーへの参照を設定
	UIManager.script_player = Player
	UIManager.character_defs = CharDefs  # v2新機能
	UIManager.layer_manager = LayerManager  # v2新機能
	
	print("🔗 Manager references configured")

func _build_definitions():
	"""v2新機能: 各定義ステートメントをビルド"""
	print("📊 Building definitions...")
	CharDefs.build_definitions()
	ImageDefs.build_definitions()
	AudioDefs.build_definitions()
	ShaderDefs.build_definitions()
	print("✅ All definitions built")

func _emit_initialization_errors():
	"""初期化エラーをシグナルで通知"""
	for error in initialization_errors:
		system_error.emit(error)
		push_error("🚫 ArgodeSystem Error: " + error)

func get_layer(role_name: String) -> CanvasLayer:
	"""
	v2設計: レイヤーを取得するための安全なインターフェース
	@param role_name: レイヤーのロール名 ("background", "character", "ui"等)
	@return: 対応するCanvasLayer、なければnull
	"""
	var layer = layers.get(role_name, null)
	if not layer:
		push_warning("⚠️ Layer not found for role: " + role_name)
	return layer

# === Convenience methods ===

func start_script(script_path: String, label_name: String = "start"):
	"""スクリプトの読み込みと実行開始"""
	if not is_initialized:
		push_error("🚫 ArgodeSystem not initialized! Call initialize_game() first.")
		return
	
	Player.load_script(script_path)
	
	# v2新機能: スクリプトロード後に定義ステートメントを事前解析
	_preparse_v2_definitions(Player.script_lines)
	
	Player.play_from_label(label_name)

func is_playing() -> bool:
	"""シナリオ再生中かどうか"""
	return Player.is_playing if Player else false

func _preparse_v2_definitions(script_lines: PackedStringArray):
	"""v2新機能: スクリプト内の定義ステートメントを事前解析"""
	print("🔍 Preparsing v2 definition statements...")
	
	var definitions_found = 0
	
	for line in script_lines:
		line = line.strip_edges()
		
		# 空行やコメントをスキップ
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# 各定義ステートメントを解析
		if line.begins_with("character "):
			if CharDefs and CharDefs.parse_character_statement(line):
				definitions_found += 1
		elif line.begins_with("image "):
			if ImageDefs and ImageDefs.parse_image_statement(line):
				definitions_found += 1
		elif line.begins_with("audio "):
			if AudioDefs and AudioDefs.parse_audio_statement(line):
				definitions_found += 1
		elif line.begins_with("shader "):
			if ShaderDefs and ShaderDefs.parse_shader_statement(line):
				definitions_found += 1
	
	print("✅ Preparsed ", definitions_found, " v2 definition statements")
	
	# 定義カウント更新
	_rebuild_definition_counts()

func _rebuild_definition_counts():
	"""定義カウントを再計算（デバッグ用）"""
	if CharDefs:
		CharDefs.build_definitions()
	if ImageDefs:
		ImageDefs.build_definitions()
	if AudioDefs:
		AudioDefs.build_definitions()
	if ShaderDefs:
		ShaderDefs.build_definitions()

func next_line():
	"""次の行に進む（ユーザー入力処理用）"""
	if Player:
		Player.next()

# === カスタムコマンド管理API ===

func get_custom_command_handler() -> CustomCommandHandler:
	"""CustomCommandHandlerへの安全なアクセス"""
	return CustomCommandHandler

func register_custom_command(custom_command: BaseCustomCommand) -> bool:
	"""カスタムコマンドを登録（外部から呼び出し可能）"""
	if not CustomCommandHandler:
		push_error("❌ CustomCommandHandler not initialized")
		return false
	
	return CustomCommandHandler.add_custom_command(custom_command)

func register_command_by_callable(command_name: String, callable: Callable, is_sync: bool = false) -> bool:
	"""Callable形式でカスタムコマンドを登録"""
	if not CustomCommandHandler:
		push_error("❌ CustomCommandHandler not initialized")
		return false
	
	return CustomCommandHandler.add_custom_command_by_callable(command_name, callable, is_sync)

func list_custom_commands() -> Array[String]:
	"""登録されているカスタムコマンド一覧を取得"""
	if not CustomCommandHandler:
		return []
	
	return CustomCommandHandler.list_registered_commands()