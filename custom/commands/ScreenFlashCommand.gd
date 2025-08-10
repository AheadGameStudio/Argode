# ScreenFlashCommand.gd
# screen_flash コマンド実装 - 画面フラッシュ効果
class_name ScreenFlashCommand
extends "res://addons/argode/commands/BaseCustomCommand.gd"

func _init():
	command_name = "screen_flash"
	description = "Flash the screen with specified color and duration"
	help_text = "screen_flash white 0.2 | screen_flash color=red duration=0.5"
	
	# パラメータ情報を設定
	set_parameter_info("color", "string", false, "white", "Flash color (white, red, blue, etc.)")
	set_parameter_info("duration", "float", false, 0.2, "Flash duration in seconds")

func has_visual_effect() -> bool:
	return true  # このコマンドは視覚効果を持つ

func execute(params: Dictionary, adv_system: Node) -> void:
	var color_str = get_param_value(params, "color", 0, "white")
	var duration = get_param_value(params, "duration", 1, 0.2)
	
	var color = parse_color(str(color_str))
	
	log_command("Screen flash requested: color=" + str(color) + " duration=" + str(duration))
	
	# 動的シグナル発行
	emit_screen_flash(color, duration, adv_system)

func execute_visual_effect(params: Dictionary, ui_node: Node) -> void:
	"""視覚効果の実行（AdvGameUIから呼び出される）"""
	var color_str = get_param_value(params, "color", 0, "white")
	var duration = get_param_value(params, "duration", 1, 0.2)
	
	var color = parse_color(str(color_str))
	
	log_command("Executing screen flash visual effect: color=" + str(color) + " duration=" + str(duration))
	
	# BaseCustomCommandのヘルパーメソッドを使用
	flash_screen(ui_node, color, duration)

func validate_parameters(params: Dictionary) -> bool:
	var duration = get_param_value(params, "duration", 1, 0.2)
	
	if not (duration is float or duration is int):
		log_error("Duration must be a number")
		return false
	
	if duration <= 0:
		log_error("Duration must be positive")
		return false
	
	return true