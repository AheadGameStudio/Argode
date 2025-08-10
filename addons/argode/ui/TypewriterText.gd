extends Node
class_name TypewriterText

# シグナル定義
signal typewriter_started(text: String)
signal character_typed(character: String, position: int)
signal word_completed(word: String, position: int)
signal line_completed(line_text: String)
signal typewriter_finished()
signal typewriter_skipped()
signal typewriter_interrupted()
# v2新機能: インラインタグ関連シグナル
signal inline_tag_executed(tag_name: String, parameters: Dictionary)
signal speed_changed(multiplier: float)
signal custom_inline_tag_executed(tag_name: String, parameters: Dictionary)

# 設定プロパティ
@export var characters_per_second: float = 30.0
@export var punctuation_delay_multiplier: float = 3.0  # 句読点での追加待機
@export var auto_skip_enabled: bool = true
@export var skip_key_enabled: bool = true

# 内部状態
var target_label: Control
var original_text: String = ""
var visible_text: String = ""  # 実際に表示されるテキスト（BBCodeなし）
var bbcode_text: String = ""   # BBCode付きテキスト
var current_position: int = 0
var is_typing: bool = false
var is_skipped: bool = false
var is_paused: bool = false

# BBCode処理用
var bbcode_stack: Array = []
var bbcode_map: Dictionary = {}

# v2新機能: インラインタグ処理
var inline_tag_processor  # InlineTagProcessor
var processed_tags: Array  # ParsedTagの配列
var current_speed_multiplier: float = 1.0

# タイマー
var type_timer: Timer
var punctuation_timer: Timer

func _ready():
	# タイマー初期化
	type_timer = Timer.new()
	punctuation_timer = Timer.new()
	add_child(type_timer)
	add_child(punctuation_timer)
	
	type_timer.wait_time = 1.0 / characters_per_second
	type_timer.one_shot = true
	type_timer.timeout.connect(_on_type_timer_timeout)
	
	punctuation_timer.one_shot = true
	punctuation_timer.timeout.connect(_on_punctuation_timer_timeout)
	
	# v2新機能: InlineTagProcessorを初期化
	var inline_tag_script = preload("res://addons/argode/script/InlineTagProcessor.gd")
	inline_tag_processor = inline_tag_script.new()
	
	# 自分自身のシグナルを接続してインラインタグに対応
	speed_changed.connect(_on_speed_changed)
	
	print("⌨️ TypewriterText initialized")

func setup_target(label: Control):
	"""ターゲットとなるラベルを設定"""
	target_label = label
	if not target_label:
		push_error("❌ TypewriterText: Invalid target label")

func start_typing(text: String):
	"""タイプライターアニメーションを開始"""
	if not target_label:
		push_error("❌ TypewriterText: No target label set")
		return
	
	# 状態初期化
	original_text = text
	
	# v2新機能: インラインタグを処理
	# inline_tag_processorが初期化されていない場合は初期化
	if not inline_tag_processor:
		var inline_tag_script = preload("res://addons/argode/script/InlineTagProcessor.gd")
		inline_tag_processor = inline_tag_script.new()
		print("⚠️ TypewriterText: InlineTagProcessor initialized in start_typing()")
	
	# タイマーが初期化されていない場合は初期化
	if not type_timer:
		type_timer = Timer.new()
		punctuation_timer = Timer.new()
		add_child(type_timer)
		add_child(punctuation_timer)
		
		type_timer.wait_time = 1.0 / characters_per_second
		type_timer.one_shot = true
		type_timer.timeout.connect(_on_type_timer_timeout)
		
		punctuation_timer.one_shot = true
		punctuation_timer.timeout.connect(_on_punctuation_timer_timeout)
		
		# 自分自身のシグナルを接続
		speed_changed.connect(_on_speed_changed)
		
		print("⚠️ TypewriterText: Timers initialized in start_typing()")
	
	var process_result = inline_tag_processor.process_text(text)
	processed_tags = process_result.tags
	
	# process_result.clean_textはすでにBBCode変換済みなので、これを元のテキストとして使用
	original_text = process_result.clean_text
	visible_text = _extract_visible_text(process_result.clean_text)
	
	# インラインタグの位置をvisible_text基準で再計算
	_recalculate_tag_positions()
	
	bbcode_text = ""
	current_position = 0
	current_speed_multiplier = 1.0
	is_typing = true
	is_skipped = false
	is_paused = false
	
	# BBCodeマッピングを作成（変換後のテキストに基づく）
	_build_bbcode_map()
	
	print("🎨 TypewriterText: Original text: ", original_text)
	print("🎨 TypewriterText: Visible text: ", visible_text)
	
	# ラベルを空にして開始
	_set_label_text("")
	
	typewriter_started.emit(text)
	print("⌨️ Typewriter started: ", visible_text)
	
	# 最初の文字をタイプ
	_type_next_character()

func skip_typing():
	"""タイプライターをスキップ"""
	if not is_typing:
		return
	
	is_skipped = true
	is_typing = false
	
	# タイマーを停止
	type_timer.stop()
	punctuation_timer.stop()
	
	# 全文を即座に表示
	_set_label_text(original_text)
	current_position = visible_text.length()
	
	typewriter_skipped.emit()
	typewriter_finished.emit()
	print("⌨️ Typewriter skipped")

func pause_typing():
	"""タイプライターを一時停止"""
	is_paused = true
	type_timer.stop()
	punctuation_timer.stop()
	print("⌨️ Typewriter paused")

func resume_typing():
	"""タイプライターを再開"""
	if not is_paused:
		return
		
	is_paused = false
	if is_typing:
		_type_next_character()
	print("⌨️ Typewriter resumed")

func interrupt_typing():
	"""タイプライターを中断（外部から強制停止）"""
	if not is_typing:
		return
		
	is_typing = false
	type_timer.stop()
	punctuation_timer.stop()
	
	typewriter_interrupted.emit()
	print("⌨️ Typewriter interrupted")

func _type_next_character():
	"""次の文字をタイプ"""
	if not is_typing or is_paused or current_position >= visible_text.length():
		if current_position >= visible_text.length():
			_finish_typing()
		return
	
	# v2新機能: この位置でインラインタグをチェック・実行
	await _check_and_execute_inline_tags_at_position(current_position)
	
	# インラインタグ実行後に再度範囲チェック
	if current_position >= visible_text.length():
		_finish_typing()
		return
	
	var character = visible_text[current_position]
	current_position += 1
	
	# BBCodeありの部分文字列を構築
	bbcode_text = _build_bbcode_substring(current_position)
	
	# ラベルに反映
	_set_label_text(bbcode_text)
	
	# シグナル発行
	character_typed.emit(character, current_position - 1)
	
	# 単語完了チェック
	if character in [" ", "\n", "\t"]:
		var words = visible_text.substr(0, current_position).split(" ")
		if words.size() > 0:
			var last_word = words[-1].strip_edges()
			if not last_word.is_empty():
				word_completed.emit(last_word, current_position - 1)
	
	# 行完了チェック  
	if character == "\n":
		var lines = visible_text.substr(0, current_position).split("\n")
		if lines.size() > 1:
			var completed_line = lines[-2]  # 完了した行
			line_completed.emit(completed_line)
	
	# 次の文字の待機時間を計算（v2新機能: インラインタグによる速度変更対応）
	var delay = (1.0 / characters_per_second) / current_speed_multiplier
	
	# 句読点での追加遅延
	if character in ["。", "、", ".", ",", "!", "?", "；", "："]:
		punctuation_timer.wait_time = delay * punctuation_delay_multiplier
		punctuation_timer.start()
	else:
		type_timer.wait_time = delay
		type_timer.start()

func _finish_typing():
	"""タイプライター完了処理"""
	is_typing = false
	
	# 最後の行の完了チェック
	if not original_text.ends_with("\n"):
		var lines = original_text.split("\n")
		if lines.size() > 0:
			line_completed.emit(lines[-1])
	
	typewriter_finished.emit()
	print("⌨️ Typewriter finished")

func _set_label_text(text: String):
	"""ラベルにテキストを設定（RichTextLabel/Label対応）"""
	if not target_label:
		return
		
	if target_label is RichTextLabel:
		target_label.text = text
	elif target_label is Label:
		target_label.text = text
	elif target_label.has_method("set_text"):
		target_label.text = text
	else:
		push_warning("⚠️ Unsupported label type: " + str(target_label.get_class()))

func _on_type_timer_timeout():
	"""通常文字のタイマータイムアウト"""
	_type_next_character()

func _on_punctuation_timer_timeout():
	"""句読点のタイマータイムアウト"""
	_type_next_character()

func _unhandled_input(event):
	"""スキップキー入力処理"""
	# UIManagerに制御を委譲するため、直接の入力処理は無効化
	return

# 設定変更関数
func set_speed(cps: float):
	"""タイプ速度を変更（文字/秒）"""
	characters_per_second = cps
	print("⌨️ Typewriter speed changed to: ", cps, " chars/sec")

func set_punctuation_delay(multiplier: float):
	"""句読点での遅延倍率を設定"""
	punctuation_delay_multiplier = multiplier

func is_typing_active() -> bool:
	"""現在タイプ中かどうか"""
	return is_typing

func get_typing_progress() -> float:
	"""タイプ進行率（0.0-1.0）"""
	if visible_text.is_empty():
		return 1.0
	return float(current_position) / float(visible_text.length())

# BBCode処理関数
func _extract_visible_text(bbcode_text: String) -> String:
	"""BBCodeタグを除去して表示テキストのみを抽出"""
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\]]+\\]")
	return regex.sub(bbcode_text, "", true)

func _build_bbcode_map():
	"""BBCodeタグと位置のマッピングを作成"""
	bbcode_map.clear()
	var regex = RegEx.new()
	regex.compile("\\[/?[^\\]]+\\]")
	
	var visible_pos = 0
	var original_pos = 0
	
	while original_pos < original_text.length():
		var match_result = regex.search(original_text, original_pos)
		
		if match_result and match_result.get_start() == original_pos:
			# BBCodeタグを発見
			var tag = match_result.get_string()
			bbcode_map[visible_pos] = bbcode_map.get(visible_pos, [])
			bbcode_map[visible_pos].append(tag)
			original_pos = match_result.get_end()
		else:
			# 通常の文字
			original_pos += 1
			visible_pos += 1

func _build_bbcode_substring(pos: int) -> String:
	"""指定位置までのBBCode付きテキストを構築"""
	var result = ""
	var open_tags: Array = []
	
	for i in range(pos):
		# この位置にBBCodeタグがあるか確認
		if bbcode_map.has(i):
			for tag in bbcode_map[i]:
				result += tag
				# 開始タグか終了タグかを判定してスタック管理
				if not tag.begins_with("[/"):
					open_tags.append(tag)
				else:
					# 終了タグの場合、対応する開始タグを除去
					var tag_name = tag.substr(2, tag.length() - 3)
					for j in range(open_tags.size() - 1, -1, -1):
						var open_tag = open_tags[j]
						if open_tag.begins_with("[" + tag_name):
							open_tags.remove_at(j)
							break
		
		# 文字を追加
		if i < visible_text.length():
			result += visible_text[i]
	
	# 未閉じタグを閉じる
	for i in range(open_tags.size() - 1, -1, -1):
		var tag = open_tags[i]
		var tag_name = tag.split("=")[0].substr(1)  # [color=red] -> color
		result += "[/" + tag_name + "]"
	
	return result

# === v2新機能: インラインタグ処理メソッド ===

func _check_and_execute_inline_tags_at_position(position: int):
	"""指定位置でインラインタグをチェック・実行"""
	for tag in processed_tags:
		if tag.start_position == position:
			print("🏷️ Executing inline tag '", tag.tag_name, "' at position ", position)
			inline_tag_executed.emit(tag.tag_name, tag.parameters)
			# 視覚効果と機能効果でターゲットを分ける
			var effect_target
			if tag.tag_name == "speed":
				# 速度変更はTypewriterText自体で処理
				effect_target = self
			else:
				# シェイクなどの視覚効果は実際のテキスト表示ラベルに適用
				effect_target = target_label if target_label else self
			
			print("🎯 Using effect target for '", tag.tag_name, "': ", effect_target, " (class: ", effect_target.get_class(), ")")
			await inline_tag_processor.execute_tag_at_position(tag, effect_target)

func _recalculate_tag_positions():
	"""インラインタグの位置をvisible_text基準で再計算"""
	# original_textとvisible_textの文字位置マッピングを作成
	var visible_to_original = []
	var original_pos = 0
	var visible_pos = 0
	var in_bbcode_tag = false
	
	while original_pos < original_text.length():
		var char = original_text[original_pos]
		
		if char == '[':
			in_bbcode_tag = true
		elif char == ']' and in_bbcode_tag:
			in_bbcode_tag = false
			original_pos += 1
			continue
		
		if not in_bbcode_tag:
			visible_to_original.append(original_pos)
			visible_pos += 1
		
		original_pos += 1
	
	# タグ位置をvisible_text基準で再計算
	for tag in processed_tags:
		var original_position = tag.start_position
		var visible_position = -1
		
		# original_positionに対応するvisible_positionを見つける
		for i in range(visible_to_original.size()):
			if visible_to_original[i] >= original_position:
				visible_position = i
				break
		
		if visible_position >= 0:
			print("🔄 Recalculating tag '", tag.tag_name, "': ", tag.start_position, " -> ", visible_position)
			tag.start_position = visible_position
		else:
			print("⚠️ Could not recalculate position for tag '", tag.tag_name, "' at original position ", original_position)

func _on_speed_changed(multiplier: float):
	"""速度変更シグナルハンドラー"""
	current_speed_multiplier = multiplier
	print("⚡ TypewriterText: Speed changed to ", multiplier, "x")

# === インラインタグ用の公開API ===

func add_custom_inline_tag(tag_name: String, tag_type: int = 6):  # TagType.CUSTOM = 6
	"""カスタムインラインタグを追加"""
	if inline_tag_processor:
		inline_tag_processor.add_custom_tag(tag_name, tag_type)

func get_supported_inline_tags() -> Array[String]:
	"""サポートされているインラインタグ一覧を取得"""
	if inline_tag_processor:
		return inline_tag_processor.get_supported_tags()
	return []

func get_inline_tag_help(tag_name: String) -> String:
	"""インラインタグのヘルプを取得"""
	if inline_tag_processor:
		return inline_tag_processor.get_tag_help(tag_name)
	return "InlineTagProcessor not available"