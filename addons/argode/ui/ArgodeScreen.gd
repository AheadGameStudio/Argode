# AdvScreen.gd
# v2設計: UI基底クラス - call_screenで呼び出されるUIシーンが継承すべき高機能な基底クラス
extends Control
class_name ArgodeScreen

# === 削除済み: レイヤー自動展開システム ===

# === 新しいRubyTextManager統合 ===
const RubyTextManager = preload("res://addons/argode/ui/ruby/RubyTextManager.gd")
# 削除済み: RubyParser (未使用)
const RubyMessageHandler = preload("res://addons/argode/ui/ruby/RubyMessageHandler.gd")
# 統合済み: MessageDisplayManager → UIManager
# 統合済み: LayerInitializationManager → LayerManager
# 統合済み: UIElementDiscoveryManager → UIManager
const TypewriterTextIntegrationManager = preload("res://addons/argode/ui/managers/TypewriterTextIntegrationManager.gd")

# === シグナル ===
signal screen_closed(return_value)
signal screen_ready()
signal screen_pre_close()

# === 画面管理プロパティ ===
var screen_name: String = ""
var is_screen_active: bool = false
var return_value: Variant = null
var screen_parameters: Dictionary = {}
# 削除済み: parent_screen (未使用変数)

# === UI要素参照（実行時に設定される） ===
# === TypewriterText統合 ===
var typewriter_integration_manager: TypewriterTextIntegrationManager = null
var is_message_complete: bool = false
var handle_input: bool = true
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

# === 削除済み: 自動スクリプト設定 ===
# use ArgodeSystem.set_auto_start_label() instead
# === ルビ表示設定 ===
## RubyRichTextLabelを使用するかどうか（推奨実装）
@export var use_ruby_rich_text_label: bool = true
## ルビのデバッグ表示を有効にするかどうか
@export var show_ruby_debug: bool = true

# 改行調整されたテキストを保存（TypewriterTextからアクセス可能）
var adjusted_text: String = ""

# === 削除済み: レガシールビ描画システム（_draw方式用） ===
# === 統合済み: RubyTextManager統合（新しいアーキテクチャ） ===
var ruby_text_manager: RubyTextManager = null  # Ruby処理の専用マネージャー
@export var use_ruby_text_manager: bool = true  # 新しいRubyTextManagerを使用するか（テスト有効化）

# === Ruby Message Handler ===
var ruby_message_handler: RubyMessageHandler = null  # Ruby処理専用ハンドラー
# 統合済み: MessageDisplayManager → UIManager

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
	# UI要素の自動発見（UIManager統合機能使用）
	_setup_ui_element_discovery_integration()
	
	# TypewriterText初期化
	_initialize_typewriter()
	
	# RubyTextManager初期化（新しいアーキテクチャ）
	_initialize_ruby_text_manager()
	
	# レイヤー初期化（LayerManager統合機能使用）
	_setup_layer_initialization_integration()
	
	# カスタムコマンド接続
	_connect_custom_command_signals()
	
	# UIManager統合
	_setup_ui_manager_integration()
	
	# RubyRichTextLabel設定
	_setup_ruby_rich_text_label()
	
	# RubyMessageHandler初期化
	_initialize_ruby_message_handler()
	# MessageDisplayManager統合済み（UIManager）
	
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

# === UI要素発見システム（UIManager統合） ===

func _setup_ui_element_discovery_integration():
	"""UIManager統合機能を使用してUI要素を発見"""
	if not adv_system or not adv_system.UIManager:
		print("❌ ArgodeScreen: UIManager not available for UI element discovery")
		return
	
	var ui_manager = adv_system.UIManager
	
	# UIManagerの統合機能を使用してUI要素を発見
	var discovered = ui_manager.discover_ui_elements(
		self,
		message_box_path,
		name_label_path,
		message_label_path,
		choice_container_path,
		choice_panel_path,
		choice_vbox_path,
		continue_prompt_path
	)
	
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
	
	print("✅ ArgodeScreen: UI element discovery completed via UIManager integration")
	
	# RubyRichTextLabelの設定
	_setup_ruby_rich_text_label()
	
	# meta_clickedシグナルの接続（Glossaryタグ対応）
	_setup_meta_clicked_handler()

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

func _setup_meta_clicked_handler():
	"""RichTextLabelのmeta_clickedシグナル接続（Glossaryタグ対応）"""
	if not message_label:
		print("⚠️ No message_label found - skipping meta_clicked setup")
		return
	
	if not message_label is RichTextLabel:
		print("⚠️ message_label is not RichTextLabel - cannot setup meta_clicked")
		return
	
	# BBCode有効化（URLタグのため）
	var rich_text_label = message_label as RichTextLabel
	rich_text_label.bbcode_enabled = true
	print("🔗 BBCode enabled for meta_clicked functionality")
	
	# meta_clickedシグナルが既に接続されている場合は切断
	if message_label.meta_clicked.is_connected(_on_message_label_meta_clicked):
		message_label.meta_clicked.disconnect(_on_message_label_meta_clicked)
		print("🔄 Disconnected existing meta_clicked signal")
	
	# meta_clickedシグナルを接続
	var result = message_label.meta_clicked.connect(_on_message_label_meta_clicked)
	if result == OK:
		print("✅ meta_clicked signal connected successfully for Glossary tags")
	else:
		print("❌ Failed to connect meta_clicked signal: %d" % result)

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
	# 削除済み: preserve_ruby_data = true (未使用変数)
	print("⌨️ AdvScreen: Typewriter started")

func _on_typewriter_finished():
	is_message_complete = true
	# 削除済み: preserve_ruby_data = false (未使用変数)
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

# === レイヤー初期化システム（LayerManager統合） ===

func _setup_layer_initialization_integration():
	"""LayerManager統合機能を使用してレイヤーを初期化"""
	if not adv_system or not adv_system.LayerManager:
		print("❌ ArgodeScreen: LayerManager not available for layer initialization")
		return
	
	var layer_manager = adv_system.LayerManager
	
	# LayerManagerの統合機能を使用してレイヤーを初期化
	var parent_scene = get_tree().current_scene
	var layer_mappings = layer_manager.initialize_argode_layers(
		parent_scene,
		auto_create_layers,
		background_layer_path,
		character_layer_path,
		ui_layer_path,
		self
	)
	
	if layer_mappings.is_empty():
		print("❌ ArgodeScreen: Layer initialization failed")
		return
	
	print("✅ ArgodeScreen: Layer initialization completed via LayerManager integration")
	print("   Layers: ", layer_mappings.keys())

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

# === メッセージ表示API ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE, override_multi_label_ruby: bool = false):
	"""メッセージを表示する（UIManager統合機能使用）"""
	if adv_system and adv_system.UIManager:
		adv_system.UIManager.display_message_with_effects(character_name, message, name_color, override_multi_label_ruby)
	else:
		_log_manager_not_available("UIManager")

func show_choices(choices: Array, is_numbered: bool = false):
	"""選択肢を表示する（UIManager統合機能使用）"""
	if adv_system and adv_system.UIManager:
		# UIManagerの選択肢表示機能を呼び出し（引数1つのみ対応）
		adv_system.UIManager.show_choices(choices)
	else:
		_log_manager_not_available("UIManager")

func _log_manager_not_available(manager_name: String):
	"""マネージャー不在エラーログの統一メソッド"""
	print("❌ ArgodeScreen: %s not available" % manager_name)

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
		print("🎮 ArgodeScreen: Input detected (ui_accept/ui_select)")
		
		# UIManagerの入力処理を優先的に呼び出し
		if adv_system and adv_system.UIManager:
			var handled = adv_system.UIManager.handle_input_for_argode(event)
			if handled:
				print("✅ Input handled by UIManager")
				get_viewport().set_input_as_handled()
				return
			else:
				print("➡️ UIManager returned false, proceeding with ArgodeScreen logic")
		
		# UIManagerが処理しなかった場合の従来ロジック
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

# === Glossaryタグ対応: meta_clickedハンドラー ===

func _on_message_label_meta_clicked(meta: Variant):
	"""RichTextLabelのmeta_clickedシグナル処理（Glossaryタグ対応）"""
	print("🔗 meta_clicked triggered: %s (%s)" % [meta, typeof(meta)])
	
	# meta引数の型チェック
	var meta_str: String = ""
	if meta is String:
		meta_str = meta as String
	else:
		meta_str = str(meta)
	
	# Glossaryタグの処理
	if meta_str.begins_with("glossary:"):
		var glossary_key = meta_str.substr(9)  # "glossary:"の部分を除去
		print("📖 Glossary tag clicked: '%s'" % glossary_key)
		_handle_glossary_click(glossary_key)
	else:
		print("ℹ️ Unknown meta tag: '%s'" % meta_str)

func _handle_glossary_click(glossary_key: String):
	"""Glossaryクリック処理"""
	print("📋 Handling glossary click for: '%s'" % glossary_key)
	
	# TODO: ここにGlossaryシステムとの連携処理を実装
	# 例: Glossaryウィンドウを開く、説明テキストを表示する等
	
	# 現在はデバッグ表示のみ
	print("💡 Glossary '%s' の説明を表示する処理をここに実装予定" % glossary_key)
