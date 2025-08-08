@tool
extends EditorPlugin

const AUTOLOAD_SCRIPT_PLAYER = "AdvScriptPlayer"
const AUTOLOAD_VARIABLE_MANAGER = "VariableManager"
const AUTOLOAD_CHARACTER_MANAGER = "CharacterManager"
const AUTOLOAD_UI_MANAGER = "UIManager"
const AUTOLOAD_TRANSITION_PLAYER = "TransitionPlayer"
const AUTOLOAD_LABEL_REGISTRY = "LabelRegistry"

func _enter_tree():
	# Add autoloads for the core systems
	add_autoload_singleton(AUTOLOAD_SCRIPT_PLAYER, "res://addons/adv_engine/AdvScriptPlayer.gd")
	add_autoload_singleton(AUTOLOAD_VARIABLE_MANAGER, "res://addons/adv_engine/managers/VariableManager.gd")
	add_autoload_singleton(AUTOLOAD_CHARACTER_MANAGER, "res://addons/adv_engine/managers/CharacterManager.gd")
	add_autoload_singleton(AUTOLOAD_UI_MANAGER, "res://addons/adv_engine/managers/UIManager.gd")
	add_autoload_singleton(AUTOLOAD_TRANSITION_PLAYER, "res://addons/adv_engine/managers/TransitionPlayer.gd")
	add_autoload_singleton(AUTOLOAD_LABEL_REGISTRY, "res://addons/adv_engine/LabelRegistry.gd")

func _exit_tree():
	# Remove autoloads when plugin is disabled
	remove_autoload_singleton(AUTOLOAD_SCRIPT_PLAYER)
	remove_autoload_singleton(AUTOLOAD_VARIABLE_MANAGER)
	remove_autoload_singleton(AUTOLOAD_CHARACTER_MANAGER)
	remove_autoload_singleton(AUTOLOAD_UI_MANAGER)
	remove_autoload_singleton(AUTOLOAD_TRANSITION_PLAYER)
	remove_autoload_singleton(AUTOLOAD_LABEL_REGISTRY)