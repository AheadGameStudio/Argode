# AdvScreen.gd
# v2設計: UI基底クラス - call_screenで呼び出されるUIシーンが継承すべき高機能な基底クラス
extends Control
class_name ArgodeScreen

# === シグナル ===
signal screen_closed(return_value)
signal screen_ready()
signal screen_pre_close()

# === 画面管理プロパティ ===
var screen_name: String = ""
var is_screen_active: bool = false
var return_value: Variant = null
var screen_parameters: Dictionary = {}
var parent_screen = null

# === ArgodeSystem統合 ===
var adv_system: Node = null

# === UI要素NodePath設定（エディタで指定可能） ===
@export_group("UI Element Paths")
## メッセージボックス全体のコンテナ（キャラクター名＋メッセージを含む）
@export var message_box_path: NodePath = ""
## キャラクター名を表示するラベル（「由子」「斎藤」など）
@export var name_label_path: NodePath = ""
## メッセージ本文を表示するRichTextLabel（「こんにちは」など）
@export var message_label_path: NodePath = ""
## 選択肢UI全体のコンテナ（選択肢が表示される際に表示される）
@export var choice_container_path: NodePath = ""
## 選択肢の背景パネルコンテナ（選択肢ボタンの背景装飾＋自動配置）
@export var choice_panel_path: NodePath = ""
## 選択肢ボタンが配置されるVBoxContainer（縦に並ぶボタンの親）
@export var choice_vbox_path: NodePath = ""
## 「▼」や「クリックで続行」などの継続プロンプト表示
@export var continue_prompt_path: NodePath = ""

# === 標準UI要素参照（実行時に設定される） ===
var message_box: Control = null
var name_label: Label = null  
var message_label: RichTextLabel = null
var choice_container: Control = null
var choice_panel: PanelContainer = null
var choice_vbox: VBoxContainer = null
var continue_prompt: Label = null

# === TypewriterText統合 ===
var typewriter: TypewriterText = null
var is_message_complete: bool = false
var handle_input: bool = true

# === 自動スクリプト設定 ===
## シーン開始時に自動的にスクリプトを実行するかどうか
@export var auto_start_script: bool = false
## 自動実行するスクリプトファイルのパス（.rgdファイル）
@export var default_script_path: String = ""
## スクリプト開始時のラベル名（通常は"start"）
@export var start_label: String = "start"

# === レイヤーNodePath設定（エディタで指定可能） ===
@export_group("Layer Paths")
## 背景画像を表示するレイヤーノード（CanvasLayerやControlなど）
@export var background_layer_path: NodePath = ""
## キャラクター画像を表示するレイヤーノード（CanvasLayerやControlなど）
@export var character_layer_path: NodePath = ""

# === レイヤーマッピング設定 ===
## レイヤーの実際のノード参照（背景・キャラクター・UIの3層構造）
@export var layer_mappings: Dictionary = {
	"background": null,    # 背景レイヤー（最下層）
	"character": null,     # キャラクターレイヤー（中層）
	"ui": null            # UIレイヤー（最上層、通常はArgodeScreen自身）
}

func _ready():
	screen_name = get_scene_file_path().get_file().get_basename() if get_scene_file_path() else name
	print("📱 AdvScreen initialized: ", screen_name)
	
	# ArgodeSystemへの参照を取得
	adv_system = get_node("/root/ArgodeSystem")
	if not adv_system:
		push_warning("⚠️ AdvScreen: ArgodeSystem not found")
	
	# 初期化完了を通知
	call_deferred("_emit_screen_ready")

func _emit_screen_ready():
	# UI要素の自動発見
	_auto_discover_ui_elements()
	
	# TypewriterText初期化
	_initialize_typewriter()
	
	# レイヤーマッピング初期化
	_initialize_layer_mappings()
	
	# カスタムコマンド接続
	_connect_custom_command_signals()
	
	# UIManager統合
	_setup_ui_manager_integration()
	
	# 自動スクリプト開始
	if auto_start_script:
		call_deferred("_start_auto_script")
	
	screen_ready.emit()
	on_screen_ready()

# === 仮想メソッド群（継承先でオーバーライド） ===

func on_screen_ready():
	"""画面の初期化完了時に呼び出される（継承先でオーバーライド）"""
	pass

func on_screen_shown(parameters: Dictionary = {}):
	"""画面が表示された時に呼び出される（継承先でオーバーライド）"""
	screen_parameters = parameters
	is_screen_active = true
	print("📱 Screen shown: ", screen_name, " with params: ", parameters)

func on_screen_hidden():
	"""画面が非表示になった時に呼び出される（継承先でオーバーライド）"""
	is_screen_active = false
	print("📱 Screen hidden: ", screen_name)

func on_screen_closing() -> bool:
	"""画面が閉じられる直前に呼び出される（継承先でオーバーライド）
	@return: falseを返すとクローズをキャンセル可能"""
	return true

# === スクリーン制御API ===

func show_screen(parameters: Dictionary = {}):
	"""画面を表示する"""
	visible = true
	on_screen_shown(parameters)

func hide_screen():
	"""画面を非表示にする"""
	visible = false
	on_screen_hidden()

func close_screen(return_val: Variant = null):
	"""画面を閉じる"""
	if not on_screen_closing():
		print("📱 Screen close cancelled by on_screen_closing(): ", screen_name)
		return
	
	screen_pre_close.emit()
	return_value = return_val
	is_screen_active = false
	
	# UIManagerに画面クローズを通知
	if adv_system and adv_system.UIManager:
		adv_system.UIManager.close_screen(self, return_val)
	
	screen_closed.emit(return_val)
	print("📱 Screen closed: ", screen_name, " with return value: ", return_val)

func call_screen(screen_path: String, parameters: Dictionary = {}) -> Variant:
	"""子画面を呼び出す（スクリーンスタック）"""
	if adv_system and adv_system.UIManager:
		return await adv_system.UIManager.call_screen(screen_path, parameters, self)
	else:
		push_error("❌ AdvScreen: Cannot call screen - UIManager not available")
		return null

# === シナリオ操作API ===

func jump_to(label_name: String):
	"""シナリオの指定ラベルにジャンプ"""
	if adv_system and adv_system.Player:
		adv_system.Player.play_from_label(label_name)
	else:
		push_error("❌ AdvScreen: Cannot jump - AdvScriptPlayer not available")

func call_label(label_name: String):
	"""シナリオの指定ラベルをcall（return可能）"""
	if adv_system and adv_system.Player:
		# call_stackに現在位置を積んでからジャンプ
		adv_system.Player.call_stack.append({"line": adv_system.Player.current_line_index, "screen": self})
		adv_system.Player.play_from_label(label_name)
	else:
		push_error("❌ AdvScreen: Cannot call label - AdvScriptPlayer not available")

func set_variable(var_name: String, value: Variant):
	"""シナリオ変数を設定"""
	if adv_system and adv_system.VariableManager:
		adv_system.VariableManager.global_vars[var_name] = value
		print("📊 Variable set from screen: ", var_name, " = ", value)
	else:
		push_error("❌ AdvScreen: Cannot set variable - VariableManager not available")

func get_variable(var_name: String) -> Variant:
	"""シナリオ変数を取得"""
	if adv_system and adv_system.VariableManager:
		return adv_system.VariableManager.global_vars.get(var_name, null)
	else:
		push_error("❌ AdvScreen: Cannot get variable - VariableManager not available")
		return null

# === ユーティリティ ===

func get_parameter(key: String, default_value: Variant = null) -> Variant:
	"""画面パラメータを取得"""
	return screen_parameters.get(key, default_value)

func has_parameter(key: String) -> bool:
	"""画面パラメータが存在するかチェック"""
	return key in screen_parameters

func get_screen_name() -> String:
	"""画面名を取得"""
	return screen_name

func is_active() -> bool:
	"""画面がアクティブかチェック"""
	return is_screen_active

# === UI要素自動発見システム ===

func _auto_discover_ui_elements():
	"""UI要素を設定（@export NodePath優先、フォールバック自動発見）"""
	
	# 1. @exportで指定されたNodePathを優先使用
	message_box = _get_node_from_path_or_fallback(message_box_path, "MessageBox")
	name_label = _get_node_from_path_or_fallback(name_label_path, "NameLabel", message_box)
	message_label = _get_node_from_path_or_fallback(message_label_path, "MessageLabel", message_box)
	
	choice_container = _get_node_from_path_or_fallback(choice_container_path, "ChoiceContainer")
	choice_panel = _get_node_from_path_or_fallback(choice_panel_path, "ChoicePanel", choice_container)
	choice_vbox = _get_node_from_path_or_fallback(choice_vbox_path, "VBoxContainer", choice_panel)
	
	continue_prompt = _get_node_from_path_or_fallback(continue_prompt_path, "ContinuePrompt")
	
	print("📱 AdvScreen UI discovery: MessageBox=", message_box != null, 
		  ", ChoiceContainer=", choice_container != null, 
		  ", MessageLabel=", message_label != null)
	print("   Using NodePath exports: ", _count_exported_paths(), "/7 specified")

func _get_node_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_node: Node = null) -> Node:
	"""NodePathが指定されていればそれを使用、なければ自動発見"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if node:
			print("   ✅ Using NodePath: ", fallback_name, " -> ", node_path)
			return node
		else:
			print("   ⚠️ NodePath not found: ", node_path, " for ", fallback_name)
	
	# 2. フォールバック：自動発見
	var search_root = parent_node if parent_node else self
	var node = search_root.find_child(fallback_name, true, false)
	
	if node:
		print("   🔍 Auto-discovered: ", fallback_name, " -> ", node.get_path())
	else:
		print("   ❌ Not found: ", fallback_name)
	
	return node

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

# === TypewriterText統合システム ===

func _initialize_typewriter():
	"""TypewriterTextを初期化"""
	if not message_label:
		print("⚠️ AdvScreen: No message_label found - skipping typewriter initialization")
		return
	
	typewriter = TypewriterText.new()
	add_child(typewriter)
	typewriter.setup_target(message_label)
	typewriter.skip_key_enabled = false
	
	# シグナル接続
	typewriter.typewriter_started.connect(_on_typewriter_started)
	typewriter.typewriter_finished.connect(_on_typewriter_finished)
	typewriter.typewriter_skipped.connect(_on_typewriter_skipped)
	typewriter.character_typed.connect(_on_character_typed)
	
	print("📱 AdvScreen: TypewriterText initialized")

func _on_typewriter_started(_text: String):
	is_message_complete = false
	if continue_prompt:
		continue_prompt.visible = false
	print("⌨️ AdvScreen: Typewriter started")

func _on_typewriter_finished():
	is_message_complete = true
	if continue_prompt:
		continue_prompt.visible = true
	print("⌨️ AdvScreen: Typewriter finished")

func _on_typewriter_skipped():
	is_message_complete = true
	if continue_prompt:
		continue_prompt.visible = true
	print("⌨️ AdvScreen: Typewriter skipped")

func _on_character_typed(_character: String, _position: int):
	# 継承先でオーバーライド可能
	on_character_typed(_character, _position)

func on_character_typed(_character: String, _position: int):
	"""文字が入力された時の仮想メソッド（継承先でオーバーライド）"""
	pass

# === レイヤーマッピングシステム ===

func _initialize_layer_mappings():
	"""レイヤーマッピングの初期化（@export NodePath優先、フォールバック自動発見）"""
	layer_mappings["ui"] = self
	
	var parent_scene = get_tree().current_scene
	if not parent_scene:
		print("⚠️ Current scene not found for layer mapping")
		return
	
	# BackgroundLayer
	var bg_layer = _get_layer_from_path_or_fallback(background_layer_path, "BackgroundLayer", parent_scene)
	if bg_layer:
		layer_mappings["background"] = bg_layer
	
	# CharacterLayer  
	var char_layer = _get_layer_from_path_or_fallback(character_layer_path, "CharacterLayer", parent_scene)
	if char_layer:
		layer_mappings["character"] = char_layer
	
	print("📱 AdvScreen: Layer mappings initialized:", layer_mappings)

func _get_layer_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_scene: Node) -> Node:
	"""レイヤーをNodePathまたは自動発見で取得"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if node:
			print("   ✅ Using layer NodePath: ", fallback_name, " -> ", node_path)
			return node
		else:
			print("   ⚠️ Layer NodePath not found: ", node_path, " for ", fallback_name)
	
	# 2. フォールバック：自動発見
	var node = parent_scene.find_child(fallback_name, true, false)
	if node:
		print("   🔍 Auto-discovered layer: ", fallback_name, " -> ", node.get_path())
	else:
		print("   ❌ Layer not found: ", fallback_name)
	
	return node

# === カスタムコマンド統合 ===

func _connect_custom_command_signals():
	"""カスタムコマンドの動的シグナルに接続"""
	if adv_system and adv_system.CustomCommandHandler:
		var handler = adv_system.CustomCommandHandler
		handler.dynamic_signal_emitted.connect(_on_dynamic_signal_emitted)
		print("📱 AdvScreen: Connected to custom command signals")

func _on_dynamic_signal_emitted(signal_name: String, args: Array, source_command: String):
	"""動的シグナルハンドラー（継承先でオーバーライド可能）"""
	on_dynamic_signal_emitted(signal_name, args, source_command)

func on_dynamic_signal_emitted(signal_name: String, args: Array, source_command: String):
	"""動的シグナル受信の仮想メソッド（継承先でオーバーライド）"""
	print("📡 AdvScreen: Received dynamic signal: ", signal_name, " from: ", source_command)

# === UIManager統合 ===

func _setup_ui_manager_integration():
	"""UIManagerとの連携を設定"""
	if not adv_system or not adv_system.UIManager:
		print("⚠️ AdvScreen: UIManager not available - skipping UI integration")
		return
	
	var ui_manager = adv_system.UIManager
	
	# UIManagerの参照を設定
	if name_label:
		ui_manager.name_label = name_label
	if message_label:
		ui_manager.text_label = message_label
	if choice_vbox:
		ui_manager.choice_container = choice_vbox
	
	handle_input = true
	print("📱 AdvScreen: UI integrated with UIManager")

# === 自動スクリプト開始 ===

func _start_auto_script():
	"""自動スクリプトを開始"""
	print("📱 AdvScreen: Starting auto script")
	
	if default_script_path.is_empty():
		print("⚠️ No default script path specified")
		return
	
	if not adv_system:
		push_error("❌ ArgodeSystem not found")
		return
	
	print("🎬 Auto-starting script:", default_script_path, "from label:", start_label)
	
	# ArgodeSystemにレイヤーマッピングを渡して初期化
	if not adv_system.is_initialized:
		print("🚀 Initializing ArgodeSystem...")
		var success = adv_system.initialize_game(layer_mappings)
		if not success:
			print("❌ ArgodeSystem initialization failed")
			return
		print("✅ ArgodeSystem initialization successful")
	
	# スクリプトを開始
	adv_system.start_script(default_script_path, start_label)

# === メッセージ表示API ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE):
	"""メッセージを表示する（タイプライター付き）"""
	if not message_box or not message_label:
		push_error("❌ AdvScreen: MessageBox or MessageLabel not available")
		return
	
	message_box.visible = true
	if choice_container:
		choice_container.visible = false
	if continue_prompt:
		continue_prompt.visible = false
	is_message_complete = false
	
	if character_name.is_empty():
		if name_label:
			name_label.text = ""
			name_label.visible = false
	else:
		if name_label:
			name_label.text = character_name
			name_label.modulate = name_color
			name_label.visible = true
	
	var processed_message = _process_escape_sequences(message)
	
	if typewriter:
		typewriter.start_typing(processed_message)
	else:
		message_label.text = processed_message
		is_message_complete = true
		if continue_prompt:
			continue_prompt.visible = true
	
	print("💬 AdvScreen Message: [", character_name, "] ", processed_message)

func show_choices(choices: Array, is_numbered: bool = false):
	"""選択肢を表示する"""
	if not choice_container or not choice_vbox:
		push_error("❌ AdvScreen: ChoiceContainer or choice_vbox not available")
		return
	
	if message_box:
		message_box.visible = true
	choice_container.visible = true
	if continue_prompt:
		continue_prompt.visible = false
	
	_clear_choice_buttons()
	
	for i in range(choices.size()):
		var button = Button.new()
		button.text = ""
		if is_numbered:
			button.text += str(i + 1) + "."
		button.text += choices[i]
		button.pressed.connect(_on_choice_selected.bind(i))
		choice_vbox.add_child(button)
	
	print("🤔 AdvScreen Choices displayed: ", choices.size(), " options")

func hide_ui():
	"""UI全体を非表示にする"""
	if message_box:
		message_box.visible = false
	if choice_container:
		choice_container.visible = false
	if continue_prompt:
		continue_prompt.visible = false

# === 入力処理 ===

func _unhandled_input(event):
	"""UIでの入力処理"""
	if not handle_input:
		return
	
	if not message_box:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if message_box.visible and not (choice_container and choice_container.visible):
			if not is_message_complete:
				if typewriter:
					typewriter.skip_typing()
				get_viewport().set_input_as_handled()
			else:
				if adv_system and adv_system.Player:
					adv_system.Player.next()
				get_viewport().set_input_as_handled()

# === 選択肢処理 ===

func _on_choice_selected(choice_index: int):
	"""選択肢選択時の処理"""
	print("🔘 AdvScreen Choice selected: ", choice_index)
	if choice_container:
		choice_container.visible = false
	
	if adv_system and adv_system.Player:
		adv_system.Player.on_choice_selected(choice_index)

# === ヘルパーメソッド ===

func _clear_choice_buttons():
	"""選択肢ボタンをクリア"""
	if not choice_vbox:
		return
	
	for child in choice_vbox.get_children():
		if child is Button:
			child.queue_free()

func _process_escape_sequences(text: String) -> String:
	"""エスケープシーケンスを処理"""
	var result = text
	result = result.replace("\\n", "\n")
	result = result.replace("\\t", "\t")
	result = result.replace("\\r", "\r")
	result = result.replace("\\\\", "\\")
	return result

func set_script_path(path: String, label: String = "start"):
	"""スクリプトパスとラベルを設定"""
	default_script_path = path
	start_label = label
	print("📱 AdvScreen: Script path set to:", path, "with label:", label)

# === デバッグ用 ===

func debug_info() -> Dictionary:
	"""デバッグ情報を取得"""
	return {
		"screen_name": screen_name,
		"is_active": is_screen_active,
		"parameters": screen_parameters,
		"return_value": return_value,
		"has_adv_system": adv_system != null,
		"ui_elements": {
			"message_box": message_box != null,
			"message_label": message_label != null,
			"choice_container": choice_container != null,
			"typewriter": typewriter != null
		}
	}