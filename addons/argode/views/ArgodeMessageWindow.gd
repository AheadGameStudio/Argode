extends ArgodeViewBase
class_name ArgodeMessageWindow

@export_node_path var message_container
@export_node_path var message_label
@export_node_path var continue_prompt
@export_node_path var name_plate
var name_label: Label
@export_node_path var choice_container

@export var is_visible_choice_number: bool

@export_category("Theme Variation")
@export var choice_button_theme_variation: String = "ChoiceButton"

func _init():
	await ready
	_after_ready_setup()

func _after_ready_setup():
	ArgodeSystem.log("✅ ArgodeMessageWindow is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

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

## メッセージウィンドウ全体を表示にする
func show_message_window():
	visible = true

## メッセージウィンドウ全体を非表示にする
func hide_message_window():
	visible = false

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

# 選択肢コンテナを表示
func show_choice_container():
	choice_container.visible = true

# 選択肢コンテナを非表示にする
func hide_choice_container():
	choice_container.visible = false