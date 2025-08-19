extends CharacterAnimationEffect
class_name FadeInEffect

## フェードイン効果
## 透明度を徐々に上げて文字を表示する

var start_alpha: float = 0.0
var end_alpha: float = 1.0

func _init(fade_duration: float = 0.3):
	duration = fade_duration
	_setup_effect_info()

func _setup_effect_info():
	effect_name = "fade"
	effect_description = "フェードイン効果 - 透明度を徐々に上げて文字を表示"

func calculate_effect(progress: float) -> Dictionary:
	var alpha = lerp(start_alpha, end_alpha, progress)
	return {"alpha": alpha}

## カスタムパラメータ設定
func set_alpha_range(start: float, end: float) -> FadeInEffect:
	start_alpha = start
	end_alpha = end
	return self
