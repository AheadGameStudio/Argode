# AdvScreen.gd
# v2設計: UI基底クラス - call_screenで呼び出されるUIシーンが継承すべき高機能な基底クラス
extends Control
class_name ArgodeScreen

# レイヤー自動展開システム
# const AutoLayerSetup = preload("res://addons/argode/managers/AutoLayerSetup.gd")
# const RubyTextRenderer = preload("res://addons/argode/ui/RubyTextRenderer.gd")
# const RubyRichTextLabel = preload("res://addons/argode/ui/RubyRichTextLabel.gd")

# === 新しいRubyTextManager統合 ===
const RubyTextManager = preload("res://addons/argode/ui/ruby/RubyTextManager.gd")

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
var continue_prompt: Control = null

# === TypewriterText統合 ===
var typewriter: TypewriterText = null
var ruby_text_renderer: RubyTextRenderer = null  # 複数Label方式のルビ表示システム
var is_message_complete: bool = false
var handle_input: bool = true

# === 自動スクリプト設定 ===
## シーン開始時に自動的にスクリプトを実行するかどうか
@export var auto_start_script: bool = false
## 自動実行するスクリプトファイルのパス（.rgdファイル）
@export var default_script_path: String = ""
## スクリプト開始時のラベル名（通常は"start"）
@export var start_label: String = "start"

# === ルビ表示設定 ===
## 複数Label方式のルビシステムを使用するかどうか
@export var use_multi_label_ruby: bool = false
## _draw()関数でルビを直接描画するかどうか（レガシー実装）
@export var use_draw_ruby: bool = false
## RubyRichTextLabelを使用するかどうか（推奨実装）
@export var use_ruby_rich_text_label: bool = true
## ルビのデバッグ表示を有効にするかどうか
@export var show_ruby_debug: bool = true

# 改行調整されたテキストを保存（TypewriterTextからアクセス可能）
var adjusted_text: String = ""

# === ルビ描画システム（レガシー_draw方式用） ===
var ruby_data: Array[Dictionary] = []  # 描画するルビ情報
var display_ruby_data: Array[Dictionary] = []  # 実際に表示するルビ情報（表示制御用）
var preserve_ruby_data: bool = false  # TypewriterText実行中はruby_dataを保持
var ruby_main_font: Font = null
var ruby_font: Font = null

# === RubyTextManager統合（新しいアーキテクチャ） ===
var ruby_text_manager: RubyTextManager = null  # Ruby処理の専用マネージャー
@export var use_ruby_text_manager: bool = true  # 新しいRubyTextManagerを使用するか（テスト有効化）

# === RubyRichTextLabel統合 ===
var current_rubies: Array = []  # 現在のメッセージのルビデータ

# === レイヤー自動展開設定 ===
@export_group("Auto Layer Setup")
## Argode標準レイヤー（Background/Character/UI）を自動作成するか
@export var auto_create_layers: bool = true

# === レイヤーNodePath設定（エディタで指定可能） ===
@export_group("Layer Paths")
## 背景画像を表示するレイヤーノード（CanvasLayerやControlなど）
@export var background_layer_path: NodePath = ""
## キャラクター画像を表示するレイヤーノード（CanvasLayerやControlなど）
@export var character_layer_path: NodePath = ""
## UIレイヤーノード（通常は空の場合、このArgodeScreen自身が使用される）
@export var ui_layer_path: NodePath = ""

# === レイヤーマッピング設定 ===
## レイヤーの実際のノード参照（背景・キャラクター・UIの3層構造）
@export var layer_mappings: Dictionary = {
	"background": null,	# 背景レイヤー（最下層）
	"character": null,	 # キャラクターレイヤー（中層）
	"ui": null			# UIレイヤー（最上層、通常はArgodeScreen自身またはui_layer_pathで指定）
}

func _ready():
	print("📱 AdvScreen initializing:", name, " (", get_class(), ")")
	
	# ArgodeSystemの参照を取得
	adv_system = get_node_or_null("/root/ArgodeSystem")
	if not adv_system:
		push_error("❌ AdvScreen: ArgodeSystem not found!")
		return
	
	# 🚀 v2: UIManagerにcurrent_screenとして自動登録
	if adv_system.UIManager:
		print("📱 Auto-registering as current_screen with UIManager")
		adv_system.UIManager.current_screen = self
		print("✅ current_screen set to:", self.name, " (", self.get_class(), ")")
		
		# RubyRichTextLabel設定をArgodeSystemに通知
		adv_system.set_ruby_rich_text_label_enabled(use_ruby_rich_text_label)
		print("✅ RubyRichTextLabel setting synchronized to ArgodeSystem")
		
		# デバッグ: 登録確認
		await get_tree().process_frame  # 1フレーム待つ
		if adv_system.UIManager.current_screen == self:
			print("✅ Registration confirmed: current_screen is", self.name)
		else:
			print("❌ Registration failed: current_screen is", adv_system.UIManager.current_screen)
	else:
		print("❌ UIManager not found")
	
	# 初期化完了を通知
	call_deferred("_emit_screen_ready")

func _emit_screen_ready():
	# UI要素の自動発見
	_auto_discover_ui_elements()
	
	# TypewriterText初期化
	_initialize_typewriter()
	
	# RubyTextManager初期化（新しいアーキテクチャ）
	_initialize_ruby_text_manager()
	
	# レイヤーマッピング初期化
	_initialize_layer_mappings()
	
	# ArgodeSystemのレイヤー初期化を確実に実行
	_ensure_layer_manager_initialization()
	
	# カスタムコマンド接続
	_connect_custom_command_signals()
	
	# UIManager統合
	_setup_ui_manager_integration()
	
	# RubyRichTextLabel設定
	_setup_ruby_rich_text_label()
	
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
	print("🟦 show_screen called!")
	print_stack()
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
	
	print("🔍 [Debug] _auto_discover_ui_elements() called")
	print("  - Current scene name: ", get_scene_file_path())
	print("  - Node count: ", get_child_count())
	
	# 子ノードの一覧を表示
	print("🔍 [Debug] Child nodes:")
	for i in range(get_child_count()):
		var child = get_child(i)
		print("  - [", i, "] ", child.name, " (", child.get_class(), ")")
	
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
	
	# デバッグ: 実際に見つかった要素を詳細表示
	print("🔍 [Debug] Found UI elements:")
	print("  - message_box: ", message_box, " (type: ", message_box.get_class() if message_box else "null", ")")
	print("  - message_label: ", message_label, " (type: ", message_label.get_class() if message_label else "null", ")")
	
	# RubyRichTextLabelの設定
	_setup_ruby_rich_text_label()

func _get_node_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_node: Node = null) -> Node:
	"""NodePathが指定されていればそれを使用、なければ自動発見"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if node:
			print("   ✅ Using NodePath: ", fallback_name, " -> ", node_path, " (", node.get_class(), ")")
			return node
		else:
			print("   ⚠️ NodePath not found: ", node_path, " for ", fallback_name)
	
	# 2. フォールバック：自動発見
	var search_root = parent_node if parent_node else self
	var node = search_root.find_child(fallback_name, true, false)
	
	if node:
		print("   🔍 Auto-discovered: ", fallback_name, " -> ", node.get_path(), " (", node.get_class(), ")")
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
	"""TypewriterTextとRubyTextRendererを初期化"""
	if not message_label:
		print("⚠️ AdvScreen: No message_label found - skipping typewriter initialization")
		return
	
	# TypewriterText初期化
	typewriter = TypewriterText.new()
	add_child(typewriter)
	typewriter.setup_target(message_label)
	typewriter.skip_key_enabled = false
	
	# RubyTextRenderer初期化（複数Label方式のルビシステム）
	ruby_text_renderer = RubyTextRenderer.new()
	ruby_text_renderer.name = "RubyTextRenderer"
	# message_labelの親に追加してオーバーレイ
	if message_label.get_parent():
		message_label.get_parent().add_child(ruby_text_renderer)
		# message_labelと同じ位置・サイズに設定
		ruby_text_renderer.position = message_label.position
		ruby_text_renderer.size = message_label.size
		ruby_text_renderer.anchor_left = message_label.anchor_left
		ruby_text_renderer.anchor_top = message_label.anchor_top
		ruby_text_renderer.anchor_right = message_label.anchor_right
		ruby_text_renderer.anchor_bottom = message_label.anchor_bottom
	else:
		add_child(ruby_text_renderer)
	
	# シグナル接続
	typewriter.typewriter_started.connect(_on_typewriter_started)
	typewriter.typewriter_finished.connect(_on_typewriter_finished)
	typewriter.typewriter_skipped.connect(_on_typewriter_skipped)
	typewriter.character_typed.connect(_on_character_typed)
	
	# RichTextLabelのリンククリック処理を接続
	if message_label is RichTextLabel:
		message_label.meta_clicked.connect(_on_glossary_link_clicked)
		message_label.bbcode_enabled = true
		print("🔗 AdvScreen: Glossary link support enabled")
	
	print("📱 AdvScreen: TypewriterText and RubyTextRenderer initialized")

func _setup_ruby_rich_text_label():
	"""RubyRichTextLabelの設定を行う"""
	if not message_label:
		print("⚠️ No message_label found - skipping RubyRichTextLabel setup")
		return
	
	print("🔍 message_label details:")
	print("  - Type: %s" % message_label.get_class())
	print("  - Script: %s" % message_label.get_script())
	print("  - Is RichTextLabel: %s" % (message_label is RichTextLabel))
	print("  - Is RubyRichTextLabel: %s" % (message_label is RubyRichTextLabel))
	
	# message_labelがRubyRichTextLabelかどうかチェック
	if message_label is RubyRichTextLabel:
		print("✅ message_label is RubyRichTextLabel - configuring ruby settings")
		var ruby_label = message_label as RubyRichTextLabel
		ruby_label.show_ruby_debug = show_ruby_debug
		print("🔤 RubyRichTextLabel configured with debug=%s" % show_ruby_debug)
	elif message_label.has_method("set_ruby_data"):
		print("✅ message_label has ruby methods - treating as RubyRichTextLabel")
		message_label.show_ruby_debug = show_ruby_debug
		print("🔤 RubyRichTextLabel methods configured with debug=%s" % show_ruby_debug)
	else:
		print("ℹ️ message_label is %s - RubyRichTextLabel features not available" % message_label.get_class())

func _initialize_ruby_text_manager():
	"""新しいRubyTextManagerの初期化"""
	if not use_ruby_text_manager:
		print("ℹ️ RubyTextManager is disabled - skipping initialization")
		return
	
	if not message_label:
		print("⚠️ No message_label found - cannot initialize RubyTextManager")
		return
	
	print("🚀 Initializing RubyTextManager...")
	
	# RubyTextManagerインスタンス作成
	ruby_text_manager = RubyTextManager.new(message_label, null)
	
	# デバッグモード設定
	ruby_text_manager.set_debug_mode(show_ruby_debug)
	
	# 既存の設定を引き継ぎ
	ruby_text_manager.set_draw_mode(use_draw_ruby)
	
	# シグナル接続
	ruby_text_manager.ruby_text_updated.connect(_on_ruby_text_updated)
	ruby_text_manager.ruby_visibility_changed.connect(_on_ruby_visibility_changed)
	
	print("✅ RubyTextManager initialized successfully")
	print("🔍 RubyTextManager debug info: %s" % ruby_text_manager.debug_info())

func _on_ruby_text_updated(ruby_data: Array):
	"""RubyTextManagerからのruby_text_updatedシグナル処理"""
	print("📝 Ruby text updated: %d items" % ruby_data.size())

func _on_ruby_visibility_changed(visible_count: int):
	"""RubyTextManagerからのruby_visibility_changedシグナル処理"""
	print("👁️ Ruby visibility changed: %d visible" % visible_count)

func _on_typewriter_started(_text: String):
	is_message_complete = false
	if continue_prompt:
		continue_prompt.visible = false
	preserve_ruby_data = true  # TypewriterText実行中はruby_dataを保護
	print("⌨️ AdvScreen: Typewriter started")

func _on_typewriter_finished():
	is_message_complete = true
	preserve_ruby_data = false  # TypewriterText完了時は保護解除
	if continue_prompt:
		continue_prompt.visible = true
	print("⌨️ AdvScreen: Typewriter finished")
	
	# _draw方式のルビを使用している場合の処理
	if use_draw_ruby and ruby_data.size() > 0:
		# タイプライター完了時に全ルビを表示（現在のテキストを元に計算）
		current_rubies.clear()
		for ruby_info in ruby_data:
			current_rubies.append({
				"kanji": ruby_info.get("kanji", ""),
				"reading": ruby_info.get("reading", ""),
				"clean_pos": ruby_info.get("clean_pos", 0)
			})
		_calculate_ruby_positions(current_rubies, message_label.text)

func _on_typewriter_skipped():
	is_message_complete = true
	if continue_prompt:
		continue_prompt.visible = true
	print("⌨️ AdvScreen: Typewriter skipped")
	
	# RubyRichTextLabelを使用している場合のスキップ時ルビ位置計算
	if use_ruby_rich_text_label and message_label is RubyRichTextLabel:
		var ruby_label = message_label as RubyRichTextLabel
		var raw_rubies = ruby_label.get_raw_ruby_data()
		if raw_rubies.size() > 0:
			# タイプライター完了時に全ルビを正しい位置で表示
			ruby_label.calculate_ruby_positions(raw_rubies, message_label.get_parsed_text())
			print("✅ Ruby positions recalculated on typewriter skip with %d raw rubies" % raw_rubies.size())
		else:
			print("🔍 No raw ruby data available for recalculation")
	
	# _draw方式のルビを使用している場合の処理
	elif use_draw_ruby and ruby_data.size() > 0:
		# タイプライター完了時に全ルビを表示（現在のテキストを元に計算）
		current_rubies.clear()
		for ruby_info in ruby_data:
			current_rubies.append({
				"kanji": ruby_info.get("kanji", ""),
				"reading": ruby_info.get("reading", ""),
				"clean_pos": ruby_info.get("clean_pos", 0)
			})
		_calculate_ruby_positions(current_rubies, message_label.text)
		print("✅ Legacy ruby positions recalculated on typewriter skip")

func _on_character_typed(_character: String, _position: int):
	print("🔤 [Character Typed] character='%s', position=%d" % [_character, _position])
	# _draw方式のルビを使用している場合の処理
	if use_draw_ruby:
		print("🔤 [Character Typed] Calling _update_ruby_visibility_for_position")
		_update_ruby_visibility_for_position(_position)
	
	# 継承先でオーバーライド可能
	on_character_typed(_character, _position)

func on_character_typed(_character: String, _position: int):
	"""文字が入力された時の仮想メソッド（継承先でオーバーライド）"""
	pass

# === グロッサリーリンクシステム ===

signal glossary_link_clicked(link_type: String, link_key: String)

func _on_glossary_link_clicked(meta: Variant):
	"""RichTextLabelのリンククリック処理"""
	var link_data = str(meta)
	print("🔗 AdvScreen: Glossary link clicked: ", link_data)
	
	# "glossary:sangenjaya" のような形式を解析
	if link_data.contains(":"):
		var parts = link_data.split(":", 2)
		if parts.size() >= 2:
			var link_type = parts[0]
			var link_key = parts[1]
			print("📖 AdvScreen: Parsed link - type: ", link_type, ", key: ", link_key)
			glossary_link_clicked.emit(link_type, link_key)
		else:
			print("⚠️ AdvScreen: Invalid link format: ", link_data)
	else:
		# 単純なリンクの場合
		glossary_link_clicked.emit("link", link_data)

# === レイヤーマッピングシステム ===

func _ensure_layer_manager_initialization():
	"""LayerManagerの初期化を確実に実行する"""
	if not adv_system:
		print("⚠️ ArgodeSystem not available - skipping layer initialization")
		return
	
	if adv_system.is_initialized:
		print("✅ ArgodeSystem already initialized")
		return
	
	print("🚀 Initializing ArgodeSystem LayerManager...")
	var success = adv_system.initialize_game(layer_mappings)
	if not success:
		print("❌ ArgodeSystem LayerManager initialization failed")
	else:
		print("✅ ArgodeSystem LayerManager initialization successful")

func _initialize_layer_mappings():
	"""レイヤーマッピングの初期化（@export NodePath優先、フォールバック自動発見）"""
	
	var parent_scene = get_tree().current_scene
	if not parent_scene:
		print("⚠️ Current scene not found for layer mapping")
		return
	
	# 自動展開モードが有効な場合
	if auto_create_layers:
		print("🏗️ Auto-creating Argode standard layers...")
		layer_mappings = AutoLayerSetup.setup_layer_hierarchy(parent_scene)
		print("✅ Auto-created layers:", layer_mappings.keys())
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
	
	# UILayer（NodePathが指定されていない場合はself、指定されている場合はそのノードを使用）
	var ui_layer = _get_layer_from_path_or_fallback(ui_layer_path, "", parent_scene)
	if ui_layer:
		layer_mappings["ui"] = ui_layer
		print("   🎯 Using specified UI layer: ", ui_layer.get_path())
	else:
		layer_mappings["ui"] = self
		print("   🎯 Using self as UI layer: ", self.get_path())
	
	print("📱 AdvScreen: Layer mappings initialized:", layer_mappings)
	
	# LayerManagerを初期化
	_initialize_layer_manager()

func _get_layer_from_path_or_fallback(node_path: NodePath, fallback_name: String, parent_scene: Node) -> Node:
	"""レイヤーをNodePathまたは自動発見で取得"""
	
	# 1. @export NodePathが指定されている場合
	if not node_path.is_empty():
		var node = get_node_or_null(node_path)
		if node:
			print("   ✅ Using layer NodePath: ", fallback_name if not fallback_name.is_empty() else "UILayer", " -> ", node_path)
			return node
		else:
			print("   ⚠️ Layer NodePath not found: ", node_path, " for ", fallback_name if not fallback_name.is_empty() else "UILayer")
	
	# 2. フォールバック：自動発見（UIレイヤーの場合はスキップ）
	if fallback_name.is_empty():
		# UIレイヤーの場合は自動発見をスキップ（selfがデフォルト）
		return null
	
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
	
	# LayerManager初期化は_ensure_layer_manager_initialization()で実行済み
	if not adv_system.is_initialized:
		print("⚠️ ArgodeSystem not initialized - this should not happen")
		var success = adv_system.initialize_game(layer_mappings)
		if not success:
			print("❌ ArgodeSystem initialization failed")
			return
		print("✅ ArgodeSystem initialization successful")
	
	# スクリプトを開始
	adv_system.start_script(default_script_path, start_label)

# === メッセージ表示API ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE, override_multi_label_ruby: bool = false):
	"""メッセージを表示する（タイプライター付き）
	@param override_multi_label_ruby: trueで複数Label方式を強制使用（通常はuse_multi_label_rubyプロパティを使用）
	"""
	print("🔍 [Debug] show_message called:")
	print("  - message_box: ", message_box)
	print("  - message_label: ", message_label)
	print("  - message_box is null: ", message_box == null)
	print("  - message_label is null: ", message_label == null)
	
	if not message_box or not message_label:
		push_error("❌ AdvScreen: MessageBox or MessageLabel not available")
		print("❌ [Debug] Missing UI elements - attempting re-initialization")
		_auto_discover_ui_elements()  # 再初期化を試行
		if not message_box or not message_label:
			push_error("❌ AdvScreen: UI elements still not available after re-initialization")
			return
		else:
			print("✅ [Debug] UI elements found after re-initialization")
	
	message_box.visible = true
	if choice_container:
		choice_container.visible = false
	if continue_prompt:
		continue_prompt.visible = false
	is_message_complete = false
	
	# 前のメッセージのルビデータをクリア
	if current_rubies:
		current_rubies.clear()
		print("🔄 Previous current_rubies cleared")
	
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
	
	# 初回呼び出し時にRubyRichTextLabel設定を確認
	if not use_draw_ruby and use_ruby_rich_text_label:
		print("🔧 [Lazy Init] RubyRichTextLabel setup not yet done, triggering...")
		_setup_ruby_rich_text_label()
	
	# ルビシステム選択（プロパティまたは強制オーバーライド）
	var should_use_multi_label = use_multi_label_ruby or override_multi_label_ruby
	
	if use_ruby_rich_text_label and (message_label is RubyRichTextLabel or (message_label != null and message_label.has_method("set_ruby_data"))):
		print("🎨 Using RubyRichTextLabel ruby system")
		
		# 前のルビデータをクリア
		if message_label.has_method("clear_ruby_data"):
			message_label.clear_ruby_data()
			print("🔄 Previous ruby data cleared")
		
		# RubyRichTextLabel方式でルビを表示
		if ruby_text_renderer:
			ruby_text_renderer.visible = false
		message_label.visible = true
		
		# BBCode形式のルビを元の【｜】形式に逆変換
		var raw_ruby_message = _reverse_ruby_conversion(processed_message)
		print("🔄 [Debug] Raw ruby message: '%s'" % raw_ruby_message.replace("\n", "\\n"))
		
		# シンプルな改行調整を適用
		var adjusted_message = simple_ruby_line_break_adjustment(raw_ruby_message)
		print("✅ [Simple] Using adjusted message: '%s'" % adjusted_message.replace("\n", "\\n"))
		
		set_text_with_ruby_draw(adjusted_message)
		
		# TypewriterTextでタイプライター効果（RubyRichTextLabel使用時はclean_textを使用）
		if typewriter:
			# RubyRichTextLabel用にclean_textを取得
			var parse_result = _parse_ruby_syntax(adjusted_message)
			var clean_text_for_typing = parse_result.text
			print("🎨 TypewriterText using clean text for RubyRichTextLabel: '%s'" % clean_text_for_typing)
			typewriter.start_typing(clean_text_for_typing)
		else:
			is_message_complete = true
			if continue_prompt:
				continue_prompt.visible = true
	elif use_draw_ruby:
		print("🎨 Using draw-based ruby system")
		# _draw()方式でルビを表示
		if ruby_text_renderer:
			ruby_text_renderer.visible = false
		message_label.visible = true
		
		# BBCode形式のルビを元の【｜】形式に逆変換
		var raw_ruby_message = _reverse_ruby_conversion(processed_message)
		preserve_ruby_data = true  # ruby_dataを保護
		set_text_with_ruby_draw(raw_ruby_message)
		preserve_ruby_data = false  # 保護解除（ただしTypewriterTextが再度設定）
		
		# TypewriterTextでタイプライター効果
		if typewriter:
			typewriter.start_typing(processed_message)
		else:
			is_message_complete = true
			if continue_prompt:
				continue_prompt.visible = true
	elif should_use_multi_label and ruby_text_renderer:
		print("🏷️ Using multi-label ruby system")
		# 複数Label方式でルビを表示
		ruby_text_renderer.set_text_with_ruby(processed_message)
		# メインラベルは非表示（RubyTextRendererが代替）
		message_label.visible = false
		ruby_text_renderer.visible = true
		# タイプライターは無効化（複数Labelでは複雑）
		is_message_complete = true
		if continue_prompt:
			continue_prompt.visible = true
	else:
		# 従来のBBCodeベースのルビシステム
		print("🏷️ Using BBCode-based ruby system")
		if ruby_text_renderer:
			ruby_text_renderer.visible = false
		message_label.visible = true
		
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

# === v2新機能: メッセージウィンドウ表示制御 ===
# 注意: v2.1でUIManagerがCanvasLayerレベル制御に変更されたため、
# 個別UI要素制御は不要になりました。UIManager.visible で全体制御されます。

func _initialize_layer_manager():
	"""LayerManagerをレイヤーマッピングで初期化"""
	var adv_system = get_node("/root/ArgodeSystem")
	if not adv_system:
		print("⚠️ ArgodeSystem not found for LayerManager initialization")
		return
	
	var layer_manager = adv_system.get("LayerManager")
	if not layer_manager:
		print("⚠️ LayerManager not found in ArgodeSystem")
		return
	
	# レイヤーを取得
	var bg_layer = layer_mappings.get("background")
	var char_layer = layer_mappings.get("character") 
	var ui_layer = layer_mappings.get("ui")
	
	if bg_layer and char_layer and ui_layer:
		layer_manager.initialize_layers(bg_layer, char_layer, ui_layer)
		print("✅ LayerManager initialized with layers:", layer_mappings.keys())
	else:
		print("⚠️ Missing layers for LayerManager initialization:", {
			"background": bg_layer != null,
			"character": char_layer != null,
			"ui": ui_layer != null
		})

func set_message_window_visible(visible: bool):
	"""メッセージウィンドウの表示/非表示を制御（レガシー互換用）"""
	print("🪟 ArgodeScreen.set_message_window_visible(", visible, ") - レガシー互換")
	print("ℹ️  現在はUIManager.visible で全体制御されるため、この処理は無効です")
	
	# 互換性のため残しておくが、実際の制御はUIManagerで行われる
	# if message_box:
	#     message_box.visible = visible
	#     print("📦 Message box visibility set to:", visible)
	# else:
	#     print("⚠️ message_box not found for visibility control")

# === ルビ描画システム（_draw方式） ===

func _draw():
	"""カスタム描画関数 - ルビを直接描画（RubyTextManager経由）"""
	print("🔍 [Ruby Debug] _draw() called")
	print("🔍 [Ruby Debug] use_draw_ruby = %s" % use_draw_ruby)
	print("🔍 [Ruby Debug] display_ruby_data.size() = %d" % display_ruby_data.size())
	
	if not use_draw_ruby or display_ruby_data.is_empty():
		print("🔍 [Ruby Debug] Exiting _draw: use_draw_ruby=%s, display_ruby_data empty=%s" % [use_draw_ruby, display_ruby_data.is_empty()])
		return
	
	# RubyTextManagerが利用可能な場合はそちらを使用
	if ruby_text_manager and ruby_text_manager.renderer:
		print("🎨 [Ruby Debug] Using RubyTextManager for drawing")
		ruby_text_manager.execute_ruby_drawing(self)
		return
	
	# フォールバック: 従来の描画方式
	if not message_label or not ruby_font:
		print("🔍 [Ruby Debug] Missing message_label or ruby_font")
		return
	
	print("🔍 [Ruby Debug] Using fallback drawing mode: %d rubies" % display_ruby_data.size())
	
	# デバッグ表示: メッセージラベルの境界
	if show_ruby_debug:
		var label_global_pos = message_label.global_position
		var label_size = message_label.size
		var screen_global_pos = global_position
		var relative_pos = label_global_pos - screen_global_pos
		var rect = Rect2(relative_pos, label_size)
		draw_rect(rect, Color.CYAN, false, 2.0)
		draw_string(ThemeDB.fallback_font, relative_pos + Vector2(5, -10), "Message Label Area", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.CYAN)
	
	for ruby_info in display_ruby_data:
		_draw_single_ruby(ruby_info)

func _draw_single_ruby(ruby_info: Dictionary):
	"""単一のルビを描画"""
	var reading = ruby_info.get("reading", "")
	var kanji = ruby_info.get("kanji", "")
	var position = ruby_info.get("position", Vector2.ZERO)
	# 色を明るくし、メインテキストに近い色に
	var color = ruby_info.get("color", Color(0.9, 0.9, 0.9, 1.0))
	
	# ルビの描画位置（position には既にメッセージラベルの位置が含まれている）
	var draw_pos = position
	
	# デバッグ表示
	if show_ruby_debug:
		# ルビの基点を緑の円で表示
		draw_circle(draw_pos, 3.0, Color.GREEN)
		
		# ルビの範囲を青い矩形で表示
		var ruby_font_size = 14
		var ruby_width = ruby_font.get_string_size(reading, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		var ruby_rect = Rect2(draw_pos, Vector2(ruby_width, ruby_font_size))
		draw_rect(ruby_rect, Color.BLUE, false, 1.0)
		
		# デバッグ情報をテキストで表示
		var debug_text = "漢字: %s | ルビ: %s" % [kanji, reading]
		draw_string(ThemeDB.fallback_font, draw_pos + Vector2(0, ruby_font_size + 15), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.YELLOW)
	
	# ルビテキストを描画（サイズも少し大きく）
	var font_size = 14
	draw_string(ruby_font, draw_pos, reading, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func setup_ruby_fonts():
	"""ルビ描画用フォントを設定"""
	var default_font_path = "res://assets/common/fonts/03スマートフォントUI.otf"
	
	# メインフォント設定
	if FileAccess.file_exists(default_font_path):
		ruby_main_font = load(default_font_path)
		ruby_font = ruby_main_font  # ルビも同じフォントを使用
		print("🎨 Ruby draw fonts loaded: ", default_font_path)
	else:
		ruby_main_font = ThemeDB.fallback_font
		ruby_font = ThemeDB.fallback_font
		print("⚠️ Using fallback font for ruby drawing")

func simple_ruby_line_break_adjustment(text: String) -> String:
	"""行をまたぐルビ対象文字の前にのみ改行を挿入"""
	print("🔧 [Smart Fix] Checking for ruby targets that cross lines")
	
	if not message_label:
		print("❌ [Smart Fix] No message_label available")
		return text
	
	var font = message_label.get_theme_default_font()
	if not font:
		print("❌ [Smart Fix] No font available")
		return text
	
	var font_size = message_label.get_theme_font_size("normal_font_size")
	var container_width = message_label.get_rect().size.x
	
	if container_width <= 0:
		print("❌ [Smart Fix] Invalid container width: %f" % container_width)
		return text
	
	print("🔧 [Smart Fix] Container width: %f, font size: %d" % [container_width, font_size])
	
	# 【漢字｜ひらがな】パターンを検索
	var regex = RegEx.new()
	regex.compile("【([^｜]+)｜[^】]+】")
	
	var result = text
	var matches = regex.search_all(result)
	
	for match in matches:
		var full_match = match.get_string()
		var kanji_part = match.get_string(1)  # 【】内の漢字部分
		var match_start = result.find(full_match)
		
		if match_start >= 0:
			# このルビ対象文字が行をまたぐかどうかをチェック
			if _will_ruby_cross_line(result, match_start, kanji_part, font, font_size, container_width):
				print("🔧 [Cross Line] Ruby target '%s' will cross line - adding break" % kanji_part)
				
				# ルビ対象文字の前に改行を挿入
				var before_ruby = result.substr(0, match_start)
				var from_ruby = result.substr(match_start)
				result = before_ruby.strip_edges() + "\n" + from_ruby
			else:
				print("🔧 [Same Line] Ruby target '%s' stays on same line - no break needed" % kanji_part)
	
	print("🔧 [Smart Fix] Result: '%s'" % result.replace("\n", "\\n"))
	return result

func _will_ruby_cross_line(text: String, ruby_start_pos: int, kanji_part: String, font: Font, font_size: int, container_width: float) -> bool:
	"""ルビ対象文字が行をまたぐかどうかを判定"""
	
	# ruby_start_pos以前の文字で、最後の改行位置を見つける
	var line_start_pos = 0
	var last_newline = text.rfind("\n", ruby_start_pos - 1)
	if last_newline >= 0:
		line_start_pos = last_newline + 1
	
	# 現在行の開始からルビ対象文字までのテキスト
	var line_before_ruby = text.substr(line_start_pos, ruby_start_pos - line_start_pos)
	
	# 現在行の幅を計算
	var current_line_width = font.get_string_size(line_before_ruby, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# ルビ対象文字の幅を計算
	var kanji_width = font.get_string_size(kanji_part, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# ルビ対象文字を追加すると行幅を超えるかどうか
	var will_cross = (current_line_width + kanji_width) > container_width
	
	print("📏 [Line Check] Line before ruby: '%s' (width: %f)" % [line_before_ruby.replace("\n", "\\n"), current_line_width])
	print("📏 [Line Check] Kanji '%s' width: %f, total would be: %f, container: %f" % [kanji_part, kanji_width, current_line_width + kanji_width, container_width])
	print("📏 [Line Check] Will cross line: %s" % will_cross)
	
	return will_cross

func set_text_with_ruby_draw(text: String):
	"""ルビ付きテキストを設定（RubyRichTextLabel優先）"""
	print("🔍 [Ruby Debug] set_text_with_ruby_draw called with: '%s'" % text)
	print("🔍 [Ruby Debug] use_ruby_rich_text_label = %s" % use_ruby_rich_text_label)
	print("🔍 [Ruby Debug] message_label is RubyRichTextLabel = %s" % (message_label is RubyRichTextLabel))
	
	# RubyRichTextLabelが利用可能な場合は優先使用
	if use_ruby_rich_text_label and message_label is RubyRichTextLabel:
		print("🎨 [RubyRichTextLabel] Using RubyRichTextLabel system")
		
		# ルビを解析
		var parse_result = _parse_ruby_syntax(text)
		var clean_text = parse_result.text
		var rubies = parse_result.rubies
		
		print("🎨 [RubyRichTextLabel] Clean text: '%s'" % clean_text)
		print("🎨 [RubyRichTextLabel] Found %d rubies" % rubies.size())
		
		# メインテキストを設定
		message_label.text = clean_text
		
		# ルビデータを計算して設定
		var ruby_label = message_label as RubyRichTextLabel
		ruby_label.calculate_ruby_positions(rubies)
		
		# 調整済みテキストを保存（TypewriterText用）
		adjusted_text = clean_text
		
	else:
		# 通常のRichTextLabel処理
		print("🎨 [Standard] Using standard RichTextLabel")
		message_label.text = text
		adjusted_text = text
	
	print("✅ [Ruby Debug] set_text_with_ruby_draw completed")

func _update_ruby_visibility_for_position(typed_position: int):
	"""タイプライター位置に応じてルビの表示を更新（RubyRichTextLabel優先）"""
	print("🔍 [Ruby Visibility] typed_position=%d" % typed_position)
	
	# RubyRichTextLabelが利用可能な場合は優先使用
	if use_ruby_rich_text_label and message_label is RubyRichTextLabel:
		print("✅ Using RubyRichTextLabel for ruby visibility update")
		var ruby_label = message_label as RubyRichTextLabel
		ruby_label.update_ruby_positions_for_visible(ruby_label.ruby_data, typed_position)
		return
	
	# レガシー_draw方式（後方互換性のため）
	print("🔍 [Ruby Visibility] ruby_data.size()=%d" % ruby_data.size())
	if ruby_data.is_empty():
		print("🔍 [Ruby Visibility] ruby_data is empty - returning early")
		return
	
	var visible_rubies = []
	for ruby_info in ruby_data:
		var kanji_start_pos = ruby_info.get("clean_pos", 0)
		var kanji_text = ruby_info.get("kanji", "")
		var kanji_end_pos = kanji_start_pos + kanji_text.length()
		
		# ルビ対象文字が完全に表示されている場合のみルビを表示
		if kanji_end_pos <= typed_position:
			visible_rubies.append(ruby_info)
			print("🔍 [Ruby Visible] Kanji '%s' at pos %d-%d is fully visible (typed: %d)" % [kanji_text, kanji_start_pos, kanji_end_pos, typed_position])
		else:
			print("🔍 [Ruby Hidden] Kanji '%s' at pos %d-%d not yet fully visible (typed: %d)" % [kanji_text, kanji_start_pos, kanji_end_pos, typed_position])
	
	print("🔍 [Ruby Visibility] visible_rubies count: %d" % visible_rubies.size())
	
	# 表示するルビがある場合のみ位置を計算
	if visible_rubies.size() > 0:
		_calculate_ruby_positions_for_visible(visible_rubies, message_label.text.substr(0, typed_position))
	else:
		print("🔍 [Ruby Visibility] No visible rubies - skipping position calculation")
		# ルビが表示されない場合は表示をクリア
		display_ruby_data.clear()
		queue_redraw()

func _calculate_ruby_positions_for_visible(visible_rubies: Array, current_text: String):
	"""表示中のルビの位置を計算"""
	print("📍 [Ruby Position Calc] _calculate_ruby_positions_for_visible")
	
	# 表示するルビがない場合は処理しない
	if visible_rubies.size() == 0:
		print("🔍 [Ruby Protection] No visible rubies - clearing display data")
		display_ruby_data.clear()
		queue_redraw()
		return
	
	# 表示用のルビデータを更新（常に実行）
	display_ruby_data.clear()
	
	if not message_label or not ruby_main_font:
		return
	
	var font_size = 16
	if message_label.has_theme_font_size_override("font_size"):
		font_size = message_label.get_theme_font_size("font_size")
	
	# メッセージラベルのグローバル位置を取得
	var label_global_pos = message_label.global_position
	var screen_global_pos = global_position
	var label_offset = label_global_pos - screen_global_pos
	
	for ruby in visible_rubies:
		var kanji_text = ruby.kanji
		var reading_text = ruby.reading
		var kanji_pos_in_text = ruby.clean_pos
		
		# 表示されているテキストはBBCodeが処理されたプレーンテキスト
		# message_labelから直接取得する（RichTextLabelのplain_textプロパティを使用）
		var displayed_text = message_label.get_parsed_text()
		
		# クリーンテキストでの漢字位置を、実際に表示されるテキストでの位置に変換
		# 漢字そのものを探して正確な位置を取得
		var kanji_start_in_displayed = displayed_text.find(kanji_text, kanji_pos_in_text - 10 if kanji_pos_in_text > 10 else 0)
		if kanji_start_in_displayed == -1:
			# 見つからない場合はクリーンポジションをそのまま使用
			kanji_start_in_displayed = kanji_pos_in_text
		
		# 漢字位置までのテキスト幅を計算（BBCode処理後のテキストで）
		var text_before = displayed_text.substr(0, kanji_start_in_displayed)
		var text_width = ruby_main_font.get_string_size(text_before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# 漢字の幅を計算
		var kanji_width = ruby_main_font.get_string_size(kanji_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# ルビの幅を計算
		var ruby_font_size = 14
		var ruby_width = ruby_font.get_string_size(reading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		
		# ルビを漢字の中央揃えで配置（メッセージラベルの位置を考慮）
		var ruby_x = label_offset.x + text_width + (kanji_width - ruby_width) / 2
		var ruby_y = label_offset.y - ruby_font_size - 3  # メインテキストより上に配置
		
		display_ruby_data.append({
			"reading": reading_text,
			"kanji": kanji_text,
			"position": Vector2(ruby_x, ruby_y),
			"color": Color(0.9, 0.9, 0.9, 1.0)
		})
		
		print("🔍 [Ruby Position] Ruby '%s' at position (%f, %f)" % [reading_text, ruby_x, ruby_y])
		print("🔍 [Ruby Debug] kanji_text='%s', kanji_pos_in_text=%d" % [kanji_text, kanji_pos_in_text])
		print("🔍 [Ruby Debug] kanji_start_in_displayed=%d" % kanji_start_in_displayed)
		print("🔍 [Ruby Debug] text_before='%s', text_width=%f" % [text_before, text_width])
		print("🔍 [Ruby Debug] kanji_width=%f, ruby_width=%f" % [kanji_width, ruby_width])
		print("🔍 [Ruby Debug] displayed_text='%s'" % displayed_text)
	
	print("🔍 [Ruby Position] Updated display_ruby_data with %d rubies" % display_ruby_data.size())
	
	# 再描画をトリガー
	queue_redraw()

func _calculate_ruby_positions(rubies: Array, main_text: String):
	"""ルビの描画位置を計算"""
	print("🔍 [Ruby Debug] _calculate_ruby_positions called")
	print("🔍 [Ruby Debug] rubies.size() = %d" % rubies.size())
	print("🔍 [Ruby Debug] main_text = '%s'" % main_text)
	print("🔍 [Ruby Debug] message_label = %s" % message_label)
	print("🔍 [Ruby Debug] ruby_main_font = %s" % ruby_main_font)
	
	print("📍 [Ruby Data Clear] Location: _calculate_ruby_positions")
	ruby_data.clear()
	
	if not message_label or not ruby_main_font:
		print("🔍 [Ruby Debug] Missing message_label or ruby_main_font, exiting")
		return
	
	var font_size = 16
	if message_label.has_theme_font_size_override("font_size"):
		font_size = message_label.get_theme_font_size("font_size")
	
	print("🔍 [Ruby Debug] Using font_size = %d" % font_size)
	
	for i in range(rubies.size()):
		var ruby = rubies[i]
		var kanji_text = ruby.kanji
		var reading_text = ruby.reading
		var kanji_pos_in_text = ruby.clean_pos
		
		print("🔍 [Ruby Debug] Processing ruby %d: kanji='%s', reading='%s', pos=%d" % [i, kanji_text, reading_text, kanji_pos_in_text])
		
		# メッセージラベルのグローバル位置を取得
		var label_global_pos = message_label.global_position
		var screen_global_pos = global_position
		var label_offset = label_global_pos - screen_global_pos
		
		# 表示されているテキストから文字幅を計算
		var displayed_text = message_label.get_parsed_text()
		
		# クリーンテキストでの漢字位置を、実際に表示されるテキストでの位置に変換
		var kanji_start_in_displayed = displayed_text.find(kanji_text, kanji_pos_in_text - 10 if kanji_pos_in_text > 10 else 0)
		if kanji_start_in_displayed == -1:
			# 見つからない場合はクリーンポジションをそのまま使用
			kanji_start_in_displayed = kanji_pos_in_text
		
		var text_before = displayed_text.substr(0, kanji_start_in_displayed)
		var text_width = ruby_main_font.get_string_size(text_before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# 漢字の幅を計算
		var kanji_width = ruby_main_font.get_string_size(kanji_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# ルビの幅を計算
		var ruby_font_size = 12
		var ruby_width = ruby_font.get_string_size(reading_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_font_size).x
		
		# ルビを漢字の中央揃えで配置（メッセージラベルの位置を考慮）
		var ruby_x = label_offset.x + text_width + (kanji_width - ruby_width) / 2
		var ruby_y = label_offset.y - ruby_font_size - 3  # メインテキストより上に配置
		
		print("🔍 [Ruby Debug] Calculated position: x=%f, y=%f" % [ruby_x, ruby_y])
		print("🔍 [Ruby Debug] kanji_start_in_displayed=%d, text_width=%f" % [kanji_start_in_displayed, text_width])
		print("🔍 [Ruby Debug] displayed_text='%s', text_before='%s'" % [displayed_text, text_before])
		print("🔍 [Ruby Debug] kanji_width=%f, ruby_width=%f" % [kanji_width, ruby_width])
		
		ruby_data.append({
			"reading": reading_text,
			"kanji": kanji_text,  # 中央揃えのために漢字も保存
			"position": Vector2(ruby_x, ruby_y),
			"color": Color(0.9, 0.9, 0.9, 1.0)  # より明るい色
		})
	
	# display_ruby_data も更新（タイプライター完了時は全ルビを表示）
	display_ruby_data = ruby_data.duplicate(true)
	
	# 再描画をトリガー
	queue_redraw()
	print("🎨 Ruby draw positions calculated: %d rubies" % ruby_data.size())
	print("🎨 Display ruby data updated: %d rubies" % display_ruby_data.size())

func _parse_ruby_syntax(text: String) -> Dictionary:
	"""【漢字｜ふりがな】形式のテキストを解析"""
	print("🚀🚀🚀 [NEW PARSE] _parse_ruby_syntax CALLED WITH FIXED CODE! 🚀🚀🚀")
	
	# BBCodeを保持しつつルビを処理する新しいアプローチ
	print("🔍 [Ruby Parse] Original text: '%s'" % text)
	
	var clean_text = ""
	var rubies = []
	var pos = 0
	
	print("🔍 [Ruby Debug] Parsing text with BBCode preserved: '%s'" % text)
	
	var ruby_pattern = RegEx.new()
	ruby_pattern.compile("【([^｜]+)｜([^】]+)】")
	
	var offset = 0
	var matches = ruby_pattern.search_all(text)
	print("🔍 [Ruby Debug] Found %d ruby matches" % matches.size())
	
	for result in matches:
		# マッチ前のテキスト
		var before_text = text.substr(offset, result.get_start() - offset)
		clean_text += before_text
		print("🔍 [Ruby Parse] Before text: '%s', clean_text_length_before: %d" % [before_text, clean_text.length()])
		
		# BBCodeを除去して実際の表示位置を計算
		var regex_bbcode = RegEx.new()
		regex_bbcode.compile("\\[/?[^\\]]*\\]")
		var clean_text_without_bbcode = regex_bbcode.sub(clean_text, "", true)
		var kanji_start_pos = clean_text_without_bbcode.length()
		
		# 漢字部分
		var kanji = result.get_string(1)
		var reading = result.get_string(2)
		clean_text += kanji
		
		print("🔍 [Ruby Parse] Added kanji: '%s', clean_pos=%d (BBCode-adjusted), clean_text_after='%s'" % [kanji, kanji_start_pos, clean_text])
		
		# ルビ情報を保存（BBCode除去後の位置で）
		rubies.append({
			"kanji": kanji,
			"reading": reading,
			"clean_pos": kanji_start_pos
		})
		
		offset = result.get_end()
	
	# 残りのテキスト
	clean_text += text.substr(offset)
	
	print("🔍 [Ruby Debug] Result: clean_text='%s', rubies=%s" % [clean_text, rubies])
	return {"text": clean_text, "rubies": rubies}

func _reverse_ruby_conversion(bbcode_text: String) -> String:
	"""BBCode形式のルビを【｜】形式に逆変換"""
	var result_text = bbcode_text
	
	# パターン1: 漢字[font_size=10]（読み）[/font_size] -> 【漢字｜読み】 (URLタグ無し)
	var regex1 = RegEx.new()
	regex1.compile("([^\\[\\]]+)\\[font_size=10\\]（([^）]+)）\\[/font_size\\]")
	
	# パターン2: [url=xxx]漢字[font_size=10]（読み）[/font_size][/url] -> [url=xxx]【漢字｜読み】[/url]
	var regex2 = RegEx.new()
	regex2.compile("(\\[url=[^\\]]+\\])([^\\[\\]]+)\\[font_size=10\\]（([^）]+)）\\[/font_size\\](\\[/url\\])")
	
	# パターン2を先に処理（URLタグ付き）
	var matches2 = regex2.search_all(result_text)
	for i in range(matches2.size() - 1, -1, -1):
		var match = matches2[i]
		var url_start = match.get_string(1)  # [url=xxx]
		var kanji = match.get_string(2)      # 漢字
		var reading = match.get_string(3)    # 読み
		var url_end = match.get_string(4)    # [/url]
		var ruby_format = url_start + "【" + kanji + "｜" + reading + "】" + url_end
		
		result_text = result_text.substr(0, match.get_start()) + ruby_format + result_text.substr(match.get_end())
	
	# パターン1を処理（URLタグ無し）
	var matches1 = regex1.search_all(result_text)
	for i in range(matches1.size() - 1, -1, -1):
		var match = matches1[i]
		var kanji = match.get_string(1)
		var reading = match.get_string(2)
		var ruby_format = "【" + kanji + "｜" + reading + "】"
		
		result_text = result_text.substr(0, match.get_start()) + ruby_format + result_text.substr(match.get_end())
	
	print("🔄 Ruby reverse conversion: '%s' -> '%s'" % [bbcode_text, result_text])
	return result_text

# === RubyRichTextLabelサポートメソッド ===

func get_current_ruby_data() -> Array:
	"""現在のルビデータを取得（TypewriterTextからアクセス用）"""
	if message_label and message_label.has_method("get_ruby_data"):
		return message_label.get_ruby_data()
	return current_rubies if current_rubies else []

func get_message_label():
	"""メッセージラベルを取得（TypewriterTextからアクセス用）"""
	return message_label

# 改行調整されたテキストを取得
func get_adjusted_text() -> String:
	"""改行調整されたテキストを取得（TypewriterTextからアクセス用）"""
	print("🚀 [CRITICAL] get_adjusted_text() called - adjusted_text: '%s'" % adjusted_text.replace("\n", "\\n"))
	if adjusted_text.is_empty():
		print("🚀 [CRITICAL] adjusted_text is empty, returning message_label.text")
		print("⚠️ [Ruby Text Access] adjusted_text is empty, returning message_label.text")
		return message_label.text if message_label else ""
	print("🚀 [CRITICAL] Returning adjusted text length: %d" % adjusted_text.length())
	print("🔍 [Ruby Text Access] Returning adjusted text: '%s'" % adjusted_text.replace("\n", "\\n"))
	return adjusted_text
