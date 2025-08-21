@tool
extends ArgodeViewBase
class_name ArgodeDialogBase

signal button_pressed(_value: Dictionary)
signal choice_selected(choice_index: int)  # 選択肢専用シグナル

@export_node_path var buttons_container_path: NodePath
@export var default_button_theme_variation: String = "DefaultButton"

var buttons_container: BoxContainer # VboxContainer/HBoxContainer
var choice_data: Array[Dictionary] = []  # 選択肢データ

func _ready():
	super._ready()
	if buttons_container_path == null:
		ArgodeSystem.log("⚠️ Buttons container path is not set.")
		return
	
	buttons_container = get_node(buttons_container_path)

## 選択肢ボタンを動的に生成（汎用機能）
func setup_choice_buttons(choices: Array[Dictionary], button_theme_variation: String = ""):
	"""
	選択肢ボタンを動的に生成する汎用メソッド
	choices: [{"text": "選択肢1", "data": {...}}, ...]
	"""
	ArgodeSystem.log("🎯 DialogBase: setup_choice_buttons called with %d choices" % choices.size())
	ArgodeSystem.log("🎯 DialogBase: choices parameter type: %s" % str(type_string(typeof(choices))))
	ArgodeSystem.log("🎯 DialogBase: choices parameter content: %s" % str(choices))
	
	# 配列の参照問題を避けるため、choicesを複製してからclear処理を行う
	var choices_copy = choices.duplicate(true)
	
	clear_all_buttons()
	choice_data = choices_copy  # 複製された配列を使用
	
	var theme_variation = button_theme_variation if not button_theme_variation.is_empty() else default_button_theme_variation
	
	ArgodeSystem.log("🎯 DialogBase: Setting up %d choice buttons with theme: %s" % [choices_copy.size(), theme_variation])
	ArgodeSystem.log("🎯 DialogBase: buttons_container is valid: %s" % str(buttons_container != null))
	ArgodeSystem.log("🎯 DialogBase: choices_copy content after clear: %s" % str(choices_copy))
	
	if not buttons_container:
		ArgodeSystem.log("❌ DialogBase: buttons_container is null, cannot add buttons", 2)
		return
	
	for i in range(choices_copy.size()):
		var choice = choices_copy[i]
		var choice_text = choice.get("text", "Choice %d" % (i + 1))
		ArgodeSystem.log("🎯 DialogBase: Adding choice button %d: %s" % [i, choice_text])
		add_choice_button(choice_text, i, theme_variation)
	
	ArgodeSystem.log("✅ DialogBase: Choice buttons setup completed")

## 単一選択肢ボタンを追加
func add_choice_button(text: String, choice_index: int, theme_variation: String = ""):
	"""単一の選択肢ボタンを追加"""
	var button = Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.text = text
	
	if not theme_variation.is_empty():
		button.theme_type_variation = theme_variation
	elif not default_button_theme_variation.is_empty():
		button.theme_type_variation = default_button_theme_variation
	
	buttons_container.add_child(button)
	
	# ボタンクリックイベントを接続
	button.pressed.connect(_on_choice_button_clicked.bind(choice_index, button))
	
	ArgodeSystem.log("➕ Added choice button: %s (index: %d)" % [text, choice_index])

## 選択肢ボタンクリック時の汎用処理
func _on_choice_button_clicked(choice_index: int, button: Button):
	"""選択肢ボタンがクリックされた時の汎用処理"""
	ArgodeSystem.log("🎯 Choice button clicked: %d (%s)" % [choice_index, button.text])
	
	# 選択肢専用シグナルを発行
	choice_selected.emit(choice_index)
	
	# 従来のbutton_pressedシグナルも発行（下位互換性）
	var context = {
		"id": choice_index,
		"text": button.text,
		"button": button
	}
	
	if choice_index < choice_data.size():
		context["data"] = choice_data[choice_index]
	
	button_pressed.emit(context)

## すべてのボタンをクリア
func clear_all_buttons():
	"""すべてのボタンを削除"""
	if not buttons_container:
		return
	
	for child in buttons_container.get_children():
		buttons_container.remove_child(child)
		child.queue_free()
	
	choice_data.clear()
	ArgodeSystem.log("🧹 All buttons cleared")

## 汎用ボタン追加メソッド（従来機能）
func add_button(text: String, button_data: Dictionary = {}, theme_variation: String = ""):
	"""汎用ボタンを追加（非選択肢用）"""
	var button = Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # ボタンを横に拡張
	
	if not theme_variation.is_empty():
		button.theme_type_variation = theme_variation
	elif not default_button_theme_variation.is_empty():
		button.theme_type_variation = default_button_theme_variation
	
	buttons_container.add_child(button)
	
	# 汎用ボタンクリック処理
	button.pressed.connect(_on_generic_button_clicked.bind(button_data, button))
	
	ArgodeSystem.log("➕ Added generic button: %s" % text)

## 汎用ボタンクリック処理
func _on_generic_button_clicked(button_data: Dictionary, button: Button):
	"""汎用ボタンがクリックされた時の処理"""
	var context = button_data.duplicate()
	context["text"] = button.text
	context["button"] = button
	
	ArgodeSystem.log("🎯 Generic button clicked: %s (data: %s)" % [button.text, str(button_data)])
	
	button_pressed.emit(context)

## 確認ダイアログ用の便利メソッド
func setup_confirm_buttons(button_texts: Array[String], dialog_type: String = "confirm"):
	"""確認ダイアログ用のボタンセットアップ"""
	clear_all_buttons()
	
	for i in range(button_texts.size()):
		var button_text = button_texts[i]
		var button_data = {
			"id": i,
			"type": dialog_type,
			"action": _get_button_action(button_text, i)
		}
		add_button(button_text, button_data)

## ボタンテキストからアクションを推定
func _get_button_action(button_text: String, index: int) -> String:
	"""ボタンテキストから標準的なアクションを推定"""
	var text_lower = button_text.to_lower()
	
	# 標準的なボタンパターンを認識
	if text_lower in ["ok", "はい", "yes", "確定", "実行"]:
		return "confirm"
	elif text_lower in ["cancel", "いいえ", "no", "キャンセル", "取消"]:
		return "cancel"
	elif text_lower in ["close", "閉じる", "終了"]:
		return "close"
	else:
		return "custom_%d" % index