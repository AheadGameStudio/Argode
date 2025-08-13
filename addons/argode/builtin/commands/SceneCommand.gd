# SceneCommand.gd
# scene コマンド実装 - Ren'Pyスタイルの背景切り替え
@tool
class_name BuiltinSceneCommand
extends BaseCustomCommand

func _init():
	command_name = "scene"
	description = "Change background scene (Ren'Py style)"
	help_text = "scene <background_name> [with <transition>]\nExamples:\nscene black - Sets background to black\nscene clear - Clears background (makes ArgodeSystem transparent)\nscene classroom with fade - Change to classroom with fade transition"

func execute(params: Dictionary, adv_system: Node) -> void:
	print("🎬 [scene] Executing scene command")
	
	# パラメータ取得
	var scene_name = get_param_value(params, "scene_name", 0, "black")
	var transition = get_param_value(params, "transition", 1, "none")
	
	print("🎬 [scene] Scene: '", scene_name, "', Transition: '", transition, "'")
	
	# ArgodeSystemの検証
	if not adv_system:
		push_error("❌ [scene] ArgodeSystem not provided")
		return
	
	var layer_manager = adv_system.LayerManager
	if not layer_manager:
		push_error("❌ [scene] LayerManager not found")
		return
	
	var success = false
	
	# 特別ケース: "black" - 純黒背景
	if scene_name.to_lower() == "black":
		print("⚫ [scene] Setting black background")
		success = _set_black_background(layer_manager, transition)
	# 特別ケース: "clear" - 背景を完全にクリア（透明化）
	elif scene_name.to_lower() == "clear":
		print("🔍 [scene] Clearing background (making transparent)")
		success = _clear_background(layer_manager, transition)
	else:
		# 通常の背景変更
		success = _set_normal_background(layer_manager, scene_name, transition, adv_system)
	
	if not success:
		push_warning("⚠️ [scene] Failed to change scene to: " + scene_name)
	
	# シグナル発行
	emit_signal("scene_changed", scene_name, transition)

func _set_black_background(layer_manager, transition: String) -> bool:
	# 純黒のColorRectを作成（より軽量）
	var black_bg = ColorRect.new()
	black_bg.color = Color.BLACK
	black_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# LayerManagerのプライベートメソッドを呼ぶ代わりに、直接背景レイヤーを操作
	var background_layer = layer_manager.background_layer
	if not background_layer:
		push_error("❌ [scene] Background layer not found")
		return false
	
	# 現在の背景をクリア
	if layer_manager.current_background:
		layer_manager.current_background.queue_free()
	
	# 黒背景を追加
	background_layer.add_child(black_bg)
	layer_manager.current_background = black_bg
	
	# トランジション処理
	if transition != "none":
		var adv_system = layer_manager.get_node("/root/ArgodeSystem")
		var transition_player = adv_system.TransitionPlayer if adv_system else null
		if transition_player:
			print("🎬 [scene] Executing black background transition:", transition)
			# 簡単なフェード処理
			black_bg.modulate.a = 0.0
			var tween = layer_manager.create_tween()
			tween.tween_property(black_bg, "modulate:a", 1.0, 0.5)
	
	layer_manager.background_changed.emit("black")
	return true

func _clear_background(layer_manager, transition: String) -> bool:
	"""背景を完全にクリア（透明化）してArgodeSystemを透過させる"""
	var background_layer = layer_manager.background_layer
	if not background_layer:
		push_error("❌ [scene] Background layer not found")
		return false
	
	# 現在の背景をクリア
	if layer_manager.current_background:
		if transition != "none":
			# フェードアウト後に削除
			var current_bg = layer_manager.current_background
			var tween = layer_manager.create_tween()
			tween.tween_property(current_bg, "modulate:a", 0.0, 0.5)
			tween.tween_callback(current_bg.queue_free)
		else:
			layer_manager.current_background.queue_free()
		
		layer_manager.current_background = null
	
	# 背景レイヤー自体を透明化（完全に透過）
	if transition != "none":
		var tween = layer_manager.create_tween()
		tween.tween_property(background_layer, "modulate:a", 0.0, 0.5)
	else:
		background_layer.modulate.a = 0.0
	
	print("🔍 [scene] Background cleared - ArgodeSystem is now transparent")
	layer_manager.background_changed.emit("clear")
	return true

func _set_normal_background(layer_manager, scene_name: String, transition: String, adv_system) -> bool:
	var bg_path = ""
	
	# まずImageDefinitionManagerから画像定義を取得
	if adv_system.ImageDefs:
		bg_path = adv_system.ImageDefs.get_image_path(scene_name)
		print("🔍 [scene] ImageDefs lookup for '", scene_name, "': ", bg_path)
	
	# 定義が見つからない場合はデフォルトパス構築
	if bg_path.is_empty():
		bg_path = "res://assets/images/backgrounds/" + scene_name + ".jpg"
		print("🔍 [scene] Using default path: ", bg_path)
	
	return layer_manager.change_background(bg_path, transition)

# シグナル定義
signal scene_changed(scene_name: String, transition: String)
