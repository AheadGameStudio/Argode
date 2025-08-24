extends ArgodeCommandBase
class_name GetCommand

func _ready():
	command_class_name = "GetCommand"
	command_execute_name = "get"
	is_also_tag = true
	tag_name = "get"  # 変数表示用のタグとしても使用
	command_description = "変数の値を取得して表示します"
	command_help = "get variable_name"

## 引数検証（Stage 3共通基盤）
func validate_args(args: Dictionary) -> bool:
	var variable_name = get_optional_arg(args, "0", "")
	if variable_name.is_empty():
		log_error("変数名が指定されていません")
		return false
	return true

## コマンド中核処理（Stage 3共通基盤）
func execute_core(args: Dictionary) -> void:
	var variable_name = get_required_arg(args, "0", "変数名")
	
	if variable_name == null:
		return  # エラーは既にログ出力済み
	
	# ✅ Task 6-3: GlyphSystem統合による変数展開処理
	var variable_manager = get_variable_manager()
	if not variable_manager:
		log_error("VariableManager not available")
		return
	
	var value = variable_manager.get_variable(variable_name)
	if value == null:
		log_warning("変数が見つかりません: %s" % variable_name)
		return
	
	log_info("変数取得: %s = %s" % [variable_name, str(value)])
	
	# GlyphSystemを通して変数値を表示
	var ui_manager = get_ui_manager()
	if not ui_manager:
		log_error("UIManager not available")
		return
	
	var statement_manager = get_statement_manager()
	if statement_manager and statement_manager.has_method("show_message_via_glyph_system"):
		# 変数値をメッセージとして表示
		statement_manager.show_message_via_glyph_system(str(value), "")
		log_info("✅ GetCommand: Variable value displayed via GlyphSystem - '%s' = '%s'" % [variable_name, str(value)])
	else:
		log_error("StatementManager GlyphSystem method not available")