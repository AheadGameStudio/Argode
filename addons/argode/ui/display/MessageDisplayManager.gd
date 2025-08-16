# MessageDisplayManager.gd
# ArgodeScreenから分離されたメッセージ表示専用クラス
# 責任: UI要素管理、メッセージ表示、選択肢表示の統合管理

extends RefCounted
class_name MessageDisplayManager

const RubyParser = preload("res://addons/argode/ui/ruby/RubyParser.gd")
const RubyRichTextLabel = preload("res://addons/argode/ui/RubyRichTextLabel.gd")

# === UI要素参照 ===
var message_box: Control = null
var name_label: Label = null  
var message_label: RichTextLabel = null
var choice_container: Control = null
var choice_panel: Control = null
var choice_vbox: VBoxContainer = null
var continue_prompt: Control = null

# === 関連システム参照 ===
var screen_owner: Control = null  # ArgodeScreenへの参照
var ruby_message_handler = null
var typewriter = null
var ruby_text_renderer = null

# === 状態管理 ===
var is_message_complete: bool = false
var use_ruby_rich_text_label: bool = true
var current_rubies: Array = []

func _init(owner: Control = null):
	"""初期化時にスクリーンオーナーを設定"""
	screen_owner = owner

func set_screen_owner(owner: Control):
	"""スクリーンオーナーを設定"""
	screen_owner = owner

func set_ruby_message_handler(handler):
	"""RubyMessageHandlerを設定"""
	ruby_message_handler = handler

func set_typewriter(tw):
	"""Typewriterを設定"""
	typewriter = tw

func set_ruby_text_renderer(renderer):
	"""RubyTextRendererを設定"""
	ruby_text_renderer = renderer

# === UI要素設定 ===

func set_ui_elements(msg_box: Control, name_lbl: Label, msg_lbl: RichTextLabel, 
					choice_cont: Control = null, choice_pnl: Control = null, 
					choice_vb: VBoxContainer = null, continue_prmt: Control = null):
	"""UI要素を一括設定"""
	message_box = msg_box
	name_label = name_lbl
	message_label = msg_lbl
	choice_container = choice_cont
	choice_panel = choice_pnl
	choice_vbox = choice_vb
	continue_prompt = continue_prmt
	
	print("📱 MessageDisplayManager: UI elements set")
	print("  - message_box: ", message_box != null)
	print("  - name_label: ", name_label != null)
	print("  - message_label: ", message_label != null)

# === UI要素発見 ===

func auto_discover_ui_elements() -> bool:
	"""UI要素を自動発見（ArgodeScreenのNodePath設定を使用）"""
	if not screen_owner:
		print("❌ MessageDisplayManager: No screen owner available")
		return false
	
	# ArgodeScreenからNodePath情報を取得して要素を発見
	if screen_owner.has_method("_get_node_from_path_or_fallback"):
		message_box = screen_owner._get_node_from_path_or_fallback(
			screen_owner.message_box_path, "MessageBox")
		name_label = screen_owner._get_node_from_path_or_fallback(
			screen_owner.name_label_path, "NameLabel", message_box)
		message_label = screen_owner._get_node_from_path_or_fallback(
			screen_owner.message_label_path, "MessageLabel", message_box)
		choice_container = screen_owner._get_node_from_path_or_fallback(
			screen_owner.choice_container_path, "ChoiceContainer")
		choice_panel = screen_owner._get_node_from_path_or_fallback(
			screen_owner.choice_panel_path, "ChoicePanel", choice_container)
		choice_vbox = screen_owner._get_node_from_path_or_fallback(
			screen_owner.choice_vbox_path, "ChoiceVBox", choice_panel)
		continue_prompt = screen_owner._get_node_from_path_or_fallback(
			screen_owner.continue_prompt_path, "ContinuePrompt")
		
		print("📱 MessageDisplayManager UI discovery completed:")
		print("  - MessageBox=", message_box != null)
		print("  - NameLabel=", name_label != null) 
		print("  - MessageLabel=", message_label != null)
		
		return message_box != null and message_label != null
	else:
		print("❌ MessageDisplayManager: screen_owner doesn't have _get_node_from_path_or_fallback method")
		return false

# === RubyRichTextLabel設定 ===

func setup_ruby_rich_text_label():
	"""RubyRichTextLabelを設定"""
	if not message_label:
		print("❌ MessageDisplayManager: No message_label for Ruby setup")
		return
		
	print("🔍 message_label details:")
	print("  - Type: ", message_label.get_class())
	print("  - Script: ", message_label.get_script())
	print("  - Is RichTextLabel: ", message_label is RichTextLabel)
	print("  - Is RubyRichTextLabel: ", message_label is RubyRichTextLabel)
	
	if message_label is RubyRichTextLabel:
		print("✅ message_label is RubyRichTextLabel - configuring ruby settings")
		var ruby_label = message_label as RubyRichTextLabel
		if ruby_label.has_method("set_debug_enabled"):
			ruby_label.set_debug_enabled(false)
			print("🔤 RubyRichTextLabel configured with debug=false (method)")
		elif ruby_label.get("debug_enabled") != null:
			ruby_label.debug_enabled = false
			print("🔤 RubyRichTextLabel configured with debug=false (property)")
		else:
			print("⚠️ debug_enabled not accessible - skipping configuration")
		use_ruby_rich_text_label = true
	else:
		print("⚠️ message_label is not RubyRichTextLabel - standard mode")
		use_ruby_rich_text_label = false

# === エスケープシーケンス処理 ===

func process_escape_sequences(text: String) -> String:
	"""エスケープシーケンスを処理"""
	var result = text
	result = result.replace("\\n", "\n")
	result = result.replace("\\t", "\t")
	result = result.replace("\\\\", "\\")
	return result

# === メッセージ表示 ===

func show_message(character_name: String = "", message: String = "", name_color: Color = Color.WHITE, override_multi_label_ruby: bool = false):
	"""メッセージを表示する（タイプライター付き）"""
	print("🔍 [MessageDisplayManager] show_message called:")
	print("  - message_box: ", message_box)
	print("  - message_label: ", message_label)
	print("  - message_box is null: ", message_box == null)
	print("  - message_label is null: ", message_label == null)
	
	if not message_box or not message_label:
		print("❌ MessageDisplayManager: MessageBox or MessageLabel not available")
		print("❌ [Debug] Missing UI elements - attempting re-initialization")
		if not auto_discover_ui_elements():
			print("❌ MessageDisplayManager: UI elements still not available after re-initialization")
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
	
	# キャラクター名の設定
	if character_name.is_empty():
		if name_label:
			name_label.text = ""
			name_label.visible = false
	else:
		if name_label:
			name_label.text = character_name
			name_label.modulate = name_color
			name_label.visible = true
	
	var processed_message = process_escape_sequences(message)
	
	# 初回呼び出し時にRubyRichTextLabel設定を確認
	if use_ruby_rich_text_label:
		print("🔧 [Lazy Init] RubyRichTextLabel setup not yet done, triggering...")
		setup_ruby_rich_text_label()
	
	# ルビシステム選択（複数Label方式は廃止、常にfalse）
	var should_use_multi_label = override_multi_label_ruby
	
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
		var raw_ruby_message = RubyParser.reverse_ruby_conversion(processed_message)
		print("🔄 [Debug] Raw ruby message: '%s'" % raw_ruby_message.replace("\n", "\\n"))
		
		# RubyMessageHandlerを通してルビ処理
		if ruby_message_handler:
			var adjusted_message = ruby_message_handler.simple_ruby_line_break_adjustment(raw_ruby_message)
			print("✅ [Simple] Using adjusted message: '%s'" % adjusted_message.replace("\n", "\\n"))
			ruby_message_handler.set_text_with_ruby_draw(adjusted_message)
			
			# TypewriterTextでタイプライター効果（RubyRichTextLabel使用時はclean_textを使用）
			if typewriter:
				# RubyMessageHandlerから調整されたテキストを取得
				var clean_text_for_typing = ruby_message_handler.get_adjusted_text()
				print("🎨 TypewriterText using clean text for RubyRichTextLabel: '%s'" % clean_text_for_typing)
				typewriter.start_typing(clean_text_for_typing)
			else:
				is_message_complete = true
				if continue_prompt:
					continue_prompt.visible = true
		else:
			print("❌ MessageDisplayManager: No ruby_message_handler available")
			return
			
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
	
	print("💬 MessageDisplayManager: [", character_name, "] ", processed_message)

# === 選択肢表示（スタブ実装） ===

func show_choices(choices: Array, _is_numbered: bool = false):
	"""選択肢を表示する"""
	print("📋 MessageDisplayManager: show_choices called with ", choices.size(), " choices")
	
	if not choice_container or not choice_vbox:
		print("❌ MessageDisplayManager: ChoiceContainer or choice_vbox not available")
		return
	
	if message_box:
		message_box.visible = true
	choice_container.visible = true
	if continue_prompt:
		continue_prompt.visible = false
	
	# 選択肢ボタンの実装は後で分離
	print("⚠️ MessageDisplayManager: Choice button implementation pending")
