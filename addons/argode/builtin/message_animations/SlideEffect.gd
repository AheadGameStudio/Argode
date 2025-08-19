extends CharacterAnimationEffect
class_name SlideEffect

## スライド効果
## 指定した方向から文字をスライドさせて表示する

var start_offset_x: float = 0.0
var end_offset_x: float = 0.0
var start_offset_y: float = 0.0
var end_offset_y: float = 0.0

func _init(slide_duration: float = 0.4, x_offset: float = 0.0, y_offset: float = 0.0):
	duration = slide_duration
	start_offset_x = x_offset
	start_offset_y = y_offset
	_setup_effect_info()

func _setup_effect_info():
	effect_name = "slide"
	effect_description = "スライド効果 - 指定した方向から文字をスライドさせて表示"

func calculate_effect(progress: float) -> Dictionary:
	var result = {}
	if start_offset_x != 0.0:
		result["x_offset"] = lerp(start_offset_x, end_offset_x, progress)
	if start_offset_y != 0.0:
		result["y_offset"] = lerp(start_offset_y, end_offset_y, progress)
	return result

## カスタムパラメータ設定
func set_offset(x: float, y: float) -> SlideEffect:
	start_offset_x = x
	start_offset_y = y
	return self

func set_x_offset(x: float) -> SlideEffect:
	start_offset_x = x
	return self

func set_y_offset(y: float) -> SlideEffect:
	start_offset_y = y
	return self
