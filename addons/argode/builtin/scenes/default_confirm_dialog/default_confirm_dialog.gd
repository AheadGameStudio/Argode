@tool
extends ArgodeDialogBase

@export var button_labels: Array[String] : set = set_button_labels

func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		ArgodeSystem.log("✅ DefaultConfirmDialog is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)
	
	# 初期ボタンを設定
	set_button_labels(button_labels)

func set_button_labels(labels: Array[String]) -> void:
	button_labels = labels
	
	# 基底クラスの汎用機能を使用してボタンを設定
	if is_inside_tree() and buttons_container:
		_update_buttons_from_labels()

func _update_buttons_from_labels():
	"""ラベル配列から汎用ボタンを生成"""
	if not buttons_container:
		return
	
	# 基底クラスの便利メソッドを使用
	setup_confirm_buttons(button_labels, "confirm")
	
	ArgodeSystem.log("🎯 Updated confirm dialog with %d buttons" % button_labels.size())
