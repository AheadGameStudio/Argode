# Argode Debug Manager
extends RefCounted
class_name ArgodeDebugManager


## ログレベルを定義する
enum LogLevel {
    DEBUG,      # 最も詳細なログ
    INFO,       # 情報ログ
    WARN,       # 警告
    ERROR       # エラーログ
}

## 現在のログレベルを設定する
var current_log_level:int

## ログの履歴を記録する辞書
## { "message": { "count": int, "last_logged_time": float } }
var log_history: Dictionary = {}

## レートリミットの設定 (秒)
const LOG_RATE_LIMIT:float = 0.5

func _ready():
    if ArgodeSystem and OS.is_debug_build():
        current_log_level = LogLevel.INFO
        ArgodeSystem.get_tree().root.add_child(DebugDraw.new())

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
    