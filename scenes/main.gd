extends Node

func _ready():
	if not ArgodeSystem.is_system_ready:
		await ArgodeSystem.system_ready
	ArgodeSystem.log("✅ Main scene is ready.", ArgodeSystem.DebugManager.LogLevel.INFO)
	ArgodeSystem.play("test_all_command")