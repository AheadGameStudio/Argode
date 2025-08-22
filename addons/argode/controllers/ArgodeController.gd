# ArgodeController.gd (Service Layer Pattern統合版)
extends Node

class_name ArgodeController

## フレームワーク全体のプレイヤー入力を一元管理する
## このクラスは、Godotのプロジェクト設定で定義された入力アクションを使い、
## 入力イベントを他のマネージャーやサービスに伝達する。
## Service Layer Pattern: InputHandlerService との協調により高度な入力制御を実現

# 入力が現在許可されているかどうか
var _is_input_enabled: bool = true

# Service Layer Pattern: InputHandlerService統合
var input_handler_service: ArgodeInputHandlerService = null

# 入力アクションが押されたときに送信されるシグナル（InputHandlerService連携）
signal input_action_pressed(action_name)
# 入力アクションが離されたときに送信されるシグナル
signal input_action_released(action_name)
# 有効な入力が処理されたときのシグナル（Service層統合）
signal input_received(action_name)

func _ready():
	_initialize_service_integration()
	setup_argode_default_bindings()
	ArgodeSystem.log_workflow("ArgodeController initialized with Service Layer integration")

## Service層統合の初期化
func _initialize_service_integration():
	# InputHandlerServiceとの連携を後から設定（循環参照回避）
	# StatementManagerが初期化されたときに設定される
	pass

## InputHandlerServiceとの連携を設定（StatementManagerから呼び出し）
func connect_input_handler_service(service: ArgodeInputHandlerService):
	input_handler_service = service
	if input_handler_service:
		# Service層からの有効入力シグナルを中継
		if not input_handler_service.valid_input_received.is_connected(_on_valid_input_from_service):
			input_handler_service.valid_input_received.connect(_on_valid_input_from_service)
		
		# InputHandlerServiceにControllerを設定
		input_handler_service.controller = self
		
		# 入力アクションシグナルを接続
		if not input_action_pressed.is_connected(input_handler_service._on_controller_input):
			input_action_pressed.connect(input_handler_service._on_controller_input)
		
		ArgodeSystem.log_workflow("InputHandlerService connected to ArgodeController")

## Service層からの有効入力を受信
func _on_valid_input_from_service(action_name: String):
	# 他のシステムに入力を通知
	input_received.emit(action_name)
	ArgodeSystem.log_debug_detail("Valid input processed: %s" % action_name)

# Godotの入力イベントシステムを使用（キー＋マウス統合処理）
func _input(event: InputEvent):
	if not _is_input_enabled:
		return
	
	# キーイベント処理
	if event is InputEventKey:
		_process_input_event(event)
	
	# マウスボタンイベント処理
	elif event is InputEventMouseButton:
		_process_input_event(event)
	
	# 入力イベントを他のノードにも伝播させる
	# get_viewport().set_input_as_handled() は呼ばない

## 統一された入力イベント処理
func _process_input_event(event: InputEvent):
	# デバッグログ: イベント詳細を出力
	if event is InputEventMouseButton:
		print("🖱️ Mouse event in _process_input_event: button=%d, pressed=%s" % [event.button_index, event.pressed])
	elif event is InputEventKey:
		print("⌨️ Key event in _process_input_event: key=%s, pressed=%s" % [OS.get_keycode_string(event.keycode), event.pressed])
	
	# 入力されたイベントに対応するアクションを検索
	# argode_*アクションを優先的にチェック
	var found_action = false
	var actions = InputMap.get_actions()
	
	# argode_*アクションを最初にチェック
	for action in actions:
		if action.begins_with("argode_") and InputMap.action_has_event(action, event):
			print("✅ Found matching action: %s" % action)
			found_action = true
			if event.pressed:
				_on_action_just_pressed(action)
			elif not event.pressed:
				_on_action_just_released(action)
			break
	
	# argode_*アクションが見つからない場合、他のアクションもチェック
	if not found_action:
		for action in actions:
			if not action.begins_with("argode_") and InputMap.action_has_event(action, event):
				print("✅ Found matching action: %s" % action)
				found_action = true
				if event.pressed:
					_on_action_just_pressed(action)
				elif not event.pressed:
					_on_action_just_released(action)
				break
	
	if not found_action:
		print("❌ No matching action found for event")

func _on_action_just_pressed(action_name: String):
	# 特定のアクションが押されたときの処理
	# 例: "ui_accept"アクションが押された場合、対話マネージャーに通知
	# ArgodeSystem.get_manager("DialogueManager").process_input("accept")
	
	# input_action_pressedシグナルを送信（Service層で処理される）
	ArgodeSystem.log_debug_detail("Input action pressed: %s" % action_name)
	ArgodeSystem.log_workflow("🎮 INPUT PRESSED: %s" % action_name)  # より目立つログ
	input_action_pressed.emit(action_name)

func _on_action_just_released(action_name: String):
	# 特定のアクションが離されたときの処理
	
	# input_action_releasedシグナルを送信
	input_action_released.emit(action_name)

## 入力を有効にする（Service層統合）
func enable_input(reason: String = ""):
	_is_input_enabled = true
	if input_handler_service:
		input_handler_service.enable_input()
	if reason != "":
		ArgodeSystem.log_workflow("Input enabled: %s" % reason)

## 入力を無効にする（Service層統合）
func disable_input(reason: String = ""):
	_is_input_enabled = false
	if input_handler_service:
		input_handler_service.disable_input(reason)
	if reason != "":
		ArgodeSystem.log_workflow("Input disabled: %s" % reason)

## === InputMap動的管理機能 ===

## 新しい入力アクションを追加
func add_input_action(action_name: String, deadzone: float = 0.5) -> bool:
	if InputMap.has_action(action_name):
		ArgodeSystem.log_critical("Input action '%s' already exists" % action_name)
		return false
	
	InputMap.add_action(action_name, deadzone)
	ArgodeSystem.log_workflow("Added input action: %s (deadzone: %.2f)" % [action_name, deadzone])
	return true

## 入力アクションを削除
func remove_input_action(action_name: String) -> bool:
	if not InputMap.has_action(action_name):
		ArgodeSystem.log_critical("Input action '%s' does not exist" % action_name)
		return false
	
	InputMap.erase_action(action_name)
	ArgodeSystem.log_workflow("Removed input action: %s" % action_name)
	return true

## 入力アクションにキーバインドを追加
func add_key_to_action(action_name: String, keycode: Key, physical: bool = false) -> bool:
	if not InputMap.has_action(action_name):
		ArgodeSystem.log_critical("Input action '%s' does not exist" % action_name)
		return false
	
	var event = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode if physical else KEY_NONE
	
	InputMap.action_add_event(action_name, event)
	ArgodeSystem.log_debug_detail("Added key %s to action '%s'" % [OS.get_keycode_string(keycode), action_name])
	return true

## 入力アクションにマウスボタンを追加
func add_mouse_to_action(action_name: String, mouse_button: MouseButton) -> bool:
	if not InputMap.has_action(action_name):
		ArgodeSystem.log_critical("Input action '%s' does not exist" % action_name)
		return false
	
	var event = InputEventMouseButton.new()
	event.button_index = mouse_button
	
	InputMap.action_add_event(action_name, event)
	ArgodeSystem.log_workflow("🖱️ Added mouse button %d to action '%s'" % [mouse_button, action_name])
	return true

## Argode用デフォルトキーバインドを設定
func setup_argode_default_bindings():
	var argode_bindings = {
		"argode_advance": {
			"keys": [KEY_SPACE, KEY_ENTER],
			"mouse_buttons": [MOUSE_BUTTON_LEFT],
			"deadzone": 0.2
		},
		"argode_skip": {
			"keys": [KEY_CTRL],
			"deadzone": 0.2
		},
		"argode_menu": {
			"keys": [KEY_ESCAPE, KEY_M],
			"mouse_buttons": [MOUSE_BUTTON_RIGHT],
			"deadzone": 0.2
		}
	}
	
	ArgodeSystem.log_workflow("Setting up Argode default key bindings...")
	
	# ui_acceptからEnterキーを削除（優先順位の問題を回避）
	if InputMap.has_action("ui_accept"):
		var ui_accept_events = InputMap.action_get_events("ui_accept")
		for event in ui_accept_events:
			if event is InputEventKey and event.keycode == KEY_ENTER:
				InputMap.action_erase_event("ui_accept", event)
				ArgodeSystem.log_workflow("🔧 Removed Enter key from ui_accept to avoid conflicts")
	
	var result = add_key_binding_set(argode_bindings)
	debug_print_input_map()
	return result

## キーバインドセットを一括で追加
func add_key_binding_set(bindings: Dictionary) -> bool:
	var success = true
	for action_name in bindings:
		var binding_data = bindings[action_name]
		
		# アクションを追加（存在しない場合）
		if not InputMap.has_action(action_name):
			var deadzone = binding_data.get("deadzone", 0.5)
			add_input_action(action_name, deadzone)
		
		# キーバインドを追加
		if binding_data.has("keys"):
			for key in binding_data.keys:
				if not add_key_to_action(action_name, key):
					success = false
		
		# マウスバインドを追加
		if binding_data.has("mouse_buttons"):
			for mouse_button in binding_data.mouse_buttons:
				if not add_mouse_to_action(action_name, mouse_button):
					success = false
	
	return success

## 現在の入力マップをログ出力（デバッグ用）
func debug_print_input_map():
	ArgodeSystem.log_debug_detail("=== Current InputMap ===")
	for action in InputMap.get_actions():
		var events = InputMap.action_get_events(action)
		var deadzone = InputMap.action_get_deadzone(action)
		ArgodeSystem.log_debug_detail("Action: %s (deadzone: %.2f)" % [action, deadzone])
		for event in events:
			ArgodeSystem.log_debug_detail("  - %s" % event)
	ArgodeSystem.log_debug_detail("========================")

# ===========================
# Stage 5: Service Layer Pattern拡張
# ===========================

## 入力が有効かどうかを確認
func is_input_enabled() -> bool:
	return _is_input_enabled

## 入力処理の詳細状態を取得
func get_input_status() -> Dictionary:
	return {
		"enabled": _is_input_enabled,
		"input_handler_service": input_handler_service != null,
		"argode_system": ArgodeSystem != null
	}
