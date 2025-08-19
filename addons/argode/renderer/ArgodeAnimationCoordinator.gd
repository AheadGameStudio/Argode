extends RefCounted
class_name ArgodeAnimationCoordinator

## アニメーション統制を専門に扱うコーディネーター
## ArgodeMessageRendererからアニメーション管理機能を分離

# アニメーション管理
var character_animation = null  # ArgodeCharacterAnimationインスタンス
var is_animation_enabled: bool = true  # アニメーション有効フラグ
var message_canvas = null  # MessageCanvasの参照

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
	if character_animation and is_animation_enabled:
		character_animation.initialize_for_text(text_length)
		ArgodeSystem.log("✨ Character animation initialized for text length: %d" % text_length)
		
		# MessageCanvasでアニメーション更新を開始
		if message_canvas:
			message_canvas.start_animation_updates(_update_character_animations)

## 文字アニメーションをトリガー
func trigger_character_animation(char_index: int):
	"""指定文字のアニメーションをトリガー"""
	if character_animation and is_animation_enabled:
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
	"""アニメーション完了を待つ（シグナルベース）"""
	if character_animation and is_animation_enabled:
		ArgodeSystem.log("⏳ Waiting for animations completion via signal...")
		# 完了時に_on_all_animations_completed()が自動的に呼ばれる
	else:
		# アニメーションが無効な場合は即座に完了通知
		_notify_animation_completion()

## 全アニメーション完了シグナル受信
func _on_all_animations_completed():
	"""全アニメーション完了シグナルを受信"""
	ArgodeSystem.log("✅ All character animations completed via signal")
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
