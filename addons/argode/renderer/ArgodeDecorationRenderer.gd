extends RefCounted
class_name ArgodeDecorationRenderer

## テキスト装飾を専門に扱うレンダラー
## ArgodeMessageRendererから装飾機能を分離

# テキスト装飾管理
var text_decorations: Array[Dictionary] = []  # 装飾情報を保存
var decoration_stack: Array[Dictionary] = []  # 装飾スタック（開始/終了ペア管理）

func _init():
	pass

## position_commandsから装飾データを抽出
func extract_decoration_data(position_commands: Array):
	"""位置ベースコマンドから装飾情報を抽出"""
	text_decorations.clear()
	decoration_stack.clear()
	
	ArgodeSystem.log("🎨 DecorationRenderer: Processing %d position commands" % position_commands.size())
	
	for command_info in position_commands:
		var command_name = command_info.get("command_name", "")
		var position = command_info.get("display_position", 0)
		var args = command_info.get("args", {})
		
		ArgodeSystem.log("🔍 Processing command: %s at position %d with args: %s" % [command_name, position, str(args)])
		
		# 装飾タグかチェック（コマンドのプロパティを使用）
		if _is_decoration_command(command_info):
			_process_decoration_command(command_name, position, args)
		else:
			ArgodeSystem.log("🔍 Command '%s' is not a decoration command" % command_name)

## 装飾コマンドかどうか判定
func _is_decoration_command(command_info: Dictionary) -> bool:
	"""装飾コマンドかどうかを判定"""
	# command_dataからコマンドインスタンスを取得
	var command_data = command_info.get("command_data", {})
	var command_instance = command_data.get("instance", null)
	
	if command_instance != null:
		# is_decoration_commandプロパティをチェック
		return command_instance.is_decoration_command
	
	# フォールバック：従来の名前ベース判定
	var command_name = command_info.get("command_name", "")
	var decoration_commands = ["color", "bold", "italic", "size", "underline", "animation", "scale", "move"]
	return command_name in decoration_commands

## 装飾コマンドを処理
func _process_decoration_command(command_name: String, position: int, args: Dictionary):
	"""装飾コマンドを処理して開始/終了タグのペアを作成"""
	var is_closing = args.has("_closing") or args.has("/" + command_name)
	
	if is_closing:
		# 終了タグ: スタックから対応する開始タグを探して装飾範囲を確定
		_close_decoration(command_name, position)
	else:
		# 開始タグ: スタックに登録
		_open_decoration(command_name, position, args)

## 装飾の開始を処理
func _open_decoration(command_name: String, position: int, args: Dictionary):
	"""装飾の開始タグを処理"""
	var decoration_info = {
		"type": command_name,
		"start_position": position,
		"end_position": -1,  # 未確定
		"args": args,
		"is_active": false
	}
	
	# アニメーションコマンドの場合は設定を解析して保存
	if command_name == "animation":
		decoration_info.args["animation_config"] = _parse_animation_from_args(args)
	
	decoration_stack.append(decoration_info)
	ArgodeSystem.log("🎨 Decoration opened: %s at position %d with args: %s" % [command_name, position, str(args)])

## 装飾の終了を処理
func _close_decoration(command_name: String, position: int):
	"""装飾の終了タグを処理"""
	# スタックから最後に開始された同じタイプの装飾を探す
	for i in range(decoration_stack.size() - 1, -1, -1):
		var decoration_info = decoration_stack[i]
		if decoration_info.type == command_name and decoration_info.end_position == -1:
			# 装飾範囲を確定
			decoration_info.end_position = position
			text_decorations.append(decoration_info)
			decoration_stack.remove_at(i)
			ArgodeSystem.log("🎨 Decoration closed: %s from %d to %d" % [command_name, decoration_info.start_position, position])
			return
	
	ArgodeSystem.log("⚠️ No matching opening tag found for /%s at position %d" % [command_name, position], 1)

## 指定位置で有効な装飾を取得
func get_active_decorations_at_position(position: int) -> Array[Dictionary]:
	"""指定位置で有効な装飾のリストを取得"""
	var active_decorations: Array[Dictionary] = []
	
	for decoration in text_decorations:
		if decoration.start_position <= position and position < decoration.end_position:
			active_decorations.append(decoration)
	
	return active_decorations

## 文字の描画情報を装飾に基づいて計算
func calculate_char_render_info(char: String, base_font: Font, base_font_size: int, base_color: Color, decorations: Array[Dictionary]) -> Dictionary:
	"""装飾情報に基づいて文字の描画情報を計算"""
	var render_info = {
		"font": base_font,
		"font_size": base_font_size,
		"color": base_color,
		"animation_config": {},  # アニメーション設定を追加
		"scale": Vector2.ONE,    # スケール情報を追加
		"offset": Vector2.ZERO   # 移動オフセット情報を追加
	}
	
	# 装飾を順次適用
	for decoration in decorations:
		match decoration.type:
			"color":
				render_info.color = _parse_color_from_args(decoration.args)
				if ArgodeSystem.is_verbose_mode():
					ArgodeSystem.log("🎨 Applied color decoration: %s" % str(render_info.color))
			"size":
				var new_size = _parse_size_from_args(decoration.args, base_font_size)
				render_info.font_size = new_size
				if ArgodeSystem.is_verbose_mode():
					ArgodeSystem.log("📏 Applied size decoration: %d -> %d" % [base_font_size, new_size])
			"animation":
				render_info.animation_config = _parse_animation_from_args(decoration.args)
				if ArgodeSystem.is_verbose_mode():
					ArgodeSystem.log("🎭 Applied animation decoration: %s" % str(render_info.animation_config))
			"scale":
				render_info.scale = _parse_scale_from_args(decoration.args)
				if ArgodeSystem.is_verbose_mode():
					ArgodeSystem.log("📏 Applied scale decoration: %s" % str(render_info.scale))
			"move":
				render_info.offset = _parse_move_from_args(decoration.args)
				if ArgodeSystem.is_verbose_mode():
					ArgodeSystem.log("🎯 Applied move decoration: %s" % str(render_info.offset))
			# 他の装飾タイプ（bold, italic など）はフォント変更で対応予定
	
	return render_info

## 装飾引数から色を解析
func _parse_color_from_args(args: Dictionary) -> Color:
	"""装飾引数から色を解析"""
	# {color=#ff0000} または {color=red} 形式をサポート
	if args.has("color"):
		return _parse_color_string(args["color"])
	elif args.has("0"):  # 無名引数
		return _parse_color_string(args["0"])
	return Color.WHITE

## カラー文字列をColor型に変換
func _parse_color_string(color_str: String) -> Color:
	"""カラー文字列をColor型に変換"""
	# #で始まる16進数カラー
	if color_str.begins_with("#"):
		return Color(color_str)
	
	# 名前付きカラー
	match color_str.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"white": return Color.WHITE
		"black": return Color.BLACK
		"gray", "grey": return Color.GRAY
		_: return Color.WHITE

## 装飾引数からサイズを解析
func _parse_size_from_args(args: Dictionary, base_size: int) -> int:
	"""装飾引数からフォントサイズを解析"""
	var size_value = base_size
	
	if args.has("size"):
		size_value = int(args["size"])
	elif args.has("0"):  # 無名引数
		size_value = int(args["0"])
	
	# サイズの範囲制限
	return max(8, min(48, size_value))

## 装飾引数からアニメーション設定を解析
func _parse_animation_from_args(args: Dictionary) -> Dictionary:
	"""装飾引数からアニメーション設定を解析"""
	var animation_config = {}
	
	if args.has("animation"):
		animation_config = _parse_animation_string(args["animation"])
	elif args.has("0"):  # 無名引数
		animation_config = _parse_animation_string(args["0"])
	
	return animation_config

## アニメーション文字列を解析
func _parse_animation_string(animation_str: String) -> Dictionary:
	"""アニメーション文字列をDictionaryに解析"""
	# プリセット名かカスタム設定かを判定
	if _is_animation_preset(animation_str):
		return _get_animation_preset_config(animation_str)
	else:
		return _parse_custom_animation_config(animation_str)

## アニメーションプリセット名かどうかを判定
func _is_animation_preset(value: String) -> bool:
	"""値がアニメーションプリセット名かどうかを判定"""
	var presets = ["default", "fast", "dramatic", "simple", "none", "bounce", "shake", "glow"]
	return value in presets

## アニメーションプリセット設定を取得
func _get_animation_preset_config(preset_name: String) -> Dictionary:
	"""プリセット名に対応するアニメーション設定を取得"""
	match preset_name:
		"dramatic":
			return {
				"fade_in": {"duration": 0.8, "enabled": true},
				"slide_down": {"duration": 1.0, "offset": -25.0, "enabled": true},
				"scale": {"duration": 0.6, "from": 0.5, "to": 1.0, "enabled": true}
			}
		"fast":
			return {
				"fade_in": {"duration": 0.1, "enabled": true},
				"slide_down": {"duration": 0.15, "offset": -3.0, "enabled": true}
			}
		"bounce":
			return {
				"fade_in": {"duration": 0.2, "enabled": true},
				"scale": {"duration": 0.4, "from": 0.8, "to": 1.2, "bounce": true, "enabled": true}
			}
		"simple":
			return {
				"fade_in": {"duration": 0.15, "enabled": true}
			}
		"none":
			return {}
		_:
			return {
				"fade_in": {"duration": 0.3, "enabled": true},
				"slide_down": {"duration": 0.4, "offset": -8.0, "enabled": true}
			}

## カスタムアニメーション設定を解析
func _parse_custom_animation_config(config_string: String) -> Dictionary:
	"""カスタムアニメーション設定文字列を解析"""
	var config = {}
	
	# "fade_in:0.8,scale:true" 形式をパース
	var parts = config_string.split(",")
	
	for part in parts:
		var key_value = part.split(":")
		if key_value.size() >= 2:
			var key = key_value[0].strip_edges()
			var value = key_value[1].strip_edges()
			
			# 値の型を推測して変換
			var parsed_value = _parse_animation_value(value)
			
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
	
	return config

## アニメーション値をパース
func _parse_animation_value(value: String):
	"""アニメーション設定値を適切な型に変換"""
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

## 装飾データをクリア
func clear_decoration_data():
	"""装飾データをクリア"""
	text_decorations.clear()
	decoration_stack.clear()

## デバッグ情報
func get_decoration_count() -> int:
	"""現在の装飾数を取得"""
	return text_decorations.size()

func get_pending_decoration_count() -> int:
	"""未完了の装飾数を取得"""
	return decoration_stack.size()

## 装飾引数からスケール値を解析
func _parse_scale_from_args(args: Dictionary) -> Vector2:
	"""装飾引数からスケール値を解析"""
	var scale_value = Vector2.ONE
	
	var scale_str = ""
	if args.has("scale"):
		scale_str = args["scale"]
	elif args.has("value"):
		scale_str = args["value"]
	elif args.has("0"):  # 無名引数
		scale_str = args["0"]
	
	if scale_str != "":
		var parts = scale_str.split(",")
		if parts.size() >= 2:
			# "1.5,0.3" 形式 (X倍率, 時間)
			scale_value.x = float(parts[0])
			scale_value.y = float(parts[0])  # Y倍率もX倍率と同じにする
		elif parts.size() == 1:
			# "1.5" 形式 (統一倍率)
			var scale_factor = float(parts[0])
			scale_value = Vector2(scale_factor, scale_factor)
	
	return scale_value

## 装飾引数から移動オフセットを解析
func _parse_move_from_args(args: Dictionary) -> Vector2:
	"""装飾引数から移動オフセットを解析"""
	var move_offset = Vector2.ZERO
	
	var move_str = ""
	if args.has("move"):
		move_str = args["move"]
	elif args.has("value"):
		move_str = args["value"]
	elif args.has("0"):  # 無名引数
		move_str = args["0"]
	
	if move_str != "":
		var parts = move_str.split(",")
		if parts.size() >= 2:
			# "10,5,0.5" 形式 (X移動, Y移動, 時間)
			move_offset.x = float(parts[0])
			move_offset.y = float(parts[1])
		elif parts.size() == 1:
			# "10" 形式 (X移動のみ)
			move_offset.x = float(parts[0])
	
	return move_offset

func debug_print_decorations():
	"""装飾情報をデバッグ出力"""
	ArgodeSystem.log("🎨 Decoration Debug Info:")
	ArgodeSystem.log("  - Active decorations: %d" % text_decorations.size())
	ArgodeSystem.log("  - Pending decorations: %d" % decoration_stack.size())
	
	for i in range(text_decorations.size()):
		var decoration = text_decorations[i]
		ArgodeSystem.log("  - [%d] %s: %d-%d %s" % [i, decoration.type, decoration.start_position, decoration.end_position, str(decoration.args)])
