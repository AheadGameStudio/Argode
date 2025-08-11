# BaseCustomCommand.gd
# カスタムコマンド基底クラス - プロジェクト側で継承して独自コマンドを作成可能
class_name BaseCustomCommand
extends RefCounted

# コマンド情報
var command_name: String
var description: String
var help_text: String

# パラメータ定義（オプション）
var parameter_info: Dictionary = {}

# 初期化（継承先でオーバーライド）
func _init():
	command_name = "base_command"
	description = "Base custom command class"
	help_text = "Override this in your custom command"

# メインの実行処理（継承先で必須実装）
func execute(_params: Dictionary, _adv_system: Node) -> void:
	push_warning("BaseCustomCommand.execute() not implemented in " + command_name)

# 視覚効果実行処理（継承先でオプション実装）
func execute_visual_effect(_params: Dictionary, _ui_node: Node) -> void:
	# デフォルトでは何もしない
	# 視覚効果が必要なコマンドは継承先でオーバーライド
	pass

# 視覚効果が利用可能かどうか
func has_visual_effect() -> bool:
	return false  # 継承先でオーバーライド

# 同期処理が必要かどうか（待機が必要な場合true）
func is_synchronous() -> bool:
	return false

# 非同期処理用（同期処理が必要な場合はこちらをオーバーライド）
func execute_async(params: Dictionary, adv_system: Node) -> void:
	await execute_internal_async(params, adv_system)

# 内部非同期処理（継承先でオーバーライド可能）
func execute_internal_async(params: Dictionary, adv_system: Node) -> void:
	# デフォルトでは通常のexecute()を呼び出し
	execute(params, adv_system)

# パラメータのバリデーション（オプション）
func validate_parameters(_params: Dictionary) -> bool:
	return true

# パラメータ情報の設定ヘルパー
func set_parameter_info(param_name: String, param_type: String, required: bool = false, default_value = null, description: String = ""):
	parameter_info[param_name] = {
		"type": param_type,
		"required": required,
		"default": default_value,
		"description": description
	}

# ヘルプテキストの動的生成
func get_help_text() -> String:
	if not help_text.is_empty():
		return help_text
	
	var help = description + "\n"
	if not parameter_info.is_empty():
		help += "Parameters:\n"
		for param_name in parameter_info:
			var info = parameter_info[param_name]
			var required_text = " (required)" if info.get("required", false) else " (optional)"
			var default_text = " [default: " + str(info.get("default", "")) + "]" if info.has("default") else ""
			help += "  " + param_name + ": " + info.get("type", "any") + required_text + default_text
			if info.has("description") and not info.description.is_empty():
				help += " - " + info.description
			help += "\n"
	
	return help

# デバッグ用：コマンド情報の表示
func get_command_info() -> Dictionary:
	return {
		"name": command_name,
		"description": description,
		"synchronous": is_synchronous(),
		"parameters": parameter_info
	}

# ユーティリティ：パラメータから値を取得（位置引数とキーワード引数の両方対応）
func get_param_value(params: Dictionary, param_name: String, positional_index: int = -1, default_value = null):
	# キーワード引数を優先
	if params.has(param_name):
		return params[param_name]
	
	# 位置引数をチェック（arg0, arg1, ... または 0, 1, ...）
	if positional_index >= 0:
		var arg_key = "arg" + str(positional_index)
		if params.has(arg_key):
			return params[arg_key]
		if params.has(positional_index):
			return params[positional_index]
	
	# パラメータ情報からデフォルト値を取得
	if parameter_info.has(param_name) and parameter_info[param_name].has("default"):
		return parameter_info[param_name]["default"]
	
	return default_value

# ユーティリティ：色文字列をColor型に変換
func parse_color(color_str: String) -> Color:
	match str(color_str).to_lower():
		"white", "w":
			return Color.WHITE
		"black", "b":
			return Color.BLACK
		"red", "r":
			return Color.RED
		"green", "g":
			return Color.GREEN
		"blue":
			return Color.BLUE
		"yellow", "y":
			return Color.YELLOW
		"cyan", "c":
			return Color.CYAN
		"magenta", "m":
			return Color.MAGENTA
		"transparent":
			return Color.TRANSPARENT
		_:
			# hex形式やRGBA形式の解析を試行
			if color_str.begins_with("#"):
				return Color.html(color_str)
			else:
				push_warning("Unknown color: " + color_str + " using white")
				return Color.WHITE

# ユーティリティ：動的シグナル発行システム
func emit_dynamic_signal(signal_name: String, args: Array = [], adv_system: Node = null):
	"""動的にシグナルを発行（カスタムコマンドから呼び出し）"""
	if not adv_system:
		log_error("ArgodeSystem reference is required for signal emission")
		return false
	
	var handler = adv_system.get_custom_command_handler()
	if not handler:
		log_error("CustomCommandHandler not found in ArgodeSystem")
		return false
	
	# CustomCommandHandlerの汎用シグナル発行メソッドを呼び出し
	if handler.has_method("emit_custom_signal"):
		handler.emit_custom_signal(signal_name, args, command_name)
		log_command("Emitted signal: " + signal_name + " with args: " + str(args))
		return true
	else:
		log_error("CustomCommandHandler does not support dynamic signals")
		return false

# シグナル発行の便利メソッド群
func emit_window_shake(intensity: float, duration: float, adv_system: Node):
	"""ウィンドウシェイクシグナルを発行"""
	emit_dynamic_signal("window_shake_requested", [intensity, duration], adv_system)

func emit_screen_flash(color: Color, duration: float, adv_system: Node):
	"""画面フラッシュシグナルを発行"""
	emit_dynamic_signal("screen_flash_requested", [color, duration], adv_system)

func emit_camera_effect(effect_name: String, parameters: Dictionary, adv_system: Node):
	"""カメラエフェクトシグナルを発行"""
	emit_dynamic_signal("camera_effect_requested", [effect_name, parameters], adv_system)

func emit_ui_animation(animation_name: String, parameters: Dictionary, adv_system: Node):
	"""UIアニメーションシグナルを発行"""
	emit_dynamic_signal("ui_animation_requested", [animation_name, parameters], adv_system)

func emit_particle_effect(effect_name: String, parameters: Dictionary, adv_system: Node):
	"""パーティクルエフェクトシグナルを発行"""
	emit_dynamic_signal("particle_effect_requested", [effect_name, parameters], adv_system)

func emit_text_effect(effect_name: String, parameters: Dictionary, adv_system: Node):
	"""テキストエフェクトシグナルを発行"""
	emit_dynamic_signal("text_effect_requested", [effect_name, parameters], adv_system)

func emit_custom_transition(transition_name: String, parameters: Dictionary, adv_system: Node):
	"""カスタムトランジションシグナルを発行"""
	emit_dynamic_signal("custom_transition_requested", [transition_name, parameters], adv_system)

# === 視覚効果ヘルパーメソッド ===

func create_tween_for_node(node: Node) -> Tween:
	"""ノードに対するTweenを作成"""
	if not node:
		log_error("Cannot create tween for null node")
		return null
	
	var tween = node.create_tween()
	return tween

func shake_node(node: Node, intensity: float, duration: float, shake_type: String = "both") -> void:
	"""ノードを振動させる汎用メソッド"""
	if not node:
		log_error("Cannot shake null node")
		return
	
	var original_pos = node.position
	var tween = create_tween_for_node(node)
	if not tween:
		return
		
	var shake_steps = int(duration * 30)  # 30fps相当
	
	for i in range(shake_steps):
		var shake_offset = Vector2.ZERO
		match shake_type:
			"horizontal":
				shake_offset.x = randf_range(-intensity, intensity)
			"vertical":
				shake_offset.y = randf_range(-intensity, intensity)
			_:  # "both"
				shake_offset = Vector2(
					randf_range(-intensity, intensity),
					randf_range(-intensity, intensity)
				)
		
		var target_pos = original_pos + shake_offset
		tween.tween_property(node, "position", target_pos, duration / shake_steps)
	
	# 元の位置に戻す
	tween.tween_property(node, "position", original_pos, 0.1)

func flash_screen(ui_node: Node, color: Color, duration: float) -> void:
	"""画面フラッシュ効果の汎用メソッド"""
	if not ui_node:
		log_error("Cannot flash screen - UI node is null")
		return
	
	# フラッシュ用のColorRectを作成
	var flash_rect = ColorRect.new()
	flash_rect.color = color
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_node.add_child(flash_rect)
	
	# フェードイン・アウト効果
	var tween = create_tween_for_node(ui_node)
	if not tween:
		flash_rect.queue_free()
		return
		
	flash_rect.modulate.a = 0.0
	tween.tween_property(flash_rect, "modulate:a", 0.8, duration * 0.3)
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration * 0.7)
	tween.tween_callback(flash_rect.queue_free)

func get_window_from_ui(ui_node: Node) -> Window:
	"""UIノードから親ウィンドウを取得"""
	if not ui_node:
		return null
	
	if ui_node.has_method("get_window"):
		return ui_node.get_window()
	elif ui_node.has_method("get_tree"):
		var tree = ui_node.get_tree()
		if tree and tree.has_method("get_root"):
			var root = tree.get_root()
			if root is Window:
				return root as Window
	
	return null

# ログ出力ヘルパー
func log_command(message: String):
	print("🎯 [" + command_name + "] " + message)

func log_warning(message: String):
	push_warning("⚠️ [" + command_name + "] " + message)

func log_error(message: String):
	push_error("❌ [" + command_name + "] " + message)