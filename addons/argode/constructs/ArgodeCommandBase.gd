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
var has_end_tag:bool = false
var tag_name: String

func execute(args: Dictionary) -> void:
	# コマンドの実行ロジックをここに実装
	# 引数は args で受け取る
	ArgodeSystem.log("Executing command: %s with args: %s" % [command_execute_name, str(args)])

# =============================================================================
# タイプライター制御ヘルパー関数 (StatementManager経由)
# =============================================================================

## タイプライターを一時停止 (WaitCommandなど即座に停止が必要な場合)
func pause_typewriter():
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		statement_manager.pause_typewriter()

## タイプライターを再開
func resume_typewriter():
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		statement_manager.resume_typewriter()

## タイプライター速度を変更 (Speedタグなど開始/終了ペアで使用)
func push_typewriter_speed(new_speed: float):
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		statement_manager.push_typewriter_speed(new_speed)

## タイプライター速度を復元 (Speedタグの終了時など)
func pop_typewriter_speed():
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		statement_manager.pop_typewriter_speed()

## 現在のタイプライター速度を取得
func get_current_typewriter_speed() -> float:
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		return statement_manager.get_current_typewriter_speed()
	return 0.05

## タイプライターの状態チェック
func is_typewriter_paused() -> bool:
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		return statement_manager.is_typewriter_paused()
	return false

func is_typewriter_active() -> bool:
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		return statement_manager.is_typewriter_active()
	return false
