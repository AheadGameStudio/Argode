class_name ArgodeVariableManager

## 変数を管理するマネージャー
## ゲーム内の変数（player.name, player.affection等）を保存・取得する

var variables: Dictionary = {}

## 変数を設定
func set_variable(variable_name: String, value: Variant) -> void:
	variables[variable_name] = value
	ArgodeSystem.log("📝 Variable stored: %s = %s" % [variable_name, str(value)])

## 変数を取得
func get_variable(variable_name: String) -> Variant:
	if variables.has(variable_name):
		return variables[variable_name]
	
	# 変数が見つからない場合はnullを返す
	ArgodeSystem.log("⚠️ Variable not found: %s" % variable_name, 1)
	return null

## 変数が存在するかチェック
func has_variable(variable_name: String) -> bool:
	return variables.has(variable_name)

## 全ての変数をクリア
func clear_all_variables() -> void:
	variables.clear()
	ArgodeSystem.log("🗑️ All variables cleared")

## 変数一覧を取得（デバッグ用）
func get_all_variables() -> Dictionary:
	return variables.duplicate()

## 変数をデバッグログに出力
func debug_print_variables() -> void:
	ArgodeSystem.log("📊 Current variables:")
	for key in variables.keys():
		ArgodeSystem.log("  %s = %s" % [key, str(variables[key])])