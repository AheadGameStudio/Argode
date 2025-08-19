# ArgodeTagTokenizer
# テキストをトークン（単語や記号の最小単位）に分解する。

extends RefCounted
class_name ArgodeTagTokenizer

## トークンの種類を表すenum
enum TokenType {
	TEXT,     # 通常のテキスト
	TAG,      # タグ {w=1.0} など
	VARIABLE, # 変数 [player.name] など  
	RUBY      # ルビ 【古今東西｜ここんとうざい】など
}

## トークンデータ構造
class TokenData extends RefCounted:
	var type: TokenType
	var content: String        # 元のテキスト内容
	var start_position: int    # テキスト内での開始位置
	var end_position: int      # テキスト内での終了位置
	var display_text: String   # 表示用テキスト（加工後）
	var command_data: Dictionary = {}  # コマンド実行用データ
	
	func _init(p_type: TokenType, p_content: String, p_start: int, p_end: int):
		type = p_type
		content = p_content
		start_position = p_start
		end_position = p_end
		display_text = p_content  # デフォルトは元のコンテンツ

## テキストをトークンに分解
func tokenize(text: String) -> Array[TokenData]:
	var tokens: Array[TokenData] = []
	var current_pos = 0
	
	while current_pos < text.length():
		var next_token = _find_next_token(text, current_pos)
		if next_token:
			tokens.append(next_token)
			current_pos = next_token.end_position
		else:
			# 残りのテキストを通常テキストとして処理
			var remaining_text = text.substr(current_pos)
			if not remaining_text.is_empty():
				var text_token = TokenData.new(TokenType.TEXT, remaining_text, current_pos, text.length())
				tokens.append(text_token)
			break
	
	return tokens

## TokenTypeを文字列に変換（デバッグ用）
func _token_type_to_string(type: TokenType) -> String:
	match type:
		TokenType.TEXT: return "TEXT"
		TokenType.TAG: return "TAG"
		TokenType.VARIABLE: return "VARIABLE"
		TokenType.RUBY: return "RUBY"
		_: return "UNKNOWN"

## 指定位置から次のトークンを検索
func _find_next_token(text: String, start_pos: int) -> TokenData:
	var remaining_text = text.substr(start_pos)
	
	ArgodeSystem.log("🔍 Finding token from pos %d: '%s'" % [start_pos, remaining_text.substr(0, 30) + ("..." if remaining_text.length() > 30 else "")])
	
	# 最初に特殊パターンの位置を調べる
	var earliest_pattern_pos = -1
	var earliest_pattern_type = ""
	
	# タグの検索 {xxx}
	var tag_match = _find_tag_pattern(remaining_text)
	if tag_match.has("found"):
		if earliest_pattern_pos == -1 or tag_match.start < earliest_pattern_pos:
			earliest_pattern_pos = tag_match.start
			earliest_pattern_type = "tag"
	
	# 変数の検索 [xxx]
	var var_match = _find_variable_pattern(remaining_text)
	if var_match.has("found"):
		if earliest_pattern_pos == -1 or var_match.start < earliest_pattern_pos:
			earliest_pattern_pos = var_match.start
			earliest_pattern_type = "variable"
	
	# ルビの検索 【xxx｜yyy】
	var ruby_match = _find_ruby_pattern(remaining_text)
	if ruby_match.has("found"):
		if earliest_pattern_pos == -1 or ruby_match.start < earliest_pattern_pos:
			earliest_pattern_pos = ruby_match.start
			earliest_pattern_type = "ruby"
	
	# 特殊パターンの前にテキストがある場合はテキストトークンを先に作成
	if earliest_pattern_pos > 0:
		var text_content = remaining_text.substr(0, earliest_pattern_pos)
		return TokenData.new(TokenType.TEXT, text_content, start_pos, start_pos + text_content.length())
	
	# 特殊パターンが先頭にある場合は該当するパターンを処理
	if earliest_pattern_pos == 0:
		match earliest_pattern_type:
			"tag":
				return _create_tag_token(tag_match, start_pos)
			"variable":
				return _create_variable_token(var_match, start_pos)
			"ruby":
				return _create_ruby_token(ruby_match, start_pos)
	
	# 特殊パターンがない場合、残り全てのテキストを作成
	if earliest_pattern_pos == -1:
		return _create_text_token(remaining_text, start_pos)
	
	return null
	
	return null

## タグパターンの検索 {xxx}
func _find_tag_pattern(text: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile(r"\{([^}]+)\}")
	var result = regex.search(text)
	
	if result:
		return {
			"found": true,
			"full_match": result.get_string(0),
			"tag_content": result.get_string(1),
			"start": result.get_start(),
			"end": result.get_end()
		}
	return {}

## 変数パターンの検索 [xxx]
func _find_variable_pattern(text: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile(r"\[([^\]]+)\]")
	var result = regex.search(text)
	
	if result:
		return {
			"found": true,
			"full_match": result.get_string(0),
			"var_content": result.get_string(1),
			"start": result.get_start(),
			"end": result.get_end()
		}
	return {}

## ルビパターンの検索 【xxx｜yyy】
func _find_ruby_pattern(text: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile(r"【([^｜]+)｜([^】]+)】")
	var result = regex.search(text)
	
	if result:
		return {
			"found": true,
			"full_match": result.get_string(0),
			"base_text": result.get_string(1),   # ルビベースとなる文字
			"ruby_text": result.get_string(2),  # ルビテキスト
			"start": result.get_start(),
			"end": result.get_end()
		}
	return {}

## タグトークンの作成
func _create_tag_token(match_data: Dictionary, offset: int) -> TokenData:
	var start_pos = offset + match_data.start
	var end_pos = offset + match_data.end
	var token = TokenData.new(TokenType.TAG, match_data.full_match, start_pos, end_pos)
	
	# タグ内容を解析してコマンドデータを設定
	var tag_content = match_data.tag_content
	token.command_data = _parse_tag_content(tag_content)
	token.display_text = ""  # タグは表示しない
	
	return token

## 変数トークンの作成
func _create_variable_token(match_data: Dictionary, offset: int) -> TokenData:
	var start_pos = offset + match_data.start
	var end_pos = offset + match_data.end
	var token = TokenData.new(TokenType.VARIABLE, match_data.full_match, start_pos, end_pos)
	
	# 変数名を設定
	token.command_data["variable_name"] = match_data.var_content
	token.display_text = "[VAR]"  # 一時的な表示テキスト（後で変数値に置換）
	
	return token

## ルビトークンの作成
func _create_ruby_token(match_data: Dictionary, offset: int) -> TokenData:
	var start_pos = offset + match_data.start
	var end_pos = offset + match_data.end
	var token = TokenData.new(TokenType.RUBY, match_data.full_match, start_pos, end_pos)
	
	# ルビデータを設定
	token.command_data["base_text"] = match_data.base_text
	token.command_data["ruby_text"] = match_data.ruby_text
	token.display_text = match_data.base_text  # 表示用はベーステキストのみ
	
	return token

## 通常テキストトークンの作成
func _create_text_token(text: String, offset: int) -> TokenData:
	# 次の特殊パターンまでのテキストを取得
	var min_pos = text.length()
	
	# 各パターンの最初の出現位置を調べる
	var patterns = [r"\{", r"\[", r"【"]
	for pattern in patterns:
		var regex = RegEx.new()
		regex.compile(pattern)
		var result = regex.search(text)
		if result:
			min_pos = min(min_pos, result.get_start())
	
	# min_posが0の場合、テキストの先頭に特殊パターンがある
	# この場合は特殊パターンを処理するため、nullを返す
	if min_pos == 0:
		return null
	
	var content = text.substr(0, min_pos)
	if content.is_empty():
		return null
	
	ArgodeSystem.log("📝 Creating text token: '%s' (length: %d)" % [content, content.length()])
	return TokenData.new(TokenType.TEXT, content, offset, offset + content.length())

## タグ内容をパース（例: "w=1.0" -> {"command": "w", "value": "1.0"}）
func _parse_tag_content(tag_content: String) -> Dictionary:
	var data = {}
	
	ArgodeSystem.log("🏷️ Parsing tag content: '%s'" % tag_content)
	
	if "=" in tag_content:
		var parts = tag_content.split("=", false, 1)
		if parts.size() >= 2:
			data["command"] = parts[0].strip_edges()
			data["value"] = parts[1].strip_edges()
			# WaitCommandの場合、"w"引数も追加
			data[data["command"]] = data["value"]
		else:
			data["command"] = tag_content.strip_edges()
	else:
		data["command"] = tag_content.strip_edges()
	
	ArgodeSystem.log("📋 Parsed tag data: %s" % str(data))
	return data