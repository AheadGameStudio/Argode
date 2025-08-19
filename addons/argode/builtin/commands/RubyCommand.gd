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
	# ルビ情報をMessageRendererに渡す
	var base_text = args.get("base_text", "")
	var ruby_text = args.get("ruby_text", "")
	
	if base_text.is_empty() or ruby_text.is_empty():
		ArgodeSystem.log("❌ RubyCommand: Invalid ruby data - base_text='%s', ruby_text='%s'" % [base_text, ruby_text], 2)
		return
	
	# _extract_ruby_data で既に処理済みなので、ここでは何もしない
	# ログだけ出力
	ArgodeSystem.log("📖 RubyCommand: Ruby processed - '%s' (%s)" % [base_text, ruby_text])
