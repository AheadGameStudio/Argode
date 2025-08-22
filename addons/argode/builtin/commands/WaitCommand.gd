extends ArgodeCommandBase
class_name WaitCommand

# アクティブなタイマーの参照
var active_timer: Timer = null

func _ready():
	command_class_name = "WaitCommand"
	command_execute_name = "wait"
	is_also_tag = true
	tag_name = "w"  # {w=1.0}のように使用

func validate_args(args: Dictionary) -> bool:
	# 待機時間が指定されているかチェック
	return args.has("0") or args.has("time") or args.has("w")

func execute_core(args: Dictionary) -> void:
	ArgodeSystem.log("🔧 WaitCommand.execute_core() called with args: %s" % args)
	
	var wait_time: float = 1.0
	
	# 引数から待機時間を取得（デバッグログ付き）
	if args.has("time"):
		wait_time = float(args["time"])
		ArgodeSystem.log("📝 WaitCommand: Using 'time' argument: %s" % args["time"])
	elif args.has("w"):
		wait_time = float(args["w"])
		ArgodeSystem.log("📝 WaitCommand: Using 'w' argument: %s" % args["w"])
	elif args.has("0"):  # 無名引数として渡された場合
		wait_time = float(args["0"])
		ArgodeSystem.log("📝 WaitCommand: Using '0' argument: %s" % args["0"])
	else:
		ArgodeSystem.log("⚠️ WaitCommand: No valid time argument found, using default: 1.0")
	
	# ヘッドレスモードでは待機時間を短縮
	if ArgodeSystem.is_auto_play_mode():
		ArgodeSystem.log("⏱️ WaitCommand: AUTO-PLAY MODE - Reducing wait time from %.1fs to 0.1s" % wait_time)
		wait_time = 0.1  # ヘッドレスモードでは0.1秒に短縮
	else:
		ArgodeSystem.log("⏱️ WaitCommand: Waiting for %.1f seconds" % wait_time)
	
	# Engine.get_main_loop().create_timerを使用して待機
	ArgodeSystem.log("⏲️ WaitCommand: Starting wait for %.1f seconds" % wait_time)
	await Engine.get_main_loop().create_timer(wait_time).timeout
	
	# 待機完了処理
	ArgodeSystem.log("✅ WaitCommand: Wait completed - command finished")

func execute(args: Dictionary) -> void:
	# 下位互換性のためのメソッド - execute_coreを呼び出し
	ArgodeSystem.log("🔧 WaitCommand.execute() called (compatibility method) with args: %s" % args)
	await execute_core(args)

func _on_wait_completed():
	ArgodeSystem.log("✅ WaitCommand: Wait completed - resuming execution")
	
	# タイプライターを再開
	resume_typewriter()
	
	# StatementManagerの実行を再開
	var statement_manager = ArgodeSystem.StatementManager
	if statement_manager:
		ArgodeSystem.log("🔄 WaitCommand: Calling set_waiting_for_command(false)")
		statement_manager.set_waiting_for_command(false, "")
		ArgodeSystem.log("▶️ WaitCommand: StatementManager execution resumed")
		
		# ExecutionServiceに自動的に次のステートメントに進むことを期待
		# continue_execution()は呼び出さない（無限ループを避ける）
	else:
		ArgodeSystem.log("❌ WaitCommand: StatementManager reference is null!")
	
	# タイマーをクリーンアップ
	if active_timer and is_instance_valid(active_timer):
		active_timer.queue_free()
		active_timer = null
		ArgodeSystem.log("🧹 WaitCommand: Timer cleaned up")

## タイプライターを一時停止
func pause_typewriter():
	var typewriter_service = ArgodeSystem.TypewriterService
	if typewriter_service:
		typewriter_service.pause_typing()
		ArgodeSystem.log("⏸️ WaitCommand: Typewriter paused via TypewriterService")
	else:
		ArgodeSystem.log("⚠️ WaitCommand: TypewriterService not available")

## タイプライターを再開
func resume_typewriter():
	var typewriter_service = ArgodeSystem.TypewriterService
	if typewriter_service:
		typewriter_service.resume_typing()
		ArgodeSystem.log("▶️ WaitCommand: Typewriter resumed via TypewriterService")
	else:
		ArgodeSystem.log("⚠️ WaitCommand: TypewriterService not available")
