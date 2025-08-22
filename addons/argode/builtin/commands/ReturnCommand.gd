extends ArgodeCommandBase
class_name ReturnCommand

func _ready():
	command_class_name = "ReturnCommand"
	command_execute_name = "return"

func execute(args: Dictionary) -> void:
	var statement_manager = args.get("statement_manager")
	
	if not statement_manager:
		log_error("StatementManager not provided")
		return
	
	ArgodeSystem.log_critical("🎯 RETURN_DEBUG: Return command executed - terminating child context")
	
	# コンテキスト情報の詳細ログ
	var context_service = statement_manager.context_service
	if context_service:
		var depth = context_service.get_context_depth()
		ArgodeSystem.log_critical("🎯 RETURN_DEBUG: Current context depth=%d" % depth)
	
	# 新しい設計：Returnは子コンテキストを終了するためのマーカー
	# 実際の復帰処理はContextServiceが自動的に行う
	# Call/Returnスタックはネストした呼び出しのために保持
	
	# Service Layer Pattern準拠: handle_command_result()で終了通知
	statement_manager.handle_command_result({
		"type": "return"
	})
	
	ArgodeSystem.log_critical("🎯 RETURN_DEBUG: Return handled, context should pop")
