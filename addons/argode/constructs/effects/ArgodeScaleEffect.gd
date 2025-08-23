extends ArgodeTextEffect
class_name ArgodeScaleEffect

## スケールエフェクト - 指定スケールに指定時間で変化

var target_scale: float = 1.0
var easing_type: String = "ease_out"  # ease_in, ease_out, ease_in_out, linear

func _init(scale: float = 1.5, duration_sec: float = 0.3, easing: String = "ease_out"):
	super("ScaleEffect")
	target_scale = scale
	duration = duration_sec
	easing_type = easing

## エフェクト更新処理
func update(glyph, elapsed: float) -> void:
	var progress = get_progress(elapsed)
	if progress <= 0.0:
		return  # まだ開始前
	
	# イージング適用
	var eased_progress = apply_easing(progress)
	
	# スケール補間
	glyph.current_scale = lerp(glyph.base_scale, target_scale, eased_progress)
	
	# 完了チェック
	if progress >= 1.0:
		is_completed = true

## イージング関数
func apply_easing(t: float) -> float:
	match easing_type:
		"linear":
			return t
		"ease_in":
			return t * t
		"ease_out":
			return 1.0 - pow(1.0 - t, 2.0)
		"ease_in_out":
			if t < 0.5:
				return 2.0 * t * t
			else:
				return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
		_:
			return t  # フォールバック

## 最終状態に即座に設定（スキップ対応）
func set_to_final_state():
	"""エフェクトを最終状態（100%完了）に即座に設定"""
	is_completed = true
	is_active = true
	ArgodeSystem.log("⚡ ScaleEffect: Set to final state (scale: %.2f)" % target_scale)
