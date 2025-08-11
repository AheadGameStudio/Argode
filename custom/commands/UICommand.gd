# UICommand.gd
# Controlベースのシーンを表示・制御するためのカスタムコマンド
class_name UICommand
extends BaseCustomCommand

func _init():
	command_name = "ui"
	description = "UI要素を制御します"
	help_text = "ui show path/to/scene.tscn [at position] [with transition]"
	
	set_parameter_info("subcommand", "string", true, "", "show/hide/call のいずれか")
	set_parameter_info("scene_path", "string", false, "", "表示するシーンファイルのパス")
	set_parameter_info("position", "string", false, "center", "表示位置 (left/center/right)")
	set_parameter_info("transition", "string", false, "none", "トランジション効果")

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
		"hide":
			_execute_hide(args.slice(1), adv_system)
		"call":
			_execute_call(args.slice(1), adv_system)
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
	if args.size() < 1:
		push_error("❌ ui show: シーンパスが必要です")
		return
	
	var scene_path = args[0]
	var position = "center"
	var transition = "none"
	
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
	var scene_resource = load(scene_path)
	if not scene_resource:
		push_error("❌ Failed to load UI scene: " + scene_path)
		return
	
	var scene_instance = scene_resource.instantiate()
	if not scene_instance or not scene_instance is Control:
		push_error("❌ Scene is not a Control: " + scene_path)
		if scene_instance:
			scene_instance.queue_free()
		return
	
	# LayerManagerで表示
	if adv_system.layer_manager:
		var success = adv_system.layer_manager.show_control_scene(scene_instance, position, transition)
		if not success:
			push_error("❌ Failed to display UI scene")
			scene_instance.queue_free()
		else:
			emit_dynamic_signal("ui_scene_shown", [scene_path, position, transition], adv_system)
	else:
		push_error("❌ LayerManager not available")
		scene_instance.queue_free()

func _execute_hide(_args: PackedStringArray, _adv_system: Node) -> void:
	"""UIシーンを非表示"""
	push_warning("⚠️ ui hide: 未実装")
	log_command("UI hide: not implemented")

func _execute_call(_args: PackedStringArray, _adv_system: Node) -> void:
	"""UIシーンを呼び出し（モーダル表示）"""
	push_warning("⚠️ ui call: 未実装")
	log_command("UI call: not implemented")
