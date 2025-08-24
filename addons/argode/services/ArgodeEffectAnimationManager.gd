extends RefCounted
class_name ArgodeEffectAnimationManager

## エフェクトアニメーションの統一管理クラス
## フレーム単位でのリアルタイム更新制御

# 管理対象
var glyph_manager = null  # ArgodeGlyphManager
var active_managers: Array = []  # 複数のGlyphManagerを管理可能

# 更新制御
var is_active: bool = false
var update_enabled: bool = true
var frame_rate: float = 60.0
var delta_accumulator: float = 0.0

# パフォーマンス制御
var max_updates_per_frame: int = 100  # 1フレームで更新する最大グリフ数
var skip_invisible_glyphs: bool = true

# 時間制御
var global_time_scale: float = 1.0
var animation_speed_scale: float = 1.0

# 統計情報
var total_glyphs_processed: int = 0
var total_effects_processed: int = 0
var frame_count: int = 0
var last_frame_time: int = 0  # タイミング診断用

signal animation_frame_updated(delta: float)
signal effects_batch_completed()

func _init(glyph_mgr = null):  # ArgodeGlyphManager
	if glyph_mgr:
		set_glyph_manager(glyph_mgr)

## メインのGlyphManagerを設定
func set_glyph_manager(manager) -> void:  # ArgodeGlyphManager
	glyph_manager = manager
	if manager and manager not in active_managers:
		active_managers.append(manager)

## 追加のGlyphManagerを登録
func add_glyph_manager(manager) -> void:  # ArgodeGlyphManager
	if manager and manager not in active_managers:
		active_managers.append(manager)
		ArgodeSystem.log("📝 EffectAnimationManager: Added additional GlyphManager")

## GlyphManagerを登録解除
func remove_glyph_manager(manager) -> void:  # ArgodeGlyphManager
	if manager in active_managers:
		active_managers.erase(manager)
		if glyph_manager == manager:
			glyph_manager = null

## アニメーション更新を開始
func start_animation() -> void:
	is_active = true
	frame_count = 0
	total_glyphs_processed = 0
	total_effects_processed = 0
	ArgodeSystem.log("🎭 EffectAnimationManager: Animation started")

## アニメーション更新を停止
func stop_animation() -> void:
	is_active = false
	ArgodeSystem.log("🎭 EffectAnimationManager: Animation stopped")

## メインの更新処理（毎フレーム呼び出し）
func update_animations(delta: float) -> void:
	if not is_active or not update_enabled:
		return
	
	var frame_start_time = Time.get_ticks_msec()
	
	# 時間スケール適用
	var scaled_delta = delta * global_time_scale * animation_speed_scale
	delta_accumulator += scaled_delta
	
	# フレーム間隔をチェック（遅延検出）
	if frame_start_time - last_frame_time > 20:  # 20ms以上のフレーム間隔
		ArgodeSystem.log("⏱️ FRAME_GAP: %dms, scaled_delta: %.4f (delta: %.4f × %.2f × %.2f)" % 
			[frame_start_time - last_frame_time, scaled_delta, delta, global_time_scale, animation_speed_scale])
	
	# フレームカウント更新
	frame_count += 1
	
	# すべての登録済みGlyphManagerを更新
	var processed_count = 0
	for manager in active_managers:
		if manager and processed_count < max_updates_per_frame:
			processed_count += update_glyph_manager(manager, scaled_delta)
	
	# 統計更新
	total_glyphs_processed += processed_count
	
	var frame_end_time = Time.get_ticks_msec()
	var frame_time = frame_end_time - frame_start_time
	last_frame_time = frame_start_time
	
	# 重いフレームをレポート
	if frame_time > 3:
		ArgodeSystem.log("🐌 SLOW_FRAME: %dms, processed: %d, managers: %d, total_effects: %d" % 
			[frame_time, processed_count, active_managers.size(), total_effects_processed])
	
	# シグナル発行
	animation_frame_updated.emit(scaled_delta)
	
	# バッチ完了チェック
	if processed_count == 0:
		effects_batch_completed.emit()

## 個別GlyphManagerの更新
func update_glyph_manager(manager, delta: float) -> int:  # ArgodeGlyphManager
	if not manager:
		return 0
	
	var start_time = Time.get_ticks_msec()
	var processed_glyphs = 0
	manager.update_all_effects(delta)
	
	# 処理されたグリフ数をカウント
	for glyph in manager.get_all_glyphs():
		if glyph.is_visible or not skip_invisible_glyphs:
			processed_glyphs += 1
			
			# エフェクト数もカウント
			total_effects_processed += glyph.effects.size()
	
	var end_time = Time.get_ticks_msec()
	var process_time = end_time - start_time
	
	# 処理時間が2ms以上なら報告（パフォーマンス問題検出）
	if process_time > 2:
		ArgodeSystem.log("⏱️ GlyphManager update: %dms, glyphs: %d, effects: %d" % [process_time, processed_glyphs, total_effects_processed])
	
	return processed_glyphs

## グローバル時間スケールを設定
func set_global_time_scale(scale: float) -> void:
	global_time_scale = clamp(scale, 0.0, 10.0)
	ArgodeSystem.log("⏱️ Global time scale set to: %.2f" % global_time_scale)

## アニメーション速度スケールを設定
func set_animation_speed_scale(scale: float) -> void:
	animation_speed_scale = clamp(scale, 0.0, 10.0)
	ArgodeSystem.log("🎭 Animation speed scale set to: %.2f" % animation_speed_scale)

## すべてのアニメーションを一時停止
func pause_all_animations() -> void:
	update_enabled = false
	ArgodeSystem.log("⏸️ All animations paused")

## すべてのアニメーションを再開
func resume_all_animations() -> void:
	update_enabled = true
	ArgodeSystem.log("▶️ All animations resumed")

## 特定エフェクトのみを更新
func update_specific_effect(effect_name: String, delta: float) -> void:
	for manager in active_managers:
		if not manager:
			continue
		
		for glyph in manager.get_all_glyphs():
			var effect = glyph.get_effect_by_name(effect_name)
			if effect and effect.is_active:
				var elapsed = manager.current_time - glyph.appear_time
				effect.update(glyph, elapsed)

## パフォーマンス設定を変更
func set_performance_settings(max_updates: int, skip_invisible: bool) -> void:
	max_updates_per_frame = max_updates
	skip_invisible_glyphs = skip_invisible
	ArgodeSystem.log("⚡ Performance settings updated: max_updates=%d, skip_invisible=%s" % [max_updates, str(skip_invisible)])

## すべてのエフェクトを即座に完了
func complete_all_effects_instantly() -> void:
	for manager in active_managers:
		if not manager:
			continue
		
		for glyph in manager.get_all_glyphs():
			for effect in glyph.effects:
				if effect.is_active:
					# エフェクトを強制完了
					effect.stop_effect()
	
	ArgodeSystem.log("⏭️ All effects completed instantly")

## 統計情報を取得
func get_statistics() -> Dictionary:
	return {
		"frame_count": frame_count,
		"total_glyphs_processed": total_glyphs_processed,
		"total_effects_processed": total_effects_processed,
		"active_managers": active_managers.size(),
		"is_active": is_active,
		"update_enabled": update_enabled,
		"global_time_scale": global_time_scale,
		"animation_speed_scale": animation_speed_scale,
		"average_glyphs_per_frame": float(total_glyphs_processed) / max(frame_count, 1)
	}

## 統計情報をリセット
func reset_statistics() -> void:
	frame_count = 0
	total_glyphs_processed = 0
	total_effects_processed = 0
	delta_accumulator = 0.0

## デバッグ情報を出力
func debug_print_status() -> void:
	var stats = get_statistics()
	ArgodeSystem.log("🎭 EffectAnimationManager Debug Info:")
	ArgodeSystem.log("  - Active: %s" % str(stats.is_active))
	ArgodeSystem.log("  - Update enabled: %s" % str(stats.update_enabled))
	ArgodeSystem.log("  - Frame count: %d" % stats.frame_count)
	ArgodeSystem.log("  - Total glyphs processed: %d" % stats.total_glyphs_processed)
	ArgodeSystem.log("  - Total effects processed: %d" % stats.total_effects_processed)
	ArgodeSystem.log("  - Active managers: %d" % stats.active_managers)
	ArgodeSystem.log("  - Global time scale: %.2f" % stats.global_time_scale)
	ArgodeSystem.log("  - Animation speed scale: %.2f" % stats.animation_speed_scale)
	ArgodeSystem.log("  - Average glyphs/frame: %.1f" % stats.average_glyphs_per_frame)

## 全マネージャーの状態をリセット
func reset_all_managers() -> void:
	for manager in active_managers:
		if manager:
			manager.clear_glyphs()
			manager.reset_time()
	
	reset_statistics()
	ArgodeSystem.log("🔄 All managers reset")
