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

# =============================================================================
# 共通処理メソッド (Stage 3追加)
# =============================================================================

## 引数検証の統一メソッド
func validate_args(args: Dictionary) -> bool:
	"""コマンドの引数を検証。サブクラスでオーバーライド可能"""
	return true

## コマンド実行前の共通処理
func execute_safe(args: Dictionary) -> void:
	"""安全なコマンド実行（エラーハンドリング付き）"""
	# 引数検証
	if not validate_args(args):
		log_error("引数検証に失敗しました")
		return
	
	# ログ出力（開始）
	log_debug("コマンド開始: %s" % command_execute_name)
	
	# 実際の処理実行
	execute_core(args)
	
	# ログ出力（完了）
	log_debug("コマンド完了: %s" % command_execute_name)

## コマンドの中核処理（サブクラスで実装）
func execute_core(args: Dictionary) -> void:
	"""コマンドの中核処理。サブクラスで必ずオーバーライド"""
	log_warning("execute_core()が実装されていません: %s" % command_execute_name)

## 従来のexecuteメソッド（互換性維持）
func execute(args: Dictionary) -> void:
	"""下位互換のためのexecuteメソッド"""
	execute_safe(args)

## エラーハンドリングの統一
func handle_error(message: String) -> void:
	"""エラー処理の統一"""
	log_error(message)

# =============================================================================
# ログ出力の統一
# =============================================================================

## 統一ログ出力: デバッグ
func log_debug(message: String) -> void:
	ArgodeSystem.log("🔍 %s: %s" % [command_class_name, message])

## 統一ログ出力: 情報
func log_info(message: String) -> void:
	ArgodeSystem.log("ℹ️ %s: %s" % [command_class_name, message])

## 統一ログ出力: 警告
func log_warning(message: String) -> void:
	ArgodeSystem.log("⚠️ %s: %s" % [command_class_name, message], 1)

## 統一ログ出力: エラー
func log_error(message: String) -> void:
	ArgodeSystem.log("❌ %s: %s" % [command_class_name, message], 2)

# =============================================================================
# 引数取得ヘルパー
# =============================================================================

## 必須引数の取得（エラーハンドリング付き）
func get_required_arg(args: Dictionary, key: String, arg_name: String = "") -> Variant:
	"""必須引数を取得。存在しない場合はエラー"""
	if not args.has(key):
		var display_name = arg_name if not arg_name.is_empty() else key
		log_error("必須引数が不足しています: %s" % display_name)
		return null
	
	var value = args[key]
	if typeof(value) == TYPE_STRING and value.strip_edges().is_empty():
		var display_name = arg_name if not arg_name.is_empty() else key
		log_error("必須引数が空です: %s" % display_name)
		return null
	
	return value

## オプション引数の取得
func get_optional_arg(args: Dictionary, key: String, default_value: Variant = "") -> Variant:
	"""オプション引数を取得。存在しない場合はデフォルト値"""
	return args.get(key, default_value)

## サブコマンドがある場合、その引数を返す
func get_subcommand_arg(args: Dictionary, subcommand: String) -> Variant:
	for v in args.values():
		if v == subcommand:
			# subcommandが見つかった場合のキー名を取得
			var key_name:String = args.find_key(v)
			log_info("Found 'with' in args: %s" % key_name)
			# subcommandのキー名の文字列の最後の1文字を取得
			var _subcommand_key = "arg" + str(int(key_name[-1])+1)
			if args.has(_subcommand_key):
				# subcommandの後のキーが存在すれば、その値を取得
				var _subcommand_value = args.get(_subcommand_key, "")
				log_info("Subcommand value extracted: %s" % _subcommand_value)
				return args.get(_subcommand_key, "")
			else:
				# subcommandの後の引数がない場合はエラー
				log_error("サブコマンド '%s' の後の引数が必要です" % subcommand)
				return null
	log_info("サブコマンド '%s' が設定されていません" % subcommand)
	return false

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
