extends CharacterAnimationEffect
class_name ScaleEffect

## スケール効果
## 文字を小さい状態から通常サイズまで拡大して表示する

var start_scale: float = 0.8
var end_scale: float = 1.0

func _init(scale_duration: float = 0.25):
	duration = scale_duration
	_setup_effect_info()

func _setup_effect_info():
	effect_name = "scale"
	effect_description = "スケール効果 - 文字を小さい状態から通常サイズまで拡大して表示"

func calculate_effect(progress: float) -> Dictionary:
	var scale = lerp(start_scale, end_scale, progress)
	return {"scale": scale}

## カスタムパラメータ設定
func set_scale_range(start: float, end: float) -> ScaleEffect:
	start_scale = start
	end_scale = end
	return self

func set_start_scale(scale: float) -> ScaleEffect:
	start_scale = scale
	return self
