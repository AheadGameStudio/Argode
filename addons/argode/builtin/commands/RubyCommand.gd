extends ArgodeCommandBase
class_name RubyCommand

func _ready():
	command_class_name = "RubyCommand"
	command_execute_name = "ruby"
	is_also_tag = true
	tag_name = "ruby"
	command_description = "ルビ（フリガナ）を表示"
	command_help = "【本文｜ふりがな】の形式で自動的に処理されます"

func execute(args: Dictionary) -> void:
	# ✅ Task 6-3: GlyphSystem統合によるルビ処理実装
	var base_text = args.get("base_text", "")
	var ruby_text = args.get("ruby_text", "")
	
	if base_text.is_empty() or ruby_text.is_empty():
		ArgodeSystem.log("❌ RubyCommand: Invalid ruby data - base_text='%s', ruby_text='%s'" % [base_text, ruby_text], 2)
		return
	
	ArgodeSystem.log("📖 RubyCommand: Processing ruby - '%s' (%s)" % [base_text, ruby_text])
	
	# ✅ Task 6-3: ArgodeMessageRendererに直接ルビ情報を送信
	var ui_manager = get_ui_manager()
	if not ui_manager:
		ArgodeSystem.log("❌ RubyCommand: UIManager not available", 2)
		return
	
	# UIControlService経由でMessageRendererにアクセス
	var ui_control_service = ui_manager.get_ui_control_service() if ui_manager.has_method("get_ui_control_service") else null
	if not ui_control_service:
		ArgodeSystem.log("❌ RubyCommand: UIControlService not available", 2)
		return
	
	# MessageRenderer取得
	var message_renderer = ui_control_service.get_message_renderer() if ui_control_service.has_method("get_message_renderer") else null
	if not message_renderer:
		ArgodeSystem.log("❌ RubyCommand: MessageRenderer not available", 2)
		return
	
	# ルビ情報をMessageRendererに追加
	if message_renderer.has_method("add_ruby_to_current_message"):
		message_renderer.add_ruby_to_current_message(base_text, ruby_text)
		ArgodeSystem.log("✅ RubyCommand: Ruby data sent to GlyphSystem - '%s'（%s）" % [base_text, ruby_text])
	else:
		ArgodeSystem.log("❌ RubyCommand: MessageRenderer ruby method not available", 2)
