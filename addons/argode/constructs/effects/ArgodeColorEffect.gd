extends ArgodeTextEffect
class_name ArgodeColorEffect

## 色エフェクト - 指定色に指定時間で変化（即座変更も可能）

var target_color: Color = Color.WHITE
var is_instant: bool = false

func _init(color: Color = Color.WHITE, duration_sec: float = 0.0):
	super("ColorEffect")
	target_color = color
	duration = duration_sec
	is_instant = (duration_sec <= 0.0)

## エフェクト更新処理
func update(glyph, elapsed: float) -> void:
	if is_instant:
		# 即座に色変更
		glyph.current_color = target_color
		is_completed = true
		return
	
	var progress = get_progress(elapsed)
	if progress <= 0.0:
		return  # まだ開始前
	
	# 色補間
	glyph.current_color = glyph.base_color.lerp(target_color, progress)
	
	# 完了チェック
	if progress >= 1.0:
		is_completed = true
