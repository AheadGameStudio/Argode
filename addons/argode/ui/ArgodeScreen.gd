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
const RubyParser = preload("res://addons/argode/ui/ruby/RubyParser.gd")
const RubyMessageHandler = preload("res://addons/argode/ui/ruby/RubyMessageHandler.gd")
const MessageDisplayManager = preload("res://addons/argode/ui/display/MessageDisplayManager.gd")
const TypewriterTextIntegrationManager = preload("res://addons/argode/ui/managers/TypewriterTextIntegrationManager.gd")
const LayerInitializationManager = preload("res://addons/argode/ui/managers/LayerInitializationManager.gd")
const UIElementDiscoveryManager = preload("res://addons/argode/ui/managers/UIElementDiscoveryManager.gd")

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

# === UI要素発見マネージャー ===
var ui_element_discovery_manager: UIElementDiscoveryManager = null

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
var typewriter_integration_manager: TypewriterTextIntegrationManager = null
var is_message_complete: bool = false
var handle_input: bool = true

# === 削除済み: 自動スクリプト設定 ===
# AutoScript機能はArgodeSystemに移管済み
# use ArgodeSystem.set_auto_start_label() instead

# === ルビ表示設定 ===
## RubyRichTextLabelを使用するかどうか（推奨実装）
@export var use_ruby_rich_text_label: bool = true
## ルビのデバッグ表示を有効にするかどうか
@export var show_ruby_debug: bool = true

# 改行調整されたテキストを保存（TypewriterTextからアクセス可能）
var adjusted_text: String = ""

# === ルビ描画システム（レガシー_draw方式用） ===
var ruby_data: Array[Dictionary] = []  # 描画するルビ情報
# display_ruby_data: use_draw_ruby=false により削除（デッドコード）
var preserve_ruby_data: bool = false  # TypewriterText実行中はruby_dataを保持
var ruby_main_font: Font = null
var ruby_font: Font = null

# === RubyTextManager統合（新しいアーキテクチャ） ===
var ruby_text_manager: RubyTextManager = null  # Ruby処理の専用マネージャー
@export var use_ruby_text_manager: bool = true  # 新しいRubyTextManagerを使用するか（テスト有効化）

# === Ruby Message Handler ===
var ruby_message_handler: RubyMessageHandler = null  # Ruby処理専用ハンドラー
var message_display_manager: MessageDisplayManager = null  # メッセージ表示専用マネージャー

# === レイヤー初期化マネージャー ===
var layer_initialization_manager: LayerInitializationManager = null

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
	_setup_ui_element_discovery_manager()
	
	# TypewriterText初期化
	_initialize_typewriter()
	
	# RubyTextManager初期化（新しいアーキテクチャ）
	_initialize_ruby_text_manager()
	
	# レイヤー初期化マネージャーをセットアップ
	_setup_layer_initialization_manager()
	
	# カスタムコマンド接続
	_connect_custom_command_signals()
	
	# UIManager統合
	_setup_ui_manager_integration()
	
	# RubyRichTextLabel設定
	_setup_ruby_rich_text_label()
	
	# RubyMessageHandler初期化
	_initialize_ruby_message_handler()
	_initialize_message_display_manager()
	
	# 削除済み: 自動スクリプト開始 (ArgodeSystemに移管)
	
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

# === UI要素発見システム ===

func _setup_ui_element_discovery_manager():
	"""UIElementDiscoveryManagerをセットアップ"""
	ui_element_discovery_manager = UIElementDiscoveryManager.new()
	
	var success = ui_element_discovery_manager.initialize(
		self,
		message_box_path,
		name_label_path,
		message_label_path,
		choice_container_path,
		choice_panel_path,
		choice_vbox_path,
		continue_prompt_path
	)
	
	if not success:
		print("❌ ArgodeScreen: UIElementDiscoveryManager initialization failed")
		return
	
	# UI要素を発見して設定
	var discovered = ui_element_discovery_manager.discover_ui_elements()
	
	if discovered.is_empty():
		print("⚠️ ArgodeScreen: No UI elements discovered")
		return
	
	# 発見された要素を変数に設定
	message_box = discovered.get("message_box")
	name_label = discovered.get("name_label")
	message_label = discovered.get("message_label")
	choice_container = discovered.get("choice_container")
	choice_panel = discovered.get("choice_panel")
	choice_vbox = discovered.get("choice_vbox")
	continue_prompt = discovered.get("continue_prompt")
	
	print("✅ ArgodeScreen: UI element discovery completed successfully")
	
	# RubyRichTextLabelの設定
	_setup_ruby_rich_text_label()

# === TypewriterText統合システム ===

func _initialize_typewriter():
	"""TypewriterTextIntegrationManagerを初期化"""
	if not message_label:
		print("⚠️ AdvScreen: No message_label found - skipping typewriter initialization")
		return
	
	# TypewriterTextIntegrationManager初期化
	typewriter_integration_manager = TypewriterTextIntegrationManager.new()
	var success = typewriter_integration_manager.initialize(message_label, self)
	
	if success:
		print("📱 AdvScreen: TypewriterTextIntegrationManager initialized successfully")
	else:
		print("❌ AdvScreen: TypewriterTextIntegrationManager initialization failed")
		typewriter_integration_manager = null

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
	
	# 既存の設定を引き継ぎ（_draw方式は廃止、常にfalse）
	ruby_text_manager.set_draw_mode(false)
	
	# シグナル接続
	ruby_text_manager.ruby_text_updated.connect(_on_ruby_text_updated)
	ruby_text_manager.ruby_visibility_changed.connect(_on_ruby_visibility_changed)
	
	print("✅ RubyTextManager initialized successfully")
	print("🔍 RubyTextManager debug info: %s" % ruby_text_manager.debug_info())

func _initialize_ruby_message_handler():
	"""RubyMessageHandlerの初期化"""
	print("🚀 Initializing RubyMessageHandler...")
	
	# RubyMessageHandlerインスタンス作成
	ruby_message_handler = RubyMessageHandler.new(message_label)
	
	# 設定を引き継ぎ
	if ruby_message_handler:
		ruby_message_handler.use_ruby_rich_text_label = use_ruby_rich_text_label
		print("✅ RubyMessageHandler initialized successfully")
	else:
		print("❌ Failed to initialize RubyMessageHandler")

func _initialize_message_display_manager():
	"""MessageDisplayManagerの初期化"""
	print("🚀 Initializing MessageDisplayManager...")
	
	# MessageDisplayManagerインスタンス作成
	message_display_manager = MessageDisplayManager.new(self)
	
	# UI要素を設定
	message_display_manager.set_ui_elements(
		message_box, name_label, message_label,
		choice_container, choice_panel, choice_vbox, continue_prompt
	)
	
	# 関連システムを設定
	message_display_manager.set_ruby_message_handler(ruby_message_handler)
	if typewriter_integration_manager:
		message_display_manager.set_typewriter(typewriter_integration_manager.typewriter)
		message_display_manager.set_ruby_text_renderer(typewriter_integration_manager.ruby_text_renderer)
	
	print("✅ MessageDisplayManager initialized successfully")

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
	
	# use_draw_ruby=false によりレガシー_draw方式コードは削除

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
	
	# use_draw_ruby=false によりレガシー_draw方式コードは削除

func _on_character_typed(_character: String, _position: int):
	print("🔤 [Character Typed] character='%s', position=%d" % [_character, _position])
	# use_draw_ruby=false によりレガシー_draw方式コードは削除
	
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

# === レイヤー初期化システム ===

func _setup_layer_initialization_manager():
	"""LayerInitializationManagerをセットアップ"""
	layer_initialization_manager = LayerInitializationManager.new()
	
	var success = layer_initialization_manager.initialize(
		auto_create_layers,
		background_layer_path,
		character_layer_path,
		ui_layer_path,
		adv_system
	)
	
	if not success:
		print("❌ ArgodeScreen: LayerInitializationManager initialization failed")
		return
	
	# レイヤーセットアップを実行
	var parent_scene = get_tree().current_scene
	success = layer_initialization_manager.setup_layers(parent_scene, self)
	
	if success:
		print("✅ ArgodeScreen: Layer initialization completed successfully")
	else:
		print("❌ ArgodeScreen: Layer setup failed")

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

# === 削除済み: 自動スクリプト開始 ===
# _start_auto_script()はArgodeSystemに移管済み

# === メッセージ表示API ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE, override_multi_label_ruby: bool = false):
	"""メッセージを表示する（MessageDisplayManagerに委譲）"""
	if message_display_manager:
		message_display_manager.show_message(character_name, message, name_color, override_multi_label_ruby)
	else:
		print("❌ ArgodeScreen: MessageDisplayManager not available")

func show_choices(choices: Array, is_numbered: bool = false):
	"""選択肢を表示する（MessageDisplayManagerに委譲）"""
	if message_display_manager:
		message_display_manager.show_choices(choices, is_numbered)
	else:
		print("❌ ArgodeScreen: MessageDisplayManager not available")

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
				if typewriter_integration_manager:
					typewriter_integration_manager.skip_typing()
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
	"""スクリプトパスとラベルを設定（DEPRECATED - ArgodeSystem.set_auto_start_label()を使用してください）"""
	if adv_system and adv_system.has_method("set_auto_start_label"):
		adv_system.set_auto_start_label(label)
		print("📱 AdvScreen: Auto-start label set via ArgodeSystem:", label)
	else:
		print("⚠️ DEPRECATED: set_script_path() - use ArgodeSystem.set_auto_start_label() instead")
		print("📱 AdvScreen: Script path:", path, "label:", label)

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
			"typewriter": typewriter_integration_manager != null and typewriter_integration_manager.typewriter != null
		}
	}

# === v2新機能: メッセージウィンドウ表示制御 ===
# 注意: v2.1でUIManagerがCanvasLayerレベル制御に変更されたため、
# 個別UI要素制御は不要になりました。UIManager.visible で全体制御されます。

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

# === ルビ描画システム（_draw方式） - 削除済み ===
# Note: _draw()方式は use_draw_ruby=false で無効化されており、
# 実際のルビ描画はRubyRichTextLabelで処理されるため削除

func simple_ruby_line_break_adjustment(text: String) -> String:
	"""行をまたぐルビ対象文字の前にのみ改行を挿入 - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		return ruby_message_handler.simple_ruby_line_break_adjustment(text)
	else:
		print("⚠️ RubyMessageHandler not available, returning original text")
		return text

func _will_ruby_cross_line(text: String, ruby_start_pos: int, kanji_part: String, font: Font, font_size: int, container_width: float) -> bool:
	"""ルビ対象文字が行をまたぐかどうかを判定 - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		return ruby_message_handler._will_ruby_cross_line(text, ruby_start_pos, kanji_part, font, font_size, container_width)
	else:
		print("⚠️ RubyMessageHandler not available, returning false")
		return false

func set_text_with_ruby_draw(text: String):
	"""ルビ付きテキストを設定 - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		ruby_message_handler.set_text_with_ruby_draw(text)
		# 状態を同期
		adjusted_text = ruby_message_handler.get_adjusted_text()
		current_rubies = ruby_message_handler.get_current_ruby_data()
	else:
		print("⚠️ RubyMessageHandler not available, using fallback")
		if message_label:
			message_label.text = text
		adjusted_text = text

# use_draw_ruby=false により _update_ruby_visibility_for_position 関数は削除（デッドコード）

# use_draw_ruby=false により _calculate_ruby_positions_for_visible 関数は削除（デッドコード）

# use_draw_ruby=false により _calculate_ruby_positions 関数は削除（デッドコード）

func _parse_ruby_syntax(text: String) -> Dictionary:
	"""【漢字｜ふりがな】形式のテキストを解析 - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		return ruby_message_handler._parse_ruby_syntax(text)
	else:
		print("⚠️ RubyMessageHandler not available, returning empty result")
		return {"text": text, "rubies": []}

# === RubyRichTextLabelサポートメソッド ===

func get_current_ruby_data() -> Array:
	"""現在のルビデータを取得（TypewriterTextからアクセス用） - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		return ruby_message_handler.get_current_ruby_data()
	elif message_label and message_label.has_method("get_ruby_data"):
		return message_label.get_ruby_data()
	return current_rubies if current_rubies else []

func get_message_label():
	"""メッセージラベルを取得（TypewriterTextからアクセス用）"""
	return message_label

# 改行調整されたテキストを取得
func get_adjusted_text() -> String:
	"""改行調整されたテキストを取得（TypewriterTextからアクセス用） - RubyMessageHandlerに委譲"""
	if ruby_message_handler:
		return ruby_message_handler.get_adjusted_text()
	elif not adjusted_text.is_empty():
		return adjusted_text
	else:
		return message_label.text if message_label else ""
