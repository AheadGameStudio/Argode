#!/usr/bin/env -S godot --headless --script
# UID生成ユーティリティ - コマンドラインから実行可能
# 使用方法: godot --headless --script tools/generate_uid.gd --quit

extends SceneTree

func _init():
	print("🔧 UID Generator Utility")
	print("====================================================")
	
	# 複数のUIDを一度に生成（オプション）
	var count = 1
	var args = OS.get_cmdline_args()
	
	# コマンドライン引数で生成数を指定可能
	for i in range(args.size()):
		if args[i] == "--count" and i + 1 < args.size():
			count = args[i + 1].to_int()
			break
	
	# 指定された数のUIDを生成
	for i in range(count):
		# 1. 新しいユニークIDを64ビット整数として生成
		var new_id: int = ResourceUID.create_id()
		
		# 2. 生成したIDを "uid://" から始まるテキスト形式に変換
		var uid_text: String = ResourceUID.id_to_text(new_id)
		
		# 3. 変換したUIDを標準出力に表示
		if count == 1:
			print("✅ Generated UID: ", uid_text)
		else:
			print("✅ UID #", i + 1, ": ", uid_text)
	
	print("====================================================")
	print("💡 Usage examples:")
	print("  Single UID: godot --headless --script tools/generate_uid.gd --quit")
	print("  Multiple UIDs: godot --headless --script tools/generate_uid.gd --quit -- --count 5")
	
	# 即座に終了
	quit()