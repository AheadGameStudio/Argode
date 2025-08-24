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

# メッセージ状態管理（タイプライター効果用）
var current_message_length: int = 0

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
# Phase 4: GlyphSystemメッセージ表示統合
# ====================================================================================

## Phase 4: GlyphSystemを使用してメッセージを表示（UIControlService経由）
func show_message_via_glyph_system(text: String, character_name: String = "") -> void:
	"""Phase 4: GlyphSystemを使用したメッセージ表示（高度版）"""
	ArgodeSystem.log_workflow("🎨 [Phase 4] StatementManager: GlyphSystem message display requested")
	
	# メッセージ長を保存（タイプライター効果のオートプレイ時間計算用）
	current_message_length = text.length()
	ArgodeSystem.log_debug_detail("📏 Current message length stored: %d" % current_message_length)
	
	var ui_control_service = _get_ui_control_service()
	if not ui_control_service:
		ArgodeSystem.log_critical("🚨 [Phase 4] UIControlService not available for GlyphSystem")
		return
	
	if ui_control_service.has_method("render_message_with_glyph_system"):
		ui_control_service.render_message_with_glyph_system(character_name, text)
		ArgodeSystem.log_workflow("✅ [Phase 4] GlyphSystem message rendering initiated")
		
		# タイプライターエフェクト開始の短い待機
		await Engine.get_main_loop().process_frame
		ArgodeSystem.log_debug_detail("🎬 [Phase 4] GlyphSystem rendering frame processed")
	else:
		ArgodeSystem.log_critical("❌ [Phase 4] UIControlService missing GlyphSystem method")

## UIControlServiceを取得（UIManagerから）
func _get_ui_control_service():
	"""UIManagerからUIControlServiceを取得"""
	var ui_manager = ArgodeSystem.UIManager
	if not ui_manager:
		return null
	
	if ui_manager.has_method("get_ui_control_service"):
		return ui_manager.get_ui_control_service()
	
	return null

## Phase 4: GlyphSystemが動作中かチェック
func is_glyph_system_active() -> bool:
	"""GlyphSystemによるメッセージレンダリングが動作中かチェック"""
	var ui_control_service = _get_ui_control_service()
	if ui_control_service and ui_control_service.has_method("is_glyph_system_active"):
		return ui_control_service.is_glyph_system_active()
	return false

# ====================================================================================
# ユーティリティ関数
# ====================================================================================

## 現在のメッセージ長を取得（タイプライター効果のオートプレイ時間計算用）
func get_current_message_length() -> int:
	"""現在表示中のメッセージの文字数を返す"""
	return current_message_length

## デバッグ用のサービス統計を取得
func get_service_stats() -> Dictionary:
	return {
		"execution_service_available": execution_service != null,
		"is_execution_paused": is_execution_paused(),
		"current_position": get_current_position(),
		"current_message_length": current_message_length
	}

## 簡易診断チェック
func health_check() -> void:
	ArgodeSystem.log_workflow("🔧 StatementManager ヘルスチェック:")
	var stats = get_service_stats()
	for key in stats.keys():
		ArgodeSystem.log_debug_detail("  %s: %s" % [key, str(stats[key])])
