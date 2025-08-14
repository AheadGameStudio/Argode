@tool
class_name BuiltinArgodeCommand
extends BaseCustomCommand

func _init():
	command_name = "argode"
	description = "Argodeシステム全体に関連するコマンド"
	help_text ="argode show  [with <transition>] | argode hide  [with <transition>]"

	set_parameter_info("subcommand", "string", true, "", "show/hideのいずれか")
	set_parameter_info("transition", "string", false, "none", "Transition effect")

func execute(args: Dictionary, adv_system: Node) -> void:
	print(args.size())
	print(args)
	var subcommand = args[0]
	var transition = "none"
	if args._count > 1:
		var _with = args[1]
		transition = args[2]

	match subcommand:
		"show":
			ArgodeSystem.UIManager.set_message_window_mode_with_transition("show", transition)
		"hide":
			ArgodeSystem.UIManager.set_message_window_mode_with_transition("hide", transition)
		_:
			push_warning("⚠️ Unknown subcommand: " + subcommand)
