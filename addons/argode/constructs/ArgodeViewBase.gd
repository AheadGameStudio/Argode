# Argodeフレームワークの基本ビュー

extends Control
class_name ArgodeViewBase

var default_mouse_filter: MouseFilter

func _init():
	await ready
	_post_ready()

func _ready() -> void:
	ArgodeSystem.log("ArgodeViewBase is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)

func _post_ready():
	ArgodeSystem.log("🫠 ArgodeViewBaseは基本的にMouseFilterを無視します。必要に応じてオーバーライドしてください。", ArgodeSystem.DebugManager.LogLevel.INFO)
	mouse_filter = default_mouse_filter
	ArgodeSystem.log("✅ Post ready execution completed.", ArgodeSystem.DebugManager.LogLevel.INFO)


func show_with_animation(_transition_type: String):
	visible = true

func hide_with_animation(_transition_type: String):
	visible = false