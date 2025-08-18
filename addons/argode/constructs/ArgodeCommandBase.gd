# コマンドの基底クラス

extends RefCounted
class_name ArgodeCommandBase

var is_define_command: bool = false

# コマンドの名前
var command_execute_name: String
var command_class_name: String

# コマンドの説明
var command_description: String

# コマンドの使い方を示すヘルプテキスト
var command_help: String

# コマンド指定の際の引数 key:value で保存
var command_args: Dictionary = {}

# このコマンドの引数で指定するキーワードのリスト
var command_keywords: Array = []

var is_also_tag: bool = false
var tag_name: String

func execute(args: Dictionary) -> void:
	# コマンドの実行ロジックをここに実装
	# 引数は args で受け取る
	ArgodeSystem.log("Executing command: %s with args: %s" % [command_execute_name, str(args)])
