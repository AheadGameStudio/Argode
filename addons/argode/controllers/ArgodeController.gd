# ArgodeController.gd
extends Node

class_name ArgodeController

## フレームワーク全体のプレイヤー入力を一元管理する
## このクラスは、Godotのプロジェクト設定で定義された入力アクションを使い、
## 入力イベントを他のマネージャーやサービスに伝達する。

# 入力が現在許可されているかどうか
var _is_input_enabled: bool = true

# 入力アクションが押されたときに送信されるシグナル
signal input_action_pressed(action_name)
# 入力アクションが離されたときに送信されるシグナル
signal input_action_released(action_name)

# フレームが処理されるたびに入力をチェックする
func _process(delta):
    if not _is_input_enabled:
        return

    # 全ての入力アクションをチェック
    for action in InputMap.get_actions():
        if Input.is_action_just_pressed(action):
            _on_action_just_pressed(action)
        if Input.is_action_just_released(action):
            _on_action_just_released(action)

func _on_action_just_pressed(action_name: String):
    # 特定のアクションが押されたときの処理
    # 例: "ui_accept"アクションが押された場合、対話マネージャーに通知
    # ArgodeSystem.get_manager("DialogueManager").process_input("accept")
    
    # input_action_pressedシグナルを送信
    emit_signal("input_action_pressed", action_name)

func _on_action_just_released(action_name: String):
    # 特定のアクションが離されたときの処理
    
    # input_action_releasedシグナルを送信
    emit_signal("input_action_released", action_name)

## 入力を有効にする
func enable_input():
    _is_input_enabled = true

## 入力を無効にする
func disable_input():
    _is_input_enabled = false
