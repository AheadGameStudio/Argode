extends RefCounted
class_name ArgodeAnimationCoordinator

## アニメーション統制を専門に扱うコーディネーター
## ArgodeMessageRendererからアニメーション管理機能を分離

# アニメーション管理
var character_animation = null  # ArgodeCharacterAnimationインスタンス
var is_animation_enabled: bool = true  # アニメーション有効フラグ
var message_canvas = null  # MessageCanvasの参照
var animation_timeout_timer: float = 0.0  # アニメーションタイムアウト用タイマー
var max_animation_wait_time: float = 3.0  # 最大3秒でアニメーションを強制完了

# 範囲別アニメーション設定
var range_animation_configs: Array[Dictionary] = []  # 範囲別アニメーション設定

# コールバック
var on_animation_completed: Callable  # アニメーション完了時のコールバック

func _init():
	pass

## 文字アニメーションシステムを初期化
func initialize_character_animation():
	"""文字アニメーションシステムを初期化"""
	# 動的にクラスを作成
	var CharacterAnimationClass = load("res://addons/argode/renderer/ArgodeCharacterAnimation.gd")
	character_animation = CharacterAnimationClass.new()
	
	# シグナル接続
	character_animation.all_animations_completed.connect(_on_all_animations_completed)
	
	ArgodeSystem.log("✅ AnimationCoordinator: Character animation system initialized")

## MessageCanvasの参照を設定
func set_message_canvas(canvas):
	"""MessageCanvasの参照を設定"""
	message_canvas = canvas

## テキスト長に応じてアニメーションを初期化
func initialize_for_text(text_length: int):
	"""テキスト長に応じてアニメーション配列を初期化"""
	# 前のアニメーション状態を完全クリア
	range_animation_configs.clear()
	
	if character_animation and is_animation_enabled:
		character_animation.initialize_for_text(text_length)
		ArgodeSystem.log("✨ Character animation initialized for text length: %d" % text_length)
		
		# MessageCanvasでアニメーション更新を開始
		if message_canvas:
			message_canvas.start_animation_updates(_update_character_animations)

## 範囲別アニメーション設定を登録
func set_range_animation_configs(decoration_renderer):
	"""DecorationRendererから範囲別アニメーション設定を取得"""
	range_animation_configs.clear()
	
	if not decoration_renderer:
		return
	
	# アニメーション装飾を探して登録
	for decoration in decoration_renderer.text_decorations:
		if decoration.type == "animation":
			var config_info = {
				"start_position": decoration.start_position,
				"end_position": decoration.end_position,
				"animation_config": decoration.args.get("animation_config", {})
			}
			range_animation_configs.append(config_info)
			ArgodeSystem.log("🎭 Range animation registered: pos %d-%d with config: %s" % [decoration.start_position, decoration.end_position, str(config_info.animation_config)])

## 指定位置の範囲別アニメーション設定を取得
func get_range_animation_config_for_position(position: int) -> Dictionary:
	"""指定位置に適用される範囲別アニメーション設定を取得"""
	for config in range_animation_configs:
		if config.start_position <= position and position < config.end_position:
			return config.animation_config
	
	return {}  # デフォルト設定を使用

## 文字アニメーションをトリガー
func trigger_character_animation(char_index: int):
	"""指定文字のアニメーションをトリガー（範囲別設定を考慮）"""
	if character_animation and is_animation_enabled:
		# 範囲別アニメーション設定を取得
		var range_config = get_range_animation_config_for_position(char_index)
		
		# 範囲別設定がある場合は適用
		if not range_config.is_empty():
			character_animation.trigger_character_animation_with_config(char_index, range_config)
			ArgodeSystem.log("🎭 Character %d animated with range config: %s" % [char_index, str(range_config)])
		else:
			# デフォルト設定でアニメーション
			character_animation.trigger_character_animation(char_index)

## アニメーション値を取得
func get_character_animation_values(char_index: int) -> Dictionary:
	"""指定文字のアニメーション値を取得"""
	if character_animation and is_animation_enabled:
		return character_animation.get_character_animation_values(char_index)
	return {}

## アニメーションをスキップ
func skip_all_animations():
	"""全アニメーションを強制完了"""
	if character_animation and is_animation_enabled:
		character_animation.skip_all_animations()
		ArgodeSystem.log("⏭️ All animations skipped by coordinator")

## アニメーション完了を待つ
func wait_for_animations_completion():
	"""アニメーション完了を待つ（シグナルベース＋タイムアウト）"""
	if character_animation and is_animation_enabled:
		ArgodeSystem.log("⏳ Waiting for animations completion via signal...")
		animation_timeout_timer = 0.0  # タイマーリセット
		# 完了時に_on_all_animations_completed()が自動的に呼ばれる
	else:
		# アニメーションが無効な場合は即座に完了通知
		_notify_animation_completion()

## 全アニメーション完了シグナル受信
func _on_all_animations_completed():
	"""全アニメーション完了シグナルを受信"""
	ArgodeSystem.log("✅ All character animations completed via signal")
	animation_timeout_timer = -1.0  # タイマー無効化
	_notify_animation_completion()

## アニメーション完了を通知
func _notify_animation_completion():
	"""アニメーション完了をコールバックに通知"""
	# アニメーション更新を停止
	if message_canvas:
		message_canvas.stop_animation_updates()
	
	# 完了コールバックを呼び出し
	if on_animation_completed.is_valid():
		ArgodeSystem.log("📢 Notifying animation completion")
		on_animation_completed.call()
	else:
		ArgodeSystem.log("⚠️ Animation completion callback not set")

## アニメーション更新処理（MessageCanvasから呼ばれる）
func _update_character_animations(delta: float):
	"""アニメーション更新処理"""
	if character_animation and is_animation_enabled:
		character_animation.update_animations(delta)
		
		# タイムアウトチェック（アニメーション待機中の場合）
		if animation_timeout_timer >= 0.0:
			animation_timeout_timer += delta
			if animation_timeout_timer >= max_animation_wait_time:
				ArgodeSystem.log("⏰ Animation timeout reached (%.1fs) - forcing completion" % max_animation_wait_time)
				animation_timeout_timer = -1.0  # タイマー無効化
				character_animation.skip_all_animations()
				_notify_animation_completion()

## アニメーション完了コールバックを設定
func set_animation_completion_callback(callback: Callable):
	"""アニメーション完了時のコールバックを設定"""
	on_animation_completed = callback

## アニメーション有効/無効の切り替え
func set_animation_enabled(enabled: bool):
	"""アニメーションの有効/無効を切り替え"""
	is_animation_enabled = enabled
	if not enabled and character_animation:
		# 無効にする場合は即座に完了状態にする
		character_animation.skip_all_animations()

## 現在の状態を取得
func is_animation_system_enabled() -> bool:
	"""アニメーションシステムが有効かどうか"""
	return is_animation_enabled

func are_all_animations_completed() -> bool:
	"""全アニメーションが完了しているかどうか"""
	if character_animation and is_animation_enabled:
		return character_animation.are_all_animations_completed()
	return true

func is_character_ready_to_show(char_index: int) -> bool:
	"""指定文字が表示準備できているかどうか"""
	if character_animation and is_animation_enabled:
		return character_animation.is_character_ready_to_show(char_index)
	return true

## クリーンアップ
func cleanup():
	"""リソースをクリーンアップ"""
	if character_animation:
		# シグナル接続を解除
		if character_animation.all_animations_completed.is_connected(_on_all_animations_completed):
			character_animation.all_animations_completed.disconnect(_on_all_animations_completed)
	
	# アニメーション更新を停止
	if message_canvas:
		message_canvas.stop_animation_updates()
	
	character_animation = null
	message_canvas = null
	on_animation_completed = Callable()

## デバッグ情報
func debug_print_animation_state():
	"""アニメーション状態をデバッグ出力"""
	ArgodeSystem.log("🎭 Animation Coordinator Debug Info:")
	ArgodeSystem.log("  - Animation enabled: %s" % str(is_animation_enabled))
	ArgodeSystem.log("  - Character animation exists: %s" % str(character_animation != null))
	ArgodeSystem.log("  - Message canvas exists: %s" % str(message_canvas != null))
	
	if character_animation:
		ArgodeSystem.log("  - All animations completed: %s" % str(character_animation.are_all_animations_completed()))
