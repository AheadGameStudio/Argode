# コマンドの基底クラス

extends RefCounted
class_name ArgodeCommandBase

var is_define_command: bool = false

# 装飾コマンドかどうかのフラグ（GlyphSystemで使用）
var is_decoration_command: bool = false : set = set_is_decoration_command

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

# タグ関連の設定（v1.2.0拡張性対応）
var custom_tag_patterns: Array[String] = []
var tag_removal_priority: int = 100

# =============================================================================
# プロパティセッター（自動設定）
# =============================================================================

## is_decoration_command設定時の自動処理
func set_is_decoration_command(value: bool) -> void:
	"""装飾コマンドフラグ設定時に自動的にペアタグフラグも設定"""
	is_decoration_command = value
	if value:
		has_end_tag = true
		is_also_tag = true
		ArgodeSystem.log("🏷️ 装飾コマンド設定: %s -> ペアタグ自動有効化" % command_class_name)

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
	
	# 実際の処理実行（非同期対応）
	await execute_core(args)
	
	# ログ出力（完了）
	log_debug("コマンド完了: %s" % command_execute_name)

## コマンドの中核処理（サブクラスで実装）
func execute_core(args: Dictionary) -> void:
	"""コマンドの中核処理。サブクラスで必ずオーバーライド"""
	log_warning("execute_core()が実装されていません: %s" % command_execute_name)

## 従来のexecuteメソッド（互換性維持）
func execute(args: Dictionary) -> void:
	"""下位互換のためのexecuteメソッド"""
	await execute_safe(args)

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
# Universal Block Execution ヘルパー関数 (Phase 5 追加)
# =============================================================================

## ArgodeSystem統一アクセスヘルパー
func get_ui_manager() -> ArgodeUIManager:
	"""UIManagerの安全な取得"""
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		log_error("UIManager not available")
	return ui_manager

func get_statement_manager() -> ArgodeStatementManager:
	"""StatementManagerの安全な取得"""
	var statement_manager = ArgodeSystem.StatementManager
	if not statement_manager:
		log_error("StatementManager not available")
	return statement_manager

func get_variable_manager() -> ArgodeVariableManager:
	"""VariableManagerの安全な取得"""
	var variable_manager = ArgodeSystem.VariableManager
	if not variable_manager:
		log_error("VariableManager not available")
	return variable_manager

## Variable Resolverの統一作成
func create_variable_resolver() -> ArgodeVariableResolver:
	"""Variable Resolverの統一作成（IfCommand, SetCommandで共通使用）"""
	var variable_manager = get_variable_manager()
	if not variable_manager:
		return null
	
	return ArgodeVariableResolver.new(variable_manager)

## ラベル情報の安全な取得
func get_label_info(label_name: String) -> Dictionary:
	"""ラベル情報の取得（存在チェック付き）"""
	if label_name.is_empty():
		log_error("ラベル名が空です")
		return {}
	
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		log_error("ラベル '%s' が見つかりません" % label_name)
		return {}
	
	return label_info

## ラベルステートメントの安全な取得
func get_label_statements(label_name: String) -> Array:
	"""ラベルのステートメント配列を取得（JumpCommand, CallCommandで共通使用）"""
	var statement_manager = get_statement_manager()
	if not statement_manager:
		return []
	
	var label_statements = statement_manager.get_label_statements(label_name)
	if label_statements.is_empty():
		log_error("ラベル '%s' にステートメントが見つかりません" % label_name)
		return []
	
	return label_statements

## ブロック実行のヘルパー
func execute_statements_block(statements: Array, context_name: String = "", source_label: String = "") -> void:
	"""ステートメントブロックの実行（MenuCommand, IfCommandで共通使用）"""
	if statements.is_empty():
		log_debug("実行するステートメントがありません")
		return
	
	var statement_manager = get_statement_manager()
	if not statement_manager:
		return
	
	var execution_context = context_name if not context_name.is_empty() else command_execute_name
	log_debug("ブロック実行開始: %s (%d statements)" % [execution_context, statements.size()])
	
	# source_labelが指定されている場合は連続実行を有効にする
	if not source_label.is_empty():
		await statement_manager.execute_block(statements, source_label)
	else:
		await statement_manager.execute_block(statements)
	
	log_debug("ブロック実行完了: %s" % execution_context)

## ラベルジャンプのヘルパー
func jump_to_label(label_name: String) -> void:
	"""ラベルへのジャンプ実行（JumpCommand, CallCommandで共通使用）"""
	var label_statements = get_label_statements(label_name)
	if label_statements.is_empty():
		return
	
	log_debug("ラベルジャンプ: %s (%d statements)" % [label_name, label_statements.size()])
	
	# ジャンプ先からの連続実行を有効にする
	await execute_statements_block(label_statements, "jump_" + label_name, label_name)

## オートプレイ対応の入力待ち
func wait_for_input_with_autoplay(auto_delay: float = 0.1) -> void:
	"""オートプレイ対応の統一入力待ち（SayCommand, MenuCommand, WaitCommandで共通使用）"""
	if ArgodeSystem.is_auto_play_mode():
		log_debug("AUTO-PLAY MODE - 自動進行 (delay: %s)" % auto_delay)
		await Engine.get_main_loop().create_timer(auto_delay).timeout
	else:
		var ui_manager = get_ui_manager()
		if ui_manager:
			log_debug("入力待ち開始")
			await ui_manager.wait_for_input()
			log_debug("入力受信完了")

## タイプライターエフェクト完了待ち + 入力待ち
func wait_for_typewriter_and_input() -> void:
	"""タイプライターエフェクトが完了してから入力待ちを行う"""
	# タイプライターエフェクトの完了を待つ
	log_debug("🔤 タイプライターエフェクト完了待ち開始")
	
	# オートプレイモードの場合、タイプライターエフェクトの文字数に基づいた適切な待機時間を計算
	if ArgodeSystem.is_auto_play_mode():
		var statement_manager = get_statement_manager()
		if statement_manager and statement_manager.has_method("get_current_message_length"):
			var message_length = statement_manager.get_current_message_length()
			# 1文字あたり0.05秒 + 最低0.5秒の基本待機時間
			var calculated_delay = max(0.5, message_length * 0.05)
			log_debug("AUTO-PLAY MODE - タイプライター計算待機 (chars: %d, delay: %s)" % [message_length, calculated_delay])
			await Engine.get_main_loop().create_timer(calculated_delay).timeout
		else:
			# フォールバック: 固定2秒待機
			log_debug("AUTO-PLAY MODE - タイプライター固定待機 (delay: 2.0)")
			await Engine.get_main_loop().create_timer(2.0).timeout
	else:
		# 通常モード: 入力待ち
		var ui_manager = get_ui_manager()
		if ui_manager:
			log_debug("通常モード - タイプライター完了後の入力待ち開始")
			await ui_manager.wait_for_input()
			log_debug("タイプライター完了後の入力受信完了")
	
	log_debug("🔤 タイプライターエフェクト + 入力待ち完了")

## 変数値の安全な取得
func get_variable_value(variable_name: String, default_value: Variant = null) -> Variant:
	"""変数値の安全な取得（エラーハンドリング付き）"""
	var variable_manager = get_variable_manager()
	if not variable_manager:
		return default_value
	
	return variable_manager.get_variable(variable_name, default_value)

## 変数値の安全な設定
func set_variable_value(variable_name: String, value: Variant) -> bool:
	"""変数値の安全な設定（成功/失敗を返す）"""
	var variable_manager = get_variable_manager()
	if not variable_manager:
		return false
	
	variable_manager.set_variable(variable_name, value)
	log_debug("変数設定: %s = %s" % [variable_name, str(value)])
	return true

## 式評価のヘルパー
func evaluate_expression(expression: String) -> Variant:
	"""式評価のヘルパー（条件文等で使用）"""
	var variable_resolver = create_variable_resolver()
	if not variable_resolver:
		log_error("Variable Resolverの作成に失敗しました")
		return false
	
	# ArgodeVariableResolverが評価機能を持っているかチェック
	if variable_resolver.has_method("evaluate_expression"):
		return variable_resolver.evaluate_expression(expression)
	
	# 基本的な変数参照のみサポート
	return variable_resolver._process_value(expression)

## Definition取得のヘルパー
func get_definition(definition_type: String, name: String) -> Dictionary:
	"""定義情報の取得（character, image等で使用）"""
	var definition = ArgodeSystem.DefinitionRegistry.get_definition(definition_type, name)
	if definition.is_empty():
		log_warning("定義が見つかりません: %s '%s'" % [definition_type, name])
	return definition

## ExecutionPathManager参照の取得
func get_execution_path_manager(args: Dictionary):
	"""ExecutionPathManagerの参照取得（デバッグ・ログ用）"""
	return args.get("execution_path_manager", null)

## 実行パスデバッグ出力
func debug_execution_path(args: Dictionary) -> void:
	"""実行パスのデバッグ出力"""
	var execution_path_manager = get_execution_path_manager(args)
	if execution_path_manager and execution_path_manager.has_method("debug_print_execution_stack"):
		execution_path_manager.debug_print_execution_stack()
	else:
		log_debug("ExecutionPathManager not available for path debugging")

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

## タグパターン自動生成（v1.2.0 拡張性対応）
func get_tag_patterns() -> Array[String]:
	"""このコマンドが使用するタグパターンを動的に生成"""
	var patterns: Array[String] = []
	
	if not is_also_tag or tag_name.is_empty():
		return patterns
	
	# 基本的なタグパターンを生成
	if has_end_tag:
		# 開始タグと終了タグのペア
		patterns.append("\\{%s=([^}]*)\\}" % tag_name)  # {tag=param}
		patterns.append("\\{/%s\\}" % tag_name)         # {/tag}
	else:
		# 単体タグ
		patterns.append("\\{%s(?:=([^}]*))?\\}" % tag_name)  # {tag} or {tag=param}
	
	return patterns

## タグ除去優先度を取得
func get_tag_removal_priority() -> int:
	"""タグ除去の優先度（数値が小さいほど先に処理）"""
	return tag_removal_priority

## カスタムタグパターンを取得
func get_custom_tag_patterns() -> Array[String]:
	"""カスタムタグパターンを取得"""
	return custom_tag_patterns

## v1.2.0: 開発者向け便利API
func set_tag_removal_priority(priority: int) -> void:
	"""タグ除去優先度を設定"""
	tag_removal_priority = priority

func add_custom_tag_pattern(pattern: String) -> void:
	"""カスタムタグパターンを追加"""
	if not custom_tag_patterns.has(pattern):
		custom_tag_patterns.append(pattern)

func clear_custom_tag_patterns() -> void:
	"""カスタムタグパターンをクリア"""
	custom_tag_patterns.clear()
