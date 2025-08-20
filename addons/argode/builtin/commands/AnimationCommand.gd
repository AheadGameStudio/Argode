extends ArgodeCommandBase
class_name AnimationCommand

func _ready():
	command_class_name = "AnimationCommand"
	command_execute_name = "animation"
	is_also_tag = true
	has_end_tag = true
	tag_name = "animation"
	command_description = "特定範囲のテキストアニメーションを変更します"
	command_help = "{animation=dramatic}強調したいテキスト{/animation} または {animation=fade_in:0.8,scale:true}カスタムアニメーション{/animation}の形式で使用します"

func validate_args(args: Dictionary) -> bool:
	# 終了タグの場合はバリデーション不要
	if args.has("_closing") and args["_closing"]:
		return true
	
	# アニメーション設定が存在するかチェック
	if not args.has("animation") and not args.has("0"):
		log_error("アニメーション設定が指定されていません")
		return false
	
	return true

func execute_core(args: Dictionary) -> void:
	var is_closing_tag = args.has("_closing") and args["_closing"]
	
	if is_closing_tag:
		# 終了タグの処理
		log_debug("Animation closing tag processed")
	else:
		# 開始タグの処理
		var animation_config = _parse_animation_config(args)
		log_debug("Animation opening tag processed with config: %s" % str(animation_config))

## アニメーション設定を解析
func _parse_animation_config(args: Dictionary) -> Dictionary:
	"""アニメーション設定を解析してDictionaryに変換"""
	var config = {}
	
	# アニメーション値を取得
	var animation_value = ""
	if args.has("animation"):
		animation_value = args["animation"]
	elif args.has("0"):  # 無名引数
		animation_value = args["0"]
	
	# プリセット名かカスタム設定かを判定
	if _is_preset_name(animation_value):
		config = _get_preset_config(animation_value)
	else:
		config = _parse_custom_config(animation_value)
	
	return config

## プリセット名かどうかを判定
func _is_preset_name(value: String) -> bool:
	"""値がプリセット名かどうかを判定"""
	var presets = ["default", "fast", "dramatic", "simple", "none", "bounce", "shake", "glow"]
	return value in presets

## プリセット設定を取得
func _get_preset_config(preset_name: String) -> Dictionary:
	"""プリセット名に対応する設定を取得"""
	match preset_name:
		"default":
			return {
				"fade_in": {"duration": 0.3, "enabled": true},
				"slide_down": {"duration": 0.4, "offset": -8.0, "enabled": true},
				"scale": {"enabled": false}
			}
		"fast":
			return {
				"fade_in": {"duration": 0.1, "enabled": true},
				"slide_down": {"duration": 0.15, "offset": -3.0, "enabled": true},
				"scale": {"enabled": false}
			}
		"dramatic":
			return {
				"fade_in": {"duration": 0.8, "enabled": true},
				"slide_down": {"duration": 1.0, "offset": -25.0, "enabled": true},
				"scale": {"duration": 0.6, "from": 0.5, "to": 1.0, "enabled": true}
			}
		"simple":
			return {
				"fade_in": {"duration": 0.15, "enabled": true},
				"slide_down": {"enabled": false},
				"scale": {"enabled": false}
			}
		"bounce":
			return {
				"fade_in": {"duration": 0.2, "enabled": true},
				"scale": {"duration": 0.4, "from": 0.8, "to": 1.2, "bounce": true, "enabled": true},
				"slide_down": {"enabled": false}
			}
		"shake":
			return {
				"fade_in": {"duration": 0.1, "enabled": true},
				"shake": {"duration": 0.3, "intensity": 2.0, "enabled": true},
				"slide_down": {"enabled": false}
			}
		"glow":
			return {
				"fade_in": {"duration": 0.5, "enabled": true},
				"glow": {"duration": 0.6, "intensity": 1.5, "enabled": true},
				"scale": {"duration": 0.3, "from": 0.9, "to": 1.1, "enabled": true}
			}
		"none":
			return {
				"fade_in": {"enabled": false},
				"slide_down": {"enabled": false},
				"scale": {"enabled": false}
			}
		_:
			log_warning("Unknown animation preset: %s, using default" % preset_name)
			return _get_preset_config("default")

## カスタム設定を解析
func _parse_custom_config(config_string: String) -> Dictionary:
	"""カスタム設定文字列を解析"""
	var config = {}
	
	# "fade_in:0.8,scale:true,slide_down:false" 形式をパース
	var parts = config_string.split(",")
	
	for part in parts:
		var key_value = part.split(":")
		if key_value.size() >= 2:
			var key = key_value[0].strip_edges()
			var value = key_value[1].strip_edges()
			
			# 値の型を推測して変換
			var parsed_value = _parse_config_value(value)
			
			# アニメーションタイプごとに設定を構築
			match key:
				"fade_in":
					if typeof(parsed_value) == TYPE_FLOAT:
						config["fade_in"] = {"duration": parsed_value, "enabled": true}
					elif typeof(parsed_value) == TYPE_BOOL:
						config["fade_in"] = {"enabled": parsed_value}
				"scale":
					if typeof(parsed_value) == TYPE_FLOAT:
						config["scale"] = {"duration": parsed_value, "enabled": true}
					elif typeof(parsed_value) == TYPE_BOOL:
						config["scale"] = {"enabled": parsed_value}
				"slide_down":
					if typeof(parsed_value) == TYPE_FLOAT:
						config["slide_down"] = {"duration": parsed_value, "offset": -10.0, "enabled": true}
					elif typeof(parsed_value) == TYPE_BOOL:
						config["slide_down"] = {"enabled": parsed_value}
				"duration":
					# 全般的な duration 設定
					if typeof(parsed_value) == TYPE_FLOAT:
						config["global_duration"] = parsed_value
	
	return config

## 設定値をパース
func _parse_config_value(value: String):
	"""設定値を適切な型に変換"""
	# Boolean
	if value.to_lower() == "true":
		return true
	elif value.to_lower() == "false":
		return false
	
	# Float
	if value.is_valid_float():
		return float(value)
	
	# Int
	if value.is_valid_int():
		return int(value)
	
	# String
	return value
