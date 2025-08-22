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
	
	# ArgodeVariableManagerから値を取得
	if ArgodeSystem and ArgodeSystem.has_method("get") and ArgodeSystem.get("VariableManager"):
		var variable_manager = ArgodeSystem.get("VariableManager")
		var value = variable_manager.get_variable(variable_name)
		
		if value != null:
			log_info("変数取得: %s = %s" % [variable_name, str(value)])
		else:
			log_warning("変数が見つかりません: %s" % variable_name)
	else:
		log_error("VariableManager not available")