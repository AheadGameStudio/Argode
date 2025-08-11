# UICommand.gd
# Controlベースのシーンを表示・制御するためのカスタムコマンド
class_name UICommand
extends BaseCustomCommand

func _init():
	command_name = "ui"
	description = "UI要素を制御します"
	help_text = "ui show path/to/scene.tscn [at position] [with transition] | ui free [scene_path] | ui list | ui hide | ui call path/to/scene.tscn | ui close [scene_path]"
	
	set_parameter_info("subcommand", "string", true, "", "show/free/list/hide/call/close のいずれか")
	set_parameter_info("scene_path", "string", false, "", "表示するシーンファイルのパス")
	set_parameter_info("position", "string", false, "center", "表示位置 (left/center/right)")
	set_parameter_info("transition", "string", false, "none", "トランジション効果")

# === UIシーン追跡システム ===
# 表示中のUIシーンを追跡するための辞書（シーンパス -> シーンインスタンス）
var active_ui_scenes: Dictionary = {}

# === call_screen スタック管理 ===
# call_screenで表示されたシーンのスタック（後入先出）
var call_screen_stack: Array[String] = []
# call_screenで表示されたシーンの結果を保存
var call_screen_results: Dictionary = {}

func execute(params: Dictionary, adv_system: Node) -> void:
	var raw_params = params.get("_raw", "")
	var args = _parse_raw_params(raw_params)
	
	if args.size() < 1:
		push_error("❌ ui command: サブコマンドが必要です")
		return
	
	var subcommand = args[0]
	log_command("UI command: " + subcommand)
	
	match subcommand:
		"show":
			_execute_show(args.slice(1), adv_system)
		"free":
			_execute_free(args.slice(1), adv_system)
		"list":
			_execute_list(args.slice(1), adv_system)
		"hide":
			_execute_hide(args.slice(1), adv_system)
		"call":
			_execute_call(args.slice(1), adv_system)
		"close":
			_execute_close(args.slice(1), adv_system)
		_:
			push_error("❌ ui command: 未知のサブコマンド: " + subcommand)

func _parse_raw_params(raw_params: String) -> PackedStringArray:
	"""生パラメータを解析してPackedStringArrayに変換"""
	var args = PackedStringArray()
	var tokens = raw_params.strip_edges().split(" ")
	
	for token in tokens:
		if token.length() > 0:
			args.append(token)
	
	return args

func _execute_show(args: PackedStringArray, adv_system: Node) -> void:
	"""UIシーンを表示"""
	print("🎯 [UICommand] _execute_show called with args:", args)
	
	if args.size() < 1:
		push_error("❌ ui show: シーンパスが必要です")
		return
	
	var scene_path = args[0]
	var position = "center"
	var transition = "none"
	
	print("🎯 [UICommand] Initial scene_path:", scene_path)
	
	# 既に表示中のシーンをチェック
	if scene_path in active_ui_scenes:
		var existing_scene = active_ui_scenes[scene_path]
		if existing_scene and is_instance_valid(existing_scene):
			print("⚠️ Scene already active:", scene_path)
			push_warning("⚠️ UI scene already displayed: " + scene_path + " (use 'ui free' first)")
			log_command("UI show: scene already active - " + scene_path)
			return
		else:
			# 無効なインスタンスは追跡から削除
			active_ui_scenes.erase(scene_path)
			print("🧹 Cleaned up invalid scene reference:", scene_path)
	
	# オプション引数を解析
	var i = 1
	while i < args.size():
		var arg = args[i]
		if arg == "at" and i + 1 < args.size():
			position = args[i + 1]
			i += 2
		elif arg == "with" and i + 1 < args.size():
			transition = args[i + 1]
			i += 2
		else:
			i += 1
	
	print("🎬 UI Command: Showing scene:", scene_path, "at", position, "with", transition)
	log_command("UI show: " + scene_path + " at " + position + " with " + transition)
	
	# シーンを読み込み
	print("🔍 Attempting to load scene:", scene_path)
	print("🔍 ResourceLoader.exists():", ResourceLoader.exists(scene_path))
	
	# より安全な読み込み処理
	var scene_resource = null
	if ResourceLoader.exists(scene_path):
		scene_resource = ResourceLoader.load(scene_path)
		print("🔍 Scene resource loaded via ResourceLoader:", scene_resource != null)
	else:
		print("❌ Scene file does not exist:", scene_path)
		push_error("❌ Scene file does not exist: " + scene_path)
		return
	
	if not scene_resource:
		print("❌ Failed to load scene resource")
		push_error("❌ Failed to load UI scene: " + scene_path)
		return
	
	print("🔍 Scene resource type:", scene_resource.get_class())
	print("🔍 Attempting to instantiate scene...")
	
	var scene_instance = null
	# より安全なインスタンス化
	if scene_resource.has_method("instantiate"):
		scene_instance = scene_resource.instantiate()
	else:
		print("❌ Scene resource does not have instantiate method")
		push_error("❌ Invalid scene resource: " + scene_path)
		return
	
	print("🔍 Scene instantiated:", scene_instance != null)
	if scene_instance:
		print("🔍 Scene instance type:", scene_instance.get_class())
		print("🔍 Scene is Control:", scene_instance is Control)
		print("🔍 Scene is Node:", scene_instance is Node)
	else:
		print("🔍 Scene instance is null")
	
	if not scene_instance:
		push_error("❌ Failed to instantiate scene: " + scene_path)
		return
		
	if not scene_instance is Control:
		push_error("❌ Scene is not a Control: " + scene_path + " (Type: " + scene_instance.get_class() + ")")
		scene_instance.queue_free()
		return
	
	print("✅ Scene validation passed")
	
	# LayerManagerで表示
	print("🔍 Checking LayerManager...")
	if adv_system.LayerManager:
		print("✅ LayerManager found:", adv_system.LayerManager)
		
		# LayerManagerの内部状態をチェック
		print("🔍 LayerManager ui_layer:", adv_system.LayerManager.ui_layer)
		print("🔍 LayerManager ui_layer type:", type_string(typeof(adv_system.LayerManager.ui_layer)) if adv_system.LayerManager.ui_layer else "null")
		print("🔍 LayerManager ui_layer valid:", adv_system.LayerManager.ui_layer != null)
		
		# もしui_layerがnullの場合、layer_infoを確認
		if not adv_system.LayerManager.ui_layer:
			print("❌ UI layer is null! Layer info:", adv_system.LayerManager.get_layer_info())
		
		print("🔍 Calling show_control_scene with:", scene_instance, position, transition)
		var success = adv_system.LayerManager.show_control_scene(scene_instance, position, transition)
		print("🔍 show_control_scene returned:", success)
		print("🔍 show_control_scene returned:", success)
		if not success:
			push_error("❌ Failed to display UI scene")
			scene_instance.queue_free()
		else:
			print("✅ UI scene displayed successfully")
			# シーン追跡に追加
			active_ui_scenes[scene_path] = scene_instance
			print("📝 Scene tracked:", scene_path, "Total active scenes:", active_ui_scenes.size())
			emit_dynamic_signal("ui_scene_shown", [scene_path, position, transition], adv_system)
	else:
		print("❌ LayerManager not available")
		push_error("❌ LayerManager not available")
		scene_instance.queue_free()

func _execute_free(args: PackedStringArray, adv_system: Node) -> void:
	"""UIシーンを解放（削除）"""
	print("🎯 [UICommand] _execute_free called with args:", args)
	
	if args.size() == 0:
		# 引数なしの場合：全てのUIシーンを解放
		_free_all_ui_scenes(adv_system)
	else:
		# 引数ありの場合：指定されたシーンを解放
		var scene_path = args[0]
		_free_specific_ui_scene(scene_path, adv_system)

func _free_all_ui_scenes(adv_system: Node) -> void:
	"""全ての追跡中UIシーンを解放"""
	print("🗑️ [UICommand] Freeing all UI scenes...")
	
	if active_ui_scenes.is_empty():
		print("ℹ️ No active UI scenes to free")
		log_command("UI free all: no scenes active")
		return
	
	var freed_count = 0
	var scene_paths = active_ui_scenes.keys()
	
	for scene_path in scene_paths:
		var scene_instance = active_ui_scenes[scene_path]
		if scene_instance and is_instance_valid(scene_instance):
			print("🗑️ Freeing UI scene:", scene_path)
			
			# call_screenの場合はシグナル接続を解除
			if scene_path in call_screen_stack:
				_disconnect_call_screen_signals(scene_instance)
			
			scene_instance.queue_free()
			freed_count += 1
		else:
			print("⚠️ Scene instance invalid or null for:", scene_path)
		
		# 追跡から削除
		active_ui_scenes.erase(scene_path)
	
	# call_screenスタックと結果もクリア
	if not call_screen_stack.is_empty():
		print("🗑️ Clearing call screen stack:", call_screen_stack.size(), "items")
		call_screen_stack.clear()
	
	if not call_screen_results.is_empty():
		print("🗑️ Clearing call screen results:", call_screen_results.size(), "items")
		call_screen_results.clear()
	
	print("✅ Freed", freed_count, "UI scenes")
	log_command("UI free all: freed " + str(freed_count) + " scenes")
	emit_dynamic_signal("ui_scenes_freed", [freed_count], adv_system)

func _free_specific_ui_scene(scene_path: String, adv_system: Node) -> void:
	"""特定のUIシーンを解放"""
	print("🗑️ [UICommand] Freeing specific UI scene:", scene_path)
	
	if not scene_path in active_ui_scenes:
		print("⚠️ Scene not found in active scenes:", scene_path)
		push_warning("⚠️ UI scene not active: " + scene_path)
		log_command("UI free: scene not active - " + scene_path)
		return
	
	var scene_instance = active_ui_scenes[scene_path]
	
	if scene_instance and is_instance_valid(scene_instance):
		print("🗑️ Freeing UI scene instance:", scene_instance.get_path())
		
		# call_screenの場合はシグナル接続を解除
		if scene_path in call_screen_stack:
			_disconnect_call_screen_signals(scene_instance)
			# call_screenスタックからも削除
			var stack_index = call_screen_stack.find(scene_path)
			if stack_index >= 0:
				call_screen_stack.remove_at(stack_index)
				print("📚 Removed from call stack")
		
		scene_instance.queue_free()
		print("✅ UI scene freed successfully")
	else:
		print("⚠️ Scene instance invalid or null")
		push_warning("⚠️ UI scene instance invalid: " + scene_path)
	
	# 追跡から削除
	active_ui_scenes.erase(scene_path)
	
	# 結果もクリア
	if scene_path in call_screen_results:
		call_screen_results.erase(scene_path)
		print("🗑️ Cleared call screen result")
	
	print("📝 Scene removed from tracking. Remaining scenes:", active_ui_scenes.size())
	
	log_command("UI free: " + scene_path)
	emit_dynamic_signal("ui_scene_freed", [scene_path], adv_system)

func _execute_list(_args: PackedStringArray, adv_system: Node) -> void:
	"""アクティブなUIシーンをリスト表示"""
	print("📋 [UICommand] Listing active UI scenes...")
	
	if active_ui_scenes.is_empty():
		print("ℹ️ No active UI scenes")
		log_command("UI list: no active scenes")
	else:
		print("📋 Active UI scenes (" + str(active_ui_scenes.size()) + "):")
		var index = 1
		for scene_path in active_ui_scenes.keys():
			var scene_instance = active_ui_scenes[scene_path]
			var status = "valid" if (scene_instance and is_instance_valid(scene_instance)) else "invalid"
			var is_call_screen = scene_path in call_screen_stack
			var scene_type = " [call_screen]" if is_call_screen else " [show]"
			print("  ", index, ". ", scene_path, " (", status, ")", scene_type)
			index += 1
	
	# call_screenスタックの情報も表示
	if not call_screen_stack.is_empty():
		print("📚 Call screen stack (" + str(call_screen_stack.size()) + "):")
		for i in range(call_screen_stack.size()):
			var stack_scene = call_screen_stack[i]
			var depth_indicator = "  " + "└─".repeat(i) + " "
			print(depth_indicator, i + 1, ". ", stack_scene)
	else:
		print("📚 Call screen stack: empty")
	
	# 結果待ちのcall_screenがあるか表示
	if not call_screen_results.is_empty():
		print("📋 Call screen results:")
		for scene_path in call_screen_results.keys():
			print("  - ", scene_path, ": ", call_screen_results[scene_path])
	
	var total_scenes = active_ui_scenes.size()
	var call_scenes = call_screen_stack.size()
	log_command("UI list: " + str(total_scenes) + " active scenes (" + str(call_scenes) + " call_screens)")
	emit_dynamic_signal("ui_scenes_listed", [active_ui_scenes.keys(), call_screen_stack], adv_system)

func _execute_hide(_args: PackedStringArray, _adv_system: Node) -> void:
	"""UIシーンを非表示"""
	push_warning("⚠️ ui hide: 未実装")
	log_command("UI hide: not implemented")

func _execute_call(args: PackedStringArray, adv_system: Node) -> void:
	"""UIシーンを呼び出し（モーダル表示・スタック管理）"""
	print("🎯 [UICommand] _execute_call called with args:", args)
	
	if args.size() < 1:
		push_error("❌ ui call: シーンパスが必要です")
		return
	
	var scene_path = args[0]
	var position = "center"
	var transition = "fade"
	
	print("🎯 [UICommand] Call screen:", scene_path)
	
	# 既に表示中のシーンをチェック
	if scene_path in active_ui_scenes:
		var existing_scene = active_ui_scenes[scene_path]
		if existing_scene and is_instance_valid(existing_scene):
			print("⚠️ Scene already active:", scene_path)
			push_warning("⚠️ UI scene already displayed: " + scene_path + " (use 'ui close' first)")
			log_command("UI call: scene already active - " + scene_path)
			return
		else:
			# 無効なインスタンスは追跡から削除
			active_ui_scenes.erase(scene_path)
			print("🧹 Cleaned up invalid scene reference:", scene_path)
	
	# オプション引数を解析
	var i = 1
	while i < args.size():
		var arg = args[i]
		if arg == "at" and i + 1 < args.size():
			position = args[i + 1]
			i += 2
		elif arg == "with" and i + 1 < args.size():
			transition = args[i + 1]
			i += 2
		else:
			i += 1
	
	print("🎬 UI Call Screen: ", scene_path, "at", position, "with", transition)
	log_command("UI call: " + scene_path + " at " + position + " with " + transition)
	
	# シーンを読み込み
	print("🔍 Attempting to load call screen:", scene_path)
	
	var scene_resource = null
	if ResourceLoader.exists(scene_path):
		scene_resource = ResourceLoader.load(scene_path)
		print("🔍 Call screen resource loaded:", scene_resource != null)
	else:
		print("❌ Call screen file does not exist:", scene_path)
		push_error("❌ Call screen file does not exist: " + scene_path)
		return
	
	if not scene_resource:
		print("❌ Failed to load call screen resource")
		push_error("❌ Failed to load call screen: " + scene_path)
		return
	
	var scene_instance = null
	if scene_resource.has_method("instantiate"):
		scene_instance = scene_resource.instantiate()
	else:
		print("❌ Call screen resource does not have instantiate method")
		push_error("❌ Invalid call screen resource: " + scene_path)
		return
	
	if not scene_instance or not scene_instance is Control:
		push_error("❌ Call screen is not a Control: " + scene_path)
		if scene_instance:
			scene_instance.queue_free()
		return
	
	print("✅ Call screen validation passed")
	
	# LayerManagerで表示
	if adv_system.LayerManager:
		var success = adv_system.LayerManager.show_control_scene(scene_instance, position, transition)
		if success:
			print("✅ Call screen displayed successfully")
			# シーン追跡に追加
			active_ui_scenes[scene_path] = scene_instance
			# call_screenスタックに追加
			call_screen_stack.append(scene_path)
			print("📝 Call screen tracked:", scene_path)
			print("📚 Call stack size:", call_screen_stack.size())
			print("📚 Call stack:", call_screen_stack)
			
			# call_screenの結果待ち用シグナル接続
			_connect_call_screen_signals(scene_instance, scene_path, adv_system)
			
			emit_dynamic_signal("ui_call_screen_shown", [scene_path, position, transition], adv_system)
		else:
			push_error("❌ Failed to display call screen")
			scene_instance.queue_free()
	else:
		push_error("❌ LayerManager not available")
		scene_instance.queue_free()

func _execute_close(args: PackedStringArray, adv_system: Node) -> void:
	"""call_screenで表示されたUIシーンを閉じる"""
	print("🎯 [UICommand] _execute_close called with args:", args)
	
	var scene_path_to_close = ""
	
	if args.size() == 0:
		# 引数なしの場合：最後にcall_screenで表示されたシーンを閉じる
		if call_screen_stack.is_empty():
			print("ℹ️ No call screens to close")
			push_warning("⚠️ No call screens active")
			log_command("UI close: no call screens active")
			return
		
		scene_path_to_close = call_screen_stack[-1]  # 最後の要素
		print("🔚 Closing top call screen:", scene_path_to_close)
	else:
		# 引数ありの場合：指定されたシーンを閉じる
		scene_path_to_close = args[0]
		print("🔚 Closing specific call screen:", scene_path_to_close)
		
		# 指定されたシーンがcall_screenスタックにあるかチェック
		if not scene_path_to_close in call_screen_stack:
			print("⚠️ Scene not in call stack:", scene_path_to_close)
			push_warning("⚠️ Scene not opened with call_screen: " + scene_path_to_close)
			log_command("UI close: not a call screen - " + scene_path_to_close)
			return
	
	# シーンを閉じる処理
	_close_call_screen(scene_path_to_close, adv_system)

func _close_call_screen(scene_path: String, adv_system: Node) -> void:
	"""call_screenで表示されたシーンを実際に閉じる"""
	print("🗑️ [UICommand] Closing call screen:", scene_path)
	
	# アクティブシーンから削除
	if scene_path in active_ui_scenes:
		var scene_instance = active_ui_scenes[scene_path]
		if scene_instance and is_instance_valid(scene_instance):
			print("🗑️ Freeing call screen instance:", scene_instance.get_path())
			
			# シグナル接続を解除
			_disconnect_call_screen_signals(scene_instance)
			
			scene_instance.queue_free()
			print("✅ Call screen freed successfully")
		else:
			print("⚠️ Call screen instance invalid or null")
		
		active_ui_scenes.erase(scene_path)
	
	# call_screenスタックから削除
	var stack_index = call_screen_stack.find(scene_path)
	if stack_index >= 0:
		call_screen_stack.remove_at(stack_index)
		print("📚 Removed from call stack. Remaining:", call_screen_stack.size())
		print("📚 Updated call stack:", call_screen_stack)
	
	# 結果をクリア
	if scene_path in call_screen_results:
		var result = call_screen_results[scene_path]
		call_screen_results.erase(scene_path)
		print("📋 Call screen result:", result)
	
	log_command("UI close: " + scene_path)
	emit_dynamic_signal("ui_call_screen_closed", [scene_path], adv_system)

func _connect_call_screen_signals(scene_instance: Node, scene_path: String, adv_system: Node) -> void:
	"""call_screenのシグナル接続を行う"""
	print("🔗 [UICommand] Connecting call screen signals for:", scene_path)
	
	# シーンが結果を返すシグナルがあるかチェック
	if scene_instance.has_signal("screen_result"):
		print("🔗 Connecting screen_result signal")
		scene_instance.screen_result.connect(_on_call_screen_result.bind(scene_path, adv_system))
	
	# シーンが自分自身を閉じるシグナルがあるかチェック
	if scene_instance.has_signal("close_screen"):
		print("🔗 Connecting close_screen signal")
		scene_instance.close_screen.connect(_on_call_screen_close.bind(scene_path, adv_system))

func _disconnect_call_screen_signals(scene_instance: Node) -> void:
	"""call_screenのシグナル接続を解除"""
	print("🔗 [UICommand] Disconnecting call screen signals")
	
	# 接続されているシグナルを安全に切断
	if scene_instance.has_signal("screen_result"):
		if scene_instance.screen_result.is_connected(_on_call_screen_result):
			scene_instance.screen_result.disconnect(_on_call_screen_result)
	
	if scene_instance.has_signal("close_screen"):
		if scene_instance.close_screen.is_connected(_on_call_screen_close):
			scene_instance.close_screen.disconnect(_on_call_screen_close)

func _on_call_screen_result(result: Variant, scene_path: String, adv_system: Node) -> void:
	"""call_screenから結果が返ってきた時の処理"""
	print("📋 [UICommand] Call screen result received:", result, "from:", scene_path)
	
	# 結果を保存
	call_screen_results[scene_path] = result
	
	# シーンを自動的に閉じる
	_close_call_screen(scene_path, adv_system)
	
	# 結果をシグナルで通知
	emit_dynamic_signal("ui_call_screen_result", [scene_path, result], adv_system)

func _on_call_screen_close(scene_path: String, adv_system: Node) -> void:
	"""call_screenが自分自身を閉じる時の処理"""
	print("🔚 [UICommand] Call screen requested close:", scene_path)
	_close_call_screen(scene_path, adv_system)
