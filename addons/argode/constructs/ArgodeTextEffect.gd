extends RefCounted
class_name ArgodeTextEffect

## テキストエフェクトの基底クラス
## 1文字単位のリアルタイムエフェクト処理を管理

# エフェクトの基本情報
var effect_name: String = ""
var duration: float = 0.0  # 0.0 = 無限エフェクト（ループ系等）
var start_delay: float = 0.0  # エフェクト開始遅延

# エフェクト状態
var is_active: bool = false
var is_completed: bool = false

func _init(name: String = "BaseEffect"):
	effect_name = name

## エフェクトの更新処理（毎フレーム呼び出し）
## 継承先でオーバーライド必須
func update(glyph, elapsed: float) -> void:
	ArgodeSystem.log("⚠️ ArgodeTextEffect.update() called on base class - should be overridden", ArgodeSystem.LOG_LEVEL.CRITICAL)

## エフェクトの完了判定
func is_effect_completed() -> bool:
	if duration <= 0.0:
		return false  # 無限エフェクト
	return is_completed

## エフェクトの開始処理
func start_effect() -> void:
	is_active = true
	is_completed = false

## エフェクトの停止処理
func stop_effect() -> void:
	is_active = false
	is_completed = true

## エフェクト名を取得
func get_effect_name() -> String:
	return effect_name

## エフェクトの時間進行度を取得 (0.0 ~ 1.0)
func get_progress(elapsed: float) -> float:
	if duration <= 0.0:
		return 0.0  # 無限エフェクトは進行度なし
	
	var effective_elapsed = elapsed - start_delay
	if effective_elapsed <= 0.0:
		return 0.0  # まだ開始前
	
	return min(effective_elapsed / duration, 1.0)

## エフェクトの残り時間を取得
func get_remaining_time(elapsed: float) -> float:
	if duration <= 0.0:
		return -1.0  # 無限エフェクト
	
	var effective_elapsed = elapsed - start_delay
	return max(duration - effective_elapsed, 0.0)

## デバッグ情報を出力
func debug_print() -> void:
	ArgodeSystem.log("🎭 TextEffect Debug: %s" % effect_name)
	ArgodeSystem.log("  - Duration: %.2fs" % duration)
	ArgodeSystem.log("  - Start delay: %.2fs" % start_delay)
	ArgodeSystem.log("  - Active: %s" % str(is_active))
	ArgodeSystem.log("  - Completed: %s" % str(is_completed))
