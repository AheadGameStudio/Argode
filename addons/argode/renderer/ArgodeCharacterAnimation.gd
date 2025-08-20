extends RefCounted
class_name ArgodeCharacterAnimation

# シグナル定義
signal all_animations_completed()
signal character_animation_completed(char_index: int)

# 文字アニメーション状態管理
var character_animations: Array[Dictionary] = []  # 各文字のアニメーション状態
var animation_effects: Array = []  # 適用する効果のリスト（CharacterAnimationEffectベースクラス）
var current_time: float = 0.0
var is_skip_requested: bool = false
var all_completion_notified: bool = false  # 全完了通知フラグ

func _init():
	# デフォルト効果を設定
	# add_effect(FadeInEffect.new(0.3))
	# add_effect(SlideDownEffect.new(0.2, -4.0))
	pass

## アニメーション効果を追加
func add_effect(effect):
	animation_effects.append(effect)

## カスタムアニメーション設定を適用
func setup_custom_animation(config: Dictionary):
	"""
	カスタムアニメーション設定を適用
	config例:
	{
		"fade_in": {"duration": 0.5, "enabled": true},
		"slide_down": {"duration": 0.3, "offset": -15.0, "enabled": true},
		"scale": {"duration": 0.2, "enabled": false}
	}
	"""
	animation_effects.clear()
	
	# フェードイン設定
	if config.get("fade_in", {}).get("enabled", true):
		var fade_duration = config.get("fade_in", {}).get("duration", 0.3)
		var fade_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("fade")
		if fade_effect:
			fade_effect.set_duration(fade_duration)
			add_effect(fade_effect)
	
	# スライドダウン設定（slideエフェクトのY軸オフセット版）
	if config.get("slide_down", {}).get("enabled", true):
		var slide_duration = config.get("slide_down", {}).get("duration", 0.4)
		var slide_offset = config.get("slide_down", {}).get("offset", -8.0)
		var slide_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("slide")
		if slide_effect:
			slide_effect.set_duration(slide_duration)
			if slide_effect.has_method("set_offset"):
				slide_effect.set_offset(0.0, slide_offset)
			add_effect(slide_effect)
	
	# スケール設定
	if config.get("scale", {}).get("enabled", false):
		var scale_duration = config.get("scale", {}).get("duration", 0.25)
		var scale_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("scale")
		if scale_effect:
			scale_effect.set_duration(scale_duration)
			add_effect(scale_effect)
	
	ArgodeSystem.log("🎨 Custom animation configuration applied: %s" % str(config))

## 文字数に応じてアニメーション配列を初期化
func initialize_for_text(text_length: int):
	character_animations.clear()
	current_time = 0.0
	is_skip_requested = false
	all_completion_notified = false  # 通知フラグをリセット
	
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
			
			# 即座にアニメーションの開始値を設定（1フレーム目の描画漏れを防ぐ）
			char_anim.current_values.clear()
			for effect_state in char_anim.effects:
				effect_state.is_active = true
				effect_state.progress = 0.0
				
				# 開始値（進捗0.0）を取得して即座に適用
				var start_values = effect_state.effect.calculate_effect(0.0)
				for key in start_values:
					char_anim.current_values[key] = start_values[key]
			
			ArgodeSystem.log("🎭 Character animation triggered for char %d at time %.2f with initial values: %s" % [char_index, current_time, str(char_anim.current_values)])

## カスタム設定で文字アニメーションをトリガー
func trigger_character_animation_with_config(char_index: int, animation_config: Dictionary):
	"""カスタムアニメーション設定で文字のアニメーションをトリガー"""
	if char_index >= 0 and char_index < character_animations.size():
		var char_anim = character_animations[char_index]
		if not char_anim.is_triggered:
			# 一時的に効果を置き換える
			var original_effects = char_anim.effects.duplicate()
			char_anim.effects.clear()
			
			# カスタム設定に基づいて効果を生成
			_setup_custom_effects_for_character(char_anim, animation_config)
			
			# 通常のトリガー処理
			char_anim.is_triggered = true
			char_anim.trigger_time = current_time
			
			# 即座にアニメーションの開始値を設定
			char_anim.current_values.clear()
			for effect_state in char_anim.effects:
				effect_state.is_active = true
				effect_state.progress = 0.0
				
				# 開始値（進捗0.0）を取得して即座に適用
				var start_values = effect_state.effect.calculate_effect(0.0)
				for key in start_values:
					char_anim.current_values[key] = start_values[key]
			
			ArgodeSystem.log("🎭 Character %d custom animation triggered with config: %s" % [char_index, str(animation_config)])

## 文字用のカスタム効果を設定
func _setup_custom_effects_for_character(char_anim: Dictionary, animation_config: Dictionary):
	"""指定された文字にカスタムアニメーション効果を設定"""
	# フェードイン設定
	if animation_config.get("fade_in", {}).get("enabled", true):
		var fade_duration = animation_config.get("fade_in", {}).get("duration", 0.3)
		var fade_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("fade")
		if fade_effect:
			fade_effect.set_duration(fade_duration)
			var effect_state = {
				"effect": fade_effect,
				"is_active": false,
				"progress": 0.0,
				"is_completed": false
			}
			char_anim.effects.append(effect_state)
	
	# スライドダウン設定
	if animation_config.get("slide_down", {}).get("enabled", true):
		var slide_duration = animation_config.get("slide_down", {}).get("duration", 0.4)
		var slide_offset = animation_config.get("slide_down", {}).get("offset", -8.0)
		var slide_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("slide")
		if slide_effect:
			slide_effect.set_duration(slide_duration)
			if slide_effect.has_method("set_offset"):
				slide_effect.set_offset(0.0, slide_offset)  # Y軸オフセット
			var effect_state = {
				"effect": slide_effect,
				"is_active": false,
				"progress": 0.0,
				"is_completed": false
			}
			char_anim.effects.append(effect_state)
	
	# スケール設定
	if animation_config.get("scale", {}).get("enabled", false):
		var scale_duration = animation_config.get("scale", {}).get("duration", 0.2)
		var scale_from = animation_config.get("scale", {}).get("from", 0.8)
		var scale_to = animation_config.get("scale", {}).get("to", 1.0)
		var scale_effect = ArgodeSystem.MessageAnimationRegistry.create_effect("scale")
		if scale_effect:
			scale_effect.set_duration(scale_duration)
			if scale_effect.has_method("set_scale_range"):
				scale_effect.set_scale_range(scale_from, scale_to)
			var effect_state = {
				"effect": scale_effect,
				"is_active": false,
				"progress": 0.0,
				"is_completed": false
			}
			char_anim.effects.append(effect_state)

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
		
		# 文字アニメーション完了時にシグナル発行
		if all_effects_completed and not char_anim.get("completion_notified", false):
			char_anim["completion_notified"] = true
			character_animation_completed.emit(char_anim.char_index)

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
	
	# まだトリガーされていない文字は完全に透明にする
	if not char_anim.is_triggered:
		return {"alpha": 0.0}
	
	# スキップ時は最終値を返す
	if is_skip_requested:
		var final_values = {}
		for effect_state in char_anim.effects:
			var effect_final = effect_state.effect.get_final_values()
			for key in effect_final:
				final_values[key] = effect_final[key]
		ArgodeSystem.log("⏭️ Returning final values for char %d during skip: %s" % [char_index, str(final_values)])
		return final_values
	
	# トリガーされたばかりでアニメーション値がまだ計算されていない場合は開始値を返す
	if char_anim.current_values.is_empty():
		var start_values = {}
		for effect_state in char_anim.effects:
			var effect_start = effect_state.effect.calculate_effect(0.0)
			for key in effect_start:
				start_values[key] = effect_start[key]
		ArgodeSystem.log("🎬 Returning start values for char %d (just triggered): %s" % [char_index, str(start_values)])
		return start_values
	
	# デバッグ: アニメーション値をログ出力
	if char_anim.current_values.has("alpha") and char_anim.current_values.alpha < 0.1:
		ArgodeSystem.log("🔍 Char %d animation values: %s (triggered: %s, completed: %s)" % [char_index, str(char_anim.current_values), char_anim.is_triggered, char_anim.is_completed])
	
	return char_anim.current_values

## 全アニメーションをスキップ
func skip_all_animations():
	is_skip_requested = true
	ArgodeSystem.log("⏭️ Skipping all character animations")
	
	# 全文字を即座に完了状態にする
	for char_anim in character_animations:
		# 文字をトリガー状態にする（まだトリガーされていない場合）
		if not char_anim.is_triggered:
			char_anim.is_triggered = true
			char_anim.trigger_time = current_time
		
		char_anim.is_completed = true
		char_anim.current_values.clear()
		
		# 各効果を完了状態にして最終値を統合
		for effect_state in char_anim.effects:
			effect_state.progress = 1.0
			effect_state.is_completed = true
			effect_state.is_active = true
			
			# 最終値を設定（すべての効果の最終値を統合）
			var final_values = effect_state.effect.get_final_values()
			for key in final_values:
				char_anim.current_values[key] = final_values[key]
		
		# 完了通知フラグも設定
		char_anim["completion_notified"] = true
	
	ArgodeSystem.log("✅ All character animations set to final state")
	
	# スキップ完了シグナルを発行
	if not all_completion_notified:
		all_completion_notified = true
		all_animations_completed.emit()
		ArgodeSystem.log("📢 All animations completed signal emitted")

## 全アニメーションが完了したかチェック
func are_all_animations_completed() -> bool:
	if is_skip_requested:
		return true
	
	for char_anim in character_animations:
		if not char_anim.is_completed:
			return false
	
	# 全て完了していて、まだ通知していない場合はシグナル発行
	if not all_completion_notified:
		all_completion_notified = true
		all_animations_completed.emit()
	
	return true

## 指定文字がトリガーされているかチェック
func is_character_ready_to_show(char_index: int) -> bool:
	if char_index >= character_animations.size():
		return false
	
	var char_anim = character_animations[char_index]
	return char_anim.is_triggered
