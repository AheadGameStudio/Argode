# BaseCustomTag.gd
# カスタムタグの基底クラス
@tool
class_name BaseCustomTag
extends RefCounted

# サブクラスでオーバーライドするメソッド
func get_tag_name() -> String:
	"""タグ名を返す (例: "audio")"""
	push_error("get_tag_name() must be implemented by subclass")
	return ""

func get_description() -> String:
	"""タグの説明を返す"""
	return "カスタムタグ"

func get_tag_type():
	"""タグのタイプを返す (通常はCUSTOM)"""
	# InlineTagProcessor.TagType.CUSTOMを返す（値は3）
	return 3

func get_tag_properties() -> Dictionary:
	"""タグの追加プロパティを返す"""
	return {
		"execution_timing": "PRE_VARIABLE"
	}

func process_tag(tag_name: String, parameters: Dictionary, adv_system):
	"""
	タグパラメータを処理する
	tag_name: タグ名
	parameters: タグから解析されたパラメータ辞書
	adv_system: ArgodeSystemのインスタンス
	"""
	push_error("process_tag() must be implemented by subclass")

func get_help_text() -> String:
	"""ヘルプテキストを返す"""
	return "カスタムタグ - ヘルプテキストが未設定"

# ユーティリティメソッド（サブクラスで使用可能）
func parse_colon_separated_params(param_string: String) -> Array[String]:
	"""コロン区切りパラメータを配列に分割"""
	return param_string.split(":")

func parse_key_value_params(param_string: String) -> Dictionary:
	"""key=value形式のパラメータを辞書に変換"""
	var result = {}
	var pairs = param_string.split(" ")
	
	for pair in pairs:
		if "=" in pair:
			var parts = pair.split("=", false, 1)
			if parts.size() == 2:
				result[parts[0]] = parts[1]
	
	return result
