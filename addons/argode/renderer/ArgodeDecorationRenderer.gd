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
		
		# 装飾タグかチェック（color, bold, italic, size など）
		if _is_decoration_command(command_name):
			_process_decoration_command(command_name, position, args)
		else:
			ArgodeSystem.log("🔍 Command '%s' is not a decoration command" % command_name)

## 装飾コマンドかどうか判定
func _is_decoration_command(command_name: String) -> bool:
	"""装飾コマンドかどうかを判定"""
	var decoration_commands = ["color", "bold", "italic", "size", "underline"]
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
		"color": base_color
	}
	
	# 装飾を順次適用
	for decoration in decorations:
		match decoration.type:
			"color":
				render_info.color = _parse_color_from_args(decoration.args)
				ArgodeSystem.log("🎨 Applied color decoration: %s" % str(render_info.color))
			"size":
				var new_size = _parse_size_from_args(decoration.args, base_font_size)
				render_info.font_size = new_size
				ArgodeSystem.log("📏 Applied size decoration: %d -> %d" % [base_font_size, new_size])
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

func debug_print_decorations():
	"""装飾情報をデバッグ出力"""
	ArgodeSystem.log("🎨 Decoration Debug Info:")
	ArgodeSystem.log("  - Active decorations: %d" % text_decorations.size())
	ArgodeSystem.log("  - Pending decorations: %d" % decoration_stack.size())
	
	for i in range(text_decorations.size()):
		var decoration = text_decorations[i]
		ArgodeSystem.log("  - [%d] %s: %d-%d %s" % [i, decoration.type, decoration.start_position, decoration.end_position, str(decoration.args)])
