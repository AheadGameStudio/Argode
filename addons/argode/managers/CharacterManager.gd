extends Node

# v2: CharacterLayerベースの実装に移行
var character_sprites: Dictionary = {}
var character_registry: Dictionary = {} # キャラクター登録情報

# v2: ArgodeSystem統合により、直接参照に変更
var transition_player  # TransitionPlayer
var variable_manager  # VariableManager - ArgodeSystemから設定される
var character_defs  # CharacterDefinitionManager - v2新機能
var layer_manager  # LayerManager - v2新機能

func _ready():
	print("👤 CharacterManager initialized (v2)")
	# v2: 参照はArgodeSystemの_setup_manager_references()で設定される

# キャラクター定義登録（CharacterDefinitionManagerからの呼び出し用）
func register_character(char_id: String, definition: Dictionary):
	"""キャラクターを登録"""
	character_registry[char_id] = definition
	print("✅ Character registered: ", char_id, " -> ", definition)

func is_character_defined(char_id: String) -> bool:
	"""キャラクターが定義されているかチェック"""
	return char_id in character_registry

func get_character_definition(char_id: String) -> Dictionary:
	"""キャラクター定義を取得"""
	return character_registry.get(char_id, {})

func list_characters() -> Array[String]:
	"""登録されているキャラクター一覧を取得"""
	var chars: Array[String] = []
	chars.append_array(character_registry.keys())
	return chars

func show_character(char_id: String, expression: String, position: String, transition: String):
	print("🧍‍♀️ Showing: ", char_id, " (", expression, ") at ", position, " with ", transition)
	
	# v2: LayerManagerに処理を委譲
	if not layer_manager:
		push_error("❌ LayerManager not available")
		return
	
	await layer_manager.show_character(char_id, expression, position, transition)

func hide_character(char_id: String, transition: String):
	print("👻 Hiding: ", char_id, " with ", transition)
	
	# v2: LayerManagerに処理を委譲
	if not layer_manager:
		push_error("❌ LayerManager not available")
		return
	
# v2: 古い背景処理は完全廃止 - LayerManagerを使用してください