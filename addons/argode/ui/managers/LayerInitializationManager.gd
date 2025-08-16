extends RefCounted
class_name LayerInitializationManager

## レイヤー初期化管理システム
##
## ArgodeSystemのレイヤー初期化とマッピング構築を専門に行います。
## ArgodeScreenから分離され、レイヤー管理の責任を集約しています。

# AutoLayerSetupの参照
const AutoLayerSetup = preload("res://addons/argode/managers/AutoLayerSetup.gd")

# レイヤー設定
var auto_create_layers: bool = true
var background_layer_path: NodePath = ""
var character_layer_path: NodePath = ""
var ui_layer_path: NodePath = ""

# レイヤーマッピング辞書
var layer_mappings: Dictionary = {
	"background": null,
	"character": null,
	"ui": null
}

# ArgodeSystemの参照
var adv_system = null

## 初期化
func initialize(
	auto_create: bool = true,
	bg_path: NodePath = NodePath(""),
	char_path: NodePath = NodePath(""),
	ui_path: NodePath = NodePath(""),
	argode_system = null
) -> bool:
	"""LayerInitializationManagerを初期化"""
	
	auto_create_layers = auto_create
	background_layer_path = bg_path
	character_layer_path = char_path
	ui_layer_path = ui_path
	adv_system = argode_system
	
	if not adv_system:
		adv_system = Engine.get_singleton("ArgodeSystem")
		if not adv_system:
			# RefCountedクラスではget_nodeは使用できないため、外部から注入される必要がある
			print("⚠️ LayerInitializationManager: ArgodeSystem must be provided externally")
	
	if not adv_system:
		print("❌ LayerInitializationManager: ArgodeSystem not found")
		return false
	
	print("📱 LayerInitializationManager: Initialization complete")
	return true

## レイヤーマッピングの構築とArgodeSystem初期化
func setup_layers(parent_scene: Node, ui_fallback_node: Node = null) -> bool:
	"""レイヤーマッピングを構築し、ArgodeSystemを初期化"""
	
	if not parent_scene:
		print("❌ LayerInitializationManager: No parent scene provided")
		return false
	
	# レイヤーマッピングを初期化
	_initialize_layer_mappings(parent_scene, ui_fallback_node)
	
	# ArgodeSystemのレイヤー初期化を確実に実行
	return _ensure_layer_manager_initialization()

## レイヤーマッピングの初期化（@export NodePath優先、フォールバック自動発見）
func _initialize_layer_mappings(parent_scene: Node, ui_fallback_node: Node = null):
	"""レイヤーマッピングの初期化"""
	
	if not parent_scene:
		print("⚠️ LayerInitializationManager: Current scene not found for layer mapping")
		return
	
	# 自動展開モードが有効な場合
	if auto_create_layers:
		print("🏗️ LayerInitializationManager: Auto-creating Argode standard layers...")
		layer_mappings = AutoLayerSetup.setup_layer_hierarchy(parent_scene)
		print("✅ LayerInitializationManager: Auto-created layers:", layer_mappings.keys())
		_initialize_layer_manager()
		return
	
	# BackgroundLayer
	var bg_layer = _get_layer_from_path_or_fallback(background_layer_path, "BackgroundLayer", parent_scene)
	if bg_layer:
		layer_mappings["background"] = bg_layer
	
	# CharacterLayer  
	var char_layer = _get_layer_from_path_or_fallback(character_layer_path, "CharacterLayer", parent_scene)
	if char_layer:
		layer_mappings["character"] = char_layer
	
	# UILayer（NodePathが指定されていない場合はui_fallback_node、指定されている場合はそのノードを使用）
	var ui_layer = _get_layer_from_path_or_fallback(ui_layer_path, "", parent_scene)
	if ui_layer:
		layer_mappings["ui"] = ui_layer
		print("   🎯 LayerInitializationManager: Using specified UI layer: ", ui_layer.get_path())
	elif ui_fallback_node:
		layer_mappings["ui"] = ui_fallback_node
		print("   🎯 LayerInitializationManager: Using fallback UI layer: ", ui_fallback_node.get_path())
	else:
		print("   ⚠️ LayerInitializationManager: No UI layer found")
	
	print("📱 LayerInitializationManager: Layer mappings initialized:", layer_mappings)
	
	# LayerManagerを初期化
	_initialize_layer_manager()

## レイヤーをNodePathまたは自動発見で取得
func _get_layer_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_scene: Node) -> Node:
	"""レイヤーをNodePathまたは自動発見で取得"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = parent_scene.get_node_or_null(node_path)
		if node:
			print("   ✅ LayerInitializationManager: Using layer NodePath: ", fallback_name if not fallback_name.is_empty() else "UILayer", " -> ", node_path)
			return node
		else:
			print("   ⚠️ LayerInitializationManager: Layer NodePath not found: ", node_path, " for ", fallback_name if not fallback_name.is_empty() else "UILayer")
	
	# 2. フォールバック：自動発見（UIレイヤーの場合はスキップ）
	if fallback_name.is_empty():
		return null
	
	var found_layer = parent_scene.find_child(fallback_name, true, false)
	if found_layer:
		print("   🔍 LayerInitializationManager: Auto-discovered layer: ", fallback_name, " -> ", found_layer.get_path())
		return found_layer
	else:
		print("   ⚠️ LayerInitializationManager: Layer auto-discovery failed: ", fallback_name)
		return null

## ArgodeSystemのLayerManager初期化
func _initialize_layer_manager():
	"""LayerManagerをレイヤーマッピングで初期化"""
	if not adv_system:
		print("⚠️ LayerInitializationManager: ArgodeSystem not found for LayerManager initialization")
		return
	
	var layer_manager = adv_system.get("LayerManager")
	if not layer_manager:
		print("⚠️ LayerInitializationManager: LayerManager not found in ArgodeSystem")
		return
	
	# レイヤーを取得
	var bg_layer = layer_mappings.get("background")
	var char_layer = layer_mappings.get("character") 
	var ui_layer = layer_mappings.get("ui")
	
	if bg_layer and char_layer and ui_layer:
		layer_manager.initialize_layers(bg_layer, char_layer, ui_layer)
		print("✅ LayerInitializationManager: LayerManager initialized with layers:", layer_mappings.keys())
	else:
		print("⚠️ LayerInitializationManager: Missing layers for LayerManager initialization:", {
			"background": bg_layer != null,
			"character": char_layer != null,
			"ui": ui_layer != null
		})

## LayerManagerの初期化を確実に実行
func _ensure_layer_manager_initialization() -> bool:
	"""LayerManagerの初期化を確実に実行する"""
	if not adv_system:
		print("⚠️ LayerInitializationManager: ArgodeSystem not available - skipping layer initialization")
		return false
	
	if adv_system.is_initialized:
		print("✅ LayerInitializationManager: ArgodeSystem already initialized")
		return true
	
	print("🚀 LayerInitializationManager: Initializing ArgodeSystem LayerManager...")
	var success = adv_system.initialize_game(layer_mappings)
	if not success:
		print("❌ LayerInitializationManager: ArgodeSystem LayerManager initialization failed")
		return false
	else:
		print("✅ LayerInitializationManager: ArgodeSystem LayerManager initialization successful")
		return true

## レイヤーマッピング取得API
func get_layer_mappings() -> Dictionary:
	"""現在のレイヤーマッピングを取得"""
	return layer_mappings.duplicate()

func get_background_layer() -> Node:
	"""背景レイヤーを取得"""
	return layer_mappings.get("background")

func get_character_layer() -> Node:
	"""キャラクターレイヤーを取得"""
	return layer_mappings.get("character")

func get_ui_layer() -> Node:
	"""UIレイヤーを取得"""
	return layer_mappings.get("ui")

## レイヤー設定更新API
func update_layer_settings(
	auto_create: bool = true,
	bg_path: NodePath = NodePath(""),
	char_path: NodePath = NodePath(""),
	ui_path: NodePath = NodePath("")
):
	"""レイヤー設定を更新"""
	auto_create_layers = auto_create
	background_layer_path = bg_path
	character_layer_path = char_path
	ui_layer_path = ui_path
	
	print("📱 LayerInitializationManager: Layer settings updated")

## クリーンアップ
func cleanup():
	"""リソースのクリーンアップ"""
	layer_mappings.clear()
	adv_system = null
	
	print("📱 LayerInitializationManager: Cleanup complete")
