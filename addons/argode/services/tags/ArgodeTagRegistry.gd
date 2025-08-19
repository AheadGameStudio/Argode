# タグ名と、そのタグに対応するコマンドのマップを保持。
# { "ruby": RubyCommand, "get": GetCommand }のような辞書
extends RefCounted
class_name ArgodeTagRegistry

var tag_command_dictionary: Dictionary = {}

## CommandRegistryからis_also_tagフラグを持つコマンドを収集
func initialize_from_command_registry(command_registry: ArgodeCommandRegistry):
	tag_command_dictionary.clear()
	
	for command_name in command_registry.command_dictionary:
		var command_data = command_registry.command_dictionary[command_name]
		var command_instance: ArgodeCommandBase = command_data.instance
		
		# is_also_tagフラグをチェック
		if command_instance.is_also_tag:
			var tag_name = command_instance.tag_name
			if tag_name.is_empty():
				tag_name = command_name  # tag_nameが空の場合はcommand_nameを使用
			
			tag_command_dictionary[tag_name] = command_data
			ArgodeSystem.log("🏷️ Tag registered: %s -> %s" % [tag_name, command_data.class_name])
	
	ArgodeSystem.log("✅ TagRegistry initialized with %d tags" % tag_command_dictionary.size())

## 指定されたタグ名のコマンドを取得
func get_tag_command(tag_name: String) -> Dictionary:
	return tag_command_dictionary.get(tag_name, {})

## タグが存在するかチェック
func has_tag(tag_name: String) -> bool:
	return tag_command_dictionary.has(tag_name)

## 全タグ名のリストを取得
func get_tag_names() -> Array[String]:
	var names: Array[String] = []
	names.assign(tag_command_dictionary.keys())
	return names
