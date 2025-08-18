extends Node

func _ready():
	ArgodeSystem.log("✅ Main scene is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)
	await ArgodeSystem.system_ready
	ArgodeSystem.play("test_all_command")