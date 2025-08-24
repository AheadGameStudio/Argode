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

## v1.2.0: 全登録タグの動的パターン生成
func get_all_tag_patterns() -> Array[String]:
	"""全タグのパターンを動的に生成"""
	var all_patterns: Array[String] = []
	
	for tag_name in tag_command_dictionary:
		var command_data = tag_command_dictionary[tag_name]
		var command_instance: ArgodeCommandBase = command_data.instance
		
		# 基本パターンを追加
		var basic_patterns = command_instance.get_tag_patterns()
		all_patterns.append_array(basic_patterns)
		
		# カスタムパターンを追加
		var custom_patterns = command_instance.get_custom_tag_patterns()
		all_patterns.append_array(custom_patterns)
	
	return all_patterns

## v1.2.0: 優先度順でソートされたタグパターン取得
func get_tag_patterns_by_priority() -> Array[String]:
	"""除去優先度順でソートされたタグパターン"""
	var tag_priority_pairs: Array = []
	
	for tag_name in tag_command_dictionary:
		var command_data = tag_command_dictionary[tag_name]
		var command_instance: ArgodeCommandBase = command_data.instance
		
		var priority = command_instance.get_tag_removal_priority()
		var patterns = command_instance.get_tag_patterns()
		patterns.append_array(command_instance.get_custom_tag_patterns())
		
		for pattern in patterns:
			tag_priority_pairs.append({"pattern": pattern, "priority": priority})
	
	# 優先度順でソート（高い順）
	tag_priority_pairs.sort_custom(func(a, b): return a.priority > b.priority)
	
	# パターンのみ抽出
	var sorted_patterns: Array[String] = []
	for pair in tag_priority_pairs:
		sorted_patterns.append(pair.pattern)
	
	return sorted_patterns
