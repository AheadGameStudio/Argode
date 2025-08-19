extends ArgodeCommandBase
class_name WaitCommand

# アクティブなタイマーの参照
var active_timer: Timer = null

func _ready():
	command_class_name = "WaitCommand"
	command_execute_name = "wait"
	is_also_tag = true
	tag_name = "w"  # {w=1.0}のように使用

func execute(args: Dictionary) -> void:
	var wait_time: float = 1.0
	
	# 引数から待機時間を取得
	if args.has("time"):
		wait_time = float(args["time"])
	elif args.has("w"):
		wait_time = float(args["w"])
	elif args.has("0"):  # 無名引数として渡された場合
		wait_time = float(args["0"])
	
	ArgodeSystem.log("⏱️ WaitCommand: Waiting for %.1f seconds" % wait_time)
	
	# タイプライターを一時停止
	pause_typewriter()
	
	# タイマーを作成して指定時間後に再開
	active_timer = Timer.new()
	active_timer.wait_time = wait_time
	active_timer.one_shot = true
	active_timer.timeout.connect(_on_wait_completed)
	
	# StatementManagerのシーンツリーに追加
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager and statement_manager.controller:
		statement_manager.controller.add_child(active_timer)
		active_timer.start()
	else:
		ArgodeSystem.log("❌ WaitCommand: Cannot create timer - no controller reference", 2)
		resume_typewriter()  # フォールバック: すぐに再開

func _on_wait_completed():
	ArgodeSystem.log("✅ WaitCommand: Wait completed")
	
	# タイプライターを再開
	resume_typewriter()
	
	# タイマーを削除
	if active_timer:
		active_timer.queue_free()
		active_timer = null
