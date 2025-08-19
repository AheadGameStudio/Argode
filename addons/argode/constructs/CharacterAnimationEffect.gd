extends RefCounted
class_name CharacterAnimationEffect

## 文字アニメーション効果の基底クラス
## カスタムアニメーション効果はこのクラスを継承して作成

# アニメーション効果の基本プロパティ
var duration: float = 0.5
var delay: float = 0.0
var is_completed: bool = false
var start_time: float = 0.0

# アニメーション効果の名前（レジストリで使用）
var effect_name: String = ""
var effect_description: String = ""

func _init():
	# サブクラスで効果名と説明を設定
	_setup_effect_info()

## サブクラスで実装：効果の基本情報を設定
func _setup_effect_info():
	effect_name = "base_effect"
	effect_description = "Base animation effect"

## アニメーション効果を計算（0.0-1.0の進捗で効果値を返す）
## サブクラスで必ず実装
func calculate_effect(progress: float) -> Dictionary:
	return {}

## アニメーション完了時の最終値を返す
func get_final_values() -> Dictionary:
	return calculate_effect(1.0)

## 効果の開始値を返す（即座に適用される値）
func get_start_values() -> Dictionary:
	return calculate_effect(0.0)

## 効果が有効かどうかを判定
func is_effect_active() -> bool:
	return not is_completed

## パラメータ設定用のヘルパーメソッド
func set_duration(new_duration: float) -> CharacterAnimationEffect:
	duration = new_duration
	return self

func set_delay(new_delay: float) -> CharacterAnimationEffect:
	delay = new_delay
	return self

## 効果の説明テキストを取得
func get_help_text() -> String:
	return "%s: %s (Duration: %.2fs)" % [effect_name, effect_description, duration]
