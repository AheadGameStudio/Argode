extends Node

var global_vars: Dictionary = {}
var character_defs: Dictionary = {}

func _ready():
	print("🧮 VariableManager initialized")

func set_character_def(id: String, resource_path: String):
	character_defs[id] = resource_path
	print("👤 Character defined: ", id, " -> ", resource_path)

func get_character_data(id: String):
	if character_defs.has(id):
		var resource_path = character_defs[id]
		print("🔍 Loading character resource: ", id, " from ", resource_path)
		var resource = load(resource_path)
		if resource:
			print("✅ Character resource loaded: ", id)
			return resource
		else:
			push_error("🚫 Invalid character resource: " + resource_path)
			print("❌ Available character definitions: ", character_defs.keys())
	else:
		push_error("🚫 Character not defined: " + id)
		print("❌ Available character definitions: ", character_defs.keys())
	return null

func set_variable(var_name: String, expression_str: String):
	var expression = Expression.new()
	var error = expression.parse(expression_str, _get_available_variable_names())
	if error != OK:
		push_error("🚫 Expression parse error: " + expression.get_error_text())
		return
	
	var result = expression.execute(global_vars.values())
	if not expression.has_execute_failed():
		global_vars[var_name] = result
		print("📊 Var set: ", var_name, " = ", result)
	else:
		push_error("🚫 Expression execute error.")

func evaluate_condition(expression_str: String) -> bool:
	var expression = Expression.new()
	var error = expression.parse(expression_str, _get_available_variable_names())
	if error != OK:
		push_error("🚫 Expression parse error: " + expression.get_error_text())
		return false
	
	var result = expression.execute(global_vars.values())
	if not expression.has_execute_failed():
		return bool(result)
	else:
		push_error("🚫 Expression execute error.")
		return false

func expand_variables(text: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	
	var result = text
	var matches = regex.search_all(text)
	
	for match in matches:
		var var_name = match.get_string(1)
		if global_vars.has(var_name):
			var value = str(global_vars[var_name])
			result = result.replace("{" + var_name + "}", value)
		else:
			push_warning("⚠️ Undefined variable in text: " + var_name)
	
	return result

func _get_available_variable_names() -> PackedStringArray:
	return PackedStringArray(global_vars.keys())