extends ArgodeTextEffect
class_name ArgodeMoveEffect

## 移動エフェクト - 指定相対座標に指定時間で移動

var target_offset: Vector2 = Vector2.ZERO
var easing_type: String = "ease_out"

func _init(offset: Vector2 = Vector2.ZERO, duration_sec: float = 0.5, easing: String = "ease_out"):
	super("MoveEffect")
	target_offset = offset
	duration = duration_sec
	easing_type = easing

## エフェクト更新処理
func update(glyph, elapsed: float) -> void:
	var progress = get_progress(elapsed)
	if progress <= 0.0:
		return  # まだ開始前
	
	# イージング適用
	var eased_progress = apply_easing(progress)
	
	# 位置補間
	glyph.offset_position = Vector2.ZERO.lerp(target_offset, eased_progress)
	glyph.current_position = glyph.base_position + glyph.offset_position
	
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
