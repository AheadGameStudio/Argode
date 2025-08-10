extends SceneTree

func _init():
	print("🔧 Simple command test...")
	call_deferred("_run_test")