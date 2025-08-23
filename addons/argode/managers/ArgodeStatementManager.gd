# ====================================================================================
# ArgodeStatementManager.gd
# 汎用ブロック実行インフラ v1.2.0
# ====================================================================================

class_name ArgodeStatementManager
extends RefCounted

# ====================================================================================
# サービス参照（インフラのみ）
# ====================================================================================
var execution_service: ArgodeExecutionService

# ファイルキャッシュは設計思想に反するため削除
# LabelRegistry + RGDParserの分離設計を尊重し、メモリ効率を重視

# ====================================================================================
# 基盤インフラ
# ====================================================================================

func _init() -> void:
	ArgodeSystem.log_workflow("🎬 StatementManager: 汎用ブロック実行インフラを初期化しました")

## 必要なサービスをすべて初期化
func initialize_services() -> void:
	execution_service = ArgodeExecutionService.new()
	
	# ExecutionServiceはcontextを必要としない単純な初期化
	execution_service.initialize(self, null)
	
	# Phase 1: UIControlServiceを手動登録（動的読み込み）
	var ui_control_service_script = load("res://addons/argode/services/ArgodeUIControlService.gd")
	if ui_control_service_script:
		var ui_control_service = ui_control_service_script.new()
		ArgodeSystem.register_service("UIControlService", ui_control_service)
		ArgodeSystem.log_workflow("🎬 [Phase 1] UIControlService registered")
	else:
		ArgodeSystem.log_critical("❌ Failed to load UIControlService")
	
	ArgodeSystem.log_workflow("🎬 StatementManager: 実行サービスが初期化されました")

# ====================================================================================
# 汎用ブロック実行API（公開インターフェース）
# ====================================================================================

## ステートメントブロックを実行（汎用エントリーポイント）
## すべての実行フローが使用する主要API
func execute_block(statements: Array, source_label: String = "") -> void:
	if not execution_service:
		ArgodeSystem.log_critical("🚨 StatementManager: ExecutionServiceが初期化されていません")
		return
	
	# ExecutionServiceに source_label を渡して連続ラベル実行を有効化
	execution_service.execute_block(statements, "main_execution", source_label)

## RGDコンテンツからラベルブロックを解析・抽出
## 指定されたラベルのステートメント配列を返す（非推奨：get_label_statementsを使用）
func parse_label_block(rgd_content: String, label_name: String) -> Array:
	var parser = ArgodeRGDParser.new()
	return parser.parse_label_block_from_text(rgd_content, label_name)

## 効率的なラベルステートメント取得（LabelRegistry + RGDParser分離設計）
## 設計思想: メモリ効率を重視し、必要時のみオンデマンドパース
func get_label_statements(label_name: String) -> Array:
	"""LabelRegistryとRGDParserの分離設計を活用した効率的なラベル取得"""
	
	# LabelRegistryからラベル情報を取得（軽量な位置情報のみ）
	var label_info = ArgodeSystem.LabelRegistry.get_label(label_name)
	if label_info.is_empty():
		ArgodeSystem.log_critical("Label '%s' not found in registry" % label_name)
		return []
	
	var file_path = label_info.get("path", "")
	if file_path.is_empty():
		ArgodeSystem.log_critical("Invalid file path for label '%s'" % label_name)
		return []
	
	# RGDParserに完全委譲（オンデマンド・パース）
	# メモリ効率を重視し、ファイルキャッシュは行わない
	var parser = ArgodeRGDParser.new()
	return parser.parse_label_block(file_path, label_name)

# ファイルキャッシュ機能は削除
# 設計思想: LabelRegistry（軽量キャッシュ）+ RGDParser（オンデマンド）の分離を維持

# ====================================================================================
# 実行状態管理
# ====================================================================================

## 現在の実行位置を取得
func get_current_position() -> Dictionary:
	if execution_service:
		return execution_service.get_execution_state()
	return {"label": "", "line": 0}

## 実行位置を設定
func set_current_position(label: String, line: int = 0) -> void:
	if execution_service:
		execution_service.set_execution_position(label, line)
	else:
		ArgodeSystem.log_critical("🚨 StatementManager: ExecutionServiceが利用できません")

## 実行が現在一時停止/待機中かチェック
func is_execution_paused() -> bool:
	if execution_service:
		return execution_service.is_paused()
	return false

## 一時停止された実行を再開
func resume_execution() -> void:
	if execution_service:
		execution_service.resume()
	else:
		ArgodeSystem.log_critical("🚨 StatementManager: ExecutionServiceが利用できません")

# ====================================================================================
# エラーハンドリングと診断
# ====================================================================================

## 実行中に発生した最新のエラーを取得
func get_last_error() -> String:
	if execution_service:
		return execution_service.get_last_error()
	return "エラー情報が利用できません"

## エラー状態をクリア
func clear_error_state() -> void:
	if execution_service:
		execution_service.clear_error()

## すべてのサービスが適切に初期化されているか検証
func validate_services() -> bool:
	if not execution_service:
		ArgodeSystem.log_critical("🚨 StatementManager: ExecutionServiceが初期化されていません")
		return false
	
	return true

# ====================================================================================
# ユーティリティ関数
# ====================================================================================

## デバッグ用のサービス統計を取得
func get_service_stats() -> Dictionary:
	return {
		"execution_service_available": execution_service != null,
		"is_execution_paused": is_execution_paused(),
		"current_position": get_current_position()
	}

## 簡易診断チェック
func health_check() -> void:
	ArgodeSystem.log_workflow("🔧 StatementManager ヘルスチェック:")
	var stats = get_service_stats()
	for key in stats.keys():
		ArgodeSystem.log_debug("  %s: %s" % [key, str(stats[key])])
