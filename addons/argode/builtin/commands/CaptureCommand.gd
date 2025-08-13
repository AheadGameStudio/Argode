# CaptureCommand.gd
# capture コマンド実装 - 一時的なスクリーンショットを撮影する
@tool
class_name BuiltinCaptureCommand
extends BaseCustomCommand

func _init():
	command_name = "capture"
	description = "Capture temporary screenshot for save thumbnails"
	help_text = "capture\nCapture a temporary screenshot that will be used for save thumbnails. Screenshot expires after 5 minutes."

func execute(params: Dictionary, adv_system: Node) -> void:
	print("📷 [capture] Executing capture command")
	
	var save_manager = adv_system.SaveLoadManager
	if not save_manager:
		push_error("❌ [capture] SaveLoadManager not found")
		return
	
	if not save_manager.is_screenshot_enabled():
		push_error("❌ [capture] Screenshot feature is disabled")
		return
	
	var success = save_manager.capture_temp_screenshot()
	if success:
		print("✅ [capture] Temporary screenshot captured successfully")
		print("📷 [capture] This screenshot will be used for save thumbnails")
		print("⏰ [capture] Screenshot will expire in 5 minutes if not used")
	else:
		push_error("❌ [capture] Failed to capture temporary screenshot")
