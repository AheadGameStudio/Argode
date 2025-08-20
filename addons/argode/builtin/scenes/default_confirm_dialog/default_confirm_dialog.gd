@tool
extends ArgodeDialogBase

@export var button_labels: Array[String] :set = set_button_labels

func _ready() -> void:
	super._ready()
	buttons_container = get_node_or_null(buttons_container_path)
	if buttons_container == null:
		if not Engine.is_editor_hint():
			ArgodeSystem.log("❌ Buttons container node not found at path: %s" % buttons_container_path, ArgodeSystem.DebugManager.LogLevel.ERROR)
		return
	if not Engine.is_editor_hint():
		ArgodeSystem.log("✅ DefaultConfirmDialog is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)
	set_button_labels(button_labels)

func _clear_buttons_container() -> void:
	if buttons_container != null:
		for child in buttons_container.get_children():
			buttons_container.remove_child(child)
			child.queue_free()  # メモリを解放

func _update_children() -> void:
	# コンテナノードやシーンが設定されていなければ何もしない
	if not buttons_container:
		return
		
	# 1. まずコンテナ内の既存の子をすべて削除
	for n in buttons_container.get_children():
		n.queue_free()
	
	# 2. 配列の各NodePathに対応するノードを取得し、シーンをインスタンス化して配置
	for label in button_labels:
		# NodePathが空の場合はスキップ
		if not label:
			continue

		if is_instance_valid(buttons_container):
			var instance = Button.new()
			instance.text = label
			instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# `target_node`の位置にインスタンスを配置
			buttons_container.add_child(instance)

func set_button_labels(labels: Array[String]) -> void:
	button_labels = labels
	_update_children()
