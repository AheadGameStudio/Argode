# CustomCommandHandler.gd
# v2新機能: カスタムコマンド拡張フレームワーク（シンプル化）
extends Node
class_name CustomCommandHandler

# 汎用的な動的シグナル発行システム
signal dynamic_signal_emitted(signal_name: String, args: Array, source_command: String)
# 同期コマンド完了通知
signal synchronous_command_completed(command_name: String)

var adv_system: Node

# カスタムコマンド登録システム
var registered_commands: Dictionary = {}  # command_name -> BaseCustomCommand
var registered_callables: Dictionary = {}  # command_name -> Callable (簡易登録用)

# 動的シグナル接続システム
var signal_connections: Dictionary = {}  # signal_name -> Array[Callable]

func _ready():
	print("🎯 CustomCommandHandler initialized")

func initialize(advSystem: Node):
	"""ArgodeSystemから初期化される"""
	print("🔧 CustomCommandHandler.initialize() called")
	print("🔧 advSystem:", advSystem)
	print("🔧 advSystem.Player:", advSystem.Player if advSystem else "advSystem is null")
	
	adv_system = advSystem
	
	# AdvScriptPlayerのカスタムコマンドシグナルに接続
	if adv_system and adv_system.Player:
		print("🔧 Attempting to connect to Player:", adv_system.Player)
		adv_system.Player.custom_command_executed.connect(_on_custom_command_executed)
		print("✅ CustomCommandHandler connected to AdvScriptPlayer")
	else:
		push_warning("⚠️ Cannot connect to AdvScriptPlayer")
		if not adv_system:
			print("❌ advSystem is null")
		elif not adv_system.Player:
			print("❌ advSystem.Player is null")

func _on_custom_command_executed(command_name: String, parameters: Dictionary, line: String):
	"""カスタムコマンドが実行された時の処理"""
	print("🎯 Processing custom command: '", command_name, "' with params: ", parameters)
	print("🔍 Registered commands: ", registered_commands.keys())
	print("🔍 Command '", command_name, "' in registered_commands: ", registered_commands.has(command_name))
	
	# 1. 登録されたBaseCustomCommandを優先実行
	if registered_commands.has(command_name):
		var custom_command = registered_commands[command_name] as BaseCustomCommand
		await _execute_registered_command(custom_command, parameters)
		return
	
	# 2. 登録されたCallableを実行
	if registered_callables.has(command_name):
		var callable = registered_callables[command_name] as Callable
		await _execute_callable_command(callable, parameters)
		return
	
	# 3. 従来の組み込みコマンドをフォールバック実行（後で削除予定）
	await _execute_builtin_command(command_name, parameters, line)

# === カスタムコマンド登録API ===

func add_custom_command(custom_command: BaseCustomCommand) -> bool:
	"""BaseCustomCommandを継承したカスタムコマンドを登録"""
	if not custom_command:
		push_error("❌ Cannot register null custom command")
		return false
	
	if custom_command.command_name.is_empty():
		push_error("❌ Custom command name cannot be empty")
		return false
	
	registered_commands[custom_command.command_name] = custom_command
	print("✅ Registered custom command: ", custom_command.command_name)
	return true

func add_custom_command_by_callable(command_name: String, callable: Callable, is_sync: bool = false) -> bool:
	"""Callable（関数）ベースの簡易カスタムコマンド登録"""
	if command_name.is_empty():
		push_error("❌ Command name cannot be empty")
		return false
	
	if not callable.is_valid():
		push_error("❌ Invalid callable for command: ", command_name)
		return false
	
	registered_callables[command_name] = {
		"callable": callable,
		"is_sync": is_sync
	}
	print("✅ Registered callable command: ", command_name)
	return true

func remove_custom_command(command_name: String) -> bool:
	"""カスタムコマンドの登録を削除"""
	var removed = false
	if registered_commands.has(command_name):
		registered_commands.erase(command_name)
		removed = true
	if registered_callables.has(command_name):
		registered_callables.erase(command_name)
		removed = true
	
	if removed:
		print("✅ Removed custom command: ", command_name)
	
	return removed

func list_registered_commands() -> Array[String]:
	"""登録されているカスタムコマンド一覧を取得"""
	var commands: Array[String] = []
	commands.append_array(registered_commands.keys())
	commands.append_array(registered_callables.keys())
	return commands

func get_command_help(command_name: String) -> String:
	"""カスタムコマンドのヘルプテキストを取得"""
	if registered_commands.has(command_name):
		var custom_command = registered_commands[command_name] as BaseCustomCommand
		return custom_command.get_help_text()
	
	if registered_callables.has(command_name):
		return "Custom callable command: " + command_name
	
	# フォールバック：従来のヘルプ
	return _get_builtin_command_help(command_name)

# === 動的シグナル発行システム ===

func emit_custom_signal(signal_name: String, args: Array = [], source_command: String = ""):
	"""カスタムコマンドから呼び出される汎用シグナル発行メソッド"""
	print("📡 Emitting dynamic signal: ", signal_name, " from: ", source_command)
	print("   Args: ", args)
	
	# 1. 汎用シグナルを発行
	dynamic_signal_emitted.emit(signal_name, args, source_command)
	
	# 2. 登録された個別コールバックを実行
	if signal_connections.has(signal_name):
		var callbacks = signal_connections[signal_name]
		for callback in callbacks:
			if callback.is_valid():
				callback.callv(args)

func connect_to_dynamic_signal(signal_name: String, callback: Callable) -> bool:
	"""動的シグナルに対してコールバックを登録"""
	if not signal_connections.has(signal_name):
		signal_connections[signal_name] = []
	
	signal_connections[signal_name].append(callback)
	print("✅ Connected callback to dynamic signal: ", signal_name)
	return true

func disconnect_from_dynamic_signal(signal_name: String, callback: Callable) -> bool:
	"""動的シグナルからコールバックを削除"""
	if not signal_connections.has(signal_name):
		return false
	
	var callbacks = signal_connections[signal_name]
	var index = callbacks.find(callback)
	if index >= 0:
		callbacks.remove_at(index)
		print("✅ Disconnected callback from dynamic signal: ", signal_name)
		return true
	
	return false

func list_dynamic_signals() -> Array[String]:
	"""登録されている動的シグナル一覧を取得"""
	return signal_connections.keys()

# === 従来のシグナル互換性メソッド（簡略化） ===

func emit_window_shake(intensity: float, duration: float):
	"""互換性：ウィンドウシェイクシグナル"""
	emit_custom_signal("window_shake_requested", [intensity, duration], "compatibility")

func emit_screen_flash(color: Color, duration: float):
	"""互換性：画面フラッシュシグナル"""
	emit_custom_signal("screen_flash_requested", [color, duration], "compatibility")

func emit_camera_effect(effect_name: String, parameters: Dictionary):
	"""互換性：カメラエフェクトシグナル"""
	emit_custom_signal("camera_effect_requested", [effect_name, parameters], "compatibility")

# === 登録されたコマンド実行メソッド ===

func _execute_registered_command(custom_command: BaseCustomCommand, parameters: Dictionary) -> void:
	"""登録されたBaseCustomCommandを実行"""
	print("🎯 Executing registered command: ", custom_command.command_name)
	
	# パラメータバリデーション
	if not custom_command.validate_parameters(parameters):
		push_error("❌ Parameter validation failed for command: " + custom_command.command_name)
		return
	
	# 1. コマンドの基本実行
	if custom_command.is_synchronous():
		await custom_command.execute_async(parameters, adv_system)
		synchronous_command_completed.emit(custom_command.command_name)
	else:
		custom_command.execute(parameters, adv_system)
	
	# 2. 視覚効果がある場合は実行
	if custom_command.has_visual_effect():
		_execute_visual_effect_for_command(custom_command, parameters)

func _execute_visual_effect_for_command(custom_command: BaseCustomCommand, parameters: Dictionary):
	"""コマンドの視覚効果を実行"""
	print("✨ Executing visual effect for command: ", custom_command.command_name)
	
	# UIノードを取得（AdvGameUIまたは現在のメインシーン）
	var ui_node = _find_ui_node()
	if not ui_node:
		print("⚠️ No UI node found for visual effect")
		return
	
	# コマンド側の視覚効果を実行
	custom_command.execute_visual_effect(parameters, ui_node)

func _find_ui_node() -> Node:
	"""視覚効果用のUIノードを探す"""
	if not adv_system:
		return null
	
	# 1. ArgodeSystemからUIManagerを経由してUIを取得
	if adv_system.UIManager and adv_system.UIManager.has_method("get_current_ui"):
		var ui = adv_system.UIManager.get_current_ui()
		if ui:
			return ui
	
	# 2. シーンツリーから探す
	var tree = adv_system.get_tree()
	if not tree:
		return null
	
	var current_scene = tree.current_scene
	if not current_scene:
		return null
	
	# AdvGameUIまたはControlを探す
	var ui_candidates = []
	_find_ui_nodes_recursive(current_scene, ui_candidates)
	
	# 優先順位：AdvGameUI > Control
	for candidate in ui_candidates:
		if candidate.get_script() and candidate.get_script().get_global_name() == "AdvGameUI":
			return candidate
	
	if ui_candidates.size() > 0:
		return ui_candidates[0]  # 最初に見つかったControl
	
	return current_scene  # フォールバック

func _find_ui_nodes_recursive(node: Node, candidates: Array):
	"""再帰的にUIノードを探す"""
	if node is Control:
		candidates.append(node)
	
	for child in node.get_children():
		_find_ui_nodes_recursive(child, candidates)

func _execute_callable_command(callable_info: Dictionary, parameters: Dictionary) -> void:
	"""登録されたCallableを実行"""
	var callable = callable_info.callable as Callable
	var is_sync = callable_info.get("is_sync", false)
	
	print("🎯 Executing callable command")
	
	if is_sync:
		await callable.call(parameters, adv_system)
		synchronous_command_completed.emit("callable_command")
	else:
		callable.call(parameters, adv_system)

func _execute_builtin_command(command_name: String, parameters: Dictionary, line: String) -> void:
	"""従来の組み込みコマンドを実行（非推奨・フォールバック）"""
	print("⚠️ Using deprecated builtin command fallback for: ", command_name)
	print("   Consider registering this command as BaseCustomCommand")
	
	# 不明なコマンドの処理
	print("❓ Unknown custom command: ", command_name)
	_handle_unknown_command(command_name, parameters, line)

# === 不明コマンド処理 ===

func _handle_unknown_command(command_name: String, params: Dictionary, line: String):
	"""未知のカスタムコマンド処理"""
	print("❓ Unknown custom command '", command_name, "' - forwarding as generic signal")
	print("   Parameters: ", params)
	print("   Original line: ", line)
	
	# 汎用シグナルとして発行
	emit_custom_signal("unknown_command_executed", [command_name, params, line], "unknown")

# === 従来のヘルプシステム（互換性のため簡略化） ===

func _get_builtin_command_help(command_name: String) -> String:
	"""従来の組み込みコマンドのヘルプテキストを返す（非推奨）"""
	print("⚠️ Using deprecated builtin help for: ", command_name)
	return "Deprecated builtin command: " + command_name + " (use BaseCustomCommand instead)"