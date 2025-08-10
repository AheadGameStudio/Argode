# plugin.gd
# Argode - Advanced visual novel engine for Godot
@tool
extends EditorPlugin

const ArgodeSystem = preload("res://addons/argode/core/ArgodeSystem.gd")

func _enter_tree():
	print("🎮 Argode plugin enabled")
	add_autoload_singleton("ArgodeSystem", "res://addons/argode/core/ArgodeSystem.gd")

func _exit_tree():
	print("👋 Argode plugin disabled")
	remove_autoload_singleton("ArgodeSystem")