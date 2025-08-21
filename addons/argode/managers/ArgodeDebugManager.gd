# Argode Debug Manager
extends RefCounted
class_name ArgodeDebugManager


## 従来のログレベルを定義する（後方互換性）
enum LogLevel {
    DEBUG,      # 最も詳細なログ
    INFO,       # 情報ログ
    WARN,       # 警告
    ERROR       # エラーログ
}

## GitHub Copilot効率化のためのログレベル
enum CopilotLogLevel {
    SILENT = 0,      # ログ出力なし
    CRITICAL = 1,    # エラー・重大問題のみ（GitHub Copilot最重要）
    WORKFLOW = 2,    # ワークフロー重要ポイント（実行フロー把握用）
    DEBUG = 3        # 詳細情報（開発時のみ、通常は非表示）
}

## 現在のログレベルを設定する（従来互換性）
var current_log_level:int

## GitHub Copilot用ログレベル
var copilot_log_level: int = CopilotLogLevel.WORKFLOW  # デフォルト：重要情報のみ

## ログの履歴を記録する辞書
## { "message": { "count": int, "last_logged_time": float } }
var log_history: Dictionary = {}

## レートリミットの設定 (秒)
const LOG_RATE_LIMIT:float = 0.5

func _ready():
    if ArgodeSystem and OS.is_debug_build():
        current_log_level = LogLevel.INFO
        copilot_log_level = CopilotLogLevel.WORKFLOW  # GitHub Copilot効率化：重要情報のみ
        ArgodeSystem.get_tree().root.add_child(DebugDraw.new())

## デバッグモードかどうかを判定
func is_debug_mode() -> bool:
    return OS.is_debug_build() and current_log_level <= LogLevel.DEBUG

## GitHub Copilot効率化ログレベルを設定
func set_copilot_log_level(level: int) -> void:
    copilot_log_level = level
    var level_name = ""
    match level:
        CopilotLogLevel.SILENT: level_name = "SILENT"
        CopilotLogLevel.CRITICAL: level_name = "CRITICAL" 
        CopilotLogLevel.WORKFLOW: level_name = "WORKFLOW"
        CopilotLogLevel.DEBUG: level_name = "DEBUG"
    print("🎯 Copilot log level set to: %s" % level_name)

# =============================================================================
# GitHub Copilot効率化ログメソッド
# =============================================================================

## 🚨 CRITICAL: エラー・重大問題（GitHub Copilot最重要）
func log_critical(message: String) -> void:
    if copilot_log_level >= CopilotLogLevel.CRITICAL:
        _output_copilot_log("🚨", message, "CRITICAL")

## 🎬 WORKFLOW: ワークフロー重要ポイント（実行フロー把握用）
func log_workflow(message: String) -> void:
    if copilot_log_level >= CopilotLogLevel.WORKFLOW:
        _output_copilot_log("🎬", message, "WORKFLOW")

## 🔍 DEBUG: 詳細情報（開発時のみ）
func log_debug_detail(message: String) -> void:
    if copilot_log_level >= CopilotLogLevel.DEBUG:
        _output_copilot_log("🔍", message, "DEBUG")

## GitHub Copilot用ログ出力の内部実装
func _output_copilot_log(icon: String, message: String, level_name: String) -> void:
    # レートリミット適用でノイズ削減
    if log_history.has(message):
        var log_data = log_history[message]
        if Time.get_ticks_msec() / 1000.0 - log_data.last_logged_time < LOG_RATE_LIMIT:
            log_data.count += 1
            return
        else:
            _flush_log(message, log_data)
            log_history.erase(message)
    
    log_history[message] = { "count": 1, "last_logged_time": Time.get_ticks_msec() / 1000.0 }
    print("%s %s" % [icon, message])

# =============================================================================
# 従来のログメソッド（後方互換性維持）
# =============================================================================

func log(message: String, level: int = LogLevel.INFO):
    if level >= current_log_level:
        if log_history.has(message):
            # 履歴が存在する場合、レートリミットをチェックする
            var log_data = log_history[message]
            if Time.get_ticks_msec() / 1000.0 - log_data.last_logged_time < LOG_RATE_LIMIT:
                # レートリミット時間内の場合は、カウントを増やすだけで終了
                log_data.count += 1
                return
            else:
                # レートリミット時間外の場合は、まとめてログを出力
                _flush_log(message, log_data)
                log_history.erase(message)
        
        # 新しいログとして記録する
        log_history[message] = { "count": 1, "last_logged_time": Time.get_ticks_msec() / 1000.0 }
        
        var level_str = ""
        match level:
            LogLevel.DEBUG: level_str = "🙂DEBUG : "
            LogLevel.INFO: level_str =  "💬 INFO : "
            LogLevel.WARN: level_str =  "⚠️ WARN : "
            LogLevel.ERROR: level_str = "❌ERROR : "
        print(level_str + message)

## ログをまとめて出力するプライベート関数
func _flush_log(message: String, log_data: Dictionary):
    if log_data.count > 1:
        print("[INFO] " + message + " (x" + str(log_data.count) + ")")



class DebugDraw extends CanvasLayer:

    func _init():
        layer = 100
    