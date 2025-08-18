extends ArgodeViewBase
class_name ArgodeMessageWindow

@export_node_path var message_container
@export_node_path var message_label
@export_node_path var continue_prompt
@export_node_path var name_plate
var name_label: Label

# TypewriterServiceから受け取ったメッセージを純粋に表示するだけの関数
func set_message_text(text: String):
	message_label.text = text

# 名前のテキストを設定
func set_name_text(name: String):
	if is_instance_valid(name_label):
		name_label.text = name
	else:
		# 名前ラベルがnullの場合は新規に取得
		name_label = name_plate.get_child(0) if name_plate.get_child_count() > 0 else null
		if not is_instance_valid(name_label):
			ArgodeSystem.log("❌ Error: Name label node is not valid or does not exist.", ArgodeSystem.DebugManager.LogLevel.ERROR)
			return
	if name_label:
		name_label.text = name

# 続行プロンプトを表示
func show_continue_prompt():
	continue_prompt.visible = true

# 続行プロンプトを非表示にする
func hide_continue_prompt():
	continue_prompt.visible = false

# 名前プレートを表示
func show_name_plate():
	name_plate.visible = true

# 名前プレートを非表示にする
func hide_name_plate():
	name_plate.visible = false