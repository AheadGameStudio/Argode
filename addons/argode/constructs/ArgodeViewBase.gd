# Argodeフレームワークの基本ビュー
@tool
extends Control
class_name ArgodeViewBase

var default_mouse_filter: MouseFilter
@export var is_sticky_front: bool = false :set = set_sticky_front
@onready var default_z_index: int = z_index if not z_index == null else 0
@export var is_modal: bool = false
var is_active: bool = true

var ui_manager:ArgodeUIManager

func _init():
	if Engine.is_editor_hint():
		return
	await ready
	_post_ready()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	ArgodeSystem.log("ArgodeViewBase is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)

func _post_ready():
	ArgodeSystem.log("🫠 ArgodeViewBaseは基本的にMouseFilterを無視します。必要に応じてオーバーライドしてください。", ArgodeSystem.DebugManager.LogLevel.INFO)
	mouse_filter = default_mouse_filter
	ui_manager = ArgodeSystem.UIManager
	if ui_manager:
		ArgodeSystem.log("✅ Post ready execution completed.", ArgodeSystem.DebugManager.LogLevel.INFO)


func show_with_animation(_transition_type: String):
	visible = true

func hide_with_animation(_transition_type: String):
	visible = false

func set_sticky_front(value: bool):
	is_sticky_front = value

	if is_sticky_front:
		z_index = default_z_index + 1000
	else:
		z_index = default_z_index