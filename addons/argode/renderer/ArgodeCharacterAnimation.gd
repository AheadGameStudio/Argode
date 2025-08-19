extends RefCounted
class_name ArgodeCharacterAnimation

# アニメーション効果の基底クラス
class CharacterAnimationEffect extends RefCounted:
	var duration: float = 0.5
	var delay: float = 0.0
	var is_completed: bool = false
	var start_time: float = 0.0
	
	# アニメーション効果を計算（0.0-1.0の進捗で効果値を返す）
	func calculate_effect(progress: float) -> Dictionary:
		return {}
	
	# アニメーション完了時の最終値を返す
	func get_final_values() -> Dictionary:
		return calculate_effect(1.0)

# フェードイン効果
class FadeInEffect extends CharacterAnimationEffect:
	var start_alpha: float = 0.0
	var end_alpha: float = 1.0
	
	func _init(fade_duration: float = 0.3):
		duration = fade_duration
	
	func calculate_effect(progress: float) -> Dictionary:
		var alpha = lerp(start_alpha, end_alpha, progress)
		return {"alpha": alpha}

# Y座標移動効果（上から下へフェードイン）
class SlideDownEffect extends CharacterAnimationEffect:
	var start_offset: float = -10.0
	var end_offset: float = 0.0
	
	func _init(slide_duration: float = 0.4, y_offset: float = -10.0):
		duration = slide_duration
		start_offset = y_offset
	
	func calculate_effect(progress: float) -> Dictionary:
		var y_offset = lerp(start_offset, end_offset, progress)
		return {"y_offset": y_offset}

# スケール効果
class ScaleEffect extends CharacterAnimationEffect:
	var start_scale: float = 0.8
	var end_scale: float = 1.0
	
	func _init(scale_duration: float = 0.25):
		duration = scale_duration
	
	func calculate_effect(progress: float) -> Dictionary:
		var scale = lerp(start_scale, end_scale, progress)
		return {"scale": scale}

# 文字アニメーション状態管理
var character_animations: Array[Dictionary] = []  # 各文字のアニメーション状態
var animation_effects: Array[CharacterAnimationEffect] = []  # 適用する効果のリスト
var current_time: float = 0.0
var is_skip_requested: bool = false

func _init():
	# デフォルト効果を設定
	add_effect(FadeInEffect.new(0.3))
	add_effect(SlideDownEffect.new(0.4, -8.0))

## アニメーション効果を追加
func add_effect(effect: CharacterAnimationEffect):
	animation_effects.append(effect)

## 文字数に応じてアニメーション配列を初期化
func initialize_for_text(text_length: int):
	character_animations.clear()
	current_time = 0.0
	is_skip_requested = false
	
	for i in range(text_length):
		var char_anim = {
			"char_index": i,
			"is_triggered": false,  # タイプライターによってトリガーされたかどうか
			"trigger_time": 0.0,    # トリガーされた時刻
			"effects": [],
			"is_completed": false,
			"current_values": {}
		}
		
		# 各効果の個別状態を初期化
		for effect in animation_effects:
			var effect_state = {
				"effect": effect,
				"local_start_time": 0.0,  # トリガー後の相対時間で計算
				"progress": 0.0,
				"is_active": false,
				"is_completed": false
			}
			char_anim.effects.append(effect_state)
		
		character_animations.append(char_anim)

## 文字がタイプライターで表示された時にアニメーションをトリガー
func trigger_character_animation(char_index: int):
	if char_index >= 0 and char_index < character_animations.size():
		var char_anim = character_animations[char_index]
		if not char_anim.is_triggered:
			char_anim.is_triggered = true
			char_anim.trigger_time = current_time
			ArgodeSystem.log("🎭 Character animation triggered for char %d at time %.2f" % [char_index, current_time])

## アニメーション更新（毎フレーム呼び出し）
func update_animations(delta_time: float):
	current_time += delta_time
	
	for char_anim in character_animations:
		if char_anim.is_completed or not char_anim.is_triggered:
			continue
		
		var all_effects_completed = true
		char_anim.current_values.clear()
		
		# トリガーからの経過時間を計算
		var elapsed_time = current_time - char_anim.trigger_time
		
		# 各効果を更新
		for effect_state in char_anim.effects:
			_update_effect_state_with_elapsed_time(effect_state, char_anim, elapsed_time)
			
			if not effect_state.is_completed:
				all_effects_completed = false
			
			# 効果値をマージ
			var effect_values = effect_state.effect.calculate_effect(effect_state.progress)
			for key in effect_values:
				char_anim.current_values[key] = effect_values[key]
		
		char_anim.is_completed = all_effects_completed

## 個別効果状態の更新（経過時間ベース）
func _update_effect_state_with_elapsed_time(effect_state: Dictionary, char_anim: Dictionary, elapsed_time: float):
	if effect_state.is_completed:
		return
	
	# 効果の開始遅延をチェック
	if elapsed_time < effect_state.effect.delay:
		effect_state.is_active = false
		effect_state.progress = 0.0
		return
	
	effect_state.is_active = true
	
	# スキップ要求があれば即座に完了
	if is_skip_requested:
		effect_state.progress = 1.0
		effect_state.is_completed = true
		return
	
	# 進捗計算（遅延を考慮）
	var effect_elapsed = elapsed_time - effect_state.effect.delay
	effect_state.progress = min(effect_elapsed / effect_state.effect.duration, 1.0)
	
	if effect_state.progress >= 1.0:
		effect_state.is_completed = true
	
	# 効果値をマージ
	var effect_values = effect_state.effect.calculate_effect(effect_state.progress)
	for key in effect_values:
		char_anim.current_values[key] = effect_values[key]

## 個別効果状態の更新（旧版・互換性のため残す）
func _update_effect_state(effect_state: Dictionary, char_anim: Dictionary):
	if effect_state.is_completed:
		return
	
	# 開始時間チェック
	if current_time < effect_state.local_start_time:
		effect_state.is_active = false
		effect_state.progress = 0.0
		return
	
	effect_state.is_active = true
	
	# スキップ要求があれば即座に完了
	if is_skip_requested:
		effect_state.progress = 1.0
		effect_state.is_completed = true
		return
	
	# 進捗計算
	var elapsed = current_time - effect_state.local_start_time
	effect_state.progress = min(elapsed / effect_state.effect.duration, 1.0)
	
	if effect_state.progress >= 1.0:
		effect_state.is_completed = true

## 指定文字のアニメーション値を取得
func get_character_animation_values(char_index: int) -> Dictionary:
	if char_index >= character_animations.size():
		return {}
	
	var char_anim = character_animations[char_index]
	
	# スキップ時は最終値を返す
	if is_skip_requested:
		var final_values = {}
		for effect_state in char_anim.effects:
			var effect_final = effect_state.effect.get_final_values()
			for key in effect_final:
				final_values[key] = effect_final[key]
		return final_values
	
	return char_anim.current_values

## 全アニメーションをスキップ
func skip_all_animations():
	is_skip_requested = true
	
	# 全文字を即座に完了状態にする
	for char_anim in character_animations:
		char_anim.is_completed = true
		char_anim.current_values.clear()
		
		for effect_state in char_anim.effects:
			effect_state.progress = 1.0
			effect_state.is_completed = true
			effect_state.is_active = true
			
			# 最終値を設定
			var final_values = effect_state.effect.get_final_values()
			for key in final_values:
				char_anim.current_values[key] = final_values[key]

## 全アニメーションが完了したかチェック
func are_all_animations_completed() -> bool:
	if is_skip_requested:
		return true
	
	for char_anim in character_animations:
		if not char_anim.is_completed:
			return false
	return true

## 指定文字がトリガーされているかチェック
func is_character_ready_to_show(char_index: int) -> bool:
	if char_index >= character_animations.size():
		return false
	
	var char_anim = character_animations[char_index]
	return char_anim.is_triggered
