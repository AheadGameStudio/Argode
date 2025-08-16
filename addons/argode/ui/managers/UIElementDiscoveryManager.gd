extends RefCounted
class_name UIElementDiscoveryManager

## UI要素発見・設定管理システム
##
## ArgodeScreenのUI要素自動発見とNodePath設定を専門に行います。
## @export NodePath優先、フォールバック自動発見の高度なUI要素発見機能を提供します。

# UI要素のNodePath設定
var message_box_path: NodePath = ""
var name_label_path: NodePath = ""
var message_label_path: NodePath = ""
var choice_container_path: NodePath = ""
var choice_panel_path: NodePath = ""
var choice_vbox_path: NodePath = ""
var continue_prompt_path: NodePath = ""

# 発見されたUI要素の参照
var discovered_elements: Dictionary = {}

# 検索ルートノード
var root_node: Node = null

## 初期化
func initialize(
	target_root: Node,
	msg_box_path: NodePath = NodePath(""),
	name_lbl_path: NodePath = NodePath(""),
	msg_lbl_path: NodePath = NodePath(""),
	choice_cont_path: NodePath = NodePath(""),
	choice_pnl_path: NodePath = NodePath(""),
	choice_vbox_path: NodePath = NodePath(""),
	continue_prmpt_path: NodePath = NodePath("")
) -> bool:
	"""UIElementDiscoveryManagerを初期化"""
	
	if not target_root:
		print("❌ UIElementDiscoveryManager: No root node provided")
		return false
	
	root_node = target_root
	message_box_path = msg_box_path
	name_label_path = name_lbl_path
	message_label_path = msg_lbl_path
	choice_container_path = choice_cont_path
	choice_panel_path = choice_pnl_path
	choice_vbox_path = choice_vbox_path
	continue_prompt_path = continue_prmpt_path
	
	print("📱 UIElementDiscoveryManager: Initialization complete")
	return true

## UI要素の自動発見とマッピング
func discover_ui_elements() -> Dictionary:
	"""UI要素を設定（@export NodePath優先、フォールバック自動発見）"""
	
	if not root_node:
		print("❌ UIElementDiscoveryManager: No root node available")
		return {}
	
	print("🔍 UIElementDiscoveryManager: Starting UI element discovery")
	print("  - Root node: ", root_node.name, " (", root_node.get_class(), ")")
	print("  - Child count: ", root_node.get_child_count())
	
	# 子ノードの一覧を表示
	print("🔍 UIElementDiscoveryManager: Child nodes:")
	for i in range(root_node.get_child_count()):
		var child = root_node.get_child(i)
		print("  - [", i, "] ", child.name, " (", child.get_class(), ")")
	
	# 1. @exportで指定されたNodePathを優先使用
	var message_box = _get_node_from_path_or_fallback(message_box_path, "MessageBox")
	var name_label = _get_node_from_path_or_fallback(name_label_path, "NameLabel", message_box)
	var message_label = _get_node_from_path_or_fallback(message_label_path, "MessageLabel", message_box)
	
	var choice_container = _get_node_from_path_or_fallback(choice_container_path, "ChoiceContainer")
	var choice_panel = _get_node_from_path_or_fallback(choice_panel_path, "ChoicePanel", choice_container)
	var choice_vbox = _get_node_from_path_or_fallback(choice_vbox_path, "VBoxContainer", choice_panel)
	
	var continue_prompt = _get_node_from_path_or_fallback(continue_prompt_path, "ContinuePrompt")
	
	# 発見結果を辞書に格納
	discovered_elements = {
		"message_box": message_box,
		"name_label": name_label,
		"message_label": message_label,
		"choice_container": choice_container,
		"choice_panel": choice_panel,
		"choice_vbox": choice_vbox,
		"continue_prompt": continue_prompt
	}
	
	print("📱 UIElementDiscoveryManager: Discovery complete - MessageBox=", message_box != null, 
		  ", ChoiceContainer=", choice_container != null, 
		  ", MessageLabel=", message_label != null)
	print("   Using NodePath exports: ", _count_exported_paths(), "/7 specified")
	
	# デバッグ: 実際に見つかった要素を詳細表示
	print("🔍 UIElementDiscoveryManager: Found UI elements:")
	print("  - message_box: ", message_box, " (type: ", message_box.get_class() if message_box else "null", ")")
	print("  - message_label: ", message_label, " (type: ", message_label.get_class() if message_label else "null", ")")
	
	return discovered_elements.duplicate()

## NodePathが指定されていればそれを使用、なければ自動発見
func _get_node_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_node: Node = null) -> Node:
	"""NodePathが指定されていればそれを使用、なければ自動発見"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = root_node.get_node_or_null(node_path)
		if node:
			print("   ✅ UIElementDiscoveryManager: Using NodePath: ", fallback_name, " -> ", node_path, " (", node.get_class(), ")")
			return node
		else:
			print("   ⚠️ UIElementDiscoveryManager: NodePath not found: ", node_path, " for ", fallback_name)
	
	# 2. フォールバック：自動発見
	var search_root = parent_node if parent_node else root_node
	var node = search_root.find_child(fallback_name, true, false)
	
	if node:
		print("   🔍 UIElementDiscoveryManager: Auto-discovered: ", fallback_name, " -> ", node.get_path(), " (", node.get_class(), ")")
	else:
		print("   ❌ UIElementDiscoveryManager: Not found: ", fallback_name)
	
	return node

## 指定されたNodePathの数をカウント
func _count_exported_paths() -> int:
	"""指定されたNodePathの数をカウント"""
	var count = 0
	if not message_box_path.is_empty(): count += 1
	if not name_label_path.is_empty(): count += 1
	if not message_label_path.is_empty(): count += 1
	if not choice_container_path.is_empty(): count += 1
	if not choice_panel_path.is_empty(): count += 1
	if not choice_vbox_path.is_empty(): count += 1
	if not continue_prompt_path.is_empty(): count += 1
	return count

## UI要素取得API
func get_discovered_elements() -> Dictionary:
	"""発見されたUI要素の辞書を取得"""
	return discovered_elements.duplicate()

func get_message_box() -> Control:
	"""メッセージボックスを取得"""
	return discovered_elements.get("message_box")

func get_name_label() -> Label:
	"""名前ラベルを取得"""
	return discovered_elements.get("name_label")

func get_message_label() -> RichTextLabel:
	"""メッセージラベルを取得"""
	return discovered_elements.get("message_label")

func get_choice_container() -> Control:
	"""選択肢コンテナを取得"""
	return discovered_elements.get("choice_container")

func get_choice_panel() -> PanelContainer:
	"""選択肢パネルを取得"""
	return discovered_elements.get("choice_panel")

func get_choice_vbox() -> VBoxContainer:
	"""選択肢VBoxContainerを取得"""
	return discovered_elements.get("choice_vbox")

func get_continue_prompt() -> Control:
	"""継続プロンプトを取得"""
	return discovered_elements.get("continue_prompt")

## NodePath設定更新API
func update_node_paths(
	msg_box_path: NodePath = NodePath(""),
	name_lbl_path: NodePath = NodePath(""),
	msg_lbl_path: NodePath = NodePath(""),
	choice_cont_path: NodePath = NodePath(""),
	choice_pnl_path: NodePath = NodePath(""),
	choice_vbox_path: NodePath = NodePath(""),
	continue_prmpt_path: NodePath = NodePath("")
):
	"""NodePath設定を更新"""
	message_box_path = msg_box_path
	name_label_path = name_lbl_path
	message_label_path = msg_lbl_path
	choice_container_path = choice_cont_path
	choice_panel_path = choice_pnl_path
	choice_vbox_path = choice_vbox_path
	continue_prompt_path = continue_prmpt_path
	
	print("📱 UIElementDiscoveryManager: NodePath settings updated")

## 検証API
func validate_required_elements() -> bool:
	"""必須のUI要素が発見されているかを検証"""
	var message_box = discovered_elements.get("message_box")
	var message_label = discovered_elements.get("message_label")
	
	if not message_box:
		print("⚠️ UIElementDiscoveryManager: Required MessageBox not found")
		return false
	
	if not message_label:
		print("⚠️ UIElementDiscoveryManager: Required MessageLabel not found")
		return false
	
	return true

## クリーンアップ
func cleanup():
	"""リソースのクリーンアップ"""
	discovered_elements.clear()
	root_node = null
	
	print("📱 UIElementDiscoveryManager: Cleanup complete")
