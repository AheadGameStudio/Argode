# TextAnimateCommand.gd
# テキストアニメーション効果コマンド
class_name TextAnimateCommand
extends BaseCustomCommand

func _init():
	command_name = "text_animate"
	description = "Animate text with various effects (shake, wave, bounce)"
	help_text = "text_animate shake intensity=2.0 duration=1.0 | text_animate wave amplitude=5.0 speed=2.0"
	
	# パラメータ情報を設定
	set_parameter_info("effect", "string", true, "shake", "Animation type (shake, wave, bounce, fade)")
	set_parameter_info("intensity", "float", false, 2.0, "Effect intensity")
	set_parameter_info("duration", "float", false, 1.0, "Animation duration")
	set_parameter_info("amplitude", "float", false, 5.0, "Wave/bounce amplitude")
	set_parameter_info("speed", "float", false, 2.0, "Animation speed")

func has_visual_effect() -> bool:
	return true

func execute(params: Dictionary, adv_system: Node) -> void:
	var effect = get_param_value(params, "effect", 0, "shake")
	var intensity = get_param_value(params, "intensity", 1, 2.0)
	var duration = get_param_value(params, "duration", 2, 1.0)
	
	log_command("Text animate: effect=" + str(effect) + " intensity=" + str(intensity) + " duration=" + str(duration))
	
	# 動的シグナル発行
	emit_dynamic_signal("text_animate_requested", [effect, intensity, duration], adv_system)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""テキストアニメーション効果の実行"""
	var effect = get_param_value(params, "effect", 0, "shake")
	var intensity = get_param_value(params, "intensity", 1, 2.0)
	var duration = get_param_value(params, "duration", 2, 1.0)
	var amplitude = get_param_value(params, "amplitude", 3, 5.0)
	var speed = get_param_value(params, "speed", 4, 2.0)
	
	log_command("Executing text animation: " + str(effect))
	
	# TypewriterTextノードを見つける
	var typewriter_text = _find_typewriter_text(ui_node)
	if not typewriter_text:
		log_error("TypewriterText node not found for text animation")
		return
	
	# アニメーション実行
	match str(effect).to_lower():
		"shake":
			_animate_shake(typewriter_text, intensity, duration)
		"wave":
			_animate_wave(typewriter_text, amplitude, speed, duration)
		"bounce":
			_animate_bounce(typewriter_text, amplitude, speed, duration)
		"fade":
			_animate_fade(typewriter_text, duration)
		_:
			log_error("Unknown text animation effect: " + str(effect))

func _find_typewriter_text(ui_node: Node) -> Node:
	"""TypewriterTextノードを探す"""
	# デバッグ: ノード構造を出力
	print("🔍 Looking for TypewriterText in UI structure:")
	_debug_print_node_structure(ui_node, 0)
	
	# 既知のパスを試行
	var known_paths = [
		"MessageBox/MessagePanel/MarginContainer/VBoxContainer/MessageLabel",
		"MessageLabel", 
		"MessageBox/MessageLabel",
		"VBoxContainer/MessageLabel"
	]
	
	for path in known_paths:
		var node = ui_node.get_node_or_null(path)
		if node:
			print("✅ Found MessageLabel at: ", path)
			# TypewriterTextが統合されているか確認
			if node.has_method("animate_character") or node.has_method("start_typing"):
				return node
			elif node.get_child_count() > 0:
				# TypewriterTextが子ノードとして存在するかチェック
				for child in node.get_children():
					if child.get_class().contains("Typewriter") or child.has_method("animate_character"):
						print("✅ Found TypewriterText child: ", child.name)
						return child
	
	# フォールバック: 再帰的探索
	var found = _find_typewriter_text_recursive(ui_node)
	if found:
		print("✅ Found TypewriterText via recursive search: ", found.name)
	else:
		print("❌ TypewriterText not found in UI structure")
	
	return found

func _find_typewriter_text_recursive(node: Node) -> Node:
	"""再帰的にTypewriterTextノードを探す"""
	# クラス名やメソッドで判定（より広範囲）
	if (node.get_class().contains("Typewriter") or 
		node.has_method("animate_character") or 
		node.has_method("start_typing") or
		node.name.contains("MessageLabel") or
		node.name == "MessageLabel" or
		# RichTextLabelベースの場合もチェック
		(node.get_class() == "RichTextLabel" and node.name.contains("Message"))):
		print("🎯 Found potential TypewriterText node: ", node.name, " (", node.get_class(), ")")
		return node
	
	for child in node.get_children():
		var found = _find_typewriter_text_recursive(child)
		if found:
			return found
	
	return null

func _debug_print_node_structure(node: Node, depth: int):
	"""ノード構造をデバッグ出力"""
	if depth > 3:  # 深さ制限
		return
	
	var indent = "  ".repeat(depth)
	var node_class = node.get_class()
	var has_animate = node.has_method("animate_character")
	var has_typing = node.has_method("start_typing")
	
	print(indent, "- ", node.name, " (", node_class, ")", 
		  " animate=", has_animate, " typing=", has_typing)
	
	for child in node.get_children():
		_debug_print_node_structure(child, depth + 1)

func _animate_shake(typewriter_text: Node, intensity: float, duration: float):
	"""シェイクアニメーション"""
	if not typewriter_text:
		return
	
	var original_position = typewriter_text.position
	var tween = typewriter_text.create_tween()
	
	var shake_count = int(duration * 20)  # 20 shakes per second
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(typewriter_text, "position", original_position + shake_offset, duration / shake_count)
	
	# 元の位置に戻す
	tween.tween_property(typewriter_text, "position", original_position, 0.1)
	print("🎭 Text shake animation started for ", duration, "s")

func _animate_wave(typewriter_text: Node, amplitude: float, speed: float, duration: float):
	"""ウェーブアニメーション"""
	if not typewriter_text:
		return
	
	var original_position = typewriter_text.position
	var tween = typewriter_text.create_tween()
	
	var wave_steps = int(duration * 30)  # 30 steps per second
	for i in range(wave_steps):
		var progress = float(i) / wave_steps
		var wave_y = sin(progress * PI * 2 * speed) * amplitude
		tween.tween_property(typewriter_text, "position", original_position + Vector2(0, wave_y), duration / wave_steps)
	
	# 元の位置に戻す
	tween.tween_property(typewriter_text, "position", original_position, 0.1)
	print("🌊 Text wave animation started for ", duration, "s")

func _animate_bounce(typewriter_text: Node, amplitude: float, speed: float, duration: float):
	"""バウンスアニメーション"""
	if not typewriter_text:
		return
	
	var original_position = typewriter_text.position
	var tween = typewriter_text.create_tween()
	
	var bounce_count = int(duration * speed)
	for i in range(bounce_count):
		var bounce_height = amplitude * (1.0 - float(i) / bounce_count)  # 徐々に小さく
		tween.tween_property(typewriter_text, "position", original_position + Vector2(0, -bounce_height), 0.2)
		tween.tween_property(typewriter_text, "position", original_position, 0.2)
	
	print("⭐ Text bounce animation started for ", duration, "s")

func _animate_fade(typewriter_text: Node, duration: float):
	"""フェードアニメーション"""
	if not typewriter_text:
		return
	
	var tween = typewriter_text.create_tween()
	tween.tween_property(typewriter_text, "modulate:a", 0.0, duration * 0.5)
	tween.tween_property(typewriter_text, "modulate:a", 1.0, duration * 0.5)
	print("✨ Text fade animation started for ", duration, "s")

func validate_parameters(params: Dictionary) -> bool:
	var effect = get_param_value(params, "effect", 0, "shake")
	var intensity = get_param_value(params, "intensity", 1, 2.0)
	var duration = get_param_value(params, "duration", 2, 1.0)
	
	# エフェクトタイプチェック
	var valid_effects = ["shake", "wave", "bounce", "fade"]
	if str(effect).to_lower() not in valid_effects:
		log_error("Invalid effect type. Must be one of: " + str(valid_effects))
		return false
	
	# 数値チェック
	if not (intensity is float or intensity is int) or intensity < 0:
		log_error("Intensity must be a positive number")
		return false
		
	if not (duration is float or duration is int) or duration <= 0:
		log_error("Duration must be a positive number")
		return false
	
	return true